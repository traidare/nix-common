{lib, ...}: rec {
  # Converts a directory to an attrset mapping filenames (without .nix suffix) to their paths
  dirToAttrs = dir:
    lib.mapAttrs' (name: value: lib.nameValuePair (lib.removeSuffix ".nix" name) (dir + "/${name}")) (
      builtins.readDir dir
    );

  # Like dirToAttrs, but adds a 'default' entry that imports all other modules
  dirToAttrsWithDefault = dir: let
    modules = dirToAttrs dir;
    default = {
      imports = builtins.attrValues (
        # Exclude any existing 'default' to avoid circular imports
        removeAttrs modules ["default"]
      );
    };
  in
    modules // {inherit default;};

  # Creates a nullable option with a default of null
  mkNullOption = type: description:
    lib.mkOption {
      type = lib.types.nullOr type;
      default = null;
      inherit description;
    };

  # Converts a path to a name by stripping the leading '/' and replacing '/' with '-'
  mkNameFromPath = path:
    builtins.replaceStrings ["/"] ["-"] (lib.removePrefix "/" path);

  # Escape as required by: https://www.freedesktop.org/software/systemd/man/systemd.unit.html
  escapeUnitName = name:
    lib.concatMapStrings (s:
      if lib.isList s
      then "-"
      else s) (
      builtins.split "[^a-zA-Z0-9_.\\-]+" name
    );

  packaging = import ./packaging.nix {inherit lib;};
}
