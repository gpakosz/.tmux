# Plan: Modernize oh-my-tmux fork against upstream (preserving local customizations) + Dockerfile test harness

## Task Description
This fork (`bossjones/.tmux`) branched off `gpakosz/.tmux` ("oh-my-tmux") on **2021-01-11** and is now **149 commits behind** upstream (upstream latest: 2026-02-21), carrying **10** fork-only commits. The base `.tmux.conf` has been rewritten upstream (+1303/−846) and the `.tmux.conf.local` template gained new options (+139/−34). The goal is to bring `.tmux.conf` and `.tmux.conf.local` up to upstream's current state while **preserving the user's specific customizations**, and to add a `Dockerfile` that lets the user exercise the result in an interactive `zsh` shell inside a container.

For this task the "never edit `.tmux.conf`" rule is relaxed: **both `.tmux.conf` and `.tmux.conf.local` may be changed.**

## Objective
When complete:
1. `.tmux.conf` is byte-identical to upstream `gpakosz/.tmux@master` (the read-only base picks up 5 years of fixes).
2. `.tmux.conf.local` is upstream's current template **with the user's specific deviations re-applied** (plugins, clipboard, paths, history, mouse).
3. `CLAUDE.md` is updated to reflect the new upstream baseline (new options, version floor).
4. A `Dockerfile` (+ `.dockerignore`) builds an Ubuntu image with `zsh` as the default shell, oh-my-zsh installed, and all binaries oh-my-tmux needs at runtime, dropping the user into an interactive shell where `tmux` works and installs plugins on first launch.

## Problem Statement
A 5-year-old fork misses macOS/Wayland clipboard fixes, `tmux-256color` defaults, RGB 24-bit auto-detection, tmux 3.2/3.4 stock-binding compatibility, robust version detection, the `tmux_conf_theme` toggle, `@tpm_plugins` support, and many `_pane_info()`/ssh-introspection reworks. A naive `git merge upstream/master` would produce large conflicts in `.tmux.conf.local` because the local file mixes upstream template defaults with a handful of real user edits. We need a surgical re-base of the template that keeps exactly the user's edits and nothing stale.

## Solution Approach
Treat the two files differently:
- **`.tmux.conf`** — no user content lives here; **overwrite wholesale** with upstream's current version.
- **`.tmux.conf.local`** — start from **upstream's current template** and re-apply only the user's verified deviations (enumerated below). This avoids carrying forward removed/renamed template options and guarantees the new options (`tmux_conf_theme`, `tmux_conf_preserve_stock_bindings`, etc.) are present with sane defaults.

The user's deviations from the upstream template default values are small and fully enumerated in "The user's specific changes to preserve" — everything else in the current local file is just an old copy of the template defaults and is intentionally discarded in favor of the new template.

Validate everything in a disposable container (`Dockerfile`) so the running tmux on the user's host is never the test surface.

## Relevant Files
Use these files to complete the task:

- `.tmux.conf` — upstream base; **replace wholesale** with `gpakosz/.tmux@master` version (current upstream: 1900 lines).
- `.tmux.conf.local` — user override file; **rebuild from upstream template + re-applied user edits** (current local: 416 lines; upstream template: 509 lines).
- `CLAUDE.md` — update plugin list note, new options, and tmux version floor (upstream dropped tmux < 2.6).
- `Makefile` — review `place-configs`/`reload`; no functional change required, but confirm symlink/copy still matches upstream layout.
- `extra.sh` — unchanged (fzf-tmux helpers); out of scope.
- `README.md` — optional: pull upstream's refreshed README (out of scope unless requested).

### New Files
- `Dockerfile` — Ubuntu 24.04 image, zsh default shell, oh-my-zsh, all runtime deps, configs wired in. Full content in **Appendix A**.
- `.dockerignore` — keep the build context small (exclude `.git`, backups, scratch).

