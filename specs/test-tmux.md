# Spec: TDD test suite for the oh-my-tmux config using libtmux's pytest plugin

## Context

This repo is a fork of `gpakosz/.tmux` ("oh-my-tmux"): a two-file tmux config —
`.tmux.conf` (upstream base, **never edited**) plus `.tmux.conf.local` (all of our
deviations). `CLAUDE.md` documents a precise contract of how our `.local` differs
from the upstream template (clipboard, history, mouse, the 4-plugin TPM block,
the `#{prefix_highlight}` status token, the macOS `reattach` guard, sentinel
fences). The only automated check is `make docker-smoke`, which boots a headless
tmux in a container and eyeballs two options.

The risk: every upstream re-sync can silently drop one of our deviations, and
nothing fails when it does. We want an executable contract — a TDD-style test
suite — that pins the documented behavior so drift turns red.

## Objective

A `uv`-managed pytest suite (run via `uv run pytest`) that:
1. **Live layer (libtmux):** boots a real, hermetic tmux server with our config and
   asserts effective runtime options and key bindings.
2. **Static layer (file parse):** asserts file-level contracts that can't be observed
   at runtime (4 `@plugin` declarations, `#{prefix_highlight}` token, sentinel
   fences).
3. Runs locally via `uv run pytest`, via `make test`, and in GitHub Actions CI.

## Config Loading Mechanism

`.tmux.conf:153-161` — when tmux starts with `-f <path>`, if `TMUX_CONF` env var is
empty, it scans `$HOME/.tmux.conf` → `$XDG_CONFIG_HOME/tmux/tmux.conf` →
`$HOME/.config/tmux/tmux.conf`, then sets `TMUX_CONF_LOCAL=$TMUX_CONF.local` and
sources it. The test fixture sets `HOME` to a temp dir containing `.tmux.conf`
(symlink to repo) and `.tmux.conf.local` (copy), mirroring `make place-configs`.

## TPM Hermeticity

Our `.local` enables TPM with `tmux_conf_update_plugins_on_launch=true`; in a fresh
temp HOME, oh-my-tmux would `git clone` TPM from the network. The fixture pre-creates
a no-op `~/.tmux/plugins/tpm/tpm` stub (exit 0) so the clone is skipped. Core
options under test (`history-limit`, `mouse`, bindings) are set by plain tmux
commands in `.local`, independent of TPM.

## Files

### New Files
- `specs/test-tmux.md` — this spec
- `pyproject.toml` — uv project; dev deps `libtmux>=0.30`, `pytest>=8.0`
- `tests/__init__.py` — empty
- `tests/conftest.py` — fixtures: `repo_root`, `tmux_home`, `stock_tmux_home`,
  `tmux_server`, `stock_tmux_server`, and helpers `global_option()`, `list_keys()`
- `tests/test_discovery.py` — sanity: server boots with our config
- `tests/test_options_live.py` — libtmux live assertions (effective options/bindings)
- `tests/test_local_static.py` — file-parse assertions (plugins, sentinels, tokens)
- `tests/test_discriminator.py` — proves live tests genuinely discriminate local vs stock
- `tests/fixtures/stock.tmux.conf.local` — minimal upstream-defaults-only local config
- `.github/workflows/test.yml` — CI workflow
- `.python-version` — Python 3.12
- `Makefile` — add `test` target (edit)

### Existing (reference only, never edit `.tmux.conf`)
- `.tmux.conf` — upstream base; `:32` sets `history-limit 5000`; `:35,38` set `bind e`/`bind r`; `:107` sets `bind m` (overridden by our .local); `:153-161` is the discovery logic
- `.tmux.conf.local` — source of truth; key lines: `copy_to_os_clipboard=true` (373), `reattach` if-shell (388-389), `history-limit 20000` (392), `mouse on` (395), `bind m` with display (413), 4 `@plugin` lines (457-464), `#{prefix_highlight}` in status_right (274), `# EOF` (480) / `# "$@"` (517) sentinels

## Deviation Contract (assertions encoded as tests)

| Deviation | File location | Test layer | Test file |
|---|---|---|---|
| `history-limit 20000` (upstream: 5000) | .local:392 | Live | test_options_live.py |
| `mouse on` | .local:395 | Live | test_options_live.py |
| `bind m` with display message | .local:413 | Live | test_options_live.py |
| `bind r` / `bind e` (upstream sanity) | .tmux.conf:35,38 | Live | test_options_live.py |
| macOS `reattach` guard | .local:388-389 | Live (darwin-only) | test_options_live.py |
| `tmux-resurrect` plugin | .local:457 | Static | test_local_static.py |
| `tmux-prefix-highlight` plugin | .local:458 | Static | test_local_static.py |
| `tmux-continuum` plugin | .local:459 | Static | test_local_static.py |
| `sainnhe/tmux-fzf` plugin | .local:464 | Static | test_local_static.py |
| `@resurrect-capture-pane-contents 'on'` | .local:461 | Static | test_local_static.py |
| `@continuum-restore 'on'` | .local:463 | Static | test_local_static.py |
| No `tmux-plugins/tpm` manual bootstrap | .local (absent) | Static | test_local_static.py |
| `#{prefix_highlight}` in status_right | .local:274 | Static | test_local_static.py |
| `tmux_conf_copy_to_os_clipboard=true` | .local:373 | Static | test_local_static.py |
| `# EOF` sentinel present | .local:480 | Static | test_local_static.py |
| `# "$@"` sentinel present + after EOF | .local:517 | Static | test_local_static.py |

