# Tests for the recursiveDirToModules library function.
#
# Run with:
#   nix eval --file tests/recursive-dir-test.nix
#
# A successful run prints the number of passed tests.
# Any failure throws an error with the failing test name.
let
  # Minimal lib implementation using only builtins.
  # Only the functions actually called by recursiveDirToModules are needed;
  # all other lib attributes are lazily unevaluated.
  lib = {
    removeSuffix = suffix: str:
      let
        sl = builtins.stringLength suffix;
        sl' = builtins.stringLength str;
      in
        if sl > sl'
        then str
        else if builtins.substring (sl' - sl) sl str == suffix
        then builtins.substring 0 (sl' - sl) str
        else str;

    hasSuffix = suffix: str:
      let
        sl = builtins.stringLength suffix;
        sl' = builtins.stringLength str;
      in
        sl <= sl' && builtins.substring (sl' - sl) sl str == suffix;

    filter = builtins.filter;

    mapAttrsToList = f: attrs:
      map (name: f name attrs.${name}) (builtins.attrNames attrs);

    listToAttrs = builtins.listToAttrs;
  };

  # Import only what we need; other lib attrs are lazily unevaluated so the
  # minimal lib above is sufficient.
  inherit (import ../lib { inherit lib; }) recursiveDirToModules;

  # ---------------------------------------------------------------------------
  # Test helper
  # ---------------------------------------------------------------------------

  # Runs a named boolean test. Returns the name on success; throws on failure.
  mkTest = name: cond:
    if cond
    then name
    else builtins.throw "FAILED: ${name}";

  # ---------------------------------------------------------------------------
  # Evaluate the function on each fixture directory
  # ---------------------------------------------------------------------------

  # fixtures/simple/  ->  module_a.nix  module_b.nix
  simple = recursiveDirToModules ./fixtures/simple;

  # fixtures/nested/  ->  group/{child_0.nix, child_1.nix}  standalone.nix
  nested = recursiveDirToModules ./fixtures/nested;

  # fixtures/mixed/   ->  sub/deep.nix  top.nix  ignored.txt
  mixed = recursiveDirToModules ./fixtures/mixed;

  # ---------------------------------------------------------------------------
  # Test cases
  # ---------------------------------------------------------------------------
  tests = [

    # ------------------------------------------------------------------
    # simple/: flat directory with two .nix files
    # ------------------------------------------------------------------

    (mkTest "simple: has module_a attribute"
      (builtins.hasAttr "module_a" simple))

    (mkTest "simple: has module_b attribute"
      (builtins.hasAttr "module_b" simple))

    (mkTest "simple: module_a value is the correct path"
      (simple.module_a == ./fixtures/simple/module_a.nix))

    (mkTest "simple: module_b value is the correct path"
      (simple.module_b == ./fixtures/simple/module_b.nix))

    (mkTest "simple: has a default attribute"
      (builtins.hasAttr "default" simple))

    (mkTest "simple: default is an attrset with imports"
      (builtins.isAttrs simple.default && builtins.hasAttr "imports" simple.default))

    (mkTest "simple: default.imports contains module_a path"
      (builtins.elem simple.module_a simple.default.imports))

    (mkTest "simple: default.imports contains module_b path"
      (builtins.elem simple.module_b simple.default.imports))

    (mkTest "simple: default.imports has exactly 2 entries"
      (builtins.length simple.default.imports == 2))

    # ------------------------------------------------------------------
    # nested/: subdirectory (group/) and a standalone module
    # ------------------------------------------------------------------

    (mkTest "nested: has group attribute"
      (builtins.hasAttr "group" nested))

    (mkTest "nested: has standalone attribute"
      (builtins.hasAttr "standalone" nested))

    (mkTest "nested: standalone value is the correct path"
      (nested.standalone == ./fixtures/nested/standalone.nix))

    # The group attrset must carry __functor so the NixOS module system
    # can treat it as a function module.
    (mkTest "nested: group has __functor (is a functor attrset)"
      (builtins.hasAttr "__functor" nested.group))

    (mkTest "nested: group exposes child_0 attribute"
      (builtins.hasAttr "child_0" nested.group))

    (mkTest "nested: group exposes child_1 attribute"
      (builtins.hasAttr "child_1" nested.group))

    (mkTest "nested: group.child_0 is the correct path"
      (nested.group.child_0 == ./fixtures/nested/group/child_0.nix))

    (mkTest "nested: group.child_1 is the correct path"
      (nested.group.child_1 == ./fixtures/nested/group/child_1.nix))

    # group should NOT re-expose the synthesized 'default' of its subtree
    (mkTest "nested: group does not expose default"
      (!(builtins.hasAttr "default" nested.group)))

    # Calling group as a NixOS module (functor call) must return {imports = [...]}
    (mkTest "nested: group functor returns an attrset with imports"
      (let called = nested.group {}; in builtins.isAttrs called && builtins.hasAttr "imports" called))

    (mkTest "nested: group functor imports child_0"
      (builtins.elem nested.group.child_0 (nested.group {}).imports))

    (mkTest "nested: group functor imports child_1"
      (builtins.elem nested.group.child_1 (nested.group {}).imports))

    (mkTest "nested: group functor imports exactly 2 children"
      (builtins.length (nested.group {}).imports == 2))

    (mkTest "nested: default.imports has exactly 2 entries (group + standalone)"
      (builtins.length nested.default.imports == 2))

    # default.imports must include the group functor attrset
    (mkTest "nested: default.imports contains the group functor"
      (builtins.any (x: builtins.isAttrs x && builtins.hasAttr "__functor" x) nested.default.imports))

    # default.imports must include the standalone path
    (mkTest "nested: default.imports contains the standalone path"
      (builtins.any (x: x == nested.standalone) nested.default.imports))

    # ------------------------------------------------------------------
    # mixed/: non-.nix files must be silently ignored
    # ------------------------------------------------------------------

    (mkTest "mixed: has sub attribute (directory)"
      (builtins.hasAttr "sub" mixed))

    (mkTest "mixed: has top attribute (.nix file)"
      (builtins.hasAttr "top" mixed))

    (mkTest "mixed: ignored.txt is not exposed"
      (!(builtins.hasAttr "ignored" mixed)))

    (mkTest "mixed: top value is the correct path"
      (mixed.top == ./fixtures/mixed/top.nix))

    (mkTest "mixed: sub exposes deep attribute"
      (builtins.hasAttr "deep" mixed.sub))

    (mkTest "mixed: sub.deep is the correct path"
      (mixed.sub.deep == ./fixtures/mixed/sub/deep.nix))

    (mkTest "mixed: sub has __functor"
      (builtins.hasAttr "__functor" mixed.sub))

  ];

in
  "${builtins.toString (builtins.length tests)} tests passed"
