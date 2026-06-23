"""
Shared fixtures and helpers for oh-my-tmux TDD contract tests.

Design notes
------------
* Each test gets a **fresh** libtmux.Server (unique socket, isolated temp HOME)
  so tests cannot interfere with each other or with any live tmux session.

* ``tmux_home`` / ``stock_tmux_home`` are session-scoped (created once per pytest
  run) because they only lay down static files.  The server fixtures are
  function-scoped so every test gets a clean tmux process.

* After ``new_session()``, we call ``source-file .tmux.conf.local`` *synchronously*
  via libtmux.  This is necessary because the startup ``run`` commands in
  ``.tmux.conf`` that source the local file are asynchronous; without the
  explicit source-file call the option queries in tests could race with startup.

* The TPM stub (``~/.tmux/plugins/tpm/tpm``) is a no-op shell script that
  exits 0 immediately.  This prevents oh-my-tmux from attempting to git-clone
  TPM from the network during server boot.

* ASDF / pyenv note: when ``HOME`` is overridden for fixture isolation, version-
  manager shims (asdf, pyenv) can no longer find their configuration and fail
  with "unknown command: tmux".  We resolve the *real* tmux binary path at
  import time (before any HOME change) and pass it as ``tmux_bin`` to libtmux.
"""
from __future__ import annotations

import shutil
import subprocess
import uuid
from pathlib import Path
from typing import Generator

import libtmux
import pytest


# ---------------------------------------------------------------------------
# Resolve the real tmux binary path at import time, before HOME is modified.
# ---------------------------------------------------------------------------


def _resolve_tmux_bin() -> str:
    """
    Return the absolute path to the real ``tmux`` executable.

    If tmux is managed by asdf (common on macOS), ``shutil.which("tmux")``
    returns the asdf shim, which fails when HOME is overridden because asdf
    reads ``$HOME/.tool-versions`` to locate the real binary.  We use
    ``asdf which tmux`` as the primary resolution strategy.
    """
    try:
        result = subprocess.run(
            ["asdf", "which", "tmux"],
            capture_output=True,
            text=True,
            check=True,
        )
        real_bin = result.stdout.strip()
        if real_bin:
            return real_bin
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass

    # Fall back to shutil.which (works when not using asdf/pyenv shims)
    return shutil.which("tmux") or "tmux"


#: Absolute path to the real tmux binary; resolved once at import time.
TMUX_BIN: str = _resolve_tmux_bin()


# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

#: Absolute path to the repository root (parent of the ``tests/`` directory).
REPO_ROOT: Path = Path(__file__).resolve().parent.parent


@pytest.fixture(scope="session")
def repo_root() -> Path:
    """Return the repository root directory."""
    return REPO_ROOT


# ---------------------------------------------------------------------------
# Home-directory fixtures
# ---------------------------------------------------------------------------


def _make_tmux_home(
    base: Path,
    repo: Path,
    local_config_src: Path,
) -> Path:
    """
    Create an isolated HOME directory for a tmux server.

    Lays down:
    * ``$HOME/.tmux.conf`` → symlink to ``repo/.tmux.conf``
    * ``$HOME/.tmux.conf.local`` → copy of *local_config_src*
    * ``$HOME/.tmux/plugins/tpm/tpm`` → no-op executable (TPM stub)
    """
    home = base
    home.mkdir(parents=True, exist_ok=True)

    # .tmux.conf — symlink so the upstream file is always current
    tmux_conf_link = home / ".tmux.conf"
    if not tmux_conf_link.exists():
        tmux_conf_link.symlink_to(repo / ".tmux.conf")

    # .tmux.conf.local — copy of the supplied local config
    shutil.copy(local_config_src, home / ".tmux.conf.local")

    # No-op TPM stub to block network clones during boot
    tpm_dir = home / ".tmux" / "plugins" / "tpm"
    tpm_dir.mkdir(parents=True, exist_ok=True)
    tpm_stub = tpm_dir / "tpm"
    tpm_stub.write_text("#!/bin/sh\nexit 0\n")
    tpm_stub.chmod(0o755)

    return home


@pytest.fixture(scope="session")
def tmux_home(tmp_path_factory: pytest.TempPathFactory, repo_root: Path) -> Path:
    """
    Isolated HOME directory containing *our* ``.tmux.conf.local`` deviations.

    Session-scoped because the files don't change between tests.
    """
    base = tmp_path_factory.mktemp("tmux_home_local")
    return _make_tmux_home(
        base=base,
        repo=repo_root,
        local_config_src=repo_root / ".tmux.conf.local",
    )


