{ stdenv, callPackage, file, gettext, python27, bats }:
let
  deps = callPackage ./deps.nix { };
  resolveTimeDeps = [ file gettext ];
in python27.pkgs.buildPythonApplication {
  pname = "resholved";
  version = "unreleased";
  src = ./.;

  format = "other";

  propagatedBuildInputs = [ deps.oildev ];

  # TODO: try install -Dt $out/bin $src/yadm
  installPhase = ''
    mkdir -p $out/bin
    install resholver $out/bin/
  '';
  doCheck = true;
  checkInputs = [ bats ];
  RESHOLVE_PATH = "${stdenv.lib.makeBinPath resolveTimeDeps}";
  checkPhase = ''
    PATH=$out/bin:$PATH
    ./test.sh
  '';

  meta = {
    description = "Resolve external shell-script dependencies";
    homepage = "https://github.com/abathur/resholved";
    license = with stdenv.lib.licenses; [
      mit
    ];
    maintainers = with stdenv.lib.maintainers; [ abathur ];
    platforms = stdenv.lib.platforms.all;
  };
}
