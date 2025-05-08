#!/usr/bin/env bash

symlink_dotfiles() {

    create_symlinks "$(pwd)/bash/bashrc" "$HOME/.bashrc"
    create_symlinks "$(pwd)/git/.gitconfig" "$HOME/.gitconfig"
    create_symlinks "$(pwd)/tmux/tmux.conf" "$HOME/.tmux.conf"
    create_symlinks "$(pwd)/tmux/tmux.sh" "$HOME/.tmux.sh"
    create_symlinks "$(pwd)/neovim/init.lua" "$HOME/.config/nvim/init.lua"
    create_symlinks "$(pwd)/vifm/vifmrc" "$HOME/.config/vifm/vifmrc"
    create_symlinks "$(pwd)/btop/gruvbox.theme" "$HOME/.config/btop/themes/gruvbox.theme"
    create_symlinks "$(pwd)/starship/starship.toml" "$HOME/.config/starship.toml"
    create_symlinks "$(pwd)/lazygit/config.yml" "$HOME/.config/lazygit/config.yml"

    for script in "$(pwd)/scripts/"*; do
        # add executable permission to the script
        chmod +x "$script"
        create_symlinks "$script" "$HOME/.local/bin/$(basename "$script")"
    done
}

install_basic_apps() {
    sudo apt update
    sudo apt install -y --no-install-recommends \
        git \
        bash \
        tmux \
        curl \
        wget \
        vifm \
        ripgrep \
        apt-transport-https \
        ca-certificates \
        software-properties-common \
        unzip \
        gpg-agent \
        coreutils \
        sed \
        build-essential \
        lowdown \
        gcc-11 \
        g++-11 \
        bzip2 \
        xz-utils \
        p7zip-full \
        tree \
        bat \
        imagemagick \
        poppler-utils \
        mediainfo
}

install_neovim() {
    sudo add-apt-repository -y ppa:neovim-ppa/unstable
    sudo apt update
    sudo apt install -y --no-install-recommends neovim
}

install_nodejs() {
    curl -sL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt update
    sudo apt install -y --no-install-recommends nodejs
}

install_user_python() {
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt update
    sudo apt install -y --no-install-recommends \
        python3.11 \
        python3.11-dev
    python3.11 -m venv --without-pip "$HOME/.venv"
    curl -s https://bootstrap.pypa.io/get-pip.py | "$HOME/.venv/bin/python3"
    "$HOME/.venv/bin/pip3" install --upgrade pip
    "$HOME/.venv/bin/pip3" install --no-cache-dir \
        setuptools \
        wheel \
        numpy \
        yt-dlp \
        awscli
}

install_btop() {
    tmpdir=$(mktemp -d)
    git clone https://github.com/aristocratos/btop.git "$tmpdir/btop"
    cd "$tmpdir/btop" || exit 1
    make
    sudo make install
    rm -rf "$tmpdir"
}

install_lazygit() {
    tmpdir=$(mktemp -d)
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" |
        grep -Po '"tag_name": *"v\K[^"]*')
    DOWNLOAD_URL="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    curl -L "$DOWNLOAD_URL" -o "$tmpdir/lazygit.tar.gz"
    cd "$tmpdir" || exit 1
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit -D -t /usr/local/bin/
    rm -rf "$tmpdir"
}

install_gh_cli() {
    sudo mkdir -p -m 755 /etc/apt/keyrings
    out=$(mktemp)
    wget -nv -O "$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg
    cat "$out" | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg

    # Add the repository to apt sources
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] \
        https://cli.github.com/packages stable main" |
        sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
}

install_starship() {
    curl -sS https://starship.rs/install.sh | sh -s -- -y
}

setup_ubuntu() {

    execute symlink_dotfiles "symlink dotfiles"
    execute install_basic_apps "install basic applications"
    execute install_neovim "install neovim"
    execute install_nodejs "install nodejs"
    execute install_btop "install btop"
    execute install_user_python "Install python"
    execute install_lazygit "install lazygit"
    execute install_gh_cli "install github cli"
    execute install_starship "install starship"

}
