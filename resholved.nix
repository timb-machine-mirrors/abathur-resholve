{ stdenv, callPackage, file, gettext, python27 }:
let
  deps = callPackage ./deps.nix {};
  resolveTimeDeps = [ file gettext ];
in python27.pkgs.buildPythonApplication {
  name = "resholved";
  src = ./.;

  format = "other";

  buildInputs = [ python27 ];
  # TODO: this smells
  pythonPath = with python27.pkgs; [ six typing ];
  propagatedBuildInputs = [ deps.oildev ];

  installPhase = ''
    mkdir -p $out/bin

    install resholver.py $out/bin/resholver
  '';
  doCheck=true;
  checkInputs = with python27.pkgs; [ pytest deps.pytest-shell ];
  RESHOLVE_PATH = "${stdenv.lib.makeBinPath resolveTimeDeps}";
  checkPhase = ''
    PATH=$out/bin:$PATH pytest tests
  '';
}
