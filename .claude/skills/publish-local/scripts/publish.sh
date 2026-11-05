#!/bin/bash
set -euo pipefail

skip_tests=0 skip_install=0 launch=1
for arg in "$@"; do
  case "$arg" in
    --skip-tests)   skip_tests=1 ;;
    --skip-install) skip_install=1 ;;
    --no-launch)    launch=0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

cd "$(git rev-parse --show-toplevel)"
# xcode-select points at the Command Line Tools on this machine, which can't run xcodebuild.
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

bundle_id=com.intervalapp.Interval
derived=.build/DerivedData
log=$derived/publish.log
built=$derived/Build/Products/Release/Interval.app
target=/Applications/Interval.app
staging=/Applications/.Interval.app.new
previous=/Applications/.Interval.app.old
mkdir -p "$derived"

run() {
  if ! "$@" >"$log" 2>&1; then
    grep -E 'error:|FAILED|failed on' "$log" | head -20 >&2 || true
    echo "failed, full log: $log" >&2
    exit 1
  fi
}

if [ "$skip_tests" = 0 ]; then
  echo "==> Unit tests"
  run xcodebuild -scheme Interval -destination 'platform=macOS' -derivedDataPath "$derived" \
    -only-testing:IntervalTests test
fi

echo "==> Release build"
run xcodebuild -scheme Interval -configuration Release -destination 'platform=macOS' \
  -derivedDataPath "$derived" build
codesign --verify --deep --strict "$built"

if [ "$skip_install" = 1 ]; then
  echo "Built $built (not installed)"
  exit 0
fi

echo "==> Install"
# Copy before quitting, so a failed copy leaves the current app installed and running.
rm -rf "$staging" "$previous"
ditto "$built" "$staging"

if pgrep -x Interval >/dev/null; then
  osascript -e "tell application id \"$bundle_id\" to quit"
  for _ in {1..20}; do
    pgrep -x Interval >/dev/null || break
    sleep 0.5
  done
  if pgrep -x Interval >/dev/null; then
    rm -rf "$staging"
    echo "Interval did not quit; installed app left unchanged" >&2
    exit 1
  fi
fi

[ -e "$target" ] && mv "$target" "$previous"
mv "$staging" "$target"
rm -rf "$previous"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$target"

if [ "$launch" = 1 ]; then
  open "$target"
fi

echo "Installed $target from $(git rev-parse --short HEAD)"
if [ -n "$(git status --porcelain)" ]; then
  echo "Note: uncommitted changes are included in this build"
fi
