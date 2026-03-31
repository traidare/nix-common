{nnn}:
nnn.overrideAttrs (old: {
  patches = [
    ./files/nnn-keybindings.patch
  ];
})
