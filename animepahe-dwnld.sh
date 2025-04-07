#!/usr/bin/env bash

set -e
set -u

usage() {
    printf "%b\n" "$(grep '^#/' "$0" | cut -c4-)" && exit 1
}

set_var() {
    _CURL="$(command -v curl)" || command_not_found "curl"
    _JQ="$(command -v jp)" || command_not_found "jp"
    _FZF="$(command -v fzf)" || command_not_found "fzf"
    if [[-z $(ANIMEPAHE_DL_NODE:-)]]; then

}