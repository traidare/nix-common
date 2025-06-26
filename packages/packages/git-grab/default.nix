{
  lib,
  fetchFromGitHub,
  rustPlatform,
  git,
}:
rustPlatform.buildRustPackage rec {
  pname = "git-grab";
  version = "3.0.0";

  src = fetchFromGitHub {
    owner = "wezm";
    repo = "git-grab";
    rev = "${version}";
    hash = "sha256-MsJDfmWU6LyK7M0LjYQufIpKmtS4f2hgo4Yi/x1HsrU=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-nJBgKrgfmLzHVZzVUah2vS+fjNzJp5fNMzzsFu6roug=";

  buildInputs = [git];

  dontUseCmakeConfigure = true;

  meta = with lib; {
    description = "A tool to clone git repositories to a standard location organised by domain and path";
    homepage = "https://github.com/wezm/git-grab";
    license = with licenses; [mit asl20];
    mainProgram = "git-grab";
    platforms = platforms.unix;
  };
}
