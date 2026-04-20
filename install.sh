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

if ! tmux -V >/dev/null 2>&1; then
  printf '❌ tmux is not installed\n' >&2 && exit 1
fi

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
  now=$(date +'%Y%d%m%S')

  for dir in "${XDG_CONFIG_HOME:-$HOME/.config}/tmux" "$HOME/.tmux"; do
    if [ -d "$dir" ]; then
      printf '⚠️  %s directory exists, making a backup → %s\n' "${dir/#"$HOME"/'~'}" "${dir/#"$HOME"/'~'}.$now" >&2
      if ! is_true "$DRY_RUN"; then
        mv "$dir" "$dir.$now"
      fi
    fi
  done

  for conf in "$HOME/.tmux.conf" \
              "$HOME/.tmux.conf.local" \
              "${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf" \
              "${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf.local"; do
    if [ -f "$conf" ]; then
      if [ -L "$conf" ]; then
        printf '⚠️  %s symlink exists, removing → 🗑️\n' "${conf/#"$HOME"/'~'}" >&2
        if ! is_true "$DRY_RUN"; then
          rm -f "$conf"
        fi
      else
        printf '⚠️  %s file exists, making a backup -> %s\n' "${conf/#"$HOME"/'~'}" "${conf/#"$HOME"/'~'}.$now" >&2
        if ! is_true "$DRY_RUN"; then
          mv "$conf" "$conf.$now"
        fi
      fi
    fi
  done

  if [ -d "${XDG_CONFIG_HOME:-$HOME/.config}" ]; then
    mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/tmux"
    TMUX_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf"
  else
    TMUX_CONF="$HOME/.tmux.conf"
  fi
  TMUX_CONF_LOCAL="$TMUX_CONF.local"

  OH_MY_TMUX_CLONE_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/oh-my-tmux"
  if [ -d "$OH_MY_TMUX_CLONE_PATH" ]; then
    printf '⚠️  %s exists, making a backup\n' "${OH_MY_TMUX_CLONE_PATH/#"$HOME"/'~'}" >&2
    printf '%s → %s\n' "${OH_MY_TMUX_CLONE_PATH/#"$HOME"/'~'}" "${OH_MY_TMUX_CLONE_PATH/#"$HOME"/'~'}.$now" >&2
    if ! is_true "$DRY_RUN"; then
      mv "$OH_MY_TMUX_CLONE_PATH" "$OH_MY_TMUX_CLONE_PATH.$now"
    fi
  fi

  printf '\n'
  printf '✅ Using %s\n' "${OH_MY_TMUX_CLONE_PATH/#"$HOME"/'~'}" >&2
  printf '✅ Using %s\n' "${TMUX_CONF/#"$HOME"/'~'}" >&2
  printf '✅ Using %s\n' "${TMUX_CONF_LOCAL/#"$HOME"/'~'}" >&2

  printf '\n'
  OH_MY_TMUX_REPOSITORY=${OH_MY_TMUX_REPOSITORY:-https://github.com/gpakosz/.tmux.git}
  printf '⬇️  Cloning Oh my tmux! repository...\n' >&2
  if ! is_true "$DRY_RUN"; then
    mkdir -p "$(dirname "$OH_MY_TMUX_CLONE_PATH")"
    if ! git clone -q --single-branch "$OH_MY_TMUX_REPOSITORY" "$OH_MY_TMUX_CLONE_PATH"; then
      printf '❌ Failed\n' >&2 && exit 1
    fi
  fi

  printf '\n'
  if is_true "$DRY_RUN" || ln -s -f "$OH_MY_TMUX_CLONE_PATH/.tmux.conf" "$TMUX_CONF"; then
    printf '✅ Symlinked %s → %s\n' "${TMUX_CONF/#"$HOME"/'~'}" "${OH_MY_TMUX_CLONE_PATH/#"$HOME"/'~'}/.tmux.conf" >&2
  fi
  if is_true "$DRY_RUN" || cp "$OH_MY_TMUX_CLONE_PATH/.tmux.conf.local" "$TMUX_CONF_LOCAL"; then
    printf '✅ Copied %s → %s\n' "${OH_MY_TMUX_CLONE_PATH/#"$HOME"/'~'}/.tmux.conf.local" "${TMUX_CONF_LOCAL/#"$HOME"/'~'}" >&2
  fi

  tmux() {
    ${TMUX_PROGRAM:-tmux} ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} "$@"
  }
  if ! is_true "$DRY_RUN" && [ -n "$TMUX" ]; then
    tmux set-environment -g TMUX_CONF "$TMUX_CONF"
    tmux set-environment -g TMUX_CONF_LOCAL "$TMUX_CONF_LOCAL"
    tmux source "$TMUX_CONF"
  fi

  if [ -n "$TMUX" ]; then
    printf '\n' >&2
    printf '⚠️  Installed Oh my tmux! while tmux was running...\n' >&2
    printf '→ Existing sessions have outdated environment variables\n' >&2
    printf '  • TMUX_CONF\n' >&2
    printf '  • TMUX_CONF_LOCAL\n' >&2
    printf '  • TMUX_PROGRAM\n' >&2
    printf '  • TMUX_SOCKET\n' >&2
    printf '→ Some other things may not work 🤷\n' >&2
  fi

  printf '\n' >&2
  printf '🎉 Oh my tmux! successfully installed 🎉\n' >&2
}

if [ -p /dev/stdin ]; then
  printf '✋ STOP\n' >&2
  printf '   🤨 It looks like you are piping commands from the internet to your shell!\n' >&2
  printf "   🙏 Please take the time to review what's going to be executed...\n" >&2

  (
    printf '\n'

    self() {
      printf '# Oh my tmux!\n'
      printf '# 💛🩷💙🖤❤️🤍\n'
      printf '# https://github.com/gpakosz/.tmux\n'
      printf '\n'

      declare -f install
    }

    while :; do
      printf '   Do you want to review the content? [Yes/No/Cancel] > ' >&2
      read -r answer >&2
      case $(printf '%s\n' "$answer" | tr '[:upper:]' '[:lower:]') in
        y|yes)
          case "$(command -v bat)${VISUAL:-${EDITOR}}" in
            *bat*)
              self | LESS='' bat --paging always --file-name install.sh
              ;;
            *vim*) # vim, nvim, neovim ... compatible
              self | ${VISUAL:-${EDITOR}} -c ':set syntax=tmux' -R -
              ;;
            *)
              tput smcup
              clear
              self | LESS='-R' ${PAGER:-less}
              tput rmcup
              ;;
          esac
          break
          ;;
        n|no)
          break
          ;;
        c|cancel)
          printf '\n'
          printf '⛔️ Installation aborted...\n' >&2 && exit 1
          ;;
      esac
    done
  ) < /dev/tty || exit 1
  printf '\n'
fi

install
}
