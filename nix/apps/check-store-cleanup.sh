#!/usr/bin/env bash
# Synthetic SSH and node tools only. Never reboot a host or GC the real store.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
system=$(nix eval --impure --raw --expr builtins.currentSystem)
nix run --offline --no-write-lock-file .#store-cleanup -- --help >/dev/null
app=$(nix eval --offline --no-write-lock-file --raw ".#apps.$system.store-cleanup.program")
nix eval --offline --no-write-lock-file --impure --expr '
  let f = builtins.getFlake (toString ./.);
      matches = node: let gc = node.config.nix.gc; in
        gc.automatic && gc.dates == ["weekly"] && gc.options == "--delete-older-than 30d";
  in assert matches f.nixosConfigurations.engineer;
     assert matches f.nixosConfigurations.pangolin;
     "Both nodes retain weekly 30-day automatic GC"
'
REAL_DU=$(command -v du)
REAL_CAT=$(command -v cat)
REAL_NIX_ENV=$(command -v nix-env)
export REAL_DU REAL_CAT REAL_NIX_ENV
umask 077
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
export FIXTURE="$scratch"
mkdir -p "$scratch/bin" "$scratch/system-a/bin" "$scratch/system-b"
touch "$scratch/ssh-config"
export SSH_CONFIG_FILE="$scratch/ssh-config"
cat > "$scratch/system-a/bin/switch-to-configuration" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
[[ $1 == boot ]]
echo boot >> "$FIXTURE/actions"
[[ ${FAIL_BOOT_MENU:-0} == 0 ]]
SH
cat > "$scratch/bin/fake-tool" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "${0##*/}" in
  ssh)
    while [[ $1 == -* ]]; do
      case "$1" in -F|-o) shift 2 ;; -t) shift ;; *) exit 90 ;; esac
    done
    [[ $# == 2 && $1 == *-local || $# == 2 && $1 == *-remote ]]
    echo "$1" >> "$FIXTURE/connections"
    if [[ -f $FIXTURE/rebooted && ${NO_RETURN:-0} == 1 ]]; then exit 255; fi
    exec bash -c "$2"
    ;;
  sudo)
    [[ $1 == -- ]]; shift
    echo sudo >> "$FIXTURE/auth"
    export NONROOT=0
    exec "$@"
    ;;
  uname) printf '%s\n' "${FAKE_HOST:-engineer}" ;;
  id) if [[ ${NONROOT:-0} == 1 ]]; then echo 1000; else echo 0; fi ;;
  cat)
    if [[ ${1:-} == /proc/sys/kernel/random/boot_id ]]; then
      if [[ -f $FIXTURE/rebooted && ${SAME_BOOT:-0} == 0 ]]; then echo boot-new; else echo boot-old; fi
    else exec "$REAL_CAT" "$@"; fi
    ;;
  readlink)
    case "$2" in
      /run/current-system) echo "$FIXTURE/system-a" ;;
      /run/booted-system)
        if [[ ${WRONG_BOOT:-0} == 1 || ${UNBOOTED:-0} == 1 && ! -f $FIXTURE/rebooted ]]; then
          echo "$FIXTURE/system-b"
        else echo "$FIXTURE/system-a"; fi
        ;;
      /nix/var/nix/profiles/system)
        if [[ ${SELECTED_DIFF:-0} == 1 || ${PROFILE_CHANGED:-0} == 1 && -f $FIXTURE/pruned ]]; then
          echo "$FIXTURE/system-b"
        else echo "$FIXTURE/system-a"; fi
        ;;
      *) exit 91 ;;
    esac
    ;;
  du) [[ $* == '-sx -B1 -- /nix/store' ]]; exec "$REAL_DU" -sx -B1 "$FIXTURE/store" ;;
  df)
    bytes=$("$REAL_DU" -sx -B1 "$FIXTURE/store" | cut -f1)
    printf 'Size Used Avail\n1073741824 %s %s\n' "$((500000000 + bytes))" "$((500000000 - bytes))"
    ;;
  stat)
    if [[ ${SPLIT_STORE:-0} == 1 && ${!#} == /nix/store ]]; then echo 2; else echo 1; fi
    ;;
  nix-env)
    [[ $1 == -p && $2 == /nix/var/nix/profiles/system ]]
    case "$3" in
      --list-generations)
        printf '1 2026-01-01 00:00:00\n2 2026-01-02 00:00:00\n3 2026-01-03 00:00:00\n4 2026-01-04 00:00:00\n5 2026-01-05 00:00:00 (current)\n'
        if [[ ${ROLLED_BACK:-0} == 1 ]]; then echo '6 2026-01-06 00:00:00'; fi
        ;;
      --delete-generations)
        if [[ $4 == --dry-run ]]; then [[ $5 == +2 ]]; echo 'Would prune: 1 2 3';
        else
          [[ $4 == +2 && ${FAIL_PRUNE:-0} == 0 ]]
          echo prune >> "$FIXTURE/actions"
          touch "$FIXTURE/pruned"
        fi
        ;;
      *) exit 92 ;;
    esac
    ;;
  nix-store)
    case "$1" in
      --gc)
        [[ ${FAIL_GC:-0} == 0 ]]
        echo gc >> "$FIXTURE/actions"
        rm "$FIXTURE/store/garbage"
        ;;
      --optimise)
        echo optimise >> "$FIXTURE/actions"
        ln -f "$FIXTURE/store/one" "$FIXTURE/store/two"
        ;;
      *) exit 93 ;;
    esac
    ;;
  systemctl)
    case "$1" in
      is-system-running) [[ ${UNHEALTHY:-0} == 0 ]] ;;
      is-active) [[ ${UNHEALTHY:-0} == 0 && ! ( ${INACTIVE_GERBIL:-0} == 1 && ${3:-} == gerbil ) ]] ;;
      reboot)
        [[ ${FAIL_REBOOT:-0} == 0 ]]
        echo reboot >> "$FIXTURE/actions"
        touch "$FIXTURE/rebooted"
        exit "${REBOOT_DISCONNECT:-0}"
        ;;
      *) exit 94 ;;
    esac
    ;;
  sleep) : ;;
  *) exit 95 ;;
