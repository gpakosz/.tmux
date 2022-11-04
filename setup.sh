#!/bin/bash

INSTALL_DIR='$HOME/.installs'
TMUX_DIR='$INSTALL_DIR/tmux-config'

mkdir -p $INSTALL_DIR

echo 'installing tmux-config in $TMUX_DIR'
git clone git@github.com:chanwutk/tmux-config.git $TMUX_DIR

ln -s -f $TMUX_DIR/.tmux.conf ~/.tmux.conf
ln -s -f $TMUX_DIR/.tmux.conf.local ~/.tmux.conf.local
