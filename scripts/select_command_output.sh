#!/usr/bin/env bash
# Enter copy mode and SELECT a previous command and its output in the
# current tmux pane, leaving the cursor resting at the start of the
# command's prompt line (so it's clear which command the output belongs
# to). The selection can then be adjusted (see "older"/"newer" below) or
# copied as usual with tmux's normal copy-mode binds (e.g. 'y' or Enter).
#
# Usage:
#   select_command_output.sh [N]      select the command N commands back
#                                      (default 1 = most recently completed)
#   select_command_output.sh older    re-select one command further back
#   select_command_output.sh newer    re-select one command more recent
#
# "older"/"newer" are meant to be bound inside copy-mode itself, so a
# selection can be walked backward/forward through scrollback. They track
# which command is currently selected via the pane's @select_cmd_n option.
#
# Requires every shell prompt line to start with a marker character
# (default "❯", e.g. powerlevel10k's default prompt char) and expects a
# predictable number of lines per prompt - see the options below and the
# README for how to adapt this to other prompt configurations.

set -euo pipefail

get_tmux_option() {
    local option="$1"
    local default_value="$2"
    local option_value
    option_value=$(tmux show-option -gqv "$option")
    echo "${option_value:-$default_value}"
}

prompt_char=$(get_tmux_option "@select-command-output-prompt-char" "❯")
prompt_lines=$(get_tmux_option "@select-command-output-prompt-lines" "1")
live_prompt_lines=$(get_tmux_option "@select-command-output-live-prompt-lines" "3")

arg=${1:-1}

pane_text=$(tmux capture-pane -p -J -S -)
count=$(grep -c "^${prompt_char}" <<< "$pane_text" || true)
max_n=$(( count - 1 ))

current_n=$(tmux show-option -pqv @select_cmd_n)
current_n=${current_n:-0}

case "$arg" in
    older)
        n=$(( current_n + 1 ))
        ;;
    newer)
        if (( current_n <= 1 )); then
            tmux display-message "select-command-output: already at the most recent command"
            exit 0
        fi
        n=$(( current_n - 1 ))
        ;;
    *)
        if ! [[ "$arg" =~ ^[0-9]+$ ]] || (( arg < 1 )); then
            tmux display-message "select-command-output: N must be a positive integer (got '${arg}')"
            exit 0
        fi
        n=$arg
        ;;
esac

if (( max_n < 1 )); then
    tmux display-message "select-command-output: no previous commands in view"
    exit 0
fi
if (( n > max_n )); then
    tmux display-message "select-command-output: only ${max_n} previous command(s) in view"
    exit 0
fi

tmux set-option -p @select_cmd_n "$n"

# Re-enter copy mode fresh so the cursor starts from the pane's actual
# current position (cancel is a no-op error if not already in copy mode).
tmux send-keys -X cancel 2>/dev/null || true
tmux copy-mode
tmux send-keys -X start-of-line

if (( n > 1 )); then
    # Walk back to the prompt line of the next-more-recent command, then
    # step past its (fixed-size) prompt block to land on the last line of
    # our target command's output.
    tmux send-keys -X -N $(( n - 1 )) search-backward "$prompt_char"
    tmux send-keys -X -N "$prompt_lines" cursor-up
else
    # The bottommost (not-yet-submitted) prompt is often taller than a
    # normal prompt (e.g. a blank spacer + segment line above the "❯"
    # line, as with powerlevel10k's transient prompt). Skip past all but
    # its own line to land on the last line of the previous command's
    # output.
    tmux send-keys -X -N $(( live_prompt_lines - 1 )) cursor-up
fi

tmux send-keys -X end-of-line
tmux send-keys -X begin-selection
tmux send-keys -X search-backward "$prompt_char"

if (( n == 1 )); then
    tmux display-message "Selected last command's output"
else
    tmux display-message "Selected output from ${n} commands back"
fi