@pytest.fixture(scope="session")
def stock_tmux_home(tmp_path_factory: pytest.TempPathFactory, repo_root: Path) -> Path:
    """
    Isolated HOME directory containing the *stock* (no deviations) local config.

    Used by discriminator tests to prove assertions fail without our changes.
    """
    base = tmp_path_factory.mktemp("tmux_home_stock")
    return _make_tmux_home(
        base=base,
        repo=repo_root,
        local_config_src=repo_root / "tests" / "fixtures" / "stock.tmux.conf.local",
    )


# ---------------------------------------------------------------------------
# Server fixtures
# ---------------------------------------------------------------------------


def _start_server(home: Path, monkeypatch: pytest.MonkeyPatch) -> libtmux.Server:
    """
    Boot a hermetic libtmux.Server from the given HOME directory.

    Steps:
    1. Override HOME so tmux's discovery logic (`.tmux.conf:153-161`) finds
       ``$HOME/.tmux.conf`` → ``$HOME/.tmux.conf.local`` in our temp dir.
    2. Create a Server with a unique socket name and our .tmux.conf as config.
    3. Start the server by creating an initial session.
    4. **Synchronously** source ``.tmux.conf.local`` to guarantee our plain
       tmux commands (``set -g history-limit``, ``set -g mouse``, ``bind m``,
       ``set -g @plugin``) are applied before any test queries options.
       (The startup ``run`` commands that do the same thing are asynchronous.)
    """
    monkeypatch.setenv("HOME", str(home))

    socket_name = f"pytest_{uuid.uuid4().hex[:10]}"
    server = libtmux.Server(
        socket_name=socket_name,
        config_file=str(home / ".tmux.conf"),
        # Pass the absolute path so asdf/pyenv shims (which depend on HOME)
        # are bypassed entirely.  TMUX_BIN was resolved at import time when
        # the real HOME was still in effect.
        tmux_bin=TMUX_BIN,
    )

    # new_session() triggers the tmux server process to start and load config.
    server.new_session(session_name="test", x=220, y=50)

    # Synchronously apply the local config to avoid races with async `run`
    # commands in the startup config.  Plain tmux commands in the .local file
    # (set, bind, if-shell) execute; shell-var assignments like
    # `tmux_conf_*=value` fail silently as unknown tmux commands — that is OK.
    server.cmd("source-file", str(home / ".tmux.conf.local"))

    return server


@pytest.fixture
def tmux_server(
    tmux_home: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> Generator[libtmux.Server, None, None]:
    """
    Fresh libtmux.Server booted from *our* local config.

    Function-scoped: each test gets its own tmux server process.
    """
    server = _start_server(tmux_home, monkeypatch)
    yield server
    try:
        server.kill_server()
    except Exception:  # noqa: BLE001
        pass  # Already dead is fine


@pytest.fixture
def stock_tmux_server(
    stock_tmux_home: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> Generator[libtmux.Server, None, None]:
    """
    Fresh libtmux.Server booted from the *stock* (no deviations) local config.

    Used by discriminator tests.
    """
    server = _start_server(stock_tmux_home, monkeypatch)
    yield server
    try:
        server.kill_server()
    except Exception:  # noqa: BLE001
        pass


# ---------------------------------------------------------------------------
# Static config fixture
# ---------------------------------------------------------------------------


@pytest.fixture(scope="session")
def local_config_text(repo_root: Path) -> str:
    """Full text of ``.tmux.conf.local`` — shared across static parse tests."""
    return (repo_root / ".tmux.conf.local").read_text()


# ---------------------------------------------------------------------------
# Helper functions (not fixtures)
# ---------------------------------------------------------------------------


def global_option(server: libtmux.Server, name: str) -> str:
    """
    Return the value of a global tmux option as a string.

    Parses ``show-options -g <name>`` output, which is ``"<name> <value>"``
    (one line per option).  Returns empty string if the option is not found.
    """
    result = server.cmd("show-options", "-g", name)
    for line in result.stdout:
        line = line.strip()
        if line.startswith(name):
            parts = line.split(None, 1)
            if len(parts) >= 2:
                return parts[1]
    return ""


def list_keys(server: libtmux.Server, table: str = "") -> str:
    """
    Return all key bindings as a single string.

    Pass *table* (e.g. ``"copy-mode-vi"``) to restrict to a key table.
    """
    args: list[str] = ["list-keys"]
    if table:
        args += ["-T", table]
    result = server.cmd(*args)
    return "\n".join(result.stdout)
