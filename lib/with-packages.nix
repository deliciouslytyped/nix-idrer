# Build a version of idris with a set of packages visible
# packages: The packages visible to idris
{ lib, stdenv, symlinkJoin, makeWrapper }: idris: packages:

#TODO closepropagation is deprecated, and i have no idea what it does
let paths = stdenv.lib.closePropagation packages; #TODO what is this

in
stdenv.lib.appendToName "with-packages" (symlinkJoin {

  inherit (idris) name;

  paths = paths ++ [idris] ;

  buildInputs = [ makeWrapper ];

  #TODO unfuck, this doesnt compose
  #TODO im _REALLY_ not happy with needing to pass -p / at least document this
  #TODO separate this into a separate post- derivation so changes dont result in a bunch of rebuilds
  postBuild = ''
    wrapProgram $out/bin/idris \
      --run 'export IDRIS_LIBRARY_PATH=''${IDRIS_LIBRARY_PATH:-'$out/libs'}'
  ''; #TODO doesnt work --prefix IDRIS_LIBRARY_PATH : $out/libs

})
