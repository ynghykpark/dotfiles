#!/usr/bin/env bash

is_osx() {
    local platform
    platform=$(uname)
    [ "$platform" == "Darwin" ]
}

command_exists() {
    local command="$1"
    type "$command" >/dev/null 2>&1
}

create_segment() {
    local content="$1"
    echo "#[fg=$bg]#[fg=$fg,bg=$bg]$content#[fg=$bg,bg=default]"
}

main() {

    # window index to start at 1
    tmux set-option -g base-index 1

    # increase scrollback buffer size
    tmux set-option -g history-limit 50000

    # tmux messages are displayed for 4 seconds
    tmux set-option -g display-time 4000

    # refresh 'status-left' and 'status-right' every 60 seconds
    tmux set-option -g status-interval 60

    # required (only) on OS X
    if is_osx && command_exists "reattach-to-user-namespace"; then
        tmux set-option -g default-command "reattach-to-user-namespace -l $SHELL"
    fi

    # enable true color support
    tmux set-option -g default-terminal "tmux-256color"
    tmux set-option -ga terminal-overrides ",xterm-256color:Tc"

    # emacs key bindings in tmux command prompt (prefix + :) are better than
    # vi keys, even for vim users
    tmux set-option -g status-keys emacs

    # focus events enabled for terminals that support them
    tmux set-option -g focus-events on

    # auto renumber windows when one is closed
    tmux set-option -g renumber-windows on

    # Enable mouse support
    tmux set-option -g mouse on

    # set shell properly
    tmux set -g default-shell "$SHELL"

    # Change the key combination for the PEFIX key to `ctrl-s`
    tmux unbind-key C-b
    tmux set-option -g prefix C-s

    # intuitive split-window
    tmux bind '-' split-window -v
    tmux bind '|' split-window -h

    # reload tmux config
    tmux bind r source-file ~/.tmux.conf \; display "tmux configs reloaded"

    # theme
    fg="#d4be95"
    bg="#504945"

    # build status bar components
    status_bar=""
    dir_content="📂 #{?#{==:#{pane_current_path},$HOME},~,#{s|$HOME/|~/|:pane_current_path}}"
    status_bar+="$(create_segment "$dir_content") "
    status_bar+="$(create_segment "👤 #(whoami)") "
    status_bar+="$(create_segment "💻 #S")"

    # set status bar visibility
    tmux set-option -g status-justify left
    tmux set-option -g status-left-length 50
    tmux set-option -g status-right-length 150
    tmux set-option -g status-left ""
    tmux set-option -g status-right "$status_bar"
    tmux set-option -g status-position top
    tmux set-option -g status-style "bg=default, fg=default"
    tmux set-window-option -g window-status-current-format "$(create_segment "📌 #W")"
    tmux set-option -g window-status-format '#[fg=black] #W'

    # set pane border colors
    tmux set-option -g pane-active-border-style "bg=default,fg=colour240"
    tmux set-option -g pane-border-style "bg=default,fg=colour240"

    # smart pane navigation with neovim integration
    # @pane-is-vim is set by the smart-splits.nvim plugin

    # smart pane switching with awareness of neovim splits
    tmux bind-key -n C-h if -F "#{@pane-is-vim}" 'send-keys C-h' 'select-pane -L'
    tmux bind-key -n C-j if -F "#{@pane-is-vim}" 'send-keys C-j' 'select-pane -D'
    tmux bind-key -n C-k if -F "#{@pane-is-vim}" 'send-keys C-k' 'select-pane -U'
    tmux bind-key -n C-l if -F "#{@pane-is-vim}" 'send-keys C-l' 'select-pane -R'

    # smart pane resizing with awareness of neovim splits
    tmux bind-key -n C-left if -F "#{@pane-is-vim}" 'send-keys C-left' 'resize-pane -L 3'
    tmux bind-key -n C-down if -F "#{@pane-is-vim}" 'send-keys C-down' 'resize-pane -D 3'
    tmux bind-key -n C-up if -F "#{@pane-is-vim}" 'send-keys C-up' 'resize-pane -U 3'
    tmux bind-key -n C-right if -F "#{@pane-is-vim}" 'send-keys C-right' 'resize-pane -R 3'

    # use vi keys in copy mode
    tmux set-window-option -g mode-keys vi

    # v to begin selection, just like Vim
    tmux bind-key -T copy-mode-vi v send -X begin-selection

    # System-specific clipboard settings
    if is_osx; then
        # macOS clipboard integration
        tmux bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"
        tmux bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy"
    elif command_exists "xclip"; then
        # Linux with xclip
        tmux bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "xclip -selection clipboard -i"
        tmux bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "xclip -selection clipboard -i"
    elif command_exists "wl-copy"; then
        # Wayland
        tmux bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "wl-copy"
        tmux bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "wl-copy"
    else
        # Fallback without clipboard integration
        tmux bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
        tmux bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-selection
    fi

    # session management
    tmux bind D command-prompt -p "New session:" "new-session -s '%%'"
    tmux bind m command-prompt -p "Move pane to session:" "break-pane -t '%%:'"

    # remove delay when sending commands (default is 500 milliseconds)
    tmux set-option -g escape-time 0
}

main
