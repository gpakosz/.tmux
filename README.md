.tmux
=====

Self-contained, pretty and versatile `.tmux.conf` configuration file.

![Screenshot](https://cloud.githubusercontent.com/assets/553208/19740585/85596a5a-9bbf-11e6-8aa1-7c8d9829c008.gif)

Installation
------------

Requirements:

  - tmux **`>= 2.6`** running inside Linux, Mac, OpenBSD, Cygwin or WSL
  - awk, perl and sed
  - outside of tmux, `$TERM` must be set to `xterm-256color`

⚠️ Before installing, you may want to backup your existing configuration.

You can install Oh my tmux! at any of the following locations:
- `~`
- `$XDG_CONFIG_HOME/tmux`
- `~/.config/tmux`

Installing in `~`:
```
$ cd
$ git clone https://github.com/gpakosz/.tmux.git
$ ln -s -f .tmux/.tmux.conf
$ cp .tmux/.tmux.conf.local .
```

Installing in `$XDG_CONFIG_HOME/tmux`:
```
$ git clone https://github.com/gpakosz/.tmux.git "/path/to/oh-my-tmux"
$ mkdir -p "$XDG_CONFIG_HOME/tmux"
$ ln -s "/path/to/oh-my-tmux/.tmux.conf" "$XDG_CONFIG_HOME/tmux/tmux.conf"
$ cp "/path/to/oh-my-tmux/.tmux.conf.local" "$XDG_CONFIG_HOME/tmux/tmux.conf.local"
```

Installing in `~/.config/tmux`:
```
$ git clone https://github.com/gpakosz/.tmux.git "/path/to/oh-my-tmux"
$ mkdir -p "~/.config/tmux"
$ ln -s "/path/to/oh-my-tmux/.tmux.conf" "~/.config/tmux/tmux.conf"
$ cp "/path/to/oh-my-tmux/.tmux.conf.local" "~/.config/tmux/tmux.conf.local"
```
⚠️ When installing `$XDG_CONFIG_HOME/tmux` or `~/.config/tmux`, the configuration
file names don't have a leading `.` character.

❗️ You should never alter the main `.tmux.conf` or `tmux.conf` file. If you do,
you're on your own. Instead, every customization should happen in your
`.tmux.conf.local` or `tmux.conf.local` customization file copy.

If you're a Vim user, setting the `$EDITOR` environment variable to `vim` will
enable and further customize the vi-style key bindings (see tmux manual).

If you're new to tmux, I recommend you to read [tmux 2: Productive Mouse-Free
Development][bhtmux2] by [@bphogan].

Now proceed to [adjust] your `.local` customization file copy.

[bhtmux2]: https://pragprog.com/titles/bhtmux2/tmux-2
[@bphogan]: https://twitter.com/bphogan
[adjust]: #configuration

Troubleshooting
---------------

 - **I'm running tmux `HEAD` and things don't work properly. What should I do?**

   Please open an issue describing what doesn't work with upcoming tmux. I'll do
   my best to address it.

 - **Status line is broken and/or gets duplicated at the bottom of the screen.
   What gives?**

   This particularly happens on Linux when the distribution provides a version
   of glib that received Unicode 9.0 upgrades (glib `>= 2.50.1`) while providing
   a version of glibc that didn't (glibc `< 2.26`). You may also configure
   `LC_CTYPE` to use an `UTF-8` locale. Typically VTE based terminal emulators
   rely on glib's `g_unichar_iswide()` function while tmux relies on glibc's
   `wcwidth()` function. When these two functions disagree, display gets messed
   up.

   This can also happen on macOS when using iTerm2 and "Use Unicode version 9
   character widths" is enabled in `Preferences... > Profiles > Text`

   For that reason, the default sample `.local` customization file stopped using
   Unicode characters for which width changed in between Unicode 8.0 and 9.0
   standards, as well as Emojis.

 - **I installed Powerline and/or (patched) fonts but can't see Powerline
   symbols.**

   First, you don't need to install Powerline. You only need fonts patched with
   Powerline symbols or the standalone `PowerlineSymbols.otf` font. Then make
   sure your `.local` customization file copy uses the Powerline code points for
   `tmux_conf_theme_left_separator_XXX` values.

 - **I'm using Bash On Windows (WSL), colors and the Powerline look are broken.**

   There is currently a [bug][1681] in the new console powering Bash On Windows
   preventing text attributes (bold, underscore, ...) to combine properly with
   colors. The workaround is to search your `.local` customization file copy and
   replace attributes with `'none'`.

   Also, until Window's console replaces its GDI based render with a DirectWrite
   one, Powerline symbols will be broken.

   The alternative is to use the [Mintty terminal for WSL][wsltty].

