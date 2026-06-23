"""
Sanity tests: verifies that a tmux server boots successfully with our config.

If these fail, nothing else will work.  Diagnose before running other test files.
"""
from __future__ import annotations

import libtmux


def test_server_boots(tmux_server: libtmux.Server) -> None:
    """The server must be alive after startup with our config."""
    assert tmux_server.is_alive(), (
        "libtmux.Server.is_alive() returned False — "
        "the tmux server did not start or crashed during config load."
    )


def test_server_has_session(tmux_server: libtmux.Server) -> None:
    """At least one session must exist (created by the fixture)."""
    sessions = tmux_server.sessions
    assert len(sessions) > 0, "Expected at least one tmux session after new_session()"
