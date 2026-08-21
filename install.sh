#!/usr/bin/env bash
# Oh my tmux!
# 💛🩷💙🖤❤️🤍
# https://github.com/gpakosz/.tmux
# (‑●‑●)> dual licensed under the WTFPL v2 license and the MIT license,
#         without any warranty.
#         Copyright 2012— Gregory Pakosz (@gpakosz).
#
# ------------------------------------------------------------------------------
# 🚨 PLEASE REVIEW THE CONTENT OF THIS FILE BEFORE BLINDING PIPING TO CURL
# ------------------------------------------------------------------------------
{
if [ ${EUID:-$(id -u)} -eq 0 ]; then
  printf '❌ Do not execute this script as root!\n' >&2 && exit 1
fi

if [ -z "$BASH_VERSION" ]; then
  printf '❌ This installation script requires bash\n' >&2 && exit 1
fi

for cmd in tmux git perl sed awk; do
  if ! command -v "$cmd" > /dev/null 2>&1; then
    printf '❌ %s is not installed\n' "$cmd" >&2 && exit 1
  fi
done

is_true() {
  case "$1" in
    true|yes|1)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

if ! is_true "$PERMISSIVE" && [ -n "$TMUX" ]; then
  printf '❌ tmux is currently running, please terminate the server\n' >&2 && exit 1
fi

install() {
  printf '🎢 Installing Oh my tmux! Buckle up!\n' >&2
  printf '\n' >&2
  now="$(date +'%Y%m%d%H%M%S').$$"
  tilde=${HOME:+'~'}

  if [ -n "$XDG_CONFIG_HOME" ]; then
    TMUX_CONF="$XDG_CONFIG_HOME/tmux/tmux.conf"
  elif [ -d "$HOME/.config" ]; then
    TMUX_CONF="$HOME/.config/tmux/tmux.conf"
  else
    TMUX_CONF="$HOME/.tmux.conf"
  fi
  TMUX_CONF_LOCAL="$TMUX_CONF.local"
  TMUX_CONF_DIR=$(dirname "$TMUX_CONF")

  OH_MY_TMUX_CLONE_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/oh-my-tmux"

  printf '✅ Using %s\n' "${OH_MY_TMUX_CLONE_PATH/#"$HOME"/$tilde}" >&2
  printf '✅ Using %s\n' "${TMUX_CONF/#"$HOME"/$tilde}" >&2
  printf '✅ Using %s\n' "${TMUX_CONF_LOCAL/#"$HOME"/$tilde}" >&2

  printf '\n' >&2
  OH_MY_TMUX_REPOSITORY=${OH_MY_TMUX_REPOSITORY:-https://github.com/gpakosz/.tmux.git}
  OH_MY_TMUX_BRANCH=${OH_MY_TMUX_BRANCH:-}
  printf '⬇️ Cloning Oh my tmux! repository...\n' >&2
  if ! is_true "$DRY_RUN"; then
    mkdir -p "$(dirname "$OH_MY_TMUX_CLONE_PATH")"
    rm -rf "$OH_MY_TMUX_CLONE_PATH.new"
    trap 'rm -rf "$OH_MY_TMUX_CLONE_PATH.new"' EXIT
    if [ -n "$OH_MY_TMUX_BRANCH" ]; then
      if ! git clone -q --single-branch -b "$OH_MY_TMUX_BRANCH" "$OH_MY_TMUX_REPOSITORY" "$OH_MY_TMUX_CLONE_PATH.new"; then
        printf '❌ Failed to clone Oh my tmux! repository (branch: %s)\n' "$OH_MY_TMUX_BRANCH" >&2 && exit 1
      fi
    else
      if ! git clone -q --single-branch "$OH_MY_TMUX_REPOSITORY" "$OH_MY_TMUX_CLONE_PATH.new"; then
        printf '❌ Failed to clone Oh my tmux! repository\n' >&2 && exit 1
      fi
    fi
  fi

  printf '\n' >&2
  printf '🔎 Inspecting filesystem...\n' >&2
  for dir in "${XDG_CONFIG_HOME:-$HOME/.config}/tmux" "$HOME/.tmux"; do
    if [ -d "$dir" ] || [ -L "$dir" ]; then
      if ! is_true "$DRY_RUN" && ! mv "$dir" "$dir.$now"; then
        printf '❌ %s directory exists, failed to back up → %s\n' "${dir/#"$HOME"/$tilde}" "${dir/#"$HOME"/$tilde}.$now" >&2 && exit 1
      fi
      printf '⚠️ %s directory exists, made a backup → %s\n' "${dir/#"$HOME"/$tilde}" "${dir/#"$HOME"/$tilde}.$now" >&2
    fi
  done

  if ! is_true "$DRY_RUN" && ! mkdir -p "$TMUX_CONF_DIR"; then
    printf '❌ Failed to create %s\n' "${TMUX_CONF_DIR/#"$HOME"/$tilde}" >&2 && exit 1
  fi

  for conf in "$HOME/.tmux.conf" \
              "$HOME/.tmux.conf.local" \
              "${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf" \
              "${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf.local"; do
    if [ -L "$conf" ]; then
      printf '⚠️ %s symlink exists, removing → 🗑️\n' "${conf/#"$HOME"/$tilde}" >&2
      if ! is_true "$DRY_RUN"; then
        rm -f "$conf"
      fi
    elif [ -f "$conf" ]; then
      if ! is_true "$DRY_RUN" && ! mv "$conf" "$conf.$now"; then
        printf '❌ %s file exists, failed to back up → %s\n' "${conf/#"$HOME"/$tilde}" "${conf/#"$HOME"/$tilde}.$now" >&2 && exit 1
      fi
      printf '⚠️ %s file exists, made a backup → %s\n' "${conf/#"$HOME"/$tilde}" "${conf/#"$HOME"/$tilde}.$now" >&2
    fi
  done

  if [ -d "$OH_MY_TMUX_CLONE_PATH" ]; then
    if ! is_true "$DRY_RUN" && ! mv "$OH_MY_TMUX_CLONE_PATH" "$OH_MY_TMUX_CLONE_PATH.$now"; then
      printf '❌ %s exists, failed to back up → %s\n' "${OH_MY_TMUX_CLONE_PATH/#"$HOME"/$tilde}" "${OH_MY_TMUX_CLONE_PATH/#"$HOME"/$tilde}.$now" >&2 && exit 1
    fi
    printf '⚠️ %s exists, made a backup → %s\n' "${OH_MY_TMUX_CLONE_PATH/#"$HOME"/$tilde}" "${OH_MY_TMUX_CLONE_PATH/#"$HOME"/$tilde}.$now" >&2
  fi

  if ! is_true "$DRY_RUN" && ! mv "$OH_MY_TMUX_CLONE_PATH.new" "$OH_MY_TMUX_CLONE_PATH"; then
    printf '❌ Failed to move %s → %s\n' "${OH_MY_TMUX_CLONE_PATH/#"$HOME"/$tilde}.new" "${OH_MY_TMUX_CLONE_PATH/#"$HOME"/$tilde}" >&2 && exit 1
  fi
  trap - EXIT

  printf '\n' >&2
  if ! is_true "$DRY_RUN" && ! ln -snf "$OH_MY_TMUX_CLONE_PATH/.tmux.conf" "$TMUX_CONF"; then
    printf '❌ Failed to symlink %s → %s\n' "${TMUX_CONF/#"$HOME"/$tilde}" "${OH_MY_TMUX_CLONE_PATH/#"$HOME"/$tilde}/.tmux.conf" >&2 && exit 1
  fi
  printf '✅ Symlinked %s → %s\n' "${TMUX_CONF/#"$HOME"/$tilde}" "${OH_MY_TMUX_CLONE_PATH/#"$HOME"/$tilde}/.tmux.conf" >&2
  if ! is_true "$DRY_RUN" && ! cp "$OH_MY_TMUX_CLONE_PATH/.tmux.conf.local" "$TMUX_CONF_LOCAL"; then
    printf '❌ Failed to copy %s → %s\n' "${OH_MY_TMUX_CLONE_PATH/#"$HOME"/$tilde}/.tmux.conf.local" "${TMUX_CONF_LOCAL/#"$HOME"/$tilde}" >&2 && exit 1
  fi
  printf '✅ Copied %s → %s\n' "${OH_MY_TMUX_CLONE_PATH/#"$HOME"/$tilde}/.tmux.conf.local" "${TMUX_CONF_LOCAL/#"$HOME"/$tilde}" >&2

  if [ "${TMUX_PROGRAM:-tmux}" = "tmux" ]; then
    tmux() { command tmux ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} "$@"; }
  else
    tmux() { "$TMUX_PROGRAM" ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} "$@"; }
  fi
  if ! is_true "$DRY_RUN" && [ -n "$TMUX" ]; then
    tmux set-environment -g TMUX_CONF "$TMUX_CONF"
    tmux set-environment -g TMUX_CONF_LOCAL "$TMUX_CONF_LOCAL"
    tmux source "$TMUX_CONF"
  fi

  if [ -n "$TMUX" ]; then
    printf '\n' >&2
    printf '⚠️ Installed Oh my tmux! while tmux was running...\n' >&2
    printf '   → Existing sessions have outdated environment variables\n' >&2
    printf '     • TMUX_CONF\n' >&2
    printf '     • TMUX_CONF_LOCAL\n' >&2
    printf '     • TMUX_PROGRAM\n' >&2
    printf '     • TMUX_SOCKET\n' >&2
    printf '   → Some other things may not work 🤷\n' >&2
  fi

  printf '\n' >&2
  printf '🎉 Oh my tmux! successfully installed 🎉\n' >&2
}

