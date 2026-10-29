#!/bin/bash
# Checks run by CI (.github/workflows/check.yml) and locally inside a Plasma 6
# container. Run from the repository root.
set -euo pipefail

export QT_QPA_PLATFORM=offscreen

step() { printf '\n== %s\n' "$*"; }

step "metadata.json"
jq -e '.KPlugin.Id == "org.kde.video" and .KPackageStructure == "Plasma/Wallpaper"' metadata.json

step "qmllint"
bash tests/check-lint.sh
bash ci/lint.sh /usr/lib64/qt6/bin/qmllint contents/ui/*.qml

step "QML unit tests"
/usr/lib64/qt6/bin/qmltestrunner -input tests

step "kpackagetool6 install"
export XDG_DATA_HOME="$(mktemp -d)"
kpackagetool6 --type Plasma/Wallpaper --install .
kpackagetool6 --type Plasma/Wallpaper --list | grep -qx 'org.kde.video'
test -f "$XDG_DATA_HOME/plasma/wallpapers/org.kde.video/contents/ui/main.qml"

step "all checks passed"