## The user's specific changes to preserve
These are the ONLY deviations from the upstream `.tmux.conf.local` template defaults that must be carried into the new template. Everything else in the current local file matches old upstream defaults and is replaced by the new template.

| # | Setting | Value to set | Upstream template default | Location in `.tmux.conf.local` |
|---|---------|--------------|---------------------------|--------------------------------|
| 1 | `tmux_conf_new_pane_retain_current_path` | `true` | `true` (now matches — no-op, keep) | display/paths section |
| 2 | `tmux_conf_copy_to_os_clipboard` | `true` | `false` | clipboard section |
| 3 | `reattach-to-user-namespace` if-shell guard | keep block | absent | user customizations section |
| 4 | `set -g history-limit 20000` | keep | absent (commented examples only) | user customizations section |
| 5 | `set -g mouse on` | keep | absent | user customizations section |
| 6 | TPM plugins block | keep all 4 + options | template ships none enabled | tpm section |

TPM block to preserve verbatim:
```tmux
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-prefix-highlight'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @resurrect-capture-pane-contents 'on'
set -g @continuum-restore 'on'
set -g @plugin 'sainnhe/tmux-fzf'
```

Notes:
- `tmux_conf_update_plugins_on_launch=true` / `tmux_conf_update_plugins_on_reload=true` in the current local file equal upstream defaults — no action needed; the new template already has them.
- The entire theme/colour block (colours 1–17, status-left/right, separators, battery symbols) in the current local file is identical to the **old** upstream template default and should NOT be hand-carried — it is superseded by the new template's theme block. If the user had truly customized colours we would diff them, but they did not.

## New upstream template options to surface (defaults are fine)
These exist in the new template and will appear automatically once `.tmux.conf.local` is rebuilt from it; leave at upstream defaults unless the user wants otherwise:
- `tmux_conf_theme` (enable/disable all theming)
- `tmux_conf_preserve_stock_bindings`
- `tmux_conf_new_session_retain_current_path`
- `tmux_conf_new_window_reconnect_ssh`
- `tmux_conf_uninstall_plugins_on_reload`
- `tmux_conf_urlscan_options`

## Implementation Phases
### Phase 1: Foundation
- Create a safety branch and back up current configs (the repo already has `make backup`).
- Fetch upstream's current `.tmux.conf` and `.tmux.conf.local`.

### Phase 2: Core Implementation
- Overwrite `.tmux.conf` with upstream.
- Rebuild `.tmux.conf.local` from upstream template, re-applying the 6 preserved edits.
- Update `CLAUDE.md`.

### Phase 3: Integration & Polish
- Add `Dockerfile` + `.dockerignore`.
- Build the image, launch interactively, confirm tmux starts, theme renders, plugins install, and the 6 customizations are in effect.

## Step by Step Tasks
IMPORTANT: Execute every step in order, top to bottom.

### 1. Branch and back up
- Confirm work happens on a feature branch (current: `feature-modern-tmux`).
- Run `make backup` to produce `backup.tar.gz` of the current configs.
- Add the upstream remote if missing: `git remote add upstream https://github.com/gpakosz/.tmux.git` then `git fetch upstream`.

### 2. Replace the base `.tmux.conf` with upstream
- Overwrite the file with upstream's current version:
  `git checkout upstream/master -- .tmux.conf`
  (or `curl -fsSL https://raw.githubusercontent.com/gpakosz/.tmux/master/.tmux.conf -o .tmux.conf`).
- Do NOT hand-edit; this is the read-only base.

### 3. Rebuild `.tmux.conf.local` from upstream template
- Start from upstream's template:
  `curl -fsSL https://raw.githubusercontent.com/gpakosz/.tmux/master/.tmux.conf.local -o .tmux.conf.local`
