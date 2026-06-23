"""
Live integration tests: boots a real tmux server with our .tmux.conf.local
and asserts the effective runtime options and key bindings.

These tests cover every local deviation that is observable via tmux option
queries or ``list-keys`` output.  They use the ``tmux_server`` fixture from
conftest.py, which gives each test its own isolated tmux process.

Why ``source-file`` in the fixture rather than relying on startup?
  The startup run commands in ``.tmux.conf`` that load ``.local`` are
  asynchronous.  The fixture calls ``server.cmd("source-file", ...)``
  *synchronously* after new_session() to guarantee our deviations are applied
  before any test queries options.  See conftest.py for details.
"""
from __future__ import annotations

import shutil
import subprocess
import sys

import libtmux
import pytest

from tests.conftest import global_option, list_keys


# ---------------------------------------------------------------------------
# Option tests
# ---------------------------------------------------------------------------


def test_history_limit_20000(tmux_server: libtmux.Server) -> None:
    """
    Our .local sets ``set -g history-limit 20000``.

    Upstream ``.tmux.conf:32`` sets it to 5000; our deviation doubles it to 20000.
    """
    value = global_option(tmux_server, "history-limit")
    assert value == "20000", (
        f"Expected history-limit 20000, got {value!r}.  "
        "Check that 'set -g history-limit 20000' is present in .tmux.conf.local."
    )


def test_mouse_on(tmux_server: libtmux.Server) -> None:
    """
    Our .local sets ``set -g mouse on``.

    tmux default is ``off``; the upstream .tmux.conf does not set mouse.
    """
    value = global_option(tmux_server, "mouse")
    assert value == "on", (
        f"Expected mouse on, got {value!r}.  "
        "Check that 'set -g mouse on' is present in .tmux.conf.local."
    )


# ---------------------------------------------------------------------------
# Key binding tests
# ---------------------------------------------------------------------------


def test_mouse_toggle_binding_has_display(tmux_server: libtmux.Server) -> None:
    """
    Our .local overrides ``bind m`` to add a display message.

    Upstream ``.tmux.conf:107``:
        bind m run "cut -c3- '#{TMUX_CONF}' | sh -s _toggle_mouse"

    Our ``.tmux.conf.local:413``:
        bind m run "..." \\; display 'mouse #{?#{mouse},on,off}'

    Tmux normalizes ``display`` → ``display-message`` and single-quotes →
    double-quotes in ``list-keys`` output.  We therefore check for the
    normalized form: ``display-message "mouse``.
    """
    keys = list_keys(tmux_server)
    assert 'display-message "mouse' in keys, (
        'Expected \'display-message "mouse\' in bind m (list-keys) output, '
        "but it was not found.  "
        "This suggests our .local bind m override (line ~413) was not applied."
    )


def test_reload_binding_r(tmux_server: libtmux.Server) -> None:
    """
    Upstream ``.tmux.conf:38`` defines ``bind r`` to reload the config.

    This is a sanity check that the upstream config loaded correctly.
    The binding runs a shell command containing ``source``.
    """
    keys = list_keys(tmux_server)
    # The r binding's command contains the source invocation
    assert "TMUX_CONF" in keys, (
        "Expected TMUX_CONF references in list-keys output (from bind r / bind e), "
        "but none found.  The upstream .tmux.conf may not have loaded correctly."
    )


def test_edit_binding_e(tmux_server: libtmux.Server) -> None:
    """
    Upstream ``.tmux.conf:35`` defines ``bind e`` to edit ``.tmux.conf.local``.

    The binding opens a new window named ``#{TMUX_CONF_LOCAL}``.
    """
    keys = list_keys(tmux_server)
    assert "TMUX_CONF_LOCAL" in keys, (
        "Expected TMUX_CONF_LOCAL reference in list-keys (from bind e), "
        "but it was not found."
    )


# ---------------------------------------------------------------------------
# macOS-only: reattach-to-user-namespace guard
# ---------------------------------------------------------------------------


@pytest.mark.skipif(
    sys.platform != "darwin",
    reason="reattach-to-user-namespace guard is macOS-only",
)
@pytest.mark.skipif(
    shutil.which("reattach-to-user-namespace") is None,
    reason="reattach-to-user-namespace not installed; if-shell guard would be a no-op",
)
def test_reattach_macos_guard(tmux_server: libtmux.Server) -> None:
    """
    On macOS with reattach-to-user-namespace installed, our .local sets
    ``default-command`` via an ``if-shell`` guard.

    ``.tmux.conf.local:388-389``:
        if-shell 'command -v reattach-to-user-namespace > /dev/null 2>&1' \\
          'set-option -g default-command "reattach-to-user-namespace -l $SHELL"'
    """
    value = global_option(tmux_server, "default-command")
    assert "reattach-to-user-namespace" in value, (
        f"Expected 'reattach-to-user-namespace' in default-command, got {value!r}.  "
        "The if-shell guard in .tmux.conf.local may not have fired."
    )
