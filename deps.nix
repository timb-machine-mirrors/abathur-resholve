{ stdenv, fetchFromGitHub, makeWrapper,

git,

# oil deps
readline, re2c, cmark, python27, file,
}:

rec {
  py-yajl = python27.pkgs.buildPythonPackage rec {
    pname = "oil-pyyajl";
    version = "unreleased";
    src = fetchFromGitHub {
      owner = "oilshell";
      repo = "py-yajl";
      rev = "eb561e9aea6e88095d66abcc3990f2ee1f5339df";
      sha256 = "17hcgb7r7cy8r1pwbdh8di0nvykdswlqj73c85k6z8m0filj3hbh";
      fetchSubmodules = true;
    };
    # just for submodule IIRC
    nativeBuildInputs = [ git ];
  };

  # resholved's primary dependency is this developer build of the oil shell.
  oildev = python27.pkgs.buildPythonPackage rec {
    pname = "oil";
    version = "undefined";

    # I've gotten most of the changes we need upstreamed at this point, but I've still got a few they've resisted. For the near term, I've given up trying.
    # - add setup.py
    # - add MANIFEST.in,
    # - change build/codegen.sh's shebang to /usr/bin/env bash
    # - comment out the 'yajl' function call in _minimal() of build/dev.sh
    src = fetchFromGitHub {
      owner = "oilshell";
      repo = "oil";
      rev = "ea80cdad7ae1152a25bd2a30b87fe3c2ad32394a";
      sha256 = "0pxn0f8qbdman4gppx93zwml7s5byqfw560n079v68qjgzh2brq2";
    };

    # TODO: not sure why I'm having to set this for nix-build...
    #       can anyone tell if I'm doing something wrong?
    SOURCE_DATE_EPOCH=315532800;

    /*
    Not sure if there's a better way to do this, but I'm taking over the
    unpack phase because the Oil shell's directory structure isn't
    Python-package friendly--each oil subdir with an __init__.py ends up as
    an unprefixed package. Custom phase unpacks the oil shell into a sub-dir
    oil/source/. Patch phase adds oil/{setup.py,MANIFEST.in}.
    */
    unpackPhase = ''
      mkdir oil
      cd oil
      unpackFile $src
      chmod -R u+w source
    '';

    # These aren't, strictly speaking, nix/nixpkgs specific, but I've had hell
    # upstreaming them.
    patches = [
      ./0001-add_setup_py.patch
      ./0002-add_MANIFEST_in.patch
      ./0003-fix_codegen_shebang.patch
      ./0004-disable-internal-py-yajl-for-nix-built.patch
    ];

    buildInputs = [ readline cmark py-yajl makeWrapper ];

    nativeBuildInputs = [ re2c file ];

    # runtime deps
    propagatedBuildInputs = with python27.pkgs; [ python27 six typing ];

    doCheck = true;
    dontStrip = true;

    preBuild = ''
      pushd source
      build/dev.sh all
      popd
    '';

    # fabricate path for oil's packages/modules to find each other for test
    preCheck = ''
      OIL_DEV="$(pwd)/source"
      export PYTHONPATH="$PYTHONPATH:$OIL_DEV"
    '';

    # Patch shebangs so Nix can find all executables
    postPatch = ''
      pushd source
      patchShebangs asdl build core doctools frontend native oil_lang
      popd
    '';

    _NIX_SHELL_LIBCMARK = "${cmark}/lib/libcmark${stdenv.hostPlatform.extensions.sharedLibrary}";

    meta = {
      description = "A new unix shell";
      homepage = "https://www.oilshell.org/";
      license = with stdenv.lib.licenses; [
        psfl # Includes a portion of the python interpreter and standard library
        asl20 # Licence for Oil itself
      ];
    };
  };
}
