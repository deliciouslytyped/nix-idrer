#TODO
# The set of libraries that comes with idris
self: super:
let
  builtin =
    #TODO unfuck
    super.nixpkgs.lib.mapAttrs (self.util.build-builtin-package { idris = self.idris_raw; inherit (self) build-idris-package; }) { #name: deps:
      prelude = [];

      base = [ self.prelude ];

      contrib = [ self.prelude self.base ];

      effects = [ self.prelude self.base ];

      pruviloj = [ self.prelude self.base ];

      };
in
  builtin // { builtins = super.nixpkgs.lib.mapAttrsToList (n: v: v) builtin; }
