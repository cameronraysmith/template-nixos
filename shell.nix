let 
  pkgs = import <nixpkgs> {};
  nixos-generators = import (builtins.fetchTarball https://github.com/nix-community/nixos-generators/archive/master.tar.gz);
  testScript = pkgs.writeScriptBin "testscript" ''
    echo "Test Script";
  '';
in with pkgs;
mkShell {
  name = "base-nix-shell";

  nativeBuildInputs = [
    direnv
    niv
    nixos-generators
  ];

  buildInputs = [
    figlet
    nixUnstable
    testScript
  ];

  NIX_ENFORCE_PURITY = true;

  shellHook = ''
  '';
}
