#!/bin/sh
# tmux-theme.sh — theme switcher for the gpakosz .tmux framework (POSIX sh)
#
# Themes live in ~/.tmux/themes/<name>.tmux-theme as plain
# `tmux_conf_theme_*` lines (tmux `name=value` env-var syntax).
#
# usage:
#   tmux-theme.sh list             list available themes (* = active)
#   tmux-theme.sh current          print active theme name
#   tmux-theme.sh apply <name>     activate a theme and re-apply it
#   tmux-theme.sh next [current]   cycle to the next theme
#   tmux-theme.sh menu             tmux display-menu picker
#   tmux-theme.sh pick             interactive live-preview picker (popup)
#
# keybindings (see .tmux.conf.local):
#   <prefix> T  -> pick (up/down preview, enter done, q revert)
#
# how it works:
#   apply = write active pointer + sync server env (tmux source-file)
#           + re-run the framework's _apply_theme with a self-contained
#           env (theme file + local conf vars), so it never depends on
#           a stale run-shell environment snapshot.

set -u

# resolve the repository root — works for any install layout:
#   1. TMUX_THEME_ROOT: set by the .local startup `run` line under tmux
#   2. TMUX_CONF (symlink to <root>/.tmux.conf): set by the framework
#   3. the script's own location as a last resort
if [ -n "${TMUX_THEME_ROOT:-}" ]; then
    ROOT="${TMUX_THEME_ROOT}"
elif [ -n "${TMUX_CONF:-}" ]; then
    root_conf="$TMUX_CONF"
    root_target="$(readlink "$root_conf" 2>/dev/null)"
    [ -z "$root_target" ] && root_target="$root_conf"
    [ "${root_target:0:1}" != "/" ] && root_target="$(dirname "$root_conf")/$root_target"
    ROOT="$(dirname "$root_target")"
else
    ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
fi

THEMES_DIR="${TMUX_THEMES_DIR:-$ROOT/themes}"
ACTIVE_FILE="$THEMES_DIR/active"
TMUX_CONF="${TMUX_CONF:-$ROOT/.tmux.conf}"
TMUX_CONF_LOCAL="${TMUX_CONF_LOCAL:-$ROOT/.tmux.conf.local}"
LOCK_DIR="${TMPDIR:-/tmp}/.tmux-theme.lock"

themes() { # names, space-separated, alphabetical
    out=""
    for f in "$THEMES_DIR"/*.tmux-theme; do
        [ -e "$f" ] || continue
        out="$out $(basename "$f" .tmux-theme)"
    done
    printf '%s' "$out"
}

current() {
    cat "$ACTIVE_FILE" 2>/dev/null
}

acquire_lock() { # serialize concurrent applies; break stale locks (>10s)
    i=0
    while :; do
        if mkdir "$LOCK_DIR" 2>/dev/null; then
            date +%s > "$LOCK_DIR/ts" 2>/dev/null
            return 0
        fi
        i=$((i + 1))
        [ "$i" -ge 100 ] && return 1 # gave up after ~10s
        ts="$(cat "$LOCK_DIR/ts" 2>/dev/null)"
        case "$ts" in
            ''|*[!0-9]*) : ;;
            *)
                if [ $(( $(date +%s) - ts )) -gt 10 ]; then
                    rm -f "$LOCK_DIR/ts" 2>/dev/null
                    rmdir "$LOCK_DIR" 2>/dev/null
                fi
                ;;
        esac
        sleep 0.1
    done
}

release_lock() {
    rm -f "$LOCK_DIR/ts" 2>/dev/null
    rmdir "$LOCK_DIR" 2>/dev/null
}

cleanup() { # single EXIT trap: restore tty (pick) + release lock (apply)
    if [ "${stty_raw:-0}" = 1 ] && [ -n "${oldstty:-}" ]; then
        stty "$oldstty" 2>/dev/null
    fi
    release_lock
}
trap cleanup EXIT

reapply() { # $1 = theme name; self-contained, race-safe
    name="$1"
    tmp="$(mktemp "${TMPDIR:-/tmp}/tmux-theme.XXXXXX")" || return 1
    {
        # 1) active theme colours
        cat "$THEMES_DIR/$name.tmux-theme"
        # 2) every other tmux_conf_* var from the local conf
        #    (formats, separators, indicators, $colour_N references)
        grep -E '^tmux_conf_[a-zA-Z0-9_]+=' "$TMUX_CONF_LOCAL"
        # 3) export them, then run the framework's theme applier
        cat <<'EOS'
for v in $(sed -n 's/^\(tmux_conf_[a-zA-Z0-9_]*\)=.*/\1/p' "$0" | sort -u); do
    export "$v"
done
cut -c3- "$TMUX_CONF" | sh -s _apply_theme
EOS
    } > "$tmp"
    sh "$tmp"
    rc=$?
    rm -f "$tmp"
    return $rc
}

