#!/bin/bash

INSTALL_DIR='$HOME/.installs'

mkdir -p $INSTALL_DIR

TMUX_DIR='$INSTALL_DIR/tmux-config'
echo 'installing tmux-config in $TMUX_DIR'

git clone git@github.com:chanwutk/tmux-config.git $TMUX_DIR

ln -s -f $TMUX_DIR/.tmux.conf ~/.tmux.conf
ln -s -f $TMUX_DIR/.tmux.conf.local ~/.tmux.conf.local
