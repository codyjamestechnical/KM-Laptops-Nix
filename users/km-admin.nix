{
  inputs,
  config,
  pkgs,
  ...
}:
{
  users.users."kmadmin" = {
    defaultUserShell = pkgs.zsh;
    isNormalUser = true;
    description = "KM Admin";
    extraGroups = [ "networkmanager" "wheel" ];

    # user specific packages to only install for this user
    packages = with pkgs; [
    #  thunderbird
    ];
  };
}
