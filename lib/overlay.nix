{inputs, ...}: final: prev: {
  p =
    prev.p or {}
    // (import ./default.nix {lib = final;});
}
