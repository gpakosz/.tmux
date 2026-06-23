# Interactive test harness for the oh-my-tmux fork.
# Build context must be the repo root (the dir containing .tmux.conf).
#
#   docker build -t oh-my-tmux-test .
#   docker run -it --rm oh-my-tmux-test
#   (inside the container) $ tmux
#
FROM ubuntu:24.04

ARG USER=tmuxer

# Non-interactive apt; UTF-8 locale so the status-line glyphs render.
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TERM=xterm-256color

# Runtime dependencies oh-my-tmux actually shells out to, plus conveniences:
#   tmux git curl ca-certificates  -> core + plugin/TPM bootstrap over https
#   zsh                            -> default login shell
#   locales ncurses-bin ncurses-term -> UTF-8 + tmux-256color terminfo
#   procps psmisc lsof             -> ps/pgrep/pkill/lsof for _pane_info() & ssh introspection
#   gawk sed grep coreutils bc     -> status-line helpers (battery/uptime/loadavg math)
#   xsel xclip wl-clipboard        -> clipboard integration targets (inert without a display, but present)
#   openssh-client                 -> ssh args probing for #{username}/#{hostname}
#   vim                            -> <prefix> + e edit-config target
RUN apt-get update && apt-get install -y --no-install-recommends \
        tmux \
        git \
        curl \
        ca-certificates \
        zsh \
        locales \
        ncurses-bin \
        ncurses-term \
        procps \
        psmisc \
        lsof \
        gawk \
        sed \
        grep \
        coreutils \
        bc \
        xsel \
        xclip \
        wl-clipboard \
        openssh-client \
        vim \
        sudo \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user whose DEFAULT shell is zsh.
RUN useradd --create-home --shell /usr/bin/zsh ${USER} \
    && echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER} \
    && chmod 0440 /etc/sudoers.d/${USER}

USER ${USER}
WORKDIR /home/${USER}

# Install oh-my-zsh unattended (keeps zsh as the login shell, no chsh prompt).
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Wire in the fork's configs exactly like `make place-configs`:
#   ~/.tmux.conf  -> symlink to the read-only base in /opt/oh-my-tmux
#   ~/.tmux.conf.local -> copy of the user override file
COPY --chown=${USER}:${USER} .tmux.conf       /opt/oh-my-tmux/.tmux.conf
COPY --chown=${USER}:${USER} .tmux.conf.local /home/${USER}/.tmux.conf.local
RUN ln -sf /opt/oh-my-tmux/.tmux.conf /home/${USER}/.tmux.conf

# Drop straight into an interactive login zsh; the user then runs `tmux`.
CMD ["/usr/bin/zsh", "-l"]
