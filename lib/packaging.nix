{lib, ...}: rec {
  discover = path: transform:
    lib.pipe (builtins.readDir path) [
      (lib.filterAttrs (name: value: value == "directory"))
      transform
    ];

  discoverPackages = {
    path,
    callPackage,
    extraArgs ? {},
  }:
    discover path (builtins.mapAttrs (name: _: callPackage (path + "/${name}") extraArgs));

  discoverModules = path:
    discover path (builtins.mapAttrs (name: _: import (path + "/${name}")));

  # Returns `newPkg` if it's the same version or newer than `upstreamPkg`, otherwise returns `upstreamPkg`
  versionGate = newPkg: upstreamPkg: let
    newVersion = lib.getVersion newPkg;
    upstreamVersion = lib.getVersion upstreamPkg;
  in
    if builtins.compareVersions newVersion upstreamVersion >= 0
    then newPkg
    else lib.warn "Package ${lib.getName newPkg} surpassed local version ${newVersion} on upstream - upstream is now used" upstreamPkg;

  # Returns a list of all executable names in a package's bin/ directory (requires IFD)
  exeNames = pkg: builtins.attrNames (builtins.readDir "${pkg}/bin");

  # Rename "default" to the package's actual name
  renameDefaultToPname = name: pkg:
    if name == "default" && lib.isDerivation pkg
    then {
      name = pkg.pname or pkg.name;
      value = pkg;
    }
    else {
      inherit name;
      value = pkg;
    };

  # Nixpkgs config predicate that allows all unfree packages with a warning
  allowUnfreeWithWarning = pkg:
    lib.warn "Allowing unfree package: ${lib.getName pkg}" true;

  # Filter packages suitable for flake export (derivations that aren't broken)
  filterExportablePackages = pkgs:
    lib.filterAttrs
    (_: p: lib.isDerivation p && !(p.meta.broken or false))
    pkgs;

  # Create an overlay that extracts packages from flake inputs
  # Input format: list of either:
  #   - input (extracts all packages)
  #   - [input "pkg1" "pkg2"] (extracts specific packages)
  # Example:
  #   mkInputPackagesOverlay [
  #     inputs'.bubble
  #     [inputs'.nix-auto-follow "default"]
  #   ]
  mkInputPackagesOverlay = inputPackages: final: prev: let
    getInputPackages = item:
      if lib.isList item
      then lib.getAttrs (lib.tail item) (lib.head item).packages
      else item.packages;
  in
    lib.pipe inputPackages [
      (map getInputPackages)
      (map (lib.mapAttrsToList renameDefaultToPname))
      lib.flatten
      lib.listToAttrs
    ];

  # Create an overlay for locally-defined packages with optional configuration.
  # Each package can specify `upstream = prev: pkg` — a function returning the
  # corresponding upstream derivation. When set, the upstream is both passed to
  # callPackage as `{ ${name} = upstreamPkg; }` and used as the versionGate target.
  # Version-gated packages go into pkgs at the top level (e.g. pkgs.freetube).
  # Un-gated local overrides are also stashed under pkgs.p.localPackages,
  # so consumers can export them as flake packages (preserving passthru.updateScript etc.).
  # Example:
  #   mkLocalPackagesOverlay ./pkgs {
  #     calibre.upstream = p: p.calibre;
  #     freetube.upstream = p: p.stable.freetube;
  #   }
  mkLocalPackagesOverlay = path: packages: final: prev: let
    localNames = builtins.attrNames (builtins.readDir path);

    getUpstream = name:
      let upstream = (packages.${name} or {}).upstream or null;
      in if upstream != null then upstream prev else null;

    buildLocal = name: let
      upstreamPkg = getUpstream name;
      fn = import (path + "/${name}");
    in
      final.callPackage (path + "/${name}") (
        lib.optionalAttrs
          (upstreamPkg != null && builtins.isFunction fn && (builtins.functionArgs fn) ? ${name})
          {${name} = upstreamPkg;}
      );

    localPkgs = lib.genAttrs localNames buildLocal;

    gatedPkgs = lib.mapAttrs (name: base: let
      upstreamPkg = getUpstream name;
    in
      if upstreamPkg != null then versionGate base upstreamPkg
      else base
    ) localPkgs;
  in
    gatedPkgs // {
      p = (prev.p or {}) // {
        localPackages = localPkgs;
      };
    };
}
