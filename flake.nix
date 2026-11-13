{
  description = "ONLYOFFICE Desktop Editors para Nix/NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      onlyoffice = pkgs.callPackage ./package.nix { };
    in
    {
      packages.${system} = {
        default = onlyoffice;
        onlyoffice-desktopeditors = onlyoffice;
      };

      # Instalação via módulo NixOS:
      #   imports = [ inputs.onlyoffice.nixosModules.default ];
      nixosModules.onlyoffice =
        { pkgs, lib, ... }:
        {
          environment.systemPackages = lib.optional (
            pkgs.stdenv.hostPlatform.system == system
          ) self.packages.${system}.default;
        };

      nixosModules.default = self.nixosModules.onlyoffice;

      # Permite sobrescrever o pacote do nixpkgs em configurações NixOS:
      #   nixpkgs.overlays = [ inputs.onlyoffice.overlays.default ];
      overlays.default =
        final: prev:
        if final.system == system then
          {
            onlyoffice-desktopeditors = self.packages.${system}.onlyoffice-desktopeditors;
          }
        else
          { };
    };
}
