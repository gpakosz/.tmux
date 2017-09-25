# https://github.com/gpakosz/.tmux
# (‑●‑●)> dual licensed under the WTFPL v2 license and the MIT license,
#         without any warranty.
#         Copyright 2012— Gregory Pakosz (@gpakosz).


# -- navigation ----------------------------------------------------------------

# if you're running tmux within iTerm2
#   - and tmux is 1.9 or 1.9a
#   - and iTerm2 is configured to let option key act as +Esc
#   - and iTerm2 is configured to send [1;9A -> [1;9D for option + arrow keys
# then uncomment the following line to make Meta + arrow keys mapping work
#set -ga terminal-overrides "*:kUP3=\e[1;9A,*:kDN3=\e[1;9B,*:kRIT3=\e[1;9C,*:kLFT3=\e[1;9D"


# -- windows & pane creation ---------------------------------------------------

# new window retains current path, possible values are:
#   - true
#   - false (default)
tmux_conf_new_window_retain_current_path=false

# new pane retains current path, possible values are:
#   - true (default)
#   - false
tmux_conf_new_pane_retain_current_path=true

# new pane tries to reconnect ssh sessions (experimental), possible values are:
#   - true
#   - false (default)
tmux_conf_new_pane_reconnect_ssh=false

# prompt for session name when creating a new session, possible values are:
#   - true
#   - false (default)
tmux_conf_new_session_prompt=false


# -- display -------------------------------------------------------------------

# RGB 24-bit colour support (tmux >= 2.2), possible values are:
#  - true
#  - false (default)
tmux_conf_theme_24b_colour=false

# window style
tmux_conf_theme_window_fg='default'
tmux_conf_theme_window_bg='default'

# highlight focused pane (tmux >= 2.1), possible values are:
#   - true
#   - false (default)
tmux_conf_theme_highlight_focused_pane=false

# focused pane colours:
tmux_conf_theme_focused_pane_fg='default'
tmux_conf_theme_focused_pane_bg='#0087d7'               # light blue

# pane border style, possible values are:
#   - thin (default)
#   - fat
tmux_conf_theme_pane_border_style=thin

# pane borders colours:
tmux_conf_theme_pane_border='#444444'                   # gray
tmux_conf_theme_pane_active_border='#00afff'            # light blue

# pane indicator colours
tmux_conf_theme_pane_indicator='#00afff'                # light blue
tmux_conf_theme_pane_active_indicator='#00afff'         # light blue

# status line style
tmux_conf_theme_message_fg='#000000'                    # black
tmux_conf_theme_message_bg='#ffff00'                    # yellow
tmux_conf_theme_message_attr='bold'

# status line command style (<prefix> : Escape)
tmux_conf_theme_message_command_fg='#ffff00'            # yellow
tmux_conf_theme_message_command_bg='#000000'            # black
tmux_conf_theme_message_command_attr='bold'

# window modes style
tmux_conf_theme_mode_fg='#000000'                       # black
tmux_conf_theme_mode_bg='#ffff00'                       # yellow
tmux_conf_theme_mode_attr='bold'

# status line style
tmux_conf_theme_status_fg='#8a8a8a'                     # light gray
tmux_conf_theme_status_bg='#080808'                     # dark gray
tmux_conf_theme_status_attr='none'

# window status style
#   - built-in variables are:
#     - #{circled_window_index}
tmux_conf_theme_window_status_fg='#8a8a8a'              # light gray
tmux_conf_theme_window_status_bg='#080808'              # dark gray
tmux_conf_theme_window_status_attr='none'
tmux_conf_theme_window_status_format='#I #W'
#tmux_conf_theme_window_status_format='#{circled_window_index} #W'
#tmux_conf_theme_window_status_format='#I #W#{?window_bell_flag,🔔,}#{?window_zoomed_flag,🔍,}'

# window current status style
#   - built-in variables are:
#     - #{circled_window_index}
tmux_conf_theme_window_status_current_fg='#000000'      # black
tmux_conf_theme_window_status_current_bg='#00afff'      # light blue
tmux_conf_theme_window_status_current_attr='bold'
tmux_conf_theme_window_status_current_format='#I #W'
#tmux_conf_theme_window_status_current_format='#{circled_window_index} #W'
#tmux_conf_theme_window_status_current_format='#I #W#{?window_zoomed_flag,🔍,}'

# window activity status style
tmux_conf_theme_window_status_activity_fg='default'
tmux_conf_theme_window_status_activity_bg='default'
tmux_conf_theme_window_status_activity_attr='underscore'

# window bell status style
tmux_conf_theme_window_status_bell_fg='#ffff00'         # yellow
tmux_conf_theme_window_status_bell_bg='default'
tmux_conf_theme_window_status_bell_attr='blink,bold'

# window last status style
tmux_conf_theme_window_status_last_fg='#00afff'         # light blue
tmux_conf_theme_window_status_last_bg='default'
tmux_conf_theme_window_status_last_attr='none'

# status left/right sections separators
tmux_conf_theme_left_separator_main=''
tmux_conf_theme_left_separator_sub='|'
tmux_conf_theme_right_separator_main=''
tmux_conf_theme_right_separator_sub='|'
#tmux_conf_theme_left_separator_main=''  # /!\ you don't need to install Powerline
#tmux_conf_theme_left_separator_sub=''   #   you only need fonts patched with
#tmux_conf_theme_right_separator_main='' #   Powerline symbols or the standalone
#tmux_conf_theme_right_separator_sub=''  #   PowerlineSymbols.otf font

# status left/right content:
#   - separate main sections with '|'
#   - separate subsections with ','
#   - built-in variables are:
#     - #{battery_bar}
#     - #{battery_hbar}
#     - #{battery_percentage}
#     - #{battery_status}
#     - #{battery_vbar}
#     - #{circled_session_name}
#     - #{hostname_ssh}
#     - #{hostname}
#     - #{loadavg}
#     - #{pairing}
#     - #{prefix}
#     - #{root}
#     - #{uptime_d}
#     - #{uptime_h}
#     - #{uptime_m}
#     - #{uptime_s}
#     - #{username}
#     - #{username_ssh}
tmux_conf_theme_status_left=' ❐ #S | ↑#{?uptime_d, #{uptime_d}d,}#{?uptime_h, #{uptime_h}h,}#{?uptime_m, #{uptime_m}m,} '
tmux_conf_theme_status_right='#{prefix}#{pairing} #{?battery_status, #{battery_status},}#{?battery_bar, #{battery_bar},}#{?battery_percentage, #{battery_percentage},} , %R , %d %b | #{username}#{root} | #{hostname} '

# status left style
tmux_conf_theme_status_left_fg='#000000,#e4e4e4,#e4e4e4'  # black, white , white
tmux_conf_theme_status_left_bg='#ffff00,#ff00af,#00afff'  # yellow, pink, white blue
tmux_conf_theme_status_left_attr='bold,none,none'

# status right style
tmux_conf_theme_status_right_fg='#8a8a8a,#e4e4e4,#000000' # light gray, white, black
tmux_conf_theme_status_right_bg='#080808,#d70000,#e4e4e4' # dark gray, red, white
tmux_conf_theme_status_right_attr='none,none,bold'

# pairing indicator
tmux_conf_theme_pairing='👓 '          # U+1F453
tmux_conf_theme_pairing_fg='none'
tmux_conf_theme_pairing_bg='none'
tmux_conf_theme_pairing_attr='none'

# prefix indicator
tmux_conf_theme_prefix='⌨ '            # U+2328
tmux_conf_theme_prefix_fg='none'
tmux_conf_theme_prefix_bg='none'
tmux_conf_theme_prefix_attr='none'

# root indicator
tmux_conf_theme_root='!'
tmux_conf_theme_root_fg='none'
tmux_conf_theme_root_bg='none'
tmux_conf_theme_root_attr='bold,blink'

# battery bar symbols
tmux_conf_battery_bar_symbol_full='◼'
tmux_conf_battery_bar_symbol_empty='◻'
#tmux_conf_battery_bar_symbol_full='♥'
#tmux_conf_battery_bar_symbol_empty='·'

# battery bar length (in number of symbols), possible values are:
#   - auto
#   - a number, e.g. 5
tmux_conf_battery_bar_length='auto'

# battery bar palette, possible values are:
#   - gradient (default)
#   - heat
#   - 'colour_full_fg,colour_empty_fg,colour_bg'
tmux_conf_battery_bar_palette='gradient'
#tmux_conf_battery_bar_palette='#d70000,#e4e4e4,#000000'   # red, white, black

# battery hbar palette, possible values are:
#   - gradient (default)
#   - heat
#   - 'colour_low,colour_half,colour_full'
tmux_conf_battery_hbar_palette='gradient'
#tmux_conf_battery_hbar_palette='#d70000,#ff5f00,#5fff00'  # red, orange, green

# battery vbar palette, possible values are:
#   - gradient (default)
#   - heat
#   - 'colour_low,colour_half,colour_full'
tmux_conf_battery_vbar_palette='gradient'
#tmux_conf_battery_vbar_palette='#d70000,#ff5f00,#5fff00'  # red, orange, green

# symbols used to indicate whether battery is charging or discharging
tmux_conf_battery_status_charging='↑'       # U+2191
tmux_conf_battery_status_discharging='↓'    # U+2193
#tmux_conf_battery_status_charging='⚡ '    # U+26A1
#tmux_conf_battery_status_charging='🔌 '    # U+1F50C
#tmux_conf_battery_status_discharging='🔋 ' # U+1F50B

# clock style
tmux_conf_theme_clock_colour='#00afff'  # light blue
tmux_conf_theme_clock_style='24'


# -- clipboard -----------------------------------------------------------------

# in copy mode, copying selection also copies to the OS clipboard
#   - true
#   - false (default)
# on macOS, this requires installing reattach-to-user-namespace, see README.md
# on Linux, this requires xsel or xclip
tmux_conf_copy_to_os_clipboard=false


# -- user customizations -------------------------------------------------------
# this is the place to override or undo settings

# increase history size
#set -g history-limit 10000

# start with mouse mode enabled
#set -g mouse on

# force Vi mode
#   really you should export VISUAL or EDITOR environment variable, see manual
#set -g status-keys vi
#set -g mode-keys vi

# replace C-b by C-a instead of using both prefixes
# set -gu prefix2
# unbind C-a
# unbind C-b
# set -g prefix C-a
# bind C-a send-prefix

# move status line to top
#set -g status-position top
