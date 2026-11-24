users.users."kmuser" = {
  isNormalUser = true;
  description = "KM User";
  extraGroups = [ "networkmanager" ];
  hashedPassword = "$y$j9T$1nkeFcuJXg0U9iUIdxn5O1$3AMUPacoOVddpUjjxoJeEpFZa0eQ4qTnpfuI8ep1M00";

  # user specific packages to only install for this user
  packages = with pkgs; [
  #  thunderbird
  ];
};
