.tmux
=====

Self-contained, opinionated `.tmux.conf` configuration file.

Features
--------

 - `C-a` acts as secondary prefix, while keeping default `C-b` prefix
 - visual theme inspired by [powerline](https://github.com/Lokaltog/powerline)
 - [maximize any pane to a new window with `<prefix>+`](http://pempek.net/articles/2013/04/14/maximizing-tmux-pane-new-window/) (tmux 1.6+)
 - mouse mode toggle with `<prefix>m`
 - automatic usage of `reattach-to-user-namespace` if available
 - laptop battery status

Installation
------------

    $ cd
    $ rm -rf .tmux
    $ git clone https://github.com/gpakosz/.tmux.git
    $ ln -s .tmux/.tmux.conf

### Accessing the Mac OSX clipboard from within tmux sessions

[Chris Johnsen created the `reattach-to-user-namespace`
utility](https://github.com/ChrisJohnsen/tmux-MacOSX-pasteboard) that makes
`pbcopy` and `pbpaste` work again within `tmux`.

If available, `reattach-to-user-namespace` will be automatically used by this
`tmux` configuration. You just have to install it for instance with `brew`:

    $ brew install reattach-to-user-namespsace
