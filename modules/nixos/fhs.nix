{pkgs, ...}: {
  programs.nix-ld = {
    libraries = with pkgs; [
      curl
      expat
      fuse
      fuse3
      glib
      icu
      libsecret
      libunwind
      libuuid
      nss
      openssl
      stdenv.cc.cc
      util-linux
      zlib
    ];
  };
}
