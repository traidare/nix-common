{
  pkgs,
  wlib,
  ...
}: {
  imports = [wlib.wrapperModules.btop];
  package = pkgs.btop;

  settings = {
    vim_keys = true;
  };

  addFlag = [
    ["--preset" "1"]
  ];
}
