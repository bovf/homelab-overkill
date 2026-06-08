{nixpkgs, ...}: {
  mkFmtApp = system: let
    pkgs = nixpkgs.legacyPackages.${system};
    fmt = pkgs.writeShellApplication {
      name = "fmt";
      runtimeInputs = with pkgs; [alejandra git];
      text = ''
        mode="format"
        if [ "''${1:-}" = "--check" ]; then
          mode="check"
          shift
        fi

        if [ "$#" -gt 0 ]; then
          files=("$@")
        else
          mapfile -t files < <(git ls-files '*.nix')
        fi

        if [ "''${#files[@]}" -eq 0 ]; then
          exit 0
        fi

        if [ "$mode" = "check" ]; then
          exec alejandra -c "''${files[@]}"
        fi

        exec alejandra "''${files[@]}"
      '';
    };
  in {
    type = "app";
    program = nixpkgs.lib.getExe fmt;
  };
}
