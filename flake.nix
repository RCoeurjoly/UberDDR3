{
  description = "UberDDR3 OpenXC7 development shell";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.follows = "toolchain-nix/nixpkgs";
    toolchain-nix.url = "github:openXC7/toolchain-nix";
  };

  outputs = { flake-utils, nixpkgs, toolchain-nix, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        openxc7 = toolchain-nix.packages.${system};
        historicalNextpnrXilinx = openxc7.nextpnr-xilinx.overrideAttrs (old: {
          pname = "nextpnr-xilinx-b9f013d";
          src = pkgs.fetchFromGitHub {
            owner = "openXC7";
            repo = "nextpnr-xilinx";
            rev = "b9f013d91a5536ef30e9661b9600a76ad889fe78";
            hash = "sha256-++TjoG/mFqY+/g/w5Z/Mt/EjexClhGzVL6M+JR8ldSY=";
            fetchSubmodules = true;
          };
          cmakeFlags = map
            (flag:
              if pkgs.lib.hasPrefix "-DCURRENT_GIT_VERSION=" flag
              then "-DCURRENT_GIT_VERSION=b9f013d"
              else flag)
            (old.cmakeFlags or []);
        });
        mkPrjxrayDb = nextpnr: pkgs.runCommand "prjxray-db-kintex7-lioi3-tbytesrc-oclkm" { } ''
          cp -R --no-preserve=mode,ownership ${nextpnr}/share/nextpnr/external/prjxray-db $out

          cat >> $out/kintex7/segbits_lioi3_tbytesrc.db <<'DBEOF'
LIOI3_TBYTESRC.IOI_OCLKM_0.IOI_IMUX31_1 30_94 31_83 31_93
DBEOF

          cat >> $out/kintex7/segbits_lioi3_tbytesrc.origin_info.db <<'DBEOF'
LIOI3_TBYTESRC.IOI_OCLKM_0.IOI_IMUX31_1 origin:037-iob-pips 30_94 31_83 31_93
DBEOF
        '';
        prjxrayDb = mkPrjxrayDb openxc7.nextpnr-xilinx;
        historicalPrjxrayDb = mkPrjxrayDb historicalNextpnrXilinx;
        withNextpnr = nextpnr: db: old: {
          shellHook = (old.shellHook or "") + ''
            export PATH=${nextpnr}/bin:$PATH
            export NEXTPNR_XILINX_DIR=${nextpnr}
            export NEXTPNR_XILINX_PYTHON_DIR=${nextpnr}/share/nextpnr/python
            export PRJXRAY_DB_DIR=${db}
          '';
        };
      in
      {
        packages.historical-nextpnr-xilinx = historicalNextpnrXilinx;
        devShells.default = toolchain-nix.devShell.${system}.overrideAttrs
          (withNextpnr openxc7.nextpnr-xilinx prjxrayDb);
        devShells.openxc7-b9f013d = toolchain-nix.devShell.${system}.overrideAttrs
          (withNextpnr historicalNextpnrXilinx historicalPrjxrayDb);
      });
}
