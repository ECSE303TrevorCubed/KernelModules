{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    { self, ... }@inputs:
    inputs.flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import inputs.nixpkgs { inherit system; };
        treefmtconfig = inputs.treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";
          programs = {
            alejandra.enable = true;
            yamlfmt.enable = true;
            mdformat = {
              enable = true;
              plugins = ps: [
                ps.mdformat-gfm
              ];
              settings = {
                wrap = 88;
                end-of-line = "lf";
              };
            };
            clang-format.enable = true;
            nixfmt.enable = true;
            typstyle.enable = true;
          };
        };
      in
      {
        formatter = treefmtconfig.config.build.wrapper;
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            clang-tools
            pkg-config
            gcc
          ];

          packages = with pkgs; [
            typst
            typstyle
            nil
            nixd
            dtc
          ];
        };
        packages =
          let
            kernel_modules_report = pkgs.callPackage ./nix/report.nix { };
            dht11_overlay = pkgs.callPackage ./nix/dtb.nix { };
            ci = pkgs.callPackage ./nix/ci.nix {
              reports = kernel_modules_report;
              artifacts = [ dht11_overlay ];
            };
          in
          {
            default = ci;
            inherit kernel_modules_report dht11_overlay ci;
          };
        checks = {
          formatting = treefmtconfig.config.build.check self;
        };
      }
    );
}
