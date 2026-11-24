{ inputs, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    # Use the same nixpkgs instance as NixOS.
    useGlobalPkgs = true;

    # Install Home Manager packages through the NixOS user profile.
    useUserPackages = true;

    sharedModules = [
      inputs.plasma-manager.homeModules.plasma-manager
    ];

    users.kmuser = import ../home/km-user.nix;
  };
}
