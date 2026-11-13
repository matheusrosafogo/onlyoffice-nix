# Uso sem flakes:
#   nix-build
#   ./result/bin/onlyoffice-desktopeditors
{ pkgs ? import <nixpkgs> { } }:
pkgs.callPackage ./package.nix { }