[1681]: https://github.com/Microsoft/BashOnWindows/issues/1681
[wsltty]: https://github.com/mintty/wsltty

Features
--------

 - `C-a` acts as secondary prefix, while keeping default `C-b` prefix
 - visual theme inspired by [Powerline][]
 - [maximize any pane to a new window with `<prefix> +`][maximize-pane]
 - SSH/Mosh aware username and hostname status line information
 - mouse mode toggle with `<prefix> m`
 - laptop battery status line information
 - uptime status line information
 - optional highlight of focused pane
 - configurable new windows and panes behavior (optionally retain current path)
 - SSH/Mosh aware split pane (reconnects to remote server)
 - copy to OS clipboard (needs `xsel`, `xclip`, or `wl-copy` on Linux)
 - support for 4-digit hexadecimal Unicode characters
 - [Facebook PathPicker][] integration if available
 - [Urlscan][] (preferred) or [Urlview][] integration if available

[Powerline]: https://github.com/Lokaltog/powerline
[maximize-pane]: http://pempek.net/articles/2013/04/14/maximizing-tmux-pane-new-window/
[Facebook PathPicker]: https://facebook.github.io/PathPicker/
[Urlview]: https://packages.debian.org/stable/misc/urlview
[Urlscan]: https://github.com/firecat53/urlscan

The "maximize any pane to a new window with `<prefix> +`" feature is different
from builtin `resize-pane -Z` as it allows you to further split a maximized
pane. It's also more flexible by allowing you to maximize a pane to a new
window, then change window, then go back and the pane is still in maximized
state in its own window. You can then minimize a pane by using `<prefix> +`
either from the source window or the maximized window.

