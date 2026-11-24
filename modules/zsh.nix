{ config, inputs, pkgs, ... }:
{
  # Set default shell to ZSH.
  users.defaultUserShell = pkgs.zsh;

  # ZSH configuration.
  programs.zsh = {
    enable = true;
    enableBashCompletion = true;
    histSize = 10000;

    autosuggestions.enable = true;
    shellAliases = {
      # Systemctl Service Management
      startsvc = "sudo systemctl start";
      stopsvc = "sudo systemctl stop";
      restartsvc = "sudo systemctl restart";
      logsvc = "sudo journalctl -xeu";

      # File system aliases
      ls = "ls -lA";
      cat = "bat";
      spf = "superfile";

      # Speed Tests
      speed-atlanta = "iperf3 -c atl.speedtest.clouvider.net -p 5200-5209 && ping -U -c 10 atl.speedtest.clouvider.net";
      speed-germany = "iperf3 -c speedtest.fra1.de.leaseweb.net -p 5201-5210 && ping -U -c 10 speedtest.fra1.de.leaseweb.net";
      speed-amsterdam = "iperf3 -c ams.speedtest.clouvider.net -p 5200-5209 && ping -U -c 10 ams.speedtest.clouvider.net";
      speed-canada = "iperf3 -c speedtest.mtl2.ca.leaseweb.net -p 5201-5210 && ping -U -c 10 speedtest.mtl2.ca.leaseweb.net";

      # Rebuild switch NixOS from the latest commit on GitHub
      rebuild = "sudo nixos-rebuild switch --refresh --flake 'github:codyjamestechnical/KM-Laptops-Nix#${config.networking.hostName}'";

    };
  };
}
