"""
Discriminator tests: prove that the live assertions in test_options_live.py
genuinely discriminate between our local deviations and a stock config.

Each test runs the same assertion against BOTH a server booted with our
``.tmux.conf.local`` (must PASS) and a server booted with
``tests/fixtures/stock.tmux.conf.local`` (must FAIL / return stock value).

This provides the TDD guarantee that removing a deviation from ``.local``
actually causes a test to go red — the tests don't trivially pass.
"""
from __future__ import annotations

import libtmux

from tests.conftest import global_option, list_keys


def test_history_limit_discriminates(
    tmux_server: libtmux.Server,
    stock_tmux_server: libtmux.Server,
) -> None:
    """
    local  .local: ``set -g history-limit 20000``  → must be "20000"
    stock  .local: no override                      → stays at upstream "5000"

    Upstream ``.tmux.conf:32`` sets history-limit 5000 before our .local
    overrides it to 20000.
    """
    local_limit = global_option(tmux_server, "history-limit")
    stock_limit = global_option(stock_tmux_server, "history-limit")

    assert local_limit == "20000", (
        f"Local config should set history-limit to 20000, got {local_limit!r}"
    )
    assert stock_limit != "20000", (
        f"Stock config should NOT have history-limit 20000, got {stock_limit!r}.  "
        "If this passes on stock, the test does not discriminate."
    )
    # Upstream sets 5000; verify the stock server actually has the upstream value
    assert stock_limit == "5000", (
        f"Expected stock history-limit 5000 (upstream default), got {stock_limit!r}"
    )


def test_mouse_discriminates(
    tmux_server: libtmux.Server,
    stock_tmux_server: libtmux.Server,
) -> None:
    """
    local  .local: ``set -g mouse on``   → must be "on"
    stock  .local: no ``set -g mouse``   → tmux default is "off"
    """
    local_mouse = global_option(tmux_server, "mouse")
    stock_mouse = global_option(stock_tmux_server, "mouse")

    assert local_mouse == "on", (
        f"Local config should enable mouse, got {local_mouse!r}"
    )
    assert stock_mouse == "off", (
        f"Stock config should have mouse off (tmux default), got {stock_mouse!r}"
    )


def test_mouse_toggle_display_discriminates(
    tmux_server: libtmux.Server,
    stock_tmux_server: libtmux.Server,
) -> None:
    """
    local  .local: ``bind m run "..." \\; display 'mouse ...'`` → has display
    stock  .local: no ``bind m`` override → upstream binding lacks display

    Upstream ``.tmux.conf:107`` binds ``m`` without the display message.
    Our ``.local:413`` overrides it to add ``\\; display 'mouse ...'``.

    Tmux normalizes ``display`` → ``display-message`` and single-quotes to
    double-quotes in list-keys output; check the normalized form.
    """
    local_keys = list_keys(tmux_server)
    stock_keys = list_keys(stock_tmux_server)

    assert 'display-message "mouse' in local_keys, (
        "Local config bind m should contain 'display-message \"mouse' "
        "(our .local:413 override), but it does not."
    )
    assert 'display-message "mouse' not in stock_keys, (
        "Stock config bind m should NOT contain 'display-message \"mouse' "
        "(upstream .tmux.conf:107 does not have the display override)."
    )
