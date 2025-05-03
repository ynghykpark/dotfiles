#!/usr/bin/env bash

print_in_color() {
    printf "%b" "$(tput setaf "$2" 2>/dev/null)$(tput bold 2>/dev/null)" "$1" "$(tput sgr0 2>/dev/null)"
}

print_in_red() {
    print_in_color "$1" 1
}

print_in_green() {
    print_in_color "$1" 2
}

print_in_yellow() {
    print_in_color "$1" 3
}

print_in_blue() {
    print_in_color "$1" 4
}

print_success() {
    print_in_green "✅ $1\n"
}

print_error() {
    print_in_red "🙅 $1 $2\n"
}

print_error_stream() {
    while read -r line; do
        print_error "↳ ERROR: $line"
    done
}

print_result() {
    if [ "$1" -eq 0 ]; then
        print_success "Success: $2"
    else
        print_error "Fail: $2"
    fi
    return "$1"
}

kill_all_subprocesses() {
    local i=""
    for i in $(jobs -p); do
        kill "$i"
        wait "$i" &>/dev/null
    done
}

execute() {
    local -r commands="$1"
    local -r message="${2:-$1}"
    local -r tmp_error_file="$(mktemp /tmp/XXXXX)"
    local exit_code=0

    print_in_blue "⌛ Execute: $message...\n"

    # If the current process is ended,
    # also end all its subprocesses.
    trap "kill_all_subprocesses; exit" INT TERM EXIT

    # Create a temp file to store output for line counting
    local tmp_output_file
    tmp_output_file="$(mktemp /tmp/XXXXX)"

    # Run the command, tee output to console and temp file simultaneously
    set -o pipefail
    eval "$commands" 2>"$tmp_error_file" | perl -pe 'BEGIN{$|=1;} s/^/\t/' | tee "$tmp_output_file"
    exit_code=$?
    set +o pipefail

    # Print output based on what happened.
    print_result "$exit_code" "$message"

    if [ "$exit_code" -ne 0 ]; then
        print_error_stream <"$tmp_error_file"
        rm -f "$tmp_error_file" "$tmp_output_file"
        exit "$exit_code"
    fi

    rm -f "$tmp_error_file" "$tmp_output_file"
    return "$exit_code"
}

get_os() {
    local os_name=""
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Check if it's Ubuntu specifically
        if [ -f "/etc/lsb-release" ] && grep -q "Ubuntu" /etc/lsb-release; then
            os_name="ubuntu"
        else
            os_name="unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        os_name="macos"
    else
        os_name="unknown"
    fi
    echo "$os_name"
}

create_symlinks() {
    local -r source_file="$1"
    local -r target_file="$2"

    # Create parent directory if needed
    mkdir -p "$(dirname "$target_file")"

    # Remove target if it exists (file, directory, or symlink)
    if [ -e "$target_file" ] || [ -L "$target_file" ]; then
        rm -rf "$target_file"
    fi

    ln -s "$source_file" "$target_file"
}

get_sudo() {
    if ! sudo -n true 2>/dev/null; then
        if ! sudo -v; then
            print_error "We need sudo access to install packages."
            exit 1
        fi
    fi
}

command_exists() {
    command -v "$1" &>/dev/null
}