apply() { # $1 = theme name, $2 = "quiet" to skip the display-message
    name="$1"
    quiet="${2:-}"
    if [ ! -f "$THEMES_DIR/$name.tmux-theme" ]; then
        echo "tmux-theme: no such theme: $name" >&2
        return 1
    fi
    acquire_lock || { echo "tmux-theme: busy, try again" >&2; return 1; }
    printf '%s\n' "$name" > "$ACTIVE_FILE"
    tmux source-file "$THEMES_DIR/$name.tmux-theme" 2>/dev/null
    reapply "$name"
    if [ -z "$quiet" ]; then
        tmux display-message "tmux theme: $name" 2>/dev/null
    fi
    release_lock
}

next() {
    list="$(themes)"
    [ -n "$list" ] || { echo "tmux-theme: no themes found in $THEMES_DIR" >&2; return 1; }
    cur="${1:-$(current)}"
    found=""
    for t in $list; do
        if [ "$found" = "1" ]; then
            apply "$t"
            return
        fi
        [ "$t" = "$cur" ] && found=1
    done
    # cur not found or was last -> wrap to first
    apply "$(printf '%s\n' $list | head -1)"
}

menu() {
    # tmux 3.6 display-menu entries: name key command
    cur="$(current)"
    set --
    for t in $(themes); do
        if [ "$t" = "$cur" ]; then label="* $t"; else label="  $t"; fi
        set -- "$@" "$label" "" "run 'sh $TMUX_THEME_ROOT/tmux-theme.sh apply $t'"
    done
    set -- "$@" "→ next theme" "" "run 'sh $TMUX_THEME_ROOT/tmux-theme.sh next'"
    tmux display-menu -T " tmux theme — pick one, Esc to close " "$@"
}

