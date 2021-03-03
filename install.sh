ln -sf $HOME/.tmux/tmux.conf $HOME/.tmux.conf
ln -sf $HOME/.tmux/tmux.conf.local $HOME/.tmux.conf.local

if [ $(whoami) = "user" ]; then
  ln -sf $HOME/.tmux/tmux.conf.devpod $HOME/.tmux.conf.local
fi

echo "Installed tmux dotfiles"
