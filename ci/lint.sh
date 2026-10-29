#!/bin/bash
# Keep Plasma's runtime-only warnings, but fail on tool failures and errors.
set -euo pipefail

linter=${1:?qmllint executable}
shift
lint_status=0
lint_json=$("$linter" --json - "$@") || lint_status=$?
# qmllint returns 255 for failed linting, including a warning-count limit.
# Other statuses (including signals) are producer failures.
case $lint_status in 0|255) ;; *) exit "$lint_status" ;; esac
jq -e -s --argjson count "$#" '
    length == 1 and (.[0] | (.files | type) == "array" and (.files | length) == $count and $count > 0
    and all(.files[]; (.filename | type) == "string" and (.warnings | type) == "array"))
' <<< "$lint_json" >/dev/null
diagnostics=$(jq -r '.files[] | .filename as $f | .warnings[] |
    [$f, .line, .type, .message] | @tsv' <<< "$lint_json")

failed=0
seen=0
while IFS=$'\t' read -r file line severity message; do
    [[ -z $file ]] && continue
    seen=1
    source_line=$(sed -n "${line}p" "$file")
    # Plasma supplies these names, and Loader.item is only typed as QObject.
    if [[ $severity == warning ]] && {
        [[ $message == "Unqualified access" && $source_line =~ i18nd\(|parentLayout ]] ||
        [[ $message == 'Member "read" not found on type "QObject"' ]];
    }; then
        continue
    fi
    echo "$file:$line: $message"
    echo "    $source_line"
    failed=1
done <<< "$diagnostics"
[[ $failed == 0 ]]
# A nonzero tool status needs an explanation in the validated diagnostics.
if [[ $lint_status != 0 && $seen == 0 ]]; then
    exit "$lint_status"
fi
