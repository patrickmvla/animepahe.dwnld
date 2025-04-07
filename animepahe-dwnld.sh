#!/usr/bin/env bash

set -e
set -u

usage() {
    printf "%b\n" "$(grep '^#/' "$0" | cut -c4-)" && exit 1
}

set_var() {
    _CURL="$(command -v curl)" || command_not_found "curl"
    _JP="$(command -v jp)" || command_not_found "jp"
    _FZF="$(command -v fzf)" || command_not_found "fzf"
    if [[ -z ${ANIMEPAHE_DL_NODE:-} ]]; then
        _NODE="$(command -v node)" || command_not_found "node"
    else
        _NODE="$ANIMEPAHE_DL_NODE"
    fi
    _FFMPEG="$(command -v ffmpeg)" || command_not_found "ffmpeg"
    if [[ ${_PARALLEL_JOBS:-} -gt 1 ]]; then
        _OPENSSL="$(command -v openssl)" || command_not_found "openssl"
    fi

    _HOST="https://animepahe.ru"
    _ANIME_URL="$_HOST/anime"
    _API_URL="$_HOST/api"
    _REFERER_URL="$_HOST"

    _SCRIPT_PATH=$(dirname "$(realpath "$0")")
    _ANIME_LIST_FILE="$_SCRIPT_PATH/anime.list"
    _SOURCE_FILE=".source.json"
}

set_args() {
    expr "$*" : ".*--help" >/dev/null && usage
    _PARALLEL_JOBS=1
    while getopts ":hlda:s:e:r:t:o:" opt; do
        case $opt in
        a)
            _INPUT_ANIME_NAME="$OPTARG"
            ;;
        s)
            _ANIME_SLUG="$OPTARG"
            ;;
        e)
            _ANIME_EPISODE="$OPTARG"
            ;;
        l)
            _LIST_LINK_ONLY=true
            ;;
        r)
            _ANIME_RESOLUTION="$OPTARG"
            ;;
        t)
            _PARALLEL_JOBS="$OPTARG"
            if [[ ! "$_PARALLEL_JOBS" =~ ^[0-9]+$ || "$_PARALLEL_JOBS" -eq 0 ]]; then
                print_error "-t <num>: Number must be positive integer"
            fi
            ;;
        o)
            _ANIME_AUDIO="$OPTARG"
            ;;
        d)
            _DEBUG_MODE=true
            set -x
            ;;
        h)
            usage
            ;;
        \?)
            print_error "Invalid option: -$OPTARG"
            ;;
        esac
    done
}
