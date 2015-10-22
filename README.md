.tmux
=====

Self-contained, pretty and versatile `.tmux.conf` configuration file.

![Screenshot](https://cloud.githubusercontent.com/assets/553208/9889393/85e50e4e-5bfa-11e5-99d8-76572350803a.gif)

The `master` branch targets tmux `HEAD`. You may want to use the `1.9` or `2.0`
branch.

Features
--------

 - `C-a` acts as secondary prefix, while keeping default `C-b` prefix
 - visual theme inspired by [Powerline][]
 - [maximize any pane to a new window with `<prefix> +`](http://pempek.net/articles/2013/04/14/maximizing-tmux-pane-new-window/)
 - mouse mode toggle with `<prefix> m`
 - automatic usage of `reattach-to-user-namespace` if available
 - laptop battery status
 - configurable new windows and panes behavior (optionally retain current path)
 - [Facebook PathPicker][] integration if available
 - [Urlview][] integration if available

[Powerline]: https://github.com/Lokaltog/powerline
[Facebook PathPicker]: https://facebook.github.io/PathPicker/
[Urlview]: https://packages.debian.org/stable/misc/urlview

This configuration uses the following bindings:

 - `<prefix> C-c` creates a new session
 - `<prefix> e` opens `~/.tmux.conf.local` with the editor defined by the
   `$EDITOR` environment variable (defaults to `vim` when empty)
 - `<prefix> r` reloads the configuration
 - `<prefix> C-f` lets you switch to another session by name
 - `<prefix> C-h` and `<prefix> C-l` let you navigate windows (default
   `<prefix> n` and `<prefix> p` are unbound)
 - `<prefix> Tab` brings you to the last active window
 - `<prefix> h`, `<prefix> j`, `<prefix> k` and `<prefix> l` let you navigate
   panes ala Vim
 - `<prefix> H`, `<prefix> J`, `<prefix>` K`, `<prefix> L` let you resize panes
 - `<prefix> <` and `<prefix> >` let you swap panes
 - `<prefix> +` maximizes the current pane to a new window
 - `<prefix> m` toggles mouse mode on or off
 - `<prefix> U` launches Urlview (if available)
 - `<prefix> F` launches Facebook PathPicker (if available)
 - `<prefix> Enter` enters copy-mode
 - `<prefix> b` lists the paste-buffers
 - `<prefix> p` pastes from the top paste-buffer
 - `<prefix> P` lets you choose the paste-buffer to paste from
 - `C-l` clears both the screen and the history

Additionaly, `vi-choice`, `vi-edit` and `vi-copy` named tables are adjusted
   to closely match [my own Vim configuration][]

[my own Vim configuration]: https://github.com/gpakosz/.vim.git

Bindings for the `vi-choice` mode-table:

- `h` collapses the current tree node
- `l` expands the current tree node
- `H` collapes all the tree nodes
- `L` expands all the tree nodes
- `K` jumps to the start of list (tmux 2.0+)
- `L` jumps to the end of list (tmux 2.0+)
- `Escape` cancels the current operation

Bindings for the `vi-edit` mode-table:

- `H` jumps to the start of line
- `L` jumps to the end of line
- `q` cancels the current operation
- `Escape` cancels the current operation

Bindings for the `vi-copy` mode-table:

- `v` begins selection / visual mode
- `C-v` toggles between blockwise visual mode and visual mode
- `H` jumps to the start of line
- `L` jumps to the end of line
- `y` copies the selection to the top paste-buffer
- `Escape` cancels the current operation

The "maximize any pane to a new window with `<prefix> +`" feature is different
from stock `resize-pane -Z` as it allows you to further split a maximized pane.
Also, you can maximize a pane to a new window, then change window, then go back
and the pane is still in maximized state in its own window. You can then
minimize a pane by using `<prefix> +` either from the source window or the
maximized window.

![Maximize pane](https://cloud.githubusercontent.com/assets/553208/9890858/ee3c0ca6-5c02-11e5-890e-05d825a46c92.gif)

Mouse mode allows you to set the active window, set the active pane, resize
panes and select switch to copy-mode to select text.

![Mouse mode](https://cloud.githubusercontent.com/assets/553208/9890797/8dffe542-5c02-11e5-9c06-a25b452e6fcc.gif)

Installation
------------

    $ cd
    $ rm -rf .tmux
    $ git clone https://github.com/gpakosz/.tmux.git
    $ ln -s .tmux/.tmux.conf
    $ cp .tmux/.tmux.conf.local .

If you're a Vim user, setting the `$EDITOR` environment variable to `vim` will
enable and further customize the vi-style key bindings (see tmux manual).

Configuration
-------------

While this configuration tries to bring sane default settings, you may want to
customize it further to your needs. Instead of altering the `~/.tmux.conf` file
and diverging from upstream, the proper way is to edit the `~/.tmux.conf.local`
file:

    echo "set -g history-limit 10000" >> ~/.tmux.conf.local

You will also notice the default `.tmux.conf.local` file contains variables you
can change to alter different behaviors. Pressing `<prefix> e` will open
`~/.tmux.conf.local` with the editor defined by the `$EDITOR` environment
variable (defaults to `vim` when empty).

### Enabling the Powerline like visual theme

Powerline originated as a status-line plugin for Vim. Its popular eye-cacthing
look is based on the use of special symbols: <img width="80" alt="Powerline Symbols" style="vertical-align: middle;" src="https://cloud.githubusercontent.com/assets/553208/10687156/1b76dda6-796b-11e5-83a1-1634337c4571.png" />

To make use of these symbols, there are several options:

- use a font that already bundles those: this is e.g. the case of the
  [2.010R-ro/1.030R-it version][source code pro] of the Source Code Pro] font
- use a [pre-patched font][powerline patched fonts]
- use your preferred font along with the [Powerline font][powerline font] (that
  only contains the Powerline symbols): this highly depends on your operating
  system and your terminal emulator
- [patch your preferred font][powerline font patcher] by adding the missing
  Powerline symbols: this is the most difficult way and is no more documented in
  the Powerline manual

[source code pro]: https://github.com/adobe-fonts/source-code-pro/releases/tag/2.010R-ro%2F1.030R-it
[powerline patched fonts]: https://github.com/powerline/fonts
[powerline font]: https://github.com/powerline/powerline/raw/develop/font/PowerlineSymbols.otf
[powerline font patcher]: https://github.com/powerline/fontpatcher

Please see the [powerline manual] for further details.

Then edit the `~/.tmux.conf.local` file (`<prefix> e`) and adjust the
`tmux_conf_theme` variable:

    tmux_conf_theme=powerline

The possible values for `tmux_conf_theme` are `default` and `powerline`.

[fonts patched with powerline symbols]: https://github.com/Lokaltog/powerline-fonts
[powerline manual]: http://powerline.readthedocs.org/en/latest/installation.html#fonts-installation

### Configuring the battery indicator

To enable or disable the battery indicator, edit the `~/.tmux.conf.local` file
(`<prefix> e`) and adjust the `tmux_conf_theme_battery` variable:

    tmux_conf_theme_battery=enabled

The possible values for `tmux_conf_theme_battery` are `enabled` (default) or
`disabled`.

You can also customize the symbol used in the battery bar as well as their
number by adjusting the `tmux_conf_battery_symbol` and
`tmux_conf_battery_symbol_count` variables.

    tmux_conf_battery_symbol=heart
    tmux_conf_battery_symbol_count=5

The possible values for `tmux_conf_battery_symbol` are `block` (default) or
`block`. The default number of symbol displayed is `10`.

To customize the battery bar colors, adjust the `tmux_conf_battery_palette`
variable. You can either specify a `'colour_full_fg,colour_empty_fg,colour_bg'`
colour triplet or one of the `heat` or `gradient` aliases. See tmux manual for
colours definition:

> The colour is one of: black, red, green, yellow, blue, magenta, cyan, white,
> aixterm bright variants (if supported: brightred, brightgreen, and so on),
> colour0 to colour255 from the 256-colour set, default, or a hexadecimal RGB
> string such as `#ffffff`, which chooses the closest match from the default
> 256-colour set.

To use the heat palette for the battery indicator, use:

    tmux_conf_battery_palette=heat

To use the gradient palette for the battery indicator, use:

    #tmux_conf_battery_palette=heat

To disable the battery charging (⚡ U+26A1) / discharging
(🔋 U+1F50B) status, adjust the `tmux_conf_battery_status` variable:

    tmux_conf_battery_status=disabled

The possible values for `tmux_conf_battery_status` are `enabled` (defaut) or
`disabled`.

### Configuring the date and time

To disable the display of date and time, edit the `~/.tmux.conf.local` file
(`<prefix> e`) and adjust the `tmux_conf_theme_date` and
`tmux_conf_theme_time` variables:

    tmux_conf_theme_time=disabled
    tmux_conf_theme_date=disabled

The possible values for `tmux_conf_theme_date` and `tmux_conf_theme_time` are
`enabled` (defaut) or `disabled`.

### Configuring the username and hostname

To disable the display of username and hostname, edit the `~/.tmux.conf.local`
file (`<prefix> e`) and adjust the `tmux_conf_theme_username` and
`tmux_conf_theme_hostname` variables:

    tmux_conf_theme_username=disabled tmux_conf_theme_hostname=disabled

The possible values for `tmux_conf_theme_username` and
`tmux_conf_theme_hostname` are `enabled` (default) or `disabled`, or `ssh`.

When you set `tmux_conf_theme_username` or `tmux_conf_theme_hostname` to `ssh`,
information is displayed only if you're inside an SSH session.

### Configuring new windows and new panes creation

To configure whether creating new windows and new panes retains the current
path, edit the `~/.tmux.conf.local` (`<prefix> e`) and adjust the
`tmux_conf_new_windows_retain_current_path` and
`tmux_conf_new_panes_retain_current_path` variables:

    tmux_conf_new_windows_retain_current_path=false
    tmux_conf_new_panes_retain_current_path=true

The possible values for `tmux_conf_new_windows_retain_current_path` and
`tmux_conf_new_panes_retain_current_path` are `true` or `false`.

### Accessing the Mac OSX clipboard from within tmux sessions

[Chris Johnsen created the `reattach-to-user-namespace`
utility](https://github.com/ChrisJohnsen/tmux-MacOSX-pasteboard) that makes
`pbcopy` and `pbpaste` work again within tmux.

To install `reattach-to-user-namespace`, use either [MacPorts][] or
[Homebrew][]:

    $ port install tmux-pasteboard

or

    $ brew install reattach-to-user-namespace

Once installed, `reattach-to-usernamespace` will be automatically detected.

[MacPorts]: http://www.macports.org/
[Homebrew]: http://brew.sh/
