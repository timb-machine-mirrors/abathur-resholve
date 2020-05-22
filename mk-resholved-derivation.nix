{ stdenv, lib, resholved, }:

{ pname, src, version, scripts, inputs ? [ ], allow ? { }, passthru ? { }, ...
}@attrs:
let
  inherit stdenv;
  self = (stdenv.mkDerivation ((removeAttrs attrs [ "script" "inputs" "allow" ])
    // {
      inherit pname version src;
      buildInputs = [ resholved ];
      # tentatively disabled because gc probably knows things I don't :)
      #gchristensen | hmm yeah I'm not sure why this is a thing:       propagatedBuildInputs = inputs;
      # tests still pass
      # initial thinking: sourced shell libraries commonly ~propagate their dependencies (sometimes intentionally)
      # propagatedBuildInputs = inputs;
      RESHOLVE_PATH = "${lib.makeBinPath inputs}";
      RESHOLVE_ALLOW = toString
        (lib.mapAttrsToList (name: value: map (y: name + ":" + y) value) allow);
      #LOGLEVEL="INFO";
      buildPhase = ''
        runHook preBuild
        resholver ${toString scripts}
        runHook postBuild
      '';
    }));
in lib.extendDerivation true passthru self
