# Knox Makers Laptops NixOS Flake

## Description

## Steps to Setup New Laptop

1. Create folder with the name of the laptop in the hosts directory (ex: ./hosts/KM-Laptop-01)
2. Place a default.nix file in that folder with the below contents

```
{inputs, config, pkgs, ...}:
{
  imports = [
    ./hardward-configuration.nix
  ];

  networking.hostName = "KM-Laptop-01"; #<< SET HOSTNAME HERE; IT SHOULD MATCH FOLDER NAME

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?
}
```

3. Add laptop entry to flake.nix using the below example

```

    KM-Laptop-01 <<< CHANGE THIS TO MATCH THE HOSTNAME & REMOVE THIS COMMENT = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; # <<< needs to match system archetecture (eg x86_64/aarch64)
        specialArgs = { inherit inputs; };
        modules = [
          nix-flatpak.nixosModules.nix-flatpak
          nixos-hardware.nixosModules.lenovo-thinkpad-t14s # <<< Match this to the hardware you're setting from the list on the readmy from  https://github.com/NixOS/nixos-hardware/
          ./hosts/KM-Laptop-01 # <<< CHANGE THIS TO BE THE NAME OF THE FOLDER IN THE HOSTS DIRECTORY
          ./modules/core-config.nix
        ];
      };
    };
```

4. Install NixOS on the laptop

- Set the username to "kmadmin" and use the standard admin password since this will NOT be set by the flake
- Set it to erase and use the entire disk

5. Add the below to /etc/nixos/configuration.nix and run "nixos-rebuild switch"

```
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

6. Once the rebuild is complete, run the command below

```
sudo nixos-rebuild switch --refresh --flake 'github:codyjamestechnical/KM-Laptops-Nix#$KM-Laptop-01' <<< REPLACE "KM-Laptop-01" WITH HOSTNAME OF THIS LAPTOP
```

7. The laptop should now be configured as a Knox Makers Laptop and be ready to use.
