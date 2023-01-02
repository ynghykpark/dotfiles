#!/bin/bash

# ╭───────╮
# │ Alias │
# ╰───────╯
alias ll="ls -alh"
alias path='printf "%b\n" "${PATH//:/\\n}"'
alias vim="nvim"
alias tmux='tmux -u'

# ╭───────────────╮
# │ ENV Variables │
# ╰───────────────╯
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export TERM="xterm-256color"
export SHELL="$(which bash)"
export PATH="/Users/$(whoami)/Library/Python/$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1-2)/bin:$PATH"

# ╭───────────╮
# │ Functions │
# ╰───────────╯
function fssh() {

    name=$1

    json_file="/Users/yonghyukpark/.private_addr.json"

    parsed=$(python3 -c "import json,sys;obj=json.load(sys.stdin);parsed=' '.join(obj['$name']);print(parsed)" < $json_file)

    parsed_array=($parsed)

    ssh -p ${parsed_array[1]} ${parsed_array[0]}

}

function upload() {

    name=$1
    src_path=$2
    dst_path=$3

    json_file="/Users/yonghyukpark/.private_addr.json"

    parsed=$(python3 -c "import json,sys;obj=json.load(sys.stdin);parsed=' '.join(obj['$name']);print(parsed)" < $json_file)

    parsed_array=($parsed)

    scp -r -P ${parsed_array[1]} $src_path ${parsed_array[0]}:$dst_path

}

function download() {

    name=$1
    src_path=$2
    dst_path=$3

    json_file="/Users/yonghyukpark/.private_addr.json"

    parsed=$(python3 -c "import json,sys;obj=json.load(sys.stdin);parsed=' '.join(obj['$name']);print(parsed)" < $json_file)

    parsed_array=($parsed)

    scp -r -P ${parsed_array[1]} ${parsed_array[0]}:$src_path $dst_path

}

function local_forwarding() {

    name=$1
    local_port=$2
    remote_port=$3

    json_file="$HOME/.ip_port.json"

    parsed=$(python3 -c "import json,sys;obj=json.load(sys.stdin);parsed=' '.join(obj['$name']);print(parsed)" < $json_file)

    parsed_array=($parsed)

    ssh -p ${parsed_array[1]} -NL localhost:$local_port:localhost:$remote_port ${parsed_array[0]}

}

function convert_to_nfc() {
    convmv -r -f utf8 -t utf8 --nfc --notest $1
}