- Re-apply the 6 preserved edits from the table above:
  - Set `tmux_conf_copy_to_os_clipboard=true`.
  - Confirm `tmux_conf_new_pane_retain_current_path=true` (already default).
  - In the "user customizations" section, add the `reattach-to-user-namespace` if-shell guard, `set -g history-limit 20000`, and `set -g mouse on`.
  - In the "tpm" section, add the 6-line TPM plugins block verbatim.
- Leave all new upstream options at their template defaults.

### 4. Update `CLAUDE.md`
- Note the new baseline (synced to upstream `master`, date of sync).
- Document the 6 new template options now available.
- Note the tmux version floor (upstream requires tmux >= 2.6).
- Keep the "never edit `.tmux.conf`" rule (the relaxation was a one-time sync, not a standing policy).

### 5. Add `.dockerignore`
- Create `.dockerignore` with content from **Appendix B** so `.git`, backups, and scratch files stay out of the build context.

### 6. Add `Dockerfile`
- Create `Dockerfile` at the repo root with content from **Appendix A**.

### 7. Build and validate in the container
- Run the validation commands in the "Validation Commands" section.
- Inside the container: launch `tmux`, verify the status line renders, `<prefix> + I` (or auto-install) pulls TPM + the 4 plugins, mouse works, history-limit is 20000, and `tmux_conf_copy_to_os_clipboard` is active.

### 8. Final review
- `git diff` the three changed files; confirm `.tmux.conf` matches upstream exactly and `.tmux.conf.local` differs from the template only by the 6 preserved edits.

## Testing Strategy
- **Static**: `tmux -f .tmux.conf -L modern_test source-file .tmux.conf` inside the container exits 0 (config parses). Also run the upstream-shipped check: `tmux -f /dev/null -L cfgtest new-session -d \; source-file ~/.tmux.conf \; kill-server`.
- **Config-diff assertion**: diff the rebuilt `.tmux.conf.local` against the freshly downloaded template and confirm only the 6 expected hunks appear.
- **Runtime smoke test** (interactive, in container):
  - `tmux new-session -d -s smoke` then `tmux show-options -g | grep -E 'history-limit|mouse'` shows `history-limit 20000` and `mouse on`.
  - `tmux display-message -p '#{history_limit}'` returns `20000`.
  - First interactive `tmux` launch clones `~/.tmux/plugins/tpm` and the 4 plugins (network required at runtime).
- **Edge cases**: no saved resurrect state (continuum-restore is a harmless no-op); no X/Wayland display in container (clipboard integration installs but is inert — expected, does not error); `TERM` outside tmux is `xterm-256color`, tmux switches to `tmux-256color` internally.

## Acceptance Criteria
- `diff <(curl -fsSL .../gpakosz/.tmux/master/.tmux.conf) .tmux.conf` is empty.
- `.tmux.conf.local` contains all 6 preserved edits and all 6 new upstream options.
- `docker build` succeeds; `docker run -it` drops into an interactive `zsh` (default login shell).
- Inside the container, `tmux` starts without config errors and installs TPM + 4 plugins.
- `CLAUDE.md` reflects the new baseline.
- No changes to `.tmux.conf` beyond the upstream sync (no local hand-edits).

## Validation Commands
Execute these commands to validate the task is complete:

- `git fetch upstream && diff <(git show upstream/master:.tmux.conf) .tmux.conf` — must print nothing (base matches upstream).
- `grep -nE 'tmux_conf_copy_to_os_clipboard=true|history-limit 20000|set -g mouse on|@plugin .tmux-plugins/tmux-resurrect.|@plugin .sainnhe/tmux-fzf.|@continuum-restore' .tmux.conf.local` — must show all preserved edits.
- `grep -cE 'tmux_conf_theme=|tmux_conf_preserve_stock_bindings=|tmux_conf_urlscan_options=' .tmux.conf.local` — must be `3` (new options present).
- `docker build -t oh-my-tmux-test .` — image builds.
- `docker run --rm oh-my-tmux-test zsh -lc 'echo $SHELL; tmux -V; tmux -f /dev/null -L ci new-session -d \; source-file ~/.tmux.conf \; show-options -g history-limit \; kill-server'` — prints `/usr/bin/zsh`, a tmux >= 3.x version, and `history-limit 20000` with no parse errors.
- `docker run -it --rm oh-my-tmux-test` then run `tmux` — interactive confirmation that plugins install and the status line renders.

