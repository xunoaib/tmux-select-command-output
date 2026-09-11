#!/usr/bin/env bash
# tmux-select-command-output
#
# Sets up key bindings that enter copy mode and select a previous shell
# command plus its output (see scripts/select_command_output.sh for how
# commands are located in scrollback).

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$CURRENT_DIR/scripts/select_command_output.sh"

get_tmux_option() {
    local option="$1"
    local default_value="$2"
    local option_value
    option_value=$(tmux show-option -gqv "$option")
    echo "${option_value:-$default_value}"
}

key=$(get_tmux_option "@select-command-output-key" "v")
key_alt=$(get_tmux_option "@select-command-output-key-alt" "V")
older_key=$(get_tmux_option "@select-command-output-older-key" "[")
newer_key=$(get_tmux_option "@select-command-output-newer-key" "]")

# select the most recently completed command's output; set either key
# option to an empty string to disable it
[ -n "$key" ] && tmux bind-key "$key" run-shell "$SCRIPT"
[ -n "$key_alt" ] && tmux bind-key "$key_alt" run-shell "$SCRIPT"

# while already in copy mode: move the selection to an older/newer command
[ -n "$older_key" ] && tmux bind-key -T copy-mode "$older_key" run-shell "$SCRIPT older"
[ -n "$older_key" ] && tmux bind-key -T copy-mode-vi "$older_key" run-shell "$SCRIPT older"
[ -n "$newer_key" ] && tmux bind-key -T copy-mode "$newer_key" run-shell "$SCRIPT newer"
[ -n "$newer_key" ] && tmux bind-key -T copy-mode-vi "$newer_key" run-shell "$SCRIPT newer"