if [ -p /dev/stdin ]; then
  printf '✋ STOP\n' >&2
  printf '   🤨 It looks like you are piping commands from the internet to your shell!\n' >&2
  if ! : 2>/dev/null < /dev/tty; then
    printf '   ⛔️ No terminal available to review the script...\n' >&2
    printf '      → Download install.sh and run it directly instead of piping to bash\n' >&2
    exit 1
  else
    printf "   🙏 Please take the time to review what's going to be executed...\n" >&2
  fi

  (
    printf '\n' >&2

    self() {
      printf '# Oh my tmux!\n'
      printf '# 💛🩷💙🖤❤️🤍\n'
      printf '# https://github.com/gpakosz/.tmux\n'
      printf '\n'

      declare -f install
    }

    while :; do
      printf '   Do you want to review the content? [Yes/No/Cancel] > ' >&2
      if ! read -r answer; then
        printf '\n⛔️ Installation aborted...\n' >&2 && exit 1
      fi
      case $(printf '%s\n' "$answer" | tr '[:upper:]' '[:lower:]') in
        y|yes)
          if command -v bat >/dev/null 2>&1; then
            self | LESS='' bat --paging always --file-name install.sh
          else
            case "${VISUAL:-${EDITOR}}" in
              *vim*) # vim, nvim, neovim ... compatible
                self | ${VISUAL:-${EDITOR}} -c ':set syntax=bash' -R -
                ;;
              *)
                tput smcup 2>/dev/null
                clear 2>/dev/null
                self | LESS='-R' ${PAGER:-less}
                tput rmcup 2>/dev/null
                ;;
            esac
          fi
          break
          ;;
        n|no)
          break
          ;;
        c|cancel)
          printf '\n' >&2
          printf '⛔️ Installation aborted...\n' >&2 && exit 1
          ;;
      esac
    done
  ) < /dev/tty || exit 1
  printf '\n' >&2
fi

install
}