esac
SH
chmod +x "$scratch/bin/fake-tool" "$scratch/system-a/bin/switch-to-configuration"
for tool in ssh sudo uname id cat readlink du df stat nix-env nix-store systemctl sleep; do
  ln -s fake-tool "$scratch/bin/$tool"
done
unset -f ssh 2>/dev/null || true
export PATH="$scratch/bin:$PATH"

reset_fixture() {
  rm -rf "$scratch/store"
  rm -f "$scratch/rebooted" "$scratch/pruned"
  : > "$scratch/actions"
  : > "$scratch/connections"
  : > "$scratch/auth"
  mkdir -p "$scratch/store/.links"
  dd if=/dev/zero of="$scratch/store/one" bs=1024 count=64 status=none
  cp "$scratch/store/one" "$scratch/store/two"
  cp "$scratch/store/one" "$scratch/store/garbage"
  ln "$scratch/store/one" "$scratch/store/.links/existing-hardlink"
}
expect_failure() {
  if "$@" > "$scratch/output" 2>&1; then echo "Unexpected success: $*" >&2; exit 1; fi
  [[ ! -s $scratch/actions ]]
}
reset_fixture
"$app" > /dev/null
[[ ! -s $scratch/connections ]]
for args in 'engineer-local' 'pangolin-local --report' 'engineer-local --report --clean' \
  'engineer-local --report --reboot' 'engineer-remote --clean --reboot' 'engineer-local --wat'; do
  read -ra arguments <<< "$args"
  expect_failure "$app" "${arguments[@]}"
