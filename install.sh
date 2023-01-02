#!/bin/bash

print_in_color() {
    printf "%b" \
        "$(tput setaf "$2" 2> /dev/null)" \
        "$1" \
        "$(tput sgr0 2> /dev/null)"
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
    print_in_green "   [✔] $1\n"
}

print_question() {
    print_in_yellow "   [?] $1"
}

print_warning() {
    print_in_yellow "   [!] $1\n"
}

print_error() {
    print_in_red "   [✖] $1 $2\n"
}

print_error_stream() {
    while read -r line; do
        print_error "↳ ERROR: $line"
    done
}

print_result() {

    if [ "$1" -eq 0 ]; then
        print_success "$2"
    else
        print_error "$2"
    fi

    return "$1"

}

cmd_exists() {
    command -v "$1" &> /dev/null
}

kill_all_subprocesses() {

    local i=""

    for i in $(jobs -p); do
        kill "$i"
        wait "$i" &> /dev/null
    done

}

show_spinner() {

    local -r FRAMES='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

    local -r NUMBER_OR_FRAMES=${#FRAMES}

    local -r PID="$1"

    local -r MSG="$2"

    local i=0
    local frameText=""

    # Display spinner while the process are being executed.

    while kill -0 "$PID" &>/dev/null; do

        frameText="   [${FRAMES:i++%NUMBER_OR_FRAMES:1}] $MSG"

        printf "%s" "$frameText"

        sleep 0.2

        printf "\r"

    done
}

execute() {

    local -r CMDS="$1"
    local -r MSG="${2:-$1}"
    local -r TMP_FILE="$(mktemp /tmp/XXXXX)"

    local exitCode=0
    local cmdsPID=""

    # If the current process is ended,
    # also end all its subprocesses.
    trap "kill_all_subprocesses" "EXIT"

    # Execute commands in background
    eval "$CMDS" 1> /dev/null 2> "$TMP_FILE" &
    cmdsPID=$!

    # Show a spinner if the commands
    show_spinner "$cmdsPID" "$MSG"

    # Wait for the commands to no longer be executing
    # in the background, and then get their exit code.
    wait "$cmdsPID" &> /dev/null
    exitCode=$?

    # Print output based on what happened.
    print_result $exitCode "$MSG"

    if [ $exitCode -ne 0 ]; then
        print_error_stream < "$TMP_FILE"
    fi

    rm -rf "$TMP_FILE"

    return $exitCode

}

get_os() {

    local os=""
    local kernelName=""

    kernelName="$(uname -s)"

    if [ "$kernelName" == "Darwin" ]; then
        os="macos"
    elif [ "$kernelName" == "Linux" ] && [ -e "/etc/os-release" ]; then
        os="$(. /etc/os-release; printf "%s" "$ID")"
    else
        os="$kernelName"
    fi

    printf "%s" "$os"

}

get_os_version() {

    local os=""
    local version=""

    os="$(get_os)"

    if [ "$os" == "macos" ]; then
        version="$(sw_vers -productVersion)"
    elif [ -e "/etc/os-release" ]; then
        version="$(. /etc/os-release; printf "%s" "$VERSION_ID")"
    fi

    printf "%s" "$version"

}

get_here() {

    local -r here="$(dirname "${BASH_SOURCE[1]}")"

    printf "%s" "$here"

}

create_symlinks() {

    local -r sourceFile="$1"
    local -r targetFile="$2"
    local -r skipQuestions="$3"

    if [ ! -e "$targetFile" ]; then

        mkdir -p $(dirname $targetFile)

        execute \
            "ln -sf $sourceFile $targetFile" \
            "$sourceFile → $targetFile"

    elif [ "$(readlink "$targetFile")" == "$sourceFile" ]; then
        print_success "$sourceFile → $targetFile"

    else

        rm -rf "$targetFile"

        execute \
            "ln -fs $sourceFile $targetFile" \
            "$sourceFile → $targetFile"

    fi

}

install_neovim_plugin() {

    if [[ ! -f ~/.local/share/nvim/site/autoload/plug.vim ]]; then

        curl -fLo \
        ~/.local/share/nvim/site/autoload/plug.vim \
        --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

        nvim +PlugInstall +qall!

    fi

}

install_copilot() {

    if [[ ! -d ~/.config/nvim/pack/github/start/copilot.vim ]]; then

        git clone https://github.com/github/copilot.vim.git \
        ~/.config/nvim/pack/github/start/copilot.vim \

    fi

}

change_default_bash() {

    local newShellPath=""

    local brewPrefix=""

    brewPrefix="$(get_homebrew_prefix)" || return 1

    newShellPath="$brewPrefix/bin/bash"

    if ! grep "$newShellPath" < /etc/shells &> /dev/null; then
        execute \
            "printf '%s\n' '$newShellPath' | sudo tee -a /etc/shells" \
            "Bash (add '$newShellPath' in '/etc/shells')" \
        || return 1
    fi

    sudo chsh -s "$newShellPath" &> /dev/null

    print_result $? "Change default shell to Homebrew-Bash"

}

install_homebrew() {

    if ! cmd_exists "brew"; then
        printf "\n" \
            | /bin/bash -c \
            "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
            &> /dev/null
    fi

    print_result $? "Homebrew"

}

get_homebrew_prefix() {

    local path=""

    if path="$(brew --prefix 2> /dev/null)"; then
        printf "%s" "$path"
        return 0
    else
        print_error "Homebrew (get prefix)"
        return 1
    fi

}

brew_install() {

    declare -r FORMULA_READABLE_NAME="$1"
    declare -r FORMULA="$2"
    declare -r ARGUMENTS="$3"
    declare -r TAP_VALUE="$4"

    # Check if `Homebrew` is installed.
    if ! cmd_exists "brew"; then
        print_error "$FORMULA_READABLE_NAME ('Homebrew' is not installed)"
        return 1
    fi

    # If `brew tap` needs to be executed,
    # check if it executed correctly.
    if [ -n "$TAP_VALUE" ]; then
        if ! brew_tap "$TAP_VALUE"; then
            print_error "$FORMULA_READABLE_NAME ('brew tap $TAP_VALUE' failed)"
            return 1
        fi
    fi

    # Install the specified formula.
    if brew list "$FORMULA" &> /dev/null; then
        print_success "$FORMULA_READABLE_NAME"
    else
        execute \
            "brew install $FORMULA $ARGUMENTS" \
            "$FORMULA_READABLE_NAME"
    fi

}

brew_tap() {
    brew tap "$1" &> /dev/null
}

package_is_installed() {
    dpkg -s "$1" &> /dev/null
}

install_package() {

    declare -r PACKAGE_READABLE_NAME="$1"
    declare -r PACKAGE="$2"
    declare -r EXTRA_ARGUMENTS="$3"

    if ! package_is_installed "$PACKAGE"; then
        execute \
            "sudo apt-get install \
            --no-install-recommends \
            --allow-unauthenticated \
            -qqy \
            $EXTRA_ARGUMENTS $PACKAGE" "$PACKAGE_READABLE_NAME"

    else

        print_success "$PACKAGE_READABLE_NAME"

    fi

}

add_ppa() {
    sudo add-apt-repository -y ppa:"$1" &> /dev/null
}

macos() {

    print_in_blue "\n • Symlink Configs\n\n"

    declare -A FILES_TO_SYMLINK=(
        ["tmux.conf"]="$HOME/.tmux.conf"
        ["gitconfig"]="$HOME/.gitconfig"
        ["bashrc"]="$HOME/.bash_profile"
        ["init.vim"]="$HOME/.config/nvim/init.vim"
        ["vifmrc"]="$HOME/.config/vifm/vifmrc"
        ["karabiner.json"]="$HOME/.config/karabiner/karabiner.json"
        ["alacritty.yml"]="$HOME/.config/alacritty/alacritty.yml"
        [".private_addr.json"]="$HOME/.private_addr.json"
    )

    local i=""
    local sourceFile=""
    local targetFile=""

    for i in "${!FILES_TO_SYMLINK[@]}"; do

        sourceFile="$(pwd)/$i"

        targetFile="${FILES_TO_SYMLINK[$i]}"

        create_symlinks $sourceFile $targetFile

    done

    print_in_blue "\n • Install applications and tools\n\n"

    install_homebrew

    brew_install "Bash" "bash"

    brew_install "Iosevka" "font-iosevka" "homebrew/cask-fonts"

    brew_install "Git" "git"

    brew_install "Karabiner" "karabiner-elements"

    brew_install "Slack" "slack"

    brew_install "Tmux" "tmux"

    brew_install "VLC" "vlc"

    brew_install "Neovim" "neovim"

    brew_install "Vifm" "vifm"

    brew_install "Alacritty" "alacritty"

    execute "curl -sS https://starship.rs/install.sh | awk '{print $1"yes"}' | sh" "starship"

    execute "brew update" "Updating Homebrew"

    execute "brew upgrade" "Upgrading Homebrew"

    change_default_bash

    execute "install_neovim_plugin" "neovim plugin"

    execute "install_copilot" "copilot"

    execute "pip3 install pynvim" "pynvim"

    execute "pip3 install python-language-server" "python language server"

}


ubuntu() {

    print_in_blue "\n • Symlink Configs\n\n"

    declare -A FILES_TO_SYMLINK=(
        ["tmux.conf"]="$HOME/.tmux.conf"
        ["gitconfig"]="$HOME/.gitconfig"
        ["bashrc"]="$HOME/.bashrc"
        ["init.vim"]="$HOME/.config/nvim/init.vim"
        ["vifmrc"]="$HOME/.config/vifm/vifmrc"
    )

    local i=""
    local sourceFile=""
    local targetFile=""

    for i in "${!FILES_TO_SYMLINK[@]}"; do

        sourceFile="$(pwd)/$i"

        targetFile="${FILES_TO_SYMLINK[$i]}"

        create_symlinks $sourceFile $targetFile

    done

    print_in_blue "\n • Install applications and tools\n\n"

    execute "sudo apt-get update -qqy" "Updating apt cache"

    install_package "Software Properties Common" "software-properties-common"

    install_package "Git" "git"

    install_package "Bash" "bash"

    install_package "Tmux" "tmux"

    install_package "Curl" "curl"

    install_package "Tree" "tree"

    install_package "Vifm" "vifm"

    install_package "clangd-9" "clangd-9"

    install_package "DNS utils" "dnsutils"

    add_ppa "neovim-ppa/stable"

    execute "sudo apt-get update -qqy" "Updating apt cache"

    install_package "Neovim" "neovim"

    execute "sudo apt-get upgrade -qqy" "Upgrading packages"

    execute "curl -sfL \
             https://deb.nodesource.com/setup_16.x | sudo -E bash - &> /dev/null" \
            "Installing node"

    execute "sudo npm install -g typescript" "Installing typescript"

    execute "curl -sS https://starship.rs/install.sh | awk '{print $1"yes"}' | sudo sh" "starship"

    change_default_bash

    execute "install_neovim_plugin" "neovim plugin"

    execute "install_copilot" "copilot"

    execute "pip3 install pynvim" "pynvim"

    execute "pip3 install python-language-server" "python language server"

}

main() {

    os_name=$(get_os)

    if [ "$os_name" == "macos" ]; then
        macos
    elif [ "$os_name" == "ubuntu" ]; then
        ubuntu
    else
        print_error "This script is only for Ubuntu and MacOS."
    fi

}

main
