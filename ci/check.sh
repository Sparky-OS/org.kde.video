#!/bin/bash
# Checks run by CI (.github/workflows/check.yml) and locally inside a Plasma 6
# container. Run from the repository root.
set -euo pipefail

export QT_QPA_PLATFORM=offscreen

step() { printf '\n== %s\n' "$*"; }

step "metadata.json"
jq -e '.KPlugin.Id == "org.kde.video" and .KPackageStructure == "Plasma/Wallpaper"' metadata.json

step "qmllint"
# qmllint can't see what Plasma injects at runtime (i18nd, parentLayout) or the
# type of a Loader's item, so those warnings are expected. Anything else fails.
failed=0
while IFS=$'\t' read -r file line message; do
    source_line=$(sed -n "${line}p" "$file")
    if [[ $message == "Unqualified access" && $source_line =~ i18nd\(|parentLayout ]] ||
       [[ $message == 'Member "read" not found on type "QObject"' ]]; then
        continue
    fi
    echo "$file:$line: $message"
    echo "    $source_line"
    failed=1
done < <(/usr/lib64/qt6/bin/qmllint --json - contents/ui/*.qml |
         jq -r '.files[] | .filename as $f | .warnings[] | [$f, .line, .message] | @tsv')
[[ $failed == 0 ]]

step "QML unit tests"
/usr/lib64/qt6/bin/qmltestrunner -input tests

step "kpackagetool6 install"
export XDG_DATA_HOME="$(mktemp -d)"
kpackagetool6 --type Plasma/Wallpaper --install .
kpackagetool6 --type Plasma/Wallpaper --list | grep -qx 'org.kde.video'
test -f "$XDG_DATA_HOME/plasma/wallpapers/org.kde.video/contents/ui/main.qml"

step "all checks passed"
