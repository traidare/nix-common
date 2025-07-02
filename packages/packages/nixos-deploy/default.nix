{
  age,
  inputs',
  writeShellApplication,
}:
writeShellApplication {
  name = "nixos-deploy";

  runtimeInputs = [
    age
    inputs'.nix-config-helper.packages.nix-config-helper
    inputs'.nixos-anywhere.packages.nixos-anywhere
  ];

  text = ''
    TARGET_USER="nixos"
    HOST=""
    TARGET_IP=""

    while [ $# -gt 0 ]; do
      case $1 in
        --host=*)
          HOST="''${1#*=}"
          shift
          ;;
        --host)
          HOST="$2"
          shift 2
          ;;
        --target-user=*)
          TARGET_USER="''${1#*=}"
          shift
          ;;
        --target-user)
          TARGET_USER="$2"
          shift 2
          ;;
        --target-ip=*)
          TARGET_IP="''${1#*=}"
          shift
          ;;
        --target-ip)
          TARGET_IP="$2"
          shift 2
          ;;
        *)
          echo "Unknown option: $1"
          echo "Usage: $0 --host=HOST [--target-user=TARGET_USER] --target-ip=TARGET_IP"
          exit 1
          ;;
      esac
    done

    if [ -z "$HOST" ]; then
      echo "Error: --host is required"
      exit 1
    fi
    if [ -z "$TARGET_IP" ]; then
      echo "Error: --target-ip is required"
      exit 1
    fi
    if [ -z "$TARGET_USER" ]; then
      echo "Error: --target-user is required"
      exit 1
    fi

    temp=$(mktemp -d)

    cleanup() {
      rm -rf "$temp"
    }
    trap cleanup EXIT

    install -d -m755 "$temp/var/lib/sops-nix"

    age-keygen -o "$temp/var/lib/sops-nix/key.txt"
    publicKey=$(age-keygen -y "$temp/var/lib/sops-nix/key.txt")

    nix-config-helper prepare-install --config=/home/user/Projects/nix/nixos/.sops.yaml --host=pav --public-key="$publicKey"

    chmod 600 "$temp/var/lib/sops-nix/key.txt"

    exec nixos-anywhere --flake .#"''${HOST}" --extra-files "$temp" --generate-hardware-config nixos-generate-config ./hosts/"''${HOST}"/hardware-configuration.nix --target-host "''${TARGET_USER}"@"''${TARGET_IP}"
  '';
}
