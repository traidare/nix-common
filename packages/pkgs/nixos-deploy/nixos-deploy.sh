#!/usr/bin/env bash

TARGET_USER="nixos"
HOST=""
TARGET_IP=""
SOPS_CONFIG="${SOPS_CONFIG:-}"
EXTRA_ARGS=()

while [ $# -gt 0 ]; do
  case $1 in
    --host=*)
      HOST="${1#*=}"
      ;;
    --target-user=*)
      TARGET_USER="${1#*=}"
      ;;
    --target-ip=*)
      TARGET_IP="${1#*=}"
      ;;
    --sops-config=*)
      SOPS_CONFIG="${1#*=}"
      ;;
    --)
      shift
      EXTRA_ARGS=("$@")
      break
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 --host=HOST [--target-user=TARGET_USER] --target-ip=TARGET_IP --sops-config=SOPS_CONFIG [-- EXTRA_NIXOS_ANYWHERE_ARGS...]"
      exit 1
      ;;
  esac
  shift
done

if [ "$HOST" = "" ]; then
  echo "Error: --host is required"
  exit 1
fi
if [ "$TARGET_IP" = "" ]; then
  echo "Error: --target-ip is required"
  exit 1
fi
if [ "$TARGET_USER" = "" ]; then
  echo "Error: --target-user is required"
  exit 1
fi
if [ "$SOPS_CONFIG" = "" ]; then
  echo "Error: --sops-config is required (or SOPS_CONFIG environment variable)"
  exit 1
fi

if [ ! -f "./flake.nix" ]; then
  echo "Error: flake.nix not found. Are you running this from your NixOS config directory?"
  exit 1
fi

HOST_PATH="./hosts/${HOST}"
if [ ! -d "$HOST_PATH" ]; then
  echo "Error: Host directory does not exist: $HOST_PATH"
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

nix-config-helper prepare-install --config="$SOPS_CONFIG" --host="$HOST" --public-key="$publicKey"

chmod 600 "$temp/var/lib/sops-nix/key.txt"

exec nixos-anywhere --flake .#"${HOST}" \
  --generate-hardware-config nixos-generate-config ./hosts/"$HOST"/hardware-configuration.nix \
  --target-host "$TARGET_USER"@"$TARGET_IP" \
  --extra-files "$temp" "${EXTRA_ARGS[@]}"