![Maximize pane](https://cloud.githubusercontent.com/assets/553208/9890858/ee3c0ca6-5c02-11e5-890e-05d825a46c92.gif)

Mouse mode allows you to set the active window, set the active pane, resize
panes and automatically switches to copy-mode to select text.

![Mouse mode](https://cloud.githubusercontent.com/assets/553208/9890797/8dffe542-5c02-11e5-9c06-a25b452e6fcc.gif)

Bindings
--------

tmux may be controlled from an attached client by using a key combination of a
prefix key, followed by a command key. This configuration uses `C-a` as a
secondary prefix while keeping `C-b` as the default prefix. In the following
list of key bindings:
  - `<prefix>` means you have to either hit <kbd>Ctrl</kbd> + <kbd>a</kbd> or <kbd>Ctrl</kbd> + <kbd>b</kbd>
  - `<prefix> c` means you have to hit <kbd>Ctrl</kbd> + <kbd>a</kbd> or <kbd>Ctrl</kbd> + <kbd>b</kbd> followed by <kbd>c</kbd>
  - `<prefix> C-c` means you have to hit <kbd>Ctrl</kbd> + <kbd>a</kbd> or <kbd>Ctrl</kbd> + <kbd>b</kbd> followed by <kbd>Ctrl</kbd> + <kbd>c</kbd>

This configuration uses the following bindings:

 - `<prefix> e` opens the `.local` customization file copy with the editor
   defined by the `$EDITOR` environment variable (defaults to `vim` when empty)
 - `<prefix> r` reloads the configuration
 - `C-l` clears both the screen and the tmux history

 - `<prefix> C-c` creates a new session
 - `<prefix> C-f` lets you switch to another session by name

 - `<prefix> C-h` and `<prefix> C-l` let you navigate windows (default
   `<prefix> n` and `<prefix> p` are unbound)
 - `<prefix> Tab` brings you to the last active window

 - `<prefix> -` splits the current pane vertically
 - `<prefix> _` splits the current pane horizontally
 - `<prefix> h`, `<prefix> j`, `<prefix> k` and `<prefix> l` let you navigate
   panes ala Vim
 - `<prefix> H`, `<prefix> J`, `<prefix> K`, `<prefix> L` let you resize panes
 - `<prefix> <` and `<prefix> >` let you swap panes
 - `<prefix> +` maximizes the current pane to a new window

 - `<prefix> m` toggles mouse mode on or off

 - `<prefix> U` launches Urlscan (preferred) or Urlview, if available
 - `<prefix> F` launches Facebook PathPicker, if available

 - `<prefix> Enter` enters copy-mode
 - `<prefix> b` lists the paste-buffers
 - `<prefix> p` pastes from the top paste-buffer
 - `<prefix> P` lets you choose the paste-buffer to paste from

Additionally, `copy-mode-vi` matches [my own Vim configuration][]

[my own Vim configuration]: https://github.com/gpakosz/.vim.git

Bindings for `copy-mode-vi`:

- `v` begins selection / visual mode
- `C-v` toggles between blockwise visual mode and visual mode
- `H` jumps to the start of line
- `L` jumps to the end of line
- `y` copies the selection to the top paste-buffer
- `Escape` cancels the current operation

Configuration
-------------

While this configuration tries to bring sane default settings, you may want to
customize it further to your needs.

❗️ Again, you should never alter the main `.tmux.conf` or `tmux.conf` file.
If you do, you're on your own.

Please refer to the sample `.local` customization file to know more about the
variables that allow you to alter different behaviors. Upon successful
installation, pressing `<prefix> e` will open your `.local` customization file
copy with the editor defined by the `$EDITOR` environment variable (defaults to
`vim` when empty).

### Enabling the Powerline look

Powerline originated as a status-line plugin for Vim. Its popular eye-catching
look is based on the use of special symbols: <img width="80" alt="Powerline Symbols" style="vertical-align: middle;" src="https://cloud.githubusercontent.com/assets/553208/10687156/1b76dda6-796b-11e5-83a1-1634337c4571.png" />

To make use of these symbols, there are several options:

- use a font that already bundles those: this is e.g. the case of the
  [2.030R-ro/1.050R-it version][source code pro] of the Source Code Pro font
- use a [pre-patched font][powerline patched fonts]
- use your preferred font along with the [Powerline font][powerline font] (that
  only contains the Powerline symbols): [this highly depends on your operating
  system and your terminal emulator][terminal support], for instance here's a
  screenshot of iTerm2 configured to use `PowerlineSymbols.otf`
  ![iTerm2 + Powerline font](https://user-images.githubusercontent.com/553208/62243890-8232f500-b3de-11e9-9b8c-51a5d38bdaa8.png)

[source code pro]: https://github.com/adobe-fonts/source-code-pro/releases/tag/2.030R-ro/1.050R-it
[powerline patched fonts]: https://github.com/powerline/fonts
[powerline font]: https://github.com/powerline/powerline/raw/develop/font/PowerlineSymbols.otf
[terminal support]: http://powerline.readthedocs.io/en/master/usage.html#usage-terminal-emulators

Then edit your `.local` customization file copy (with `<prefix> e`) and adjust
the following variables:

```
tmux_conf_theme_left_separator_main='\uE0B0'
tmux_conf_theme_left_separator_sub='\uE0B1'
tmux_conf_theme_right_separator_main='\uE0B2'
tmux_conf_theme_right_separator_sub='\uE0B3'
```

The [Powerline manual] contains further details on how to install fonts
containing the Powerline symbols. You don't need to install Powerline itself
though.

[Powerline manual]: http://powerline.readthedocs.org/en/latest/installation.html#fonts-installation

### Configuring the status line

Edit your `.local` customization file copy (`<prefix> e`) and adjust the
`tmux_conf_theme_status_left` and `tmux_conf_theme_status_right` variables to
your own preferences.

This configuration supports the following builtin variables:

 - `#{battery_bar}`: horizontal battery charge bar
 - `#{battery_hbar}`: 1 character wide, horizontal battery charge bar
 - `#{battery_vbar}`: 1 character wide, vertical battery charge bar
 - `#{battery_percentage}`: battery percentage
 - `#{battery_status}`: is battery charging or discharging?
 - `#{circled_session_name}`: circled session number, up to 20
 - `#{hostname}`: SSH/Mosh aware hostname information
 - `#{hostname_ssh}`: SSH/Mosh aware hostname information, blank when not
   connected to a remote server through SSH/Mosh
 - `#{loadavg}`: load average
 - `#{pairing}`: is session attached to more than one client?
 - `#{prefix}`: is prefix being depressed?
 - `#{root}`: is current user root?
 - `#{synchronized}`: are the panes synchronized?
 - `#{uptime_y}`: uptime years
 - `#{uptime_d}`: uptime days, modulo 365 when `#{uptime_y}` is used
 - `#{uptime_h}`: uptime hours
 - `#{uptime_m}`: uptime minutes
 - `#{uptime_s}`: uptime seconds
 - `#{username}`: SSH/Mosh aware username information
 - `#{username_ssh}`: SSH aware username information, blank when not connected
   to a remote server through SSH/Mosh

Beside the variables mentioned above, the `tmux_conf_theme_status_left` and
`tmux_conf_theme_status_right` variables support usual tmux syntax, e.g. using
`#()` to call an external command that inserts weather information provided by
[wttr.in]:
```
tmux_conf_theme_status_right='#{prefix}#{pairing}#{synchronized} #(curl -m 1 wttr.in?format=3 2>/dev/null; sleep 900) , %R , %d %b | #{username}#{root} | #{hostname} '
```
The `sleep 900` call makes sure the network request is issued at most every 15
minutes whatever the value of `status-interval`.

![Weather information from wttr.in](https://user-images.githubusercontent.com/553208/52175490-07797c00-27a5-11e9-9fb6-42eec4fe4188.png)

[wttr.in]: https://github.com/chubin/wttr.in#one-line-output

💡 You can also define your own custom variables by writing special functions,
see the sample `.local` customization file for instructions.

Finally, remember `tmux_conf_theme_status_left` and
`tmux_conf_theme_status_right` end up being given to tmux as `status-left` and
`status-right` which means they're passed through `strftime()`. As such, the `%`
character has a special meaning and needs to be escaped by doubling it, e.g.
```
tmux_conf_theme_status_right='#(echo foo %% bar)'
```
See also `man 3 strftime`.

### Using TPM plugins

This configuration now comes with built-in [TPM] support:
- use the `set -g @plugin ...` syntax to enable a plugin
- whenever a plugin introduces a variable to be used in `status-left` or
  `status-right`, you can use it in `tmux_conf_theme_status_left` and
  `tmux_conf_theme_status_right` variables, see instructions above 👆
- ⚠️ do not add `set -g @plugin 'tmux-plugins/tpm'` to any configuration file
- ⛔️ do not add `run '~/.tmux/plugins/tpm/tpm'` to any configuration file

⚠️ The TPM bindings differ slightly from upstream:
  - installing plugins: `<prefix> + I`
  - uninstalling plugins: `<prefix> + Alt + u`
  - updating plugins: `<prefix> + u`

See the sample `.local` customization file for instructions.

[TPM]: https://github.com/tmux-plugins/tpm

### Using the configuration under Cygwin within Mintty

**I don't recommend running this configuration with Cygwin anymore. Forking
under Cygwin is extremely slow and this configuration issues a lot of
`run-shell` commands under the hood. As such, you will experience high CPU
usage. As an alternative consider using [Mintty terminal for WSL][wsltty].**

![cygwin](https://cloud.githubusercontent.com/assets/553208/19741789/67a3f3d8-9bc2-11e6-9ecc-499fc0228ee6.png)

It is possible to use this configuration under Cygwin within Mintty, however
support for Unicode symbols and emojis lacks behind Mac and Linux.

Particularly, Mintty's text rendering is implemented with GDI which has
limitations:

- color emojis are only available through DirectWrite starting with Windows 8.1
- display of double width symbols, like the battery discharging symbol indicator
  (U+1F50B) is buggy

To get Unicode symbols displayed properly, you have to use [font linking].
Open `regedit.exe` then navigate to the registry key at
`HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontLink\SystemLink`
and add a new entry for you preferred font to link it with the Segoe UI Symbol
font.

![regedit](https://cloud.githubusercontent.com/assets/553208/19741304/71a2f3ae-9bc0-11e6-96aa-4c09a812c313.png)

[font linking]: https://msdn.microsoft.com/en-us/goglobal/bb688134.aspx
