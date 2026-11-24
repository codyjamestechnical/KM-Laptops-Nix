{
  description = "Knox Makers NixOS configuration for community laptops";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    # Hardware-specific NixOS modules
    # https://github.com/NixOS/nixos-hardware
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # manage flatpak apps declaratively
    # https://wiki.nixos.org/wiki/Flatpak
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.7.0";
  };

  outputs = { self, nixpkgs, nixos-hardware, nix-flatpak }@inputs: {
    nixosConfigurations = {
      laptop-01 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          nix-flatpak.nixosModules.nix-flatpak
          nixos-hardware.nixosModules.lenovo-thinkpad-t14s
          ./hosts/laptop-01
          ./modules/core-config.nix
        ];
      };
    };
  };

}
