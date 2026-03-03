#!/usr/bin/env bash
packages=$(grep -oE '(unstable|stable)\.[a-zA-Z0-9_-]+' nixos/configuration.nix | awk -F'.' '{print $2}' | sort | uniq | grep -v "\-bin$")
for pkg in $packages; do
  if nix eval "nixpkgs#$pkg-bin.meta.name" &>/dev/null; then
    echo "Found binary version: $pkg -> $pkg-bin"
  fi
done
