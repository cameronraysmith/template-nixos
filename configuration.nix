{ pkgs, ... }: {

  networking.firewall.enable = false;

  services.openssh.enable = true;
  services.openssh.listenAddresses = [{ addr = "0.0.0.0"; port = 22; }];
  services.openssh.passwordAuthentication = true;

  nix = {
    package = pkgs.nixUnstable; # or versioned attributes like nix_2_4
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  environment.systemPackages = with pkgs; [
    curl
    gitAndTools.gitFull
    htop
    sudo
    tmux
    vim
  ];

  security.sudo.enable = true;

  users.users.root.password = "root";

  users.users.nixos = {
    extraGroups = [ "wheel" ];
    isNormalUser = true;
    password = "nixos";
  };
}