pick() { # interactive live-preview picker; run inside a tmux popup
    list="$(themes)"
    [ -n "$list" ] || { printf 'no themes in %s\n' "$THEMES_DIR"; sleep 1; return 1; }
    total=0
    for t in $list; do total=$((total + 1)); done
    orig="$(current)"
    idx=1
    i=0
    for t in $list; do
        i=$((i + 1))
        [ "$t" = "$orig" ] && idx=$i
    done
    theme_at() { # $1 = 1-based index
        i=0
        for t in $list; do
            i=$((i + 1))
            if [ "$i" -eq "$1" ]; then
                printf '%s' "$t"
                return
            fi
        done
    }
    tcol() { # $1=theme $2=slot -> hex colour (#rrggbb) from the theme file
        sed -n "s/^tmux_conf_theme_colour_$2=\"\(#[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]\)\".*/\1/p" "$THEMES_DIR/$1.tmux-theme" 2>/dev/null | head -1
    }
    rgb() { # $1=#rrggbb -> "R;G;B" for 24-bit ANSI; falls back to gray
        case "$1" in
            \#[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])
                printf '%d;%d;%d' "$((16#${1:1:2}))" "$((16#${1:3:2}))" "$((16#${1:5:2}))"
                ;;
            *)
                printf '150;150;150'
                ;;
        esac
    }
    i=1
    for t in $list; do
        eval "tbg_$i=\$(tcol \"$t\" 1)"
        eval "tfg_$i=\$(tcol \"$t\" 7)"
        eval "tacc_$i=\$(tcol \"$t\" 4)"
        i=$((i + 1))
    done
    render() { # $1 = cursor (1-based); chrome follows the previewed theme
        W=30
        cur_t="$(theme_at "$1")"
        CH_BG="$(tcol "$cur_t" 1)"
        CH_FG="$(tcol "$cur_t" 7)"
        CH_ACC="$(tcol "$cur_t" 4)"
        CH_MUTE="$(tcol "$cur_t" 3)"
        DASHES=""
        i=0
        while [ "$i" -lt 30 ]; do
            DASHES="${DASHES}─"
            i=$((i + 1))
        done
        printf '\033[2J\033[H'
        printf '\033[48;2;%s;38;2;%s;1m┌%s┐\r\n' "$(rgb "$CH_BG")" "$(rgb "$CH_ACC")" "$DASHES"
        printf '\033[38;2;%s;1m│\033[0m\033[48;2;%s;38;2;%s;1m tmux theme                   \033[0m\033[38;2;%s;1m│\r\n' "$(rgb "$CH_ACC")" "$(rgb "$CH_BG")" "$(rgb "$CH_FG")" "$(rgb "$CH_ACC")"
        printf '\033[38;2;%s;1m│\033[0m\033[48;2;%s;1m                              \033[0m\033[38;2;%s;1m│\r\n' "$(rgb "$CH_ACC")" "$(rgb "$CH_BG")" "$(rgb "$CH_ACC")"
        i=1
        for t in $list; do
            eval "a=\$tacc_$i; b=\$tbg_$i; f=\$tfg_$i"
            n=${#t}
            if [ "$i" -eq "$1" ]; then
                printf '\033[38;2;%s;1m│\033[0m\033[48;2;%s;38;2;%s;1m  > %s%*s\033[0m\033[38;2;%s;1m│\r\n' "$(rgb "$CH_ACC")" "$(rgb "$a")" "$(rgb "$b")" "$t" $((W - 4 - n)) '' "$(rgb "$CH_ACC")"
            else
                printf '\033[38;2;%s;1m│\033[0m\033[48;2;%s;38;2;%s;0m   %s%*s\033[0m\033[38;2;%s;1m│\r\n' "$(rgb "$CH_ACC")" "$(rgb "$b")" "$(rgb "$f")" "$t" $((W - 3 - n)) '' "$(rgb "$CH_ACC")"
            fi
            i=$((i + 1))
        done
        printf '\033[38;2;%s;1m│\033[0m\033[48;2;%s;1m                              \033[0m\033[38;2;%s;1m│\r\n' "$(rgb "$CH_ACC")" "$(rgb "$CH_BG")" "$(rgb "$CH_ACC")"
        printf '\033[38;2;%s;1m│\033[0m\033[48;2;%s;38;2;%s;0m  ↑↓ preview · ⏎ done · q back\033[0m\033[38;2;%s;1m│\r\n' "$(rgb "$CH_ACC")" "$(rgb "$CH_BG")" "$(rgb "$CH_MUTE")" "$(rgb "$CH_ACC")"
        printf '\033[48;2;%s;38;2;%s;1m└%s┘\r\n' "$(rgb "$CH_BG")" "$(rgb "$CH_ACC")" "$DASHES"
        printf '\033[?25l'
    }
    read_key() { # sets KEY; returns 1 on EOF
        IFS='' read -rsn1 KEY 2>/dev/null || return 1
        # bash `read -rsn1` treats CR (Enter) as a line terminator and returns an
        # empty string. Verified: ONLY Enter does this (Tab/BS/printable -> len=1).
        if [ -z "$KEY" ]; then
            KEY="$CR"
            return 0
        fi
        case "$KEY" in
            "$ESC")
                # Read the rest of the escape sequence byte by byte (non-blocking).
                # Arrow keys: ESC [ A / ESC [ B. Mouse (SGR mode): ESC [ < b ; x ; y M
                # (press) or m (release). A terminal delivers a full CSI sequence
                # atomically, so each read returns immediately; the 200ms timeout is
                # only a safety net against a truncated sequence.
                stty min 0 time 2 2>/dev/null
                seq=""
                while :; do
                    IFS='' read -rsn1 c 2>/dev/null || break
                    [ -z "$c" ] && break
                    seq="$seq$c"
                    case "$seq" in
                        '[A'|'[B') break ;;
                        '[<'*M|'[<'*m) break ;;
                    esac
                    [ ${#seq} -ge 24 ] && break
                done
                stty min 1 time 0 2>/dev/null
                case "$seq" in
                    '[A') KEY=up ;;
                    '[B') KEY=down ;;
                    '[<'*) KEY="mouse:${seq#\[<}" ;;
                    *) KEY=esc ;;
                esac
                ;;
        esac
    }
    ESC="$(printf '\033')"
    CR="$(printf '\r')"
    stty_raw=0
    oldstty=""
    if [ -t 0 ]; then
        oldstty="$(stty -g 2>/dev/null)" || oldstty=""
        if [ -n "$oldstty" ]; then
            stty raw -echo 2>/dev/null
            stty_raw=1
        fi
    fi
    # enable xterm mouse tracking (normal + SGR) so clicks inside the popup
    # reach this script as escape sequences
    printf '\033[?1000h\033[?1006h'
    render "$idx"
    while :; do
        read_key || break
        case "$KEY" in
            up|k)
                idx=$((idx - 1))
                [ "$idx" -lt 1 ] && idx=$total
                apply "$(theme_at "$idx")" quiet && render "$idx"
                ;;
            down|j)
                idx=$((idx + 1))
                [ "$idx" -gt $total ] && idx=1
                apply "$(theme_at "$idx")" quiet && render "$idx"
                ;;
            "$CR"|'\n')
                break
                ;;
            q|Q|esc|"$ESC")
                [ -n "$orig" ] && apply "$orig" quiet
                break
                ;;
            mouse:*)
                # SGR mouse: "b;x;yM" (press) / "b;x;ym" (release). Act on left
                # button press only. Theme row i (1-based) sits on screen line
                # 3+i (row 1 -> line 4 ... row 9 -> line 12), so idx = y - 3.
                m="${KEY#mouse:}"
                case "$m" in
                    *M)
                        b="${m%%;*}"
                        r="${m#*;}"
                        y="${r#*;}"
                        y="${y%M}"
                        if [ "$b" = "0" ] && [ "$y" -ge 4 ] 2>/dev/null && [ "$y" -le 12 ] 2>/dev/null; then
                            idx=$((y - 3))
                            apply "$(theme_at "$idx")"
                            break
                        fi
                        ;;
                esac
                ;;
        esac
    done
    printf '\033[?25h'
    printf '\033[?1000l\033[?1006l' # disable mouse tracking
}


