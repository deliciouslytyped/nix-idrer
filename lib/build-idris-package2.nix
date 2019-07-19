{ stdenv, lib, gmp
, wrapHook
, composefn, prelude, base
}:
idris: #Dont collide with automatic argument

{ idrisDeps ? []
, noPrelude ? false
, noBase ? false
, name
, version
, ipkgName ? name
, extraBuildInputs ? [] # TODO necessary?

# Not removeAttrs-d
, src
, meta ? {}
, ...
}@attrs:

let
  extra = builtins.removeAttrs attrs [ "idrisDeps" "noPrelude" "noBase" "name" "version" "ipkgName" "extraBuildInputs" "platforms" ];
  allIdrisDeps = idrisDeps
    ++ lib.optional (!noPrelude) prelude
    ++ lib.optional (!noBase) base;
  idrisWithDeps = composfn idris allIdrisDeps;
in

stdenv.mkDerivation {
  name = "idris-${name}-${version}";

  passthru = {#TODO abi compat on refactor? - store prent idris in passthru, check in compose
    inherit allIdrisDeps idrisWithDeps extra; # exposing the let
    inherit ipkgName; #TODO ? / what decides the -p import name #TODO remove from above instead
    };

  buildInputs = [ idrisWithDeps ] ++ extraBuildInputs;   #TODO removed gmp, is it ok?  #TODO unfuck #TODO hmm thats a lot of environments to build for a deep tree -> build everything with transitive closure? | but with symlinkjoin this should be fine
  propagatedBuildInputs = allIdrisDeps;

  meta = meta // { platforms = meta.platforms or idris.meta.platforms; }; #TODO i dont really like this

  # Some packages use the style
  # opts = -i ../../path/to/package
  # rather than the declarative pkgs attribute so we have to rewrite the path. #TODO tell people not to do this
  postPatch = ''
    runHook prePatch #TODO uhhhhh
    sed -i ${ipkgName}.ipkg -e "/^opts/ s|-i \\.\\./|-i ${idris-with-packages}/libs/|g"
    '';

  buildPhase = wrapHook "Build" ''
    idris --build ${ipkgName}.ipkg
    '';

  checkPhase = wrapHook "Check" ''
    if grep -q tests ${ipkgName}.ipkg; then
      idris --testpkg ${ipkgName}.ipkg
    fi
    '';

  installPhase = wrapHook "Install" ''
    idris --install ${ipkgName}.ipkg --ibcsubdir $out/libs
    IDRIS_DOC_PATH=$out/doc idris --installdoc ${ipkgName}.ipkg || true
    '';
  } // extra
