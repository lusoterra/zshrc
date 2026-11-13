#!/bin/sh

set -e

OS=""
if [ "$(uname -s)" = "FreeBSD" ]; then
    OS="freebsd"
elif [ "$(uname -s)" = "OpenBSD" ]; then
    OS="openbsd"
elif [ "$(uname -s)" = "Darwin" ]; then
    OS="darwin"
elif [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    case "$ID" in
        arch)   OS="arch" ;;
        debian) OS="debian" ;;
        alpine) OS="alpine" ;;
        gentoo) OS="gentoo" ;;
    esac
fi

if [ -z "$OS" ]; then
    echo "OS is not Debian/Arch/Alpine/FreeBSD/OpenBSD" >&2
    exit 1
fi

case "$OS" in
    arch)
        pacman -Syu --noconfirm zsh zsh-syntax-highlighting zsh-autosuggestions zoxide bat fzf \
            tree fastfetch git git-lfs lsd micro rsync wget moor curl fd ffmpeg
        ;;

    debian)
        apt update -y && apt upgrade -y
        # moor is on debian 14 not 13, fallback on zshrc ok
        apt install -y zsh zsh-syntax-highlighting zsh-autosuggestions zoxide bat fzf \
            tree fastfetch git git-lfs lsd micro rsync wget curl fd-find ffmpeg
        ;;

    alpine)
        # uncomment the community repo and pin it to edge before installing
        sed -i -E 's~^#?(https?://[^[:space:]]+/)v[0-9]+\.[0-9]+(/(main|community).*)$~\1edge\2~' \
            /etc/apk/repositories
        apk update && apk upgrade
        # alpine needs the shadow package for the chsh command
        apk add zsh zsh-syntax-highlighting zsh-autosuggestions zoxide bat fzf \
            tree fastfetch git git-lfs lsd micro rsync wget moor curl fd ffmpeg \
            shadow 
        ;;

    freebsd)
        pkg update && pkg upgrade -y
        pkg install -y zsh zsh-syntax-highlighting zsh-autosuggestions zoxide bat fzf \
            tree fastfetch git git-lfs lsd micro rsync wget moor curl fd ffmpeg
        ;;

    openbsd)
        pkg_add -u
        # zsh-autosuggestions, zoxide not available on openbsd fallbacks on zshrc ok
        pkg_add zsh zsh-syntax-highlighting bat fzf tree fastfetch git git-lfs \
            lsd micro rsync wget curl fd ffmpeg
        ;;
    darwin)
        brew install zsh zsh-syntax-highlighting zsh-autosuggestions zoxide bat fzf \
            tree fastfetch git git-lfs lsd micro rsync wget moor curl fd ffmpeg
        ;;
    gentoo)
        emerge --ask n zsh zsh-syntax-highlighting zsh-autosuggestions zoxide bat fzf \
            tree fastfetch git git-lfs lsd micro rsync wget moor curl fd ffmpeg
        ;;
esac

ZSH_PATH="$(command -v zsh)"
TARGET_USER="${SUDO_USER:-$(id -un)}"
grep -qxF "$ZSH_PATH" /etc/shells || echo "$ZSH_PATH" >> /etc/shells
chsh -s "$ZSH_PATH" "$TARGET_USER"
