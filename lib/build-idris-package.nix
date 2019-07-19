#TODO abi compat on refactor? - store prent idris in passthru, check in compose
# Build an idris package
{ stdenv, lib, self, gmp }:
  { idrisDeps ? []
  , noPrelude ? false
  , noBase ? false
  , name
  , version
  , ipkgName ? name
  , extraBuildInputs ? []
  , ...
  }@attrs:
let
  allIdrisDeps = idrisDeps
    ++ lib.optional (!noPrelude) self.prelude
    ++ lib.optional (!noBase) self.base;
  idris-with-packages = self._interface.withPackages self self.idris' (p: allIdrisDeps); #TODO unfuck
  newAttrs = builtins.removeAttrs attrs [
    "idrisDeps" "noPrelude" "noBase"
    "name" "version" "ipkgName" "extraBuildInputs"
  ] // {
#    meta = attrs.meta // {
#      platforms = attrs.meta.platforms or self.idris'.meta.platforms; #TODO
#    };
  };
in
stdenv.mkDerivation ({
  name = "idris-${name}-${version}";
  inherit ipkgName; #TODO ? / what decides the -p import name #TODO remove from above instead

  buildInputs = [ idris-with-packages gmp ] ++ extraBuildInputs;
  propagatedBuildInputs = allIdrisDeps;

  # Some packages use the style
  # opts = -i ../../path/to/package
  # rather than the declarative pkgs attribute so we have to rewrite the path.
  postPatch = ''
    runHook prePatch
    sed -i ${ipkgName}.ipkg -e "/^opts/ s|-i \\.\\./|-i ${idris-with-packages}/libs/|g"
  '';

  buildPhase = ''
    runHook preBuild
    idris --build ${ipkgName}.ipkg
    runHook postBuild
  '';

  checkPhase = ''
    runHook preCheck
    if grep -q tests ${ipkgName}.ipkg; then
      idris --testpkg ${ipkgName}.ipkg
    fi
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    idris --install ${ipkgName}.ipkg --ibcsubdir $out/libs
    IDRIS_DOC_PATH=$out/doc idris --installdoc ${ipkgName}.ipkg || true
    runHook postInstall
  '';

} // newAttrs)
