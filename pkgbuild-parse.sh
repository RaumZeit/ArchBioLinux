#!/bin/bash
#
# Taken from Abd� Roig-Maranges' arch-build toolkit
# which is available here: https://github.com/aroig/arch-build
#


have_function() {
	declare -f "$1" >/dev/null
}
##
#  usage : source_safe <pkgbuild>
#   desc : source a file safely
##
source_safe() {
    shopt -u extglob
    if ! source "$@"; then
        # NOTE: if source fails this does not get executed
        error "$(gettext "Failed to source %s")" "$1"
        exit 1
    fi
    shopt -s extglob
}
##
#  usage : run_function_safe <func>
#   desc : run a function safely
##
run_function_safe() {
    local restoretrap
    local pkgfunc="$1"
    set -e
    set -E
    restoretrap=$(trap -p ERR)
    trap 'error_function $pkgfunc' ERR
    $pkgfunc
    eval $restoretrap
    set +E
    set +e
}
##
#  usage : source_pkgbuild <pkgbuild>
#   desc : source a PKGBUILD safely
##
source_pkgbuild() {
    pkgbuild="$1"
    source_safe "$pkgbuild"
    pkgbase=${pkgbase:-${pkgname[0]}}
    srcdir="$path/src"
    pkgdir="$path/pkg/$pkgbase"
    epoch=${epoch:-0}
}
##
#  usage : get_full_version <pkgname>
# return : full version spec, including epoch (if necessary), pkgver, pkgrel
##
get_full_version() {
    if [[ -z $1 ]]; then
        if [[ $epoch ]] && (( ! $epoch )); then
            printf "%s\n" "$pkgver-$pkgrel"
        else
            printf "%s\n" "$epoch:$pkgver-$pkgrel"
        fi
    else
        for i in pkgver pkgrel epoch; do
            local indirect="${i}_override"
            eval $(declare -f package_$1 | sed -n "s/\(^[[:space:]]*$i=\)/${i}_override=/p")
            [[ -z ${!indirect} ]] && eval ${indirect}=\"${!i}\"
        done
        if (( ! $epoch_override )); then
            printf "%s\n" "$pkgver_override-$pkgrel_override"
        else
            printf "%s\n" "$epoch_override:$pkgver_override-$pkgrel_override"
        fi
    fi
}
##
#  usage : get_pkg_arch <pkgname>
# return : architecture of the package
##
get_pkg_arch() {
    CARCH=x86_64
	if [[ -z $1 ]]; then
        if [[ $arch = "any" ]]; then
            printf "%s\n" "any"
        else
            printf "%s\n" "$CARCH"
        fi
    else
        local arch_override
        eval $(declare -f package_$1 | sed -n 's/\(^[[:space:]]*arch=\)/arch_override=/p')
        (( ${#arch_override[@]} == 0 )) && arch_override=("${arch[@]}")
        if [[ $arch_override = "any" ]]; then
            printf "%s\n" "any"
        else
            printf "%s\n" "$CARCH"
        fi
    fi
}

pkgbuild="$1"
action="$2"

source_pkgbuild "$pkgbuild"

case $action in
    pkgfiles)
        for pkg in "${pkgname[@]}"; do
            suffix="$(get_full_version $pkg)-$(get_pkg_arch $pkg)"
            echo "$pkg-$suffix.pkg.tar.xz"
        done            
        ;;

    source)
        for src in "${source[@]}"; do
            echo "$src"
        done
        ;;

    pkgname)
        for pkg in "${pkgname[@]}"; do
            echo "$pkg"
        done
        ;;

    version)
        for pkg in "${pkgname[@]}"; do
            echo "$(get_full_version $pkg)"
        done            
        ;;

    info)
        for pkg in "${pkgname[@]}"; do
            echo "$pkg\t$pkgver\n"
        done            
        ;;

    infohtml)
        for pkg in "${pkgname[@]}"; do
            echo "<tr>\n\t<td><a href=\"$url\">$pkg</a></td>\n\t<td>$pkgver</td>\n\t<td>$pkgdesc</td>\n</tr>\n"
        done            
        ;;


    *)
        eval "echo \${$action}"
esac

        
        
        

