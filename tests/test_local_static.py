"""
Static file-parse tests: reads ``.tmux.conf.local`` as text and asserts
the file-level contract described in CLAUDE.md.

Why static tests alongside live ones?
  TPM uses ``set -g @plugin`` as a user-option trick.  Only the *last* value
  set for a user option survives in the running tmux server, so querying
  ``show-options -g @plugin`` would only reveal the last plugin declared.
  Parsing the file text is the only reliable way to verify all four declarations.
  The sentinel fences and variable assignments like ``tmux_conf_*`` are also
  shell / parser artifacts that aren't visible via tmux option queries.

All tests use the ``local_config_text`` session fixture from conftest.py,
which reads the file once and shares it across tests.
"""
from __future__ import annotations


# ---------------------------------------------------------------------------
# Plugin declarations
# ---------------------------------------------------------------------------


def test_plugin_resurrect(local_config_text: str) -> None:
    """
    ``tmux-plugins/tmux-resurrect`` must be declared with ``set -g @plugin``.

    .tmux.conf.local:457
    """
    assert "set -g @plugin 'tmux-plugins/tmux-resurrect'" in local_config_text, (
        "tmux-resurrect @plugin declaration is missing from .tmux.conf.local.  "
        "Restore: set -g @plugin 'tmux-plugins/tmux-resurrect'"
    )


def test_plugin_prefix_highlight(local_config_text: str) -> None:
    """
    ``tmux-plugins/tmux-prefix-highlight`` must be declared.

    .tmux.conf.local:458
    """
    assert "set -g @plugin 'tmux-plugins/tmux-prefix-highlight'" in local_config_text, (
        "tmux-prefix-highlight @plugin declaration is missing from .tmux.conf.local."
    )


def test_plugin_continuum(local_config_text: str) -> None:
    """
    ``tmux-plugins/tmux-continuum`` must be declared.

    .tmux.conf.local:459
    """
    assert "set -g @plugin 'tmux-plugins/tmux-continuum'" in local_config_text, (
        "tmux-continuum @plugin declaration is missing from .tmux.conf.local."
    )


def test_plugin_tmux_fzf(local_config_text: str) -> None:
    """
    ``sainnhe/tmux-fzf`` must be declared.

    .tmux.conf.local:464
    """
    assert "set -g @plugin 'sainnhe/tmux-fzf'" in local_config_text, (
        "sainnhe/tmux-fzf @plugin declaration is missing from .tmux.conf.local."
    )


# ---------------------------------------------------------------------------
# Plugin option declarations
# ---------------------------------------------------------------------------


def test_resurrect_capture_pane_contents_on(local_config_text: str) -> None:
    """
    Pane content capture must be enabled for tmux-resurrect.

    .tmux.conf.local:461
    """
    assert "set -g @resurrect-capture-pane-contents 'on'" in local_config_text, (
        "@resurrect-capture-pane-contents 'on' is missing from .tmux.conf.local."
    )


def test_continuum_restore_on(local_config_text: str) -> None:
    """
    Auto-restore must be enabled for tmux-continuum.

    .tmux.conf.local:463
    """
    assert "set -g @continuum-restore 'on'" in local_config_text, (
        "@continuum-restore 'on' is missing from .tmux.conf.local."
    )


# ---------------------------------------------------------------------------
# No manual TPM bootstrap (CLAUDE.md explicitly prohibits this)
# ---------------------------------------------------------------------------


