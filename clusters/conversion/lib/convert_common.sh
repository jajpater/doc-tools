#!/usr/bin/env bash
set -euo pipefail

die() {
    echo "ERROR: $*" >&2
    exit 1
}

check_dep() {
    local cmd="$1"
    local nix_hint="${2:-}"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: Required dependency not found: $cmd" >&2
        if [[ -n "$nix_hint" ]]; then
            echo "NixOS: nix shell $nix_hint" >&2
        fi
        exit 1
    fi
}

ensure_dir() {
    local dir="$1"
    [[ -d "$dir" ]] || die "Directory does not exist: $dir"
}

normalize_ext() {
    local ext="$1"
    ext="${ext#.}"
    echo "$ext"
}

dedupe_files() {
    local -A seen=()
    local -a out=()
    local f
    for f in "$@"; do
        [[ -e "$f" ]] || die "Bestand niet gevonden: $f"
        if [[ -z "${seen["$f"]+x}" ]]; then
            seen["$f"]=1
            out+=("$f")
        fi
    done
    printf '%s\0' "${out[@]}"
}

collect_files_by_ext() {
    local dir="$1"
    shift
    local -a exts=("$@")
    local -A seen=()
    local -a files=()
    local ext
    for ext in "${exts[@]}"; do
        ext="$(normalize_ext "$ext")"
        [[ -z "$ext" ]] && continue
        while IFS= read -r -d '' f; do
            if [[ -z "${seen["$f"]+x}" ]]; then
                seen["$f"]=1
                files+=("$f")
            fi
        done < <(find "$dir" -type f -name "*.${ext}" -print0)
    done
    printf '%s\0' "${files[@]}"
}

rename_file_if_space() {
    local file="$1"
    if [[ "$file" == *" "* ]]; then
        local dir_name
        local base_name
        local new_name
        local new_path
        dir_name="$(dirname "$file")"
        base_name="$(basename "$file")"
        new_name="$(echo "$base_name" | tr ' ' '_')"
        new_path="$dir_name/$new_name"
        mv "$file" "$new_path"
        echo "$new_path"
        return 0
    fi
    echo "$file"
}

rename_spaces_in_dir() {
    local dir="$1"
    shift
    local -a exts=("$@")
    local ext
    for ext in "${exts[@]}"; do
        ext="$(normalize_ext "$ext")"
        [[ -z "$ext" ]] && continue
        while IFS= read -r -d '' file; do
            rename_file_if_space "$file" >/dev/null
        done < <(find "$dir" -type f -name "*.${ext}" -name "* *" -print0)
    done
}

prompt_mode() {
    local count="$1"
    if [[ "$count" -le 1 ]]; then
        echo "all"
        return 0
    fi
    if [[ ! -t 0 ]]; then
        echo "all"
        return 0
    fi
    local choice=""
    while [[ -z "$choice" ]]; do
        read -r -p "Alles converteren? [A]ll/[S]electie: " choice
        case "${choice,,}" in
            a|all)
                echo "all"
                return 0
                ;;
            s|select|selection)
                echo "select"
                return 0
                ;;
            *)
                choice=""
                ;;
        esac
    done
}

prompt_mode_gui() {
    check_dep "wofi"
    local choice
    choice="$(printf 'Alles\nSelectie\n' | wofi --dmenu --prompt='Actie: ')" || true
    case "$choice" in
        Selectie)
            echo "select"
            ;;
        *)
            echo "all"
            ;;
    esac
}

read_nautilus_selected_files() {
    local -a files=()
    local line
    if [[ -n "${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS:-}" ]]; then
        while IFS= read -r line; do
            [[ -n "$line" ]] && files+=("$line")
        done <<< "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS"
    fi
    printf '%s\0' "${files[@]}"
}

choose_files_fzf() {
    check_dep "fzf"
    local -a files=("$@")
    if [[ "${#files[@]}" -eq 0 ]]; then
        return 0
    fi
    printf '%s\n' "${files[@]}" | fzf --multi --prompt="Selecteer bestanden: " --height=40% --border
}

parse_indices() {
    local input="$1"
    local max="$2"
    local -A seen=()
    local -a out=()
    local token

    input="${input//,/ }"
    for token in $input; do
        if [[ "$token" =~ ^[0-9]+-[0-9]+$ ]]; then
            local start="${token%-*}"
            local end="${token#*-}"
            if (( start > end )); then
                local tmp="$start"
                start="$end"
                end="$tmp"
            fi
            local i
            for (( i=start; i<=end; i++ )); do
                if (( i>=1 && i<=max )); then
                    if [[ -z "${seen[$i]+x}" ]]; then
                        seen[$i]=1
                        out+=("$i")
                    fi
                fi
            done
        elif [[ "$token" =~ ^[0-9]+$ ]]; then
            local i="$token"
            if (( i>=1 && i<=max )); then
                if [[ -z "${seen[$i]+x}" ]]; then
                    seen[$i]=1
                    out+=("$i")
                fi
            fi
        fi
    done
    printf '%s\0' "${out[@]}"
}

choose_files_wofi_multi() {
    check_dep "wofi"
    local -a files=("$@")
    local count="${#files[@]}"
    if [[ $count -eq 0 ]]; then
        return 0
    fi
    local -a menu=()
    local i
    for i in "${!files[@]}"; do
        local idx=$((i + 1))
        menu+=("${idx}) ${files[$i]}")
    done
    local prompt="Selecteer nummers (bv: 1 3 5-7)"
    local choice
    choice="$(printf '%s\n' "${menu[@]}" | wofi --dmenu --prompt="${prompt}")" || true
    [[ -n "$choice" ]] || return 0

    # If user picked a line, map it back to a single index.
    if [[ "$choice" =~ ^[0-9]+\\)\\  ]]; then
        local idx="${choice%%)*}"
        idx="${idx//[^0-9]/}"
        if [[ -n "$idx" ]]; then
            echo "${files[$((idx - 1))]}"
            return 0
        fi
    fi

    # Otherwise treat input as a list of indices.
    mapfile -d '' -t indices < <(parse_indices "$choice" "$count")
    local -a selected=()
    for idx in "${indices[@]}"; do
        selected+=("${files[$((idx - 1))]}")
    done
    printf '%s\n' "${selected[@]}"
}
