# Knox Makers Laptops NixOS Flake

## Description

NixOS configuration for the Knox Makers community laptops. Every laptop is a
host in `hosts/`, declared in `flake.nix`, and shares `modules/core-config.nix`.

## Adding a New Laptop

Two scripts do the whole job. You need the repo checked out on your admin
machine to run the first one.

### 1. On your admin machine - register the laptop in the repo

```bash
./scripts/add-laptop.sh
```

It asks what to call the new laptop (e.g. `KM-Laptop-02`), plus the system
architecture and the matching
[nixos-hardware](https://github.com/NixOS/nixos-hardware) module, then:

- creates `hosts/<name>/default.nix` from the template in the manual steps below
- adds the `nixosConfigurations` entry for it to `flake.nix`
- commits both as `Added <name> to fleet` and pushes to `main`

It refuses to run if the folder or the `flake.nix` entry already exists, and it
syntax-checks both files before committing.

### 2. On the new laptop - install NixOS, then provision it

Install NixOS with the standard installer:

- username `kmadmin`
- the standard admin password (the flake does **not** set this password, it
  keeps whatever the installer set)
- erase the disk and use the entire disk

Once you're booted into the fresh install, run this on the laptop:

```bash
curl -fsSL https://raw.githubusercontent.com/codyjamestechnical/KM-Laptops-Nix/main/scripts/provision-laptop.sh | sudo bash -s -- KM-Laptop-02
```

Replace `KM-Laptop-02` with the name you used in step 1. If you leave it off,
the script prompts for it, defaulting to the machine's current hostname.

The script checks that the laptop exists in the repo's `flake.nix`, that its
config actually defines a root filesystem, and then runs:

```bash
sudo NIX_CONFIG='experimental-features = nix-command flakes' \
  nixos-rebuild switch --refresh --flake 'github:codyjamestechnical/KM-Laptops-Nix#KM-Laptop-02'
```

The laptop should now be configured as a Knox Makers Laptop and be ready to use.
From here on it pulls the latest config straight from GitHub every hour, so
change things in the repo, not on the laptop.

## Manual Steps

The same thing by hand, if you'd rather (or if a script fails).

### 1. Create folder with the name of the laptop in the hosts directory (ex: ./hosts/KM-Laptop-02)

### 2. Place a default.nix file in that folder with the below contents

```
{inputs, config, pkgs, ...}:
{
  networking.hostName = "KM-Laptop-02"; #<< SET HOSTNAME HERE; IT SHOULD MATCH FOLDER NAME

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

### 3. Add laptop entry to flake.nix using the below example

```

      KM-Laptop-02 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; # <<< needs to match system archetecture (eg x86_64/aarch64)
        specialArgs = { inherit inputs; };
        modules = [
          nix-flatpak.nixosModules.nix-flatpak
          nixos-hardware.nixosModules.lenovo-thinkpad-t14s # <<< Match this to the hardware you're setting from the list on the readme from  https://github.com/NixOS/nixos-hardware/
          ./hosts/KM-Laptop-02 # <<< CHANGE THIS TO BE THE NAME OF THE FOLDER IN THE HOSTS DIRECTORY
          ./modules/core-config.nix
        ];
      };
```

### 4. Install NixOS on the laptop

- Set the username to "kmadmin" and use the standard admin password since this will NOT be set by the flake
- Set it to erase and use the entire disk

### 5. Point the laptop at the flake

Run:

```bash
sudo NIX_CONFIG='experimental-features = nix-command flakes' \
  nixos-rebuild switch --refresh --flake 'github:codyjamestechnical/KM-Laptops-Nix#KM-Laptop-02'
```

Replace "KM-Laptop-02" with the hostname of this laptop. `/etc/nixos` is left
untouched; the flake is the only source of truth.

### 6. The laptop should now be configured as a Knox Makers Laptop and be ready to use.

## Notes

- **Filesystems.** `nixos-rebuild --flake` does not read
  `/etc/nixos/hardware-configuration.nix`, so whatever defines each laptop's
  disk layout has to be reachable from the flake - a shared storage module, or a
  per-host file imported from that host's `default.nix`. `provision-laptop.sh`
  evaluates `config.fileSystems` first and stops rather than installing a system
  that can't mount its own root disk (`--force` overrides it).
- **kmadmin's password** is deliberately not managed by the flake, so it
  survives rebuilds. Install NixOS with a password on `kmadmin` or you'll have
  no working admin login afterwards.
- **Updates** are automatic: `modules/core-config.nix` points
  `system.autoUpgrade` at `github:codyjamestechnical/KM-Laptops-Nix#<hostname>`
  hourly, with a missed run caught on next boot. That's why the hostname has to
  match the folder name and the `flake.nix` entry.