done
[[ ! -s $scratch/connections ]]
expect_failure env SSH_CONFIG_FILE= "$app" engineer-local --report
expect_failure env FAKE_HOST=wrong "$app" engineer-local --report
expected=$("$REAL_DU" -sx -B1 "$scratch/store" | cut -f1)
"$app" engineer-local --report > "$scratch/output"
grep -q "($expected bytes)" "$scratch/output"
grep -q 'Reboot required: no' "$scratch/output"
[[ ! -s $scratch/actions && ! -s $scratch/auth ]]
SPLIT_STORE=1 "$app" --report engineer-remote > "$scratch/output"
grep -q 'Store filesystem:' "$scratch/output"
FAKE_HOST=pangolin "$app" pangolin-remote --report > /dev/null
expect_failure env FAKE_HOST=pangolin INACTIVE_GERBIL=1 "$app" pangolin-remote --clean <<< pangolin-remote
for scenario in UNBOOTED UNHEALTHY SELECTED_DIFF ROLLED_BACK; do
  expect_failure env "$scenario=1" "$app" engineer-local --clean <<< engineer-local
done
expect_failure "$app" engineer-local --clean <<< no
expect_failure "$app" engineer-local --clean < /dev/null
expect_failure env FAIL_REBOOT=1 "$app" engineer-local --clean --reboot <<< engineer-local
expect_failure env FAIL_PRUNE=1 "$app" engineer-local --clean <<< engineer-local

"$app" engineer-local --clean > "$scratch/output" <<< engineer-local
[[ $(< "$scratch/actions") == $'prune\nboot\ngc\noptimise' ]]
grep -q 'GC store reduction: 64KiB' "$scratch/output"
grep -q 'Optimisation store reduction: 64KiB' "$scratch/output"
grep -q 'Total store reduction: 128KiB' "$scratch/output"
[[ -f $scratch/store/one && -f $scratch/store/two && ! -e $scratch/store/garbage ]]
reset_fixture
UNBOOTED=1 REBOOT_DISCONNECT=255 "$app" engineer-local --clean --reboot > "$scratch/output" <<< engineer-local
[[ $(< "$scratch/actions") == $'reboot\nprune\nboot\ngc\noptimise' ]]
for scenario in SAME_BOOT NO_RETURN WRONG_BOOT UNHEALTHY; do
  reset_fixture
  if env "$scenario=1" "$app" engineer-local --clean --reboot > "$scratch/output" 2>&1 <<< engineer-local; then exit 1; fi
  [[ $(< "$scratch/actions") == reboot ]]
done
for scenario in FAIL_BOOT_MENU PROFILE_CHANGED FAIL_GC; do
  reset_fixture
  if env "$scenario=1" "$app" engineer-local --clean > "$scratch/output" 2>&1 <<< engineer-local; then exit 1; fi
  [[ $(< "$scratch/actions") == $'prune\nboot' ]]
done
reset_fixture
NONROOT=1 "$app" engineer-local --clean > "$scratch/output" <<< engineer-local
[[ $(< "$scratch/auth") == $'sudo\nsudo' ]]

# Exercise native retention on disposable profile symlinks, never the real profile/store.
mkdir "$scratch/profile"
for generation in 1 2 3 4 5; do
  ln -s "$app" "$scratch/profile/system-$generation-link"
done
ln -s system-5-link "$scratch/profile/system"
"$REAL_NIX_ENV" -p "$scratch/profile/system" --delete-generations --dry-run +2 >/dev/null
[[ -L $scratch/profile/system-1-link ]]
"$REAL_NIX_ENV" -p "$scratch/profile/system" --delete-generations +2 >/dev/null
[[ -L $scratch/profile/system-4-link && -L $scratch/profile/system-5-link ]]
[[ ! -L $scratch/profile/system-1-link && ! -L $scratch/profile/system-2-link && ! -L $scratch/profile/system-3-link ]]
printf '%s\n' 'PASS: read-only reporting, confirmation, retention, reboot/health failures, root/sudo, hardlinks and measured cleanup.'