## Notes
- Build context is the repo root; `Dockerfile` `COPY`s `.tmux.conf` and `.tmux.conf.local`, so the image always reflects the working tree under test.
- `reattach-to-user-namespace` is macOS-only and intentionally absent in the Linux container; the if-shell guard makes that a no-op (no error).
- Runtime plugin install needs outbound access to github.com; the upstream base already checks connectivity before attempting installs.
- `README.md` refresh from upstream is deliberately out of scope to keep the diff reviewable; do it as a follow-up if desired.
- If the user later wants ongoing upstream tracking, the clean path is `git merge upstream/master` going forward now that the base is realigned — but that is future work, not part of this task.

---

## Appendix A — `Dockerfile`
```dockerfile
# Interactive test harness for the oh-my-tmux fork.
# Build context must be the repo root (the dir containing .tmux.conf).
#
#   docker build -t oh-my-tmux-test .
#   docker run -it --rm oh-my-tmux-test
#   (inside the container) $ tmux
#
FROM ubuntu:24.04

ARG USER=tmuxer

# Non-interactive apt; UTF-8 locale so the status-line glyphs render.
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TERM=xterm-256color

# Runtime dependencies oh-my-tmux actually shells out to, plus conveniences:
#   tmux git curl ca-certificates  -> core + plugin/TPM bootstrap over https
#   zsh                            -> default login shell
#   locales ncurses-bin ncurses-term -> UTF-8 + tmux-256color terminfo
#   procps psmisc lsof             -> ps/pgrep/pkill/lsof for _pane_info() & ssh introspection
#   gawk sed grep coreutils bc     -> status-line helpers (battery/uptime/loadavg math)
#   xsel xclip wl-clipboard        -> clipboard integration targets (inert without a display, but present)
#   openssh-client                 -> ssh args probing for #{username}/#{hostname}
#   vim                            -> <prefix> + e edit-config target
RUN apt-get update && apt-get install -y --no-install-recommends \
        tmux \
        git \
        curl \
        ca-certificates \
        zsh \
        locales \
        ncurses-bin \
        ncurses-term \
        procps \
        psmisc \
        lsof \
        gawk \
        sed \
        grep \
        coreutils \
        bc \
        xsel \
        xclip \
        wl-clipboard \
        openssh-client \
        vim \
        sudo \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user whose DEFAULT shell is zsh.
RUN useradd --create-home --shell /usr/bin/zsh ${USER} \
    && echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER} \
    && chmod 0440 /etc/sudoers.d/${USER}

USER ${USER}
WORKDIR /home/${USER}

# Install oh-my-zsh unattended (keeps zsh as the login shell, no chsh prompt).
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Wire in the fork's configs exactly like `make place-configs`:
#   ~/.tmux.conf  -> symlink to the read-only base in /opt/oh-my-tmux
#   ~/.tmux.conf.local -> copy of the user override file
COPY --chown=${USER}:${USER} .tmux.conf       /opt/oh-my-tmux/.tmux.conf
COPY --chown=${USER}:${USER} .tmux.conf.local /home/${USER}/.tmux.conf.local
RUN ln -sf /opt/oh-my-tmux/.tmux.conf /home/${USER}/.tmux.conf

# Drop straight into an interactive login zsh; the user then runs `tmux`.
CMD ["/usr/bin/zsh", "-l"]
```

## Appendix B — `.dockerignore`
```
.git
.gitignore
backup.tar.gz
*.tar.gz
.claude
specs
scratchpad
README.md
```
