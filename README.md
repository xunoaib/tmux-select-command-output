# tmux-select-command-output

Enter copy mode and **select** a previous shell command plus its output,
based on where prompt lines appear in scrollback - no more dragging the
mouse or eyeballing line numbers to grab a command's output.

The cursor is left at the start of the command's own prompt line, so you
can always see which command the highlighted output belongs to. From
there, use tmux's normal copy-mode binds (`y`, Enter, etc.) to copy the
selection, or walk it to a different command first.

## Requirements

This plugin locates commands by searching scrollback for lines that start
with a prompt marker character (`❯` by default). It also assumes prompts
occupy a predictable, fixed number of lines. Out of the box it's tuned for
[Powerlevel10k](https://github.com/romkatv/powerlevel10k) with
`POWERLEVEL9K_TRANSIENT_PROMPT=always` and
`POWERLEVEL9K_PROMPT_ADD_NEWLINE=true`, which:

- prints every already-submitted prompt collapsed to a single `❯ cmd` line
- prints the current, not-yet-submitted prompt as three lines: a blank
  spacer, an os/dir/vcs segment line, then the `❯` line itself

If your prompt looks different, see [Configuration](#configuration) below
for how to adapt it.

## Installation

Using [TPM](https://github.com/tmux-plugins/tpm), add this to `.tmux.conf`:

```tmux
set -g @plugin 'xunoaib/tmux-select-command-output'
```

Then press `prefix + I` to fetch and load it.

To develop or use it locally instead, point `@plugin` at this directory:

```tmux
set -g @plugin '~/.tmux/plugins/tmux-select-command-output'
```

## Usage

| Key                  | Context        | Action                                             |
|----------------------|----------------|-----------------------------------------------------|
| `prefix + v`         | normal         | Select the most recently completed command's output |
| `[`                  | copy mode      | Move the selection to an older command               |
| `]`                  | copy mode      | Move the selection to a newer command                 |

Once a selection is made, copy it with any normal copy-mode bind (`y`,
Enter, mouse drag release, etc.) - this plugin only handles selection, not
copying, so it composes with whatever copy/clipboard setup you already
use (e.g. [tmux-yank](https://github.com/tmux-plugins/tmux-yank)).

Want a second key bound to the same action? Bind it yourself, pointing at
the plugin's script directly:

```tmux
bind-key V run-shell '~/.tmux/plugins/tmux-select-command-output/scripts/select_command_output.sh'
```

## Configuration

Set any of these in `.tmux.conf` before the `run '~/.tmux/plugins/tpm/tpm'`
line. All are optional; defaults match the Powerlevel10k setup described
above.

| Option                                       | Default | Description                                                                 |
|-----------------------------------------------|---------|------------------------------------------------------------------------------|
| `@select-command-output-key`                  | `v`     | Prefix key to select the last command's output. Set to `''` to disable.      |
| `@select-command-output-older-key`            | `[`     | Copy-mode key to move the selection to an older command.                     |
| `@select-command-output-newer-key`            | `]`     | Copy-mode key to move the selection to a newer command.                      |
| `@select-command-output-prompt-char`          | `❯`     | Regular expression each prompt line starts with (see below).                 |
| `@select-command-output-prompt-lines`         | `1`     | Total lines an already-submitted prompt occupies (its own prompt line inclusive). |
| `@select-command-output-live-prompt-lines`    | `3`     | Total lines the current, not-yet-submitted prompt occupies.                  |

`@select-command-output-prompt-char` is matched as a regular expression
(anchored to the start of the line), not a literal character, so it can
recognize more than one marker - handy if your prompt shows a different
character depending on state, e.g. `zsh-vi-mode`/similar plugins that swap
Powerlevel10k's `❯` for `❮` in vi-normal mode:

```tmux
set -g @select-command-output-prompt-char '[❯❮]'
```

For example, for a plain single-line prompt like `$ ` with no transient
collapsing:

```tmux
set -g @select-command-output-prompt-char '$'
set -g @select-command-output-prompt-lines 1
set -g @select-command-output-live-prompt-lines 1
```

## How it works

Selection is done entirely with tmux's built-in copy-mode commands
(`search-backward`, `cursor-up`, `begin-selection`, ...) rather than by
computing line numbers from captured pane text, so it stays correct even
when a command's output contains long, wrapped lines.
