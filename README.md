.tmux
=====

Self-contained, opinionated `.tmux.conf` configuration file.

![Screenshot](https://cloud.githubusercontent.com/assets/553208/9889393/85e50e4e-5bfa-11e5-99d8-76572350803a.gif)

The `master` branch targets tmux `HEAD`. You may want to use the `1.9` or `2.0`
branch.

Features
--------

 - `C-a` acts as secondary prefix, while keeping default `C-b` prefix
 - visual theme inspired by [powerline](https://github.com/Lokaltog/powerline)
 - [maximize any pane to a new window with `<prefix>+`](http://pempek.net/articles/2013/04/14/maximizing-tmux-pane-new-window/)
 - mouse mode toggle with `<prefix>m`
 - automatic usage of `reattach-to-user-namespace` if available
 - laptop battery status
 - configurable new windows and panes behavior (optionally retain current path)

The "maximize any pane to a new window with `<prefix>+`" feature is different
from stock `resize-pane -Z` as it allows you to further split a maximized pane.
Also, you can maximize a pane to a new window, then change window, then go back
and the pane is still in maximized state in its own window. You can then
minimize a pane by using `<prefix>+` either from the source window or the
maximized window.

![Maximize pane](https://cloud.githubusercontent.com/assets/553208/9890858/ee3c0ca6-5c02-11e5-890e-05d825a46c92.gif)
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
can change to alter different behaviors.

### Enabling the Powerline like visual theme

You first need to install [fonts patched with powerline symbols][] (see also the
[powerline manual][]).

Then edit the `~/.tmux.conf.local` file and uncomment the following line:

    #tmux_conf_theme=powerline_patched_font

[fonts patched with powerline symbols]: https://github.com/Lokaltog/powerline-fonts
[powerline manual]: http://powerline.readthedocs.org/en/latest/installation.html#fonts-installation

### Configuring the battery indicator

Edit the `~/.tmux.conf.local` file and uncomment the following lines:

    #tmux_conf_battery_symbol=heart
    #tmux_conf_battery_symbol_count=5

The possible values for `tmux_conf_battery_symbol` are `heart` or `block`
(default).

To use the heat palette for the battery indicator, edit the `~/.tmux.conf.local`
file and uncomment the following line:

    #tmux_conf_battery_palette=heat

To use the gradient palette for the battery indicator, edit the
`~/.tmux.conf.local` file and uncomment the following line:

    #tmux_conf_battery_palette=heat

To display the battery charging (⚡ U+26A1) / discharging (🔋 U+1F50B) status
indicators, edit the `~/.tmux.conf.local` file and uncomment the following line:

    #tmux_conf_battery_status=true

### Configuring new windows and new panes creation

Edit the `~/.tmux.conf.local` file and uncomment the following lines:

    #tmux_conf_new_windows_retain_current_path=false
    #tmux_conf_new_panes_retain_current_path=true

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
