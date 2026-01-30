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

  # Returns `newPkg` if it's newer than `upstreamPkg`, otherwise returns `upstreamPkg`
  versionGate = newPkg: upstreamPkg: let
    newVersion = lib.getVersion newPkg;
    upstreamVersion = lib.getVersion upstreamPkg;
  in
    if builtins.compareVersions newVersion upstreamVersion > 0
    then newPkg
    else lib.warn "Package ${lib.getName newPkg} reached version >=${newVersion} on upstream - upstream is now used" upstreamPkg;

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

  # Create an overlay for locally-defined packages with optional configuration
  # Options per package:
  #   - passUpstream: bool - pass the upstream package as an argument to callPackage
  #   - trackedPkg: prev -> pkg - function to get upstream version for version gating
  # Example:
  #   mkLocalPackagesOverlay ./pkgs {
  #     calibre.passUpstream = true;
  #     freetube = { passUpstream = true; trackedPkg = p: p.stable.freetube; };
  #   }
  mkLocalPackagesOverlay = path: packages: final: prev: let
    buildPkg = name: let
      cfg = packages.${name} or {};
      base = final.callPackage (path + "/${name}") (
        lib.optionalAttrs (cfg.passUpstream or false) {${name} = prev.${name};}
      );
    in
      if cfg ? trackedPkg
      then versionGate base (cfg.trackedPkg prev)
      else base;
  in
    lib.genAttrs (builtins.attrNames (builtins.readDir path)) buildPkg;
}
