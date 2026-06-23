DOCKER_IMAGE ?= oh-my-tmux-test

docker-build:
	docker build -t $(DOCKER_IMAGE) .

docker-run: docker-build
	docker run -it $(DOCKER_IMAGE)

docker-smoke: docker-build
	docker run --name ohmytmux_smoke $(DOCKER_IMAGE) zsh -lc \
		'echo "SHELL=$$(getent passwd tmuxer | cut -d: -f7)"; tmux -V; \
		tmux -f /dev/null -L ci new-session -d \; source-file ~/.tmux.conf \; \
		show-options -g history-limit \; show-options -g mouse \; kill-server' ; \
	docker container rm ohmytmux_smoke

# Run the libtmux TDD contract test suite (requires uv and tmux >= 2.6 on PATH).
# Install dependencies first: uv sync --group dev
test:
	uv run pytest -q

.PHONY: docker-build docker-run docker-smoke test

backup:
	tar -cjvf backup.tar.gz ~/dev/bossjones/oh-my-tmux/.tmux.conf ~/.tmux.conf.local
	ls -lta backup.tar.gz

place-configs: backup
	mkdir -p ~/dev/bossjones || true
	git clone git@github.com:bossjones/.tmux.git ~/dev/bossjones/oh-my-tmux || true
	ln -v -s -f ~/dev/bossjones/oh-my-tmux/.tmux.conf ~/.tmux.conf || true
	cp -av ~/dev/bossjones/oh-my-tmux/.tmux.conf.local ~/.tmux.conf.local || true
	tmux source-file ~/.tmux.conf

extra-tmux:
	bash -x extra.sh

reload:
	tmux source-file ~/.tmux.conf
