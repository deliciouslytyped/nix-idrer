{callPackage ? (import ./extern/nixpkgs-pinned.nix).callPackage }: {
  #TODO the surrogate is (a temporary workaround?) used to serve as the root for what would actually be a multi-headed package set -- TODO or you could just...parametrize over it
  idris = callPackage ./packages.nix {};
  }
