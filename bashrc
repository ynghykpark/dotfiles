#!/bin/bash

# prompt
export PS1="\n\[\e[1;34m\]\u\[\e[0m\] \[\e[1;32m\]@\[\e[0m\] \[\e[1;33m\]\w\[\e[0m\] \[\e[1;35m\]\$\[\e[0m\] "

# common
alias ll='ls -alh --sort=extension'
alias path='echo -e ${PATH//:/\\n}'
alias llpath='echo -e ${LD_LIBRARY_PATH//:/\\n}'
alias reload='source $HOME/.bashrc'
alias vim='nvim'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias psg='ps -AH u | grep'

# tmux
alias tn='tmux new -s'
alias ta='tmux attach -t'
alias tl='tmux ls'

# docker
alias drg='docker run --gpus all -it --rm --ipc=host --network=host -d'
alias dsp='docker stop $(docker ps -q)'
alias drm='docker rm $(docker ps -a -q)'
alias dka='docker kill $(docker ps -q)'

# git
alias gg='git log --graph --pretty=custom'
alias gl='git log --pretty=custom'

# environment variables
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export EDITOR=nvim
export TERM="xterm-256color"
export SHELL="$(which bash)"
export PATH="$HOME/.local/bin:$PATH"

# functions
function sshp() {
    name=$1
    json_file="$HOME/.private_addr.json"
    parsed=$(python3 -c "import json,sys;obj=json.load(sys.stdin);parsed=' '.join(obj['$name']);print(parsed)" < $json_file)
    parsed_array=($parsed)
    ssh -p ${parsed_array[1]} ${parsed_array[0]}
}

function upload() {
    name=$1
    src_path=$2
    dst_path=$3
    json_file="$HOME/.private_addr.json"
    parsed=$(python3 -c "import json,sys;obj=json.load(sys.stdin);parsed=' '.join(obj['$name']);print(parsed)" < $json_file)
    parsed_array=($parsed)
    scp -r -P ${parsed_array[1]} $src_path ${parsed_array[0]}:$dst_path
}

function download() {
    name=$1
    src_path=$2
    dst_path=$3
    json_file="$HOME/.private_addr.json"
    parsed=$(python3 -c "import json,sys;obj=json.load(sys.stdin);parsed=' '.join(obj['$name']);print(parsed)" < $json_file)
    parsed_array=($parsed)
    scp -r -P ${parsed_array[1]} ${parsed_array[0]}:$src_path $dst_path
}

function local_forwarding() {
    name=$1
    local_port=$2
    remote_port=$3
    json_file="$HOME/.private_addr.json"
    parsed=$(python3 -c "import json,sys;obj=json.load(sys.stdin);parsed=' '.join(obj['$name']);print(parsed)" < $json_file)
    parsed_array=($parsed)
    ssh -p ${parsed_array[1]} -NL localhost:$local_port:localhost:$remote_port ${parsed_array[0]}
}

function convert_to_nfc() {
    convmv -r -f utf8 -t utf8 --nfc --notest $1
}
