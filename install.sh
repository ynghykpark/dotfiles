#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

main() {

    print_in_blue "🚀 Starting system setup...\n"

    # check if the script is run with sudo
    print_in_blue "🔐 Checking permissions...\n"
    get_sudo

    # run the setup function based on the OS
    os_name=$(get_os)
    print_in_blue "🖥️ Detected OS: $os_name\n"
    if [ "$os_name" == "macos" ]; then
        source "$(dirname "${BASH_SOURCE[0]}")/macos.sh"
        setup_macos
    elif [ "$os_name" == "ubuntu" ]; then
        source "$(dirname "${BASH_SOURCE[0]}")/ubuntu.sh"
        setup_ubuntu
    else
        print_error "🚫 Unsupported OS: $os_name"
        exit 1
    fi

    print_in_blue "🎉 Setup completed successfully\n"
}

main