# -- self-installer ------------------------------------------------------------
# `install` makes this script self-contained: it embeds all themes, writes them
# to ~/.tmux/themes/, copies itself to ~/.tmux/tmux-theme.sh, and injects a
# marked block into ~/.tmux/.tmux.conf.local (idempotent). Option A: it does
# NOT touch status_right (no theme-name indicator) so the user's config is
# preserved. Re-running install updates the managed block without duplicating.

self_path() { # absolute path of this script as invoked
    case "$0" in
        /*) printf '%s' "$0" ;;
        *)  printf '%s/%s' "$PWD" "$0" ;;
    esac
}

write_themes() { # write embedded themes to $THEMES_DIR (canonical; never clobbers a same-named user file)
    mkdir -p "$THEMES_DIR"
    for name in default dracula gruvbox catppuccin nord tokyo-night one-dark solarized peach-pink; do
        f="$THEMES_DIR/$name.tmux-theme"
        [ -f "$f" ] && continue
        case "$name" in
            default)
cat > "$f" <<'EOF'
# default — original colour scheme (pre-theme-system baseline)
tmux_conf_theme_colour_1="#080808"
tmux_conf_theme_colour_2="#303030"
tmux_conf_theme_colour_3="#8a8a8a"
tmux_conf_theme_colour_4="#00afff"
tmux_conf_theme_colour_5="#ffff00"
tmux_conf_theme_colour_6="#080808"
tmux_conf_theme_colour_7="#e4e4e4"
tmux_conf_theme_colour_8="#080808"
tmux_conf_theme_colour_9="#ffff00"
tmux_conf_theme_colour_10="#ff00af"
tmux_conf_theme_colour_11="#5fff00"
tmux_conf_theme_colour_12="#8a8a8a"
tmux_conf_theme_colour_13="#e4e4e4"
tmux_conf_theme_colour_14="#080808"
tmux_conf_theme_colour_15="#080808"
tmux_conf_theme_colour_16="#d70000"
tmux_conf_theme_colour_17="#e4e4e4"
tmux_conf_theme_window_bg="#101010"
tmux_conf_theme_focused_pane_bg="#000000"
EOF
                ;;
            dracula)
cat > "$f" <<'EOF'
# dracula — https://draculatheme.com
tmux_conf_theme_colour_1="#282a36"
tmux_conf_theme_colour_2="#44475a"
tmux_conf_theme_colour_3="#6272a4"
tmux_conf_theme_colour_4="#bd93f9"
tmux_conf_theme_colour_5="#f1fa8c"
tmux_conf_theme_colour_6="#282a36"
tmux_conf_theme_colour_7="#f8f8f2"
tmux_conf_theme_colour_8="#282a36"
tmux_conf_theme_colour_9="#ff79c6"
tmux_conf_theme_colour_10="#bd93f9"
tmux_conf_theme_colour_11="#50fa7b"
tmux_conf_theme_colour_12="#6272a4"
tmux_conf_theme_colour_13="#f8f8f2"
tmux_conf_theme_colour_14="#f8f8f2"
tmux_conf_theme_colour_15="#282a36"
tmux_conf_theme_colour_16="#ff5555"
tmux_conf_theme_colour_17="#44475a"
tmux_conf_theme_window_bg="#282a36"
tmux_conf_theme_focused_pane_bg="#21222c"
EOF
                ;;
            gruvbox)
cat > "$f" <<'EOF'
# gruvbox dark — https://github.com/morhetz/gruvbox
tmux_conf_theme_colour_1="#282828"
tmux_conf_theme_colour_2="#504945"
tmux_conf_theme_colour_3="#a89984"
tmux_conf_theme_colour_4="#fabd2f"
tmux_conf_theme_colour_5="#fabd2f"
tmux_conf_theme_colour_6="#282828"
tmux_conf_theme_colour_7="#ebdbb2"
tmux_conf_theme_colour_8="#282828"
tmux_conf_theme_colour_9="#fabd2f"
tmux_conf_theme_colour_10="#458588"
tmux_conf_theme_colour_11="#98971a"
tmux_conf_theme_colour_12="#a89984"
tmux_conf_theme_colour_13="#ebdbb2"
tmux_conf_theme_colour_14="#ebdbb2"
tmux_conf_theme_colour_15="#282828"
tmux_conf_theme_colour_16="#cc241d"
tmux_conf_theme_colour_17="#504945"
tmux_conf_theme_window_bg="#282828"
tmux_conf_theme_focused_pane_bg="#1d2021"
EOF
                ;;
            catppuccin)
cat > "$f" <<'EOF'
# catppuccin mocha — https://catppuccin.com
tmux_conf_theme_colour_1="#1e1e2e"
tmux_conf_theme_colour_2="#45475a"
tmux_conf_theme_colour_3="#6c7086"
tmux_conf_theme_colour_4="#89b4fa"
tmux_conf_theme_colour_5="#f9e2af"
tmux_conf_theme_colour_6="#1e1e2e"
tmux_conf_theme_colour_7="#cdd6f4"
tmux_conf_theme_colour_8="#1e1e2e"
tmux_conf_theme_colour_9="#cba6f7"
tmux_conf_theme_colour_10="#89b4fa"
tmux_conf_theme_colour_11="#a6e3a1"
tmux_conf_theme_colour_12="#6c7086"
tmux_conf_theme_colour_13="#cdd6f4"
tmux_conf_theme_colour_14="#cdd6f4"
tmux_conf_theme_colour_15="#1e1e2e"
tmux_conf_theme_colour_16="#f38ba8"
tmux_conf_theme_colour_17="#313244"
tmux_conf_theme_window_bg="#1e1e2e"
tmux_conf_theme_focused_pane_bg="#181825"
EOF
                ;;
            nord)
cat > "$f" <<'EOF'
# nord — https://www.nordtheme.com
tmux_conf_theme_colour_1="#2e3440"
tmux_conf_theme_colour_2="#434c5e"
tmux_conf_theme_colour_3="#7b88a1"
tmux_conf_theme_colour_4="#88c0d0"
tmux_conf_theme_colour_5="#ebcb8b"
tmux_conf_theme_colour_6="#2e3440"
tmux_conf_theme_colour_7="#eceff4"
tmux_conf_theme_colour_8="#2e3440"
tmux_conf_theme_colour_9="#88c0d0"
tmux_conf_theme_colour_10="#b48ead"
tmux_conf_theme_colour_11="#a3be8c"
tmux_conf_theme_colour_12="#7b88a1"
tmux_conf_theme_colour_13="#eceff4"
tmux_conf_theme_colour_14="#eceff4"
tmux_conf_theme_colour_15="#2e3440"
tmux_conf_theme_colour_16="#bf616a"
tmux_conf_theme_colour_17="#3b4252"
tmux_conf_theme_window_bg="#2e3440"
tmux_conf_theme_focused_pane_bg="#272c36"
EOF
                ;;
            tokyo-night)
cat > "$f" <<'EOF'
# tokyo night — https://github.com/folke/tokyonight.nvim
tmux_conf_theme_colour_1="#1a1b26"
tmux_conf_theme_colour_2="#292e42"
tmux_conf_theme_colour_3="#565f89"
tmux_conf_theme_colour_4="#7aa2f7"
tmux_conf_theme_colour_5="#e0af68"
tmux_conf_theme_colour_6="#1a1b26"
tmux_conf_theme_colour_7="#c0caf5"
tmux_conf_theme_colour_8="#1a1b26"
tmux_conf_theme_colour_9="#bb9af7"
tmux_conf_theme_colour_10="#7aa2f7"
tmux_conf_theme_colour_11="#9ece6a"
tmux_conf_theme_colour_12="#565f89"
tmux_conf_theme_colour_13="#c0caf5"
tmux_conf_theme_colour_14="#c0caf5"
tmux_conf_theme_colour_15="#1a1b26"
tmux_conf_theme_colour_16="#f7768e"
tmux_conf_theme_colour_17="#292e42"
tmux_conf_theme_window_bg="#1a1b26"
tmux_conf_theme_focused_pane_bg="#16161e"
EOF
                ;;
            one-dark)
cat > "$f" <<'EOF'
# one dark — https://github.com/atom/one-dark-syntax
tmux_conf_theme_colour_1="#282c34"
tmux_conf_theme_colour_2="#3e4451"
tmux_conf_theme_colour_3="#5c6370"
tmux_conf_theme_colour_4="#61afef"
tmux_conf_theme_colour_5="#e5c07b"
tmux_conf_theme_colour_6="#282c34"
tmux_conf_theme_colour_7="#abb2bf"
tmux_conf_theme_colour_8="#282c34"
tmux_conf_theme_colour_9="#c678dd"
tmux_conf_theme_colour_10="#61afef"
tmux_conf_theme_colour_11="#98c379"
tmux_conf_theme_colour_12="#5c6370"
tmux_conf_theme_colour_13="#abb2bf"
tmux_conf_theme_colour_14="#abb2bf"
tmux_conf_theme_colour_15="#282c34"
tmux_conf_theme_colour_16="#e06c75"
tmux_conf_theme_colour_17="#3e4451"
tmux_conf_theme_window_bg="#282c34"
tmux_conf_theme_focused_pane_bg="#21252b"
EOF
                ;;
            solarized)
cat > "$f" <<'EOF'
# solarized dark — https://ethanschoonover.com/solarized
tmux_conf_theme_colour_1="#002b36"
tmux_conf_theme_colour_2="#073642"
tmux_conf_theme_colour_3="#586e75"
tmux_conf_theme_colour_4="#268bd2"
tmux_conf_theme_colour_5="#b58900"
tmux_conf_theme_colour_6="#002b36"
tmux_conf_theme_colour_7="#eee8d5"
tmux_conf_theme_colour_8="#002b36"
tmux_conf_theme_colour_9="#b58900"
tmux_conf_theme_colour_10="#6c71c4"
tmux_conf_theme_colour_11="#859900"
tmux_conf_theme_colour_12="#586e75"
tmux_conf_theme_colour_13="#eee8d5"
tmux_conf_theme_colour_14="#eee8d5"
tmux_conf_theme_colour_15="#002b36"
tmux_conf_theme_colour_16="#dc322f"
tmux_conf_theme_colour_17="#073642"
tmux_conf_theme_window_bg="#002b36"
tmux_conf_theme_focused_pane_bg="#00212b"
EOF
                ;;
            peach-pink)
cat > "$f" <<'EOF'
# peach-pink — warm peach/rose palette
tmux_conf_theme_colour_1="#2b1a24"
tmux_conf_theme_colour_2="#4a2c3a"
tmux_conf_theme_colour_3="#a8788c"
tmux_conf_theme_colour_4="#ff8fab"
tmux_conf_theme_colour_5="#ffc2d1"
tmux_conf_theme_colour_6="#2b1a24"
tmux_conf_theme_colour_7="#ffe3ee"
tmux_conf_theme_colour_8="#2b1a24"
tmux_conf_theme_colour_9="#ff8fab"
tmux_conf_theme_colour_10="#a34a68"
tmux_conf_theme_colour_11="#ffc2d1"
tmux_conf_theme_colour_12="#a8788c"
tmux_conf_theme_colour_13="#ffe3ee"
tmux_conf_theme_colour_14="#ffffff"
tmux_conf_theme_colour_15="#2b1a24"
tmux_conf_theme_colour_16="#ff8fab"
tmux_conf_theme_colour_17="#4a2c3a"
tmux_conf_theme_window_bg="#2b1a24"
tmux_conf_theme_focused_pane_bg="#33202c"
EOF
                ;;
        esac
    done
}

inject_config() { # idempotently manage the marked block in $TMUX_CONF_LOCAL
    conf="$TMUX_CONF_LOCAL"
    [ -f "$conf" ] || : > "$conf"
    tmp="$(mktemp "${TMPDIR:-/tmp}/tmux-theme-conf.XXXXXX")" || return 1
    cp "$conf" "$conf.bak.$(date +%s)" 2>/dev/null
    awk '
        $0 == "# >>> tmux-theme (auto) >>>" {skip=1; next}
        $0 == "# <<< tmux-theme (auto) <<<" {skip=0; next}
        !skip {print}
    ' "$conf" > "$tmp"
    cat >> "$tmp" <<'TMUXTHEME'

# >>> tmux-theme (auto) >>>
run 'd="$TMUX_CONF"; t="$(readlink "$d" 2>/dev/null)"; [ -z "$t" ] && t="$d"; [ "${t:0:1}" != "/" ] && t="$(dirname "$d")/$t"; root="$(dirname "$t")"; tmux set-environment -g TMUX_THEME_ROOT "$root"; theme="$(cat "$root/themes/active" 2>/dev/null)"; [ -n "$theme" ] && [ -f "$root/themes/$theme.tmux-theme" ] && tmux source-file "$root/themes/$theme.tmux-theme"'
bind T popup -E -w 34 -h 17 -T ' tmux theme ' 'sh "$TMUX_THEME_ROOT/tmux-theme.sh" pick'
# <<< tmux-theme (auto) <<<
TMUXTHEME
    mv "$tmp" "$conf"
}

install() { # self-install: themes + config block + script copy; then apply if a server is up
    write_themes
    [ -f "$ACTIVE_FILE" ] || printf 'default
' > "$ACTIVE_FILE"
    self="$(self_path)"
    target="$ROOT/tmux-theme.sh"
    if [ "$self" != "$target" ]; then
        cp "$self" "$target" 2>/dev/null && chmod +x "$target" 2>/dev/null
    fi
    inject_config
    if tmux list-sessions >/dev/null 2>&1; then
        apply "$(current)" quiet
    fi
    echo "tmux-theme: installed (themes in ~/.tmux/themes, <prefix> T opens the picker)."
}

case "${1:-list}" in
    install)
        install
        ;;

    list)
        cur="$(current)"
        for t in $(themes); do
            if [ "$t" = "$cur" ]; then
                printf '  * %s\n' "$t"
            else
                printf '    %s\n' "$t"
            fi
        done
        ;;
    current)
        current
        ;;
    apply)
        apply "${2:?usage: tmux-theme.sh apply <name>}"
        ;;
    next)
        next "${2:-}"
        ;;
    menu)
        menu
        ;;
    pick)
        pick
        ;;
    *)
        echo "usage: tmux-theme.sh {install|list|current|apply <name>|next|menu|pick}" >&2
        exit 1
        ;;
esac
