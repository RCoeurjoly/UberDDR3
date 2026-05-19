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
        prjxrayDb = pkgs.runCommand "prjxray-db-kintex7-lioi3-tbytesrc-oclkm" { } ''
          cp -R --no-preserve=mode,ownership ${openxc7.nextpnr-xilinx}/share/nextpnr/external/prjxray-db $out

          cat >> $out/kintex7/segbits_lioi3_tbytesrc.db <<'DBEOF'
LIOI3_TBYTESRC.IOI_OCLKM_0.IOI_IMUX31_1 30_94 31_83 31_93
DBEOF

          cat >> $out/kintex7/segbits_lioi3_tbytesrc.origin_info.db <<'DBEOF'
LIOI3_TBYTESRC.IOI_OCLKM_0.IOI_IMUX31_1 origin:037-iob-pips 30_94 31_83 31_93
DBEOF
        '';
      in
      {
        devShells.default = toolchain-nix.devShell.${system}.overrideAttrs (old: {
          shellHook = (old.shellHook or "") + "\nexport PRJXRAY_DB_DIR=${prjxrayDb}\n";
        });
      });
}
