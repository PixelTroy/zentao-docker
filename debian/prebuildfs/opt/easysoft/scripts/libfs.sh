#!/bin/bash
#
# Library for file system actions

# shellcheck disable=SC1091

# Load Generic Libraries
. /opt/easysoft/scripts/liblog.sh

# Functions

########################
# make link source directory to dest directory
# Arguments:
#   $1 - sourcepath
#   $2 - destpath
#   $3 - owner
# Returns:
#   None
#########################
move_then_link() {
    local source="${1:?path is missing}"
    local dest="${2:?path is missing}"
    local owner=${3:-}
    local group=${4:-}

    ensure_dir_exists "$dest" "www-data" "777"

    # 持久化目录没有文件，将代码中需要持久化的文件复制到持久化目录
    if [ ! -e "$source" ];then
        mv "$dest" "$(dirname "$source")"
    fi

    # 代码中有需要持久化的目录，将代码中的目录改名
    if [ ! -L "$dest" ];then
        mv "$dest" "$dest".bak
        ln -s "$source" "$dest"
    fi

    if [[ -n $group ]]; then
        chown -h "$owner":"$group" "$dest"
    else
        chown -h "$owner":"$owner" "$dest"
    fi
}

########################
# Ensure a file/directory is owned (user and group) but the given user
# Arguments:
#   $1 - filepath
#   $2 - owner
# Returns:
#   None
#########################
owned_by() {
    local path="${1:?path is missing}"
    local owner="${2:?owner is missing}"
    local group="${3:-}"

    if [[ -n $group ]]; then
        chown "$owner":"$group" "$path"
    else
        chown "$owner":"$owner" "$path"
    fi
}

########################
# Ensure a directory exists and, optionally, is owned by the given user
# Arguments:
#   $1 - directory
#   $2 - owner
# Returns:
#   None
#########################
ensure_dir_exists() {
    local dir="${1:?directory is missing}"
    local owner_user="${2:-}"
    local permission="${3:-}"

    # $dir is file and not exists.
    if [[ "$dir" =~ \. ]] ;then
      [ ! -d "$(dirname "$dir")" ] && mkdir -p "$(dirname "$dir")"
      touch "$dir"
    elif [ ! -d "$dir" ];then
      mkdir -p "${dir}"
    fi

    if [[ -n $owner_user ]]; then
        owned_by "$dir" "$owner_user" "$owner_user"
    fi

    if [[ -n "$permission" ]]; then
        configure_permissions_ownership "$dir" -d "$permission"
    fi
}

########################
# Checks whether a directory is empty or not
# arguments:
#   $1 - directory
# returns:
#   boolean
#########################
is_dir_empty() {
    local -r path="${1:?missing directory}"
    # Calculate real path in order to avoid issues with symlinks
    local -r dir="$(realpath "$path")"
    if [[ ! -e "$dir" ]] || [[ -z "$(ls -A "$dir")" ]]; then
        true
    else
        false
    fi
}

########################
# Checks whether a mounted directory is empty or not
# arguments:
#   $1 - directory
# returns:
#   boolean
#########################
is_mounted_dir_empty() {
    local dir="${1:?missing directory}"

    if is_dir_empty "$dir" || find "$dir" -mindepth 1 -maxdepth 1 -not -name ".snapshot" -not -name "lost+found" -exec false {} +; then
        true
    else
        false
    fi
}

########################
# Checks whether a file can be written to or not
# arguments:
#   $1 - file
# returns:
#   boolean
#########################
is_file_writable() {
    local file="${1:?missing file}"
    local dir
    dir="$(dirname "$file")"

    if [[ (-f "$file" && -w "$file") || (! -f "$file" && -d "$dir" && -w "$dir") ]]; then
        true
    else
        false
    fi
}

########################
# Relativize a path
# arguments:
#   $1 - path
#   $2 - base
# returns:
#   None
#########################
relativize() {
    local -r path="${1:?missing path}"
    local -r base="${2:?missing base}"
    pushd "$base" >/dev/null || exit
    realpath -q --no-symlinks --relative-base="$base" "$path" | sed -e 's|^/$|.|' -e 's|^/||'
    popd >/dev/null || exit
}

########################
# Configure permisions and ownership recursively
# Globals:
#   None
# Arguments:
#   $1 - paths (as a string).
# Flags:
#   -f|--file-mode - mode for directories.
#   -d|--dir-mode - mode for files.
#   -u|--user - user
#   -g|--group - group
# Returns:
#   None
#########################
configure_permissions_ownership() {
    local -r paths="${1:?paths is missing}"
    local dir_mode=""
    local file_mode=""
    local user=""
    local group=""

    # Validate arguments
    shift 1
    while [ "$#" -gt 0 ]; do
        case "$1" in
        -f | --file-mode)
            shift
            file_mode="${1:?missing mode for files}"
            ;;
        -d | --dir-mode)
            shift
            dir_mode="${1:?missing mode for directories}"
            ;;
        -u | --user)
            shift
            user="${1:?missing user}"
            ;;
        -g | --group)
            shift
            group="${1:?missing group}"
            ;;
        *)
            echo "Invalid command line flag $1" >&2
            return 1
            ;;
        esac
        shift
    done

    read -r -a filepaths <<<"$paths"
    for p in "${filepaths[@]}"; do
        if [[ -e "$p" ]]; then
            if [[ -n $dir_mode ]]; then
                find -L "$p" -type d -exec chmod "$dir_mode" {} \;
            fi
            if [[ -n $file_mode ]]; then
                find -L "$p" -type f -exec chmod "$file_mode" {} \;
            fi
            if [[ -n $user ]] && [[ -n $group ]]; then
                chown -LR "$user":"$group" "$p"
            elif [[ -n $user ]] && [[ -z $group ]]; then
                chown -LR "$user" "$p"
            elif [[ -z $user ]] && [[ -n $group ]]; then
                chgrp -LR "$group" "$p"
            fi
        else
            stderr_print "$p does not exist"
        fi
    done
}
