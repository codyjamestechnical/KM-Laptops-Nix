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

    # KM-Laser Inkscape extension bundle (pinned via flake.lock)
    # https://github.com/KnoxMakers/KM-Laser
    km-laser = {
      url = "github:KnoxMakers/KM-Laser";
      flake = false;
    };

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  };

  outputs = { self, nixpkgs, nixos-hardware, nix-flatpak, km-laser, nix-vscode-extensions }@inputs: {
    nixosConfigurations = {
      KM-Laptop-01 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          nix-flatpak.nixosModules.nix-flatpak
          nixos-hardware.nixosModules.lenovo-thinkpad-t14s
          nix-vscode-extensions.nixosModules.nix-vscode-extensions
          ./hosts/KM-Laptop-01
          ./modules/core-config.nix
        ];
      };
    };
  };

}
