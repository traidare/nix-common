{
  crudini,
  lib,
  writeShellScript,
  writeText,
}: {
  mkIniMergeScript = {
    targetFile,
    iniConfig,
  }: let
    name = lib.p.mkNameFromPath targetFile;
  in
    writeShellScript "merge-ini-${name}.sh" ''
      set -e
      mkdir -p "$(dirname ${targetFile})"
      [ ! -f ${targetFile} ] && touch ${targetFile}
      ${crudini}/bin/crudini --merge ${targetFile} < ${writeText "${name}-merge.ini" (lib.generators.toINI {} iniConfig)}
    '';
}
