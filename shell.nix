{ pkgs ? import <nixpkgs> {} }:

with pkgs; let
  deps = callPackage ./deps.nix {};
  resolveTimeDeps = [ file gettext ];
in pkgs.mkShell {
  buildInputs = [ pkgs.oildev ] ++ runtimeDeps ++ mine.checkInputs;
  RESHOLVE_PATH = "${pkgs.lib.makeBinPath mine.runtimeDeps}";
  shellHook = ''
    ln resholver.py resholver 2> /dev/null
    PATH=$PWD:$PATH
  '';
}
