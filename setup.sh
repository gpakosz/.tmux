#!/bin/bash

mkdir -p ~/.installs

TMUX_DIR='~/.installs/tmux-config'
echo 'install tmux-config in $TMUX_DIR'

git clone git@github.com:chanwutk/tmux-config.git $TMUX_DIR

ln -s -f $TMUX_DIR/.tmux.conf ~/.tmux.conf
ln -s -f $TMUX_DIR/.tmux.conf.local ~/.tmux.conf.local