def test_no_tpm_bootstrap_line(local_config_text: str) -> None:
    """
    CLAUDE.md: do NOT add ``set -g @plugin 'tmux-plugins/tpm'`` or
    ``run '~/.tmux/plugins/tpm/tpm'`` — TPM bootstrapping is automatic.

    .tmux.conf.local:449-450 contains comments that *explain* this rule; those
    lines naturally contain the forbidden strings in comment form.  We check
    only non-comment lines (lines that don't start with ``#`` after stripping).
    """
    non_comment_lines = [
        ln for ln in local_config_text.splitlines()
        if not ln.strip().startswith("#")
    ]
    non_comment_text = "\n".join(non_comment_lines)

    assert "set -g @plugin 'tmux-plugins/tpm'" not in non_comment_text, (
        "Found an uncommented 'set -g @plugin tmux-plugins/tpm' line in "
        ".tmux.conf.local.  TPM bootstrap is handled automatically by .tmux.conf."
    )
    assert "run '~/.tmux/plugins/tpm/tpm'" not in non_comment_text, (
        "Found an uncommented 'run ~/.tmux/plugins/tpm/tpm' line in "
        ".tmux.conf.local.  TPM bootstrap is handled automatically by .tmux.conf."
    )


# ---------------------------------------------------------------------------
# Status-right token
# ---------------------------------------------------------------------------


def test_prefix_highlight_in_status_right(local_config_text: str) -> None:
    """
    ``#{prefix_highlight}`` must appear in the ``tmux_conf_theme_status_right``
    assignment line.  This is a local addition not present in the upstream template.

    .tmux.conf.local:274
    """
    # Find the status_right line(s)
    lines = [
        ln for ln in local_config_text.splitlines()
        if ln.startswith("tmux_conf_theme_status_right=")
        and not ln.startswith("#")
    ]
    assert lines, "No uncommented tmux_conf_theme_status_right= line found"
    status_right_line = "\n".join(lines)
    assert "#{prefix_highlight}" in status_right_line, (
        "#{prefix_highlight} token is missing from tmux_conf_theme_status_right.  "
        "Add '#{prefix_highlight}' at the end of the status_right value in "
        ".tmux.conf.local:274."
    )


# ---------------------------------------------------------------------------
# Clipboard setting
# ---------------------------------------------------------------------------


def test_copy_to_os_clipboard_true(local_config_text: str) -> None:
    """
    ``tmux_conf_copy_to_os_clipboard=true`` must be set.

    Upstream template default is ``false``; we explicitly set it to ``true``.
    .tmux.conf.local:373
    """
    assert "tmux_conf_copy_to_os_clipboard=true" in local_config_text, (
        "tmux_conf_copy_to_os_clipboard=true is missing from .tmux.conf.local.  "
        "This enables OS clipboard integration."
    )


# ---------------------------------------------------------------------------
# Sentinel fences
# ---------------------------------------------------------------------------


def test_eof_sentinel_present(local_config_text: str) -> None:
    """
    The ``# EOF`` sentinel must be present.

    After ``cut -c3-`` processing by the oh-my-tmux shell pipeline, this
    becomes the ``EOF`` heredoc delimiter.  Without it the custom-variable
    shell functions won't be parsed correctly.

    .tmux.conf.local:480
    """
    assert "# EOF" in local_config_text, (
        "The '# EOF' sentinel is missing from .tmux.conf.local.  "
        "This is load-bearing for oh-my-tmux's custom #{foo} variable parsing."
    )


def test_at_sentinel_present(local_config_text: str) -> None:
    """
    The ``# "$@"`` sentinel must be present.

    After ``cut -c3-`` processing, this becomes ``"$@"`` which dispatches
    the shell function named by the first argument.

    .tmux.conf.local:517
    """
    assert '# "$@"' in local_config_text, (
        'The \'# "$@"\' sentinel is missing from .tmux.conf.local.  '
        "This is load-bearing for oh-my-tmux's custom variable dispatch."
    )


def test_sentinels_in_order(local_config_text: str) -> None:
    """
    ``# EOF`` must appear *before* ``# "$@"`` in the file.

    If they are reversed or missing, the oh-my-tmux shell parser will break
    custom #{foo} status-line variables.
    """
    eof_pos = local_config_text.find("# EOF")
    at_pos = local_config_text.find('# "$@"')

    assert eof_pos != -1, "# EOF sentinel not found"
    assert at_pos != -1, '# "$@" sentinel not found'
    assert eof_pos < at_pos, (
        f"# EOF (pos {eof_pos}) must come before # \"$@\" (pos {at_pos}), "
        "but the order is reversed."
    )
