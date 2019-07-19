#TODO so many small variations on idris, i need to clarify the names somehow
/*

  idrisPackages = dontRecurseIntoAttrs (callPackage ../development/idris-modules {
    idris-no-deps = haskellPackages.idris;
  });

*/
self: super: {

  #######
  #TODO rename
  idris_raw = self.nixpkgs.haskellPackages.idris; #TODO

  #TODO should only be idris no deps and this is basically .withPackages (?)
  idris' = self.idrisEnvWrapper {
    idris = self.idris_raw;
    };

  #TODO this is probably broken conceptually and or functionally
  #idris = super._interface.withPackages self idris-no-deps (p: [ p.base ]);
  idris = super._interface.withPackages self self.idris' (p: [ p.base ]);
  #######

  build-idris-package' = self.callPackage ../lib/build-idris-package2.nix;
  build-idris-package = build-idris-package' {
    composfn = idris: deps: self._interface.withPackages self idris (p: deps);
    } self.idris';

  #TODO figure out how to flatten the nested idris wrappings
  idrisEnvWrapper = self.callPackage ({makeWrapper, stdenv, lib, gmp, runCommand}: idris:
    runCommand "asdf" { buildInputs = [ makeWrapper ]; propagatedBuildInputs = [ idris ];} '' #TODO inherit name src meta? ..src? wtf?
      wrapProgram $out/bin/idris \
        --run 'export IDRIS_CC=''${IDRIS_CC:-${stdenv.cc}/bin/cc}' \
        --set NIX_CC_WRAPPER_${stdenv.cc.infixSalt}_TARGET_HOST 1 \
        --prefix NIX_CFLAGS_COMPILE " " "-I${lib.getDev gmp}/include" \
        --prefix NIX_CFLAGS_LINK " " "-L${lib.getLib gmp}/lib"
      '');
  idrisLibWrapper = self.callPackage ({ idris, makeWrapper, runCommand}:
    runCommand "asdf" { buildInputs = [ makeWrapper ];} '' #TODO inherit name src meta? ..src? wtf?
      wrapProgram $out/bin/idris \
        --set IDRIS_LIBRARY_PATH $THE_LIB_PATH #TODO make prependable upstream
      '');

  idrisComposed = {idris, plugins ? []}: #withpackages
    self.symlinkJoin {
      paths = [ (self.idrisLibWrapper idris) ] ++ plugins;#TODO gotta patch the env var
      }; # TODO platforms = attrs.meta.platforms or idris_platforms
  buildIPKG = {idris, src}: null;
  buildWrapper = null;
  #userWrapper = {idris, plugins}:
  userWrapper = {idris, paths}:
  let
    moduleflags = paths:
      let
        # "Not all command line options can be used to override package options." ??? - or at least not for the build process???!
        #Prelude and base are hardcoded in https://github.com/idris-lang/Idris-dev/blob/c5c8ede51742d03afc701e9fd854f979a5362550/src/Idris/Main.hs#L154
        filtered = builtins.filter (i: ! (builtins.elem i.ipkgName [ "base" "prelude" ])) paths; #TODO check the other builtins as well. can i just check against builtins_ ?
      in
        builtins.map (s: "-p ${s.ipkgName}") filtered;
  in
    self.nixpkgs.runCommand {} "" ''
      makeWrapper ${idris}/bin/idris $out/bin/idris_repl \
        --add-flags '${builtins.concatStringsSep " " (moduleflags paths)}' #TODO
        '';



/*
  # Idris wrapper with specified compiler and library paths, used to build packages
  idrisWrapper = self.callPackage
    ({ stdenv, lib, symlinkJoin, makeWrapper, idris_raw, gcc, gmp, plugins ? [] }:
    symlinkJoin { #TODO wtf why does this use symlinkjoin at all if it only takes one path???
      inherit (idris_raw) name src meta;
      paths = [ idris_raw ];
      buildInputs = [ makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/idris \
          --run 'export IDRIS_CC=''${IDRIS_CC:-${stdenv.cc}/bin/cc}' \
          --set NIX_CC_WRAPPER_${stdenv.cc.infixSalt}_TARGET_HOST 1 \
          --prefix NIX_CFLAGS_COMPILE " " "-I${lib.getDev gmp}/include" \
          --prefix NIX_CFLAGS_LINK " " "-L${lib.getLib gmp}/lib"
      '';
      });
*/
  }
