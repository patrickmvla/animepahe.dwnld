#!/usr/bin/env bash

#/ Usage:
#/   ./animepahe-dl.sh [-a <anime name>] [-s <anime_slug>] [-e <episode_num1,num2,num3-num4...>] [-r <resolution>] [-t <num>] [-l] [-d]
#/
#/ Options:
#/   -a <name>               anime name
#/   -s <slug>               anime slug/uuid, can be found in $_ANIME_LIST_FILE
#/                           ignored when "-a" is enabled
#/   -e <num1,num3-num4...>  optional, episode number to download
#/                           multiple episode numbers seperated by ","
#/                           episode range using "-"
#/                           all episodes using "*"
#/   -r <resolution>         optional, specify resolution: "1080", "720"...
#/                           by default, the highest resolution is selected
#/   -o <language>           optional, specify audio language: "eng", "jpn"...
#/   -t <num>                optional, specify a positive integer as num of threads
#/   -l                      optional, show m3u8 playlist link without downloading videos
#/   -d                      enable debug mode
#/   -h | --help             display this help message

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
    _PARALLEL_JOBS=1 # Default value

    # Check for --help explicitly
    for arg in "$@"; do
        if [[ "$arg" == "--help" ]]; then
            usage
        fi
    done

    while getopts ":hlda:s:e:r:t:o:" opt; do
        case $opt in
        a) _INPUT_ANIME_NAME="$OPTARG" ;;
        s) _ANIME_SLUG="$OPTARG" ;;
        e) _ANIME_EPISODE="$OPTARG" ;;
        l) _LIST_LINK_ONLY=true ;;
        r) _ANIME_RESOLUTION="$OPTARG" ;;
        t)
            _PARALLEL_JOBS="$OPTARG"
            if [[ ! "$_PARALLEL_JOBS" =~ ^[0-9]+$ || "$_PARALLEL_JOBS" -eq 0 ]]; then
                print_error "-t <num>: Number must be a positive integer"
            fi
            ;;
        o) _ANIME_AUDIO="$OPTARG" ;;
        d)
            _DEBUG_MODE=true
            set -x
            ;;
        h) usage ;;
        \?) print_error "Invalid option: -$OPTARG" ;;
        :) print_error "Option -$OPTARG requires an argument." ;;
        esac
    done
    shift "$((OPTIND - 1))" # Remove processed options
}

print_info() {
    # $1: info message
    [[ -z "${_LIST_LINK_ONLY:-}" ]] && printf "%b\n" "\033[32m[INFO]\033[0m $1" >&2
}

print_warn() {
    # $1: warning message
    [[ -z "${_LIST_LINK_ONLY:-}" ]] && printf "%b\n" "\033[33m[WARNING]\033[0m $1" >&2
}

print_error() {
    # $1: error message
    printf "%b\n" "\033[31m[ERROR]\033[0m $1" >&2
    exit 1
}


command_not_found() {
    # $1: command name
    print_error "$1 command not found!"
}

get() {
    # $1: url
    "${_CURL}" -sS -L "$1" -H "cookie: ${_COOKIE}" --compressed
}

set_cookie() {
    local u
    u="$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 16)"
    _COOKIE="__ddg2_=$u"
}

download_anime_list() {
    get "${_ANIME_URL}" |
        grep "/anime/" |
        sed -E 's|.*/anime/([^/]+)[^>]*>.*title="([^"]+).*|[\1] \2  |' \
            >"${_ANIME_LIST_FILE}"
}