## Step by Step Tasks

### 1. Write the spec file ✓
This file: `specs/test-tmux.md`.

### 2. Scaffold the uv project
- Create `pyproject.toml` with `[dependency-groups] dev = ["libtmux>=0.30", "pytest>=8.0"]`
- Create `.python-version` with `3.12`
- Run `uv sync --group dev`

### 3. Write `tests/conftest.py`
- `repo_root` fixture (session scope)
- `tmux_home(tmp_path_factory, repo_root)` fixture (session scope): creates temp HOME
  with `.tmux.conf` symlink, `.tmux.conf.local` copy, and no-op TPM stub
- `stock_tmux_home(tmp_path_factory, repo_root)` fixture (session scope): same but
  copies `tests/fixtures/stock.tmux.conf.local`
- `tmux_server(tmux_home, monkeypatch)` fixture (function scope): sets HOME, starts
  `libtmux.Server` with `config_file=home/.tmux.conf`, creates session, then
  explicitly calls `source-file home/.tmux.conf.local` to ensure deviations are
  applied synchronously (bypasses the async `run` from startup)
- `stock_tmux_server` fixture (function scope): same pattern with stock home
- `global_option(server, name)` helper: parses `show-options -g <name>` output
- `list_keys(server, table="")` helper: returns `list-keys` output as one string

### 4. Write `tests/test_discovery.py`
- `test_server_boots(tmux_server)`: `assert tmux_server.is_alive()`

### 5. Write `tests/test_options_live.py`
- `test_history_limit_20000(tmux_server)`: global `history-limit == "20000"`
- `test_mouse_on(tmux_server)`: global `mouse == "on"`
- `test_mouse_toggle_binding_has_display(tmux_server)`: our local `bind m` adds
  `\; display 'mouse ...'` — check for `"display 'mouse"` in list-keys
- `test_reload_binding_r(tmux_server)`: `bind r` with source in list-keys
- `test_edit_binding_e(tmux_server)`: `bind e` with TMUX_CONF_LOCAL in list-keys
- `test_reattach_macos_guard(tmux_server)`: darwin-only; `default-command` contains
  `reattach-to-user-namespace`; skip if `reattach-to-user-namespace` not on PATH

### 6. Write `tests/test_local_static.py`
Read `repo_root/.tmux.conf.local` once as a module-level fixture.
- `test_plugin_resurrect`
- `test_plugin_prefix_highlight`
- `test_plugin_continuum`
- `test_plugin_tmux_fzf`
- `test_resurrect_capture_pane_contents_on`
- `test_continuum_restore_on`
- `test_no_tpm_bootstrap_line`
- `test_prefix_highlight_in_status_right`
- `test_copy_to_os_clipboard_true`
- `test_eof_sentinel_present`
- `test_at_sentinel_present`
- `test_sentinels_in_order`

### 7. Write `tests/fixtures/stock.tmux.conf.local`
Minimal file with sentinel fences only — no deviations. Used by discriminator tests.

### 8. Write `tests/test_discriminator.py`
- `test_history_limit_discriminates`: local server → 20000; stock server → 5000
- `test_mouse_discriminates`: local → on; stock → off
- `test_mouse_toggle_display_discriminates`: local `bind m` → has `display 'mouse`;
  stock `bind m` (upstream) → does not have `display 'mouse'`

### 9. Update `Makefile`
Add `test` target: `uv run pytest -q` and add to `.PHONY`.

### 10. Write `.github/workflows/test.yml`
Ubuntu latest; install tmux; install uv via `astral-sh/setup-uv@v4`; `uv sync --group dev`; `uv run pytest -q`.

### 11. Validate
Run validation commands below.

## Acceptance Criteria

- `uv run pytest` collects and passes all tests in `tests/`
- Live tests boot a real libtmux Server in isolated temp HOME with TPM stub (no network)
- Every documented deviation in `CLAUDE.md` has at least one assertion
- `make test` runs the suite
- `.github/workflows/test.yml` is present and syntactically valid
- Removing `set -g mouse on` from `.local` turns `test_mouse_on` red (spot-check)

## Validation Commands

```bash
uv sync --group dev
uv run python -c "import libtmux, pytest; print(libtmux.__version__)"
tmux -V
uv run pytest -q
uv run pytest tests/test_options_live.py -q
uv run pytest tests/test_local_static.py -q
uv run pytest tests/test_discriminator.py -q
make test
```

## Notes

- Do NOT edit `.tmux.conf`
- `.tmux.conf:32` sets `history-limit 5000` upstream; our `.local:392` overrides to 20000
- `.tmux.conf:107` sets `bind m run "...toggle_mouse"`; our `.local:413` overrides to
  add `\; display 'mouse #{?#{mouse},on,off}'` — this is what we test in live discriminator
- `make docker-smoke` remains as coarse container smoke; this suite is the fine-grained contract
- Confirm `.dockerignore` excludes `tests/`, `pyproject.toml`, `uv.lock` (it already excludes `specs`)
- `uv add --dev libtmux pytest` or `uv sync --group dev` after pyproject.toml is written
