#!/bin/bash
# Exercise the real lint gate with controlled producer output and exit status.
set -euo pipefail
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
printf 'i18nd("test", "label")\nparentLayout\nunexpectedName\n' > "$work/source.qml"
cat > "$work/qmllint" <<'EOF'
#!/bin/sh
cat "$LINT_FIXTURE"
exit "$LINT_STATUS"
EOF
chmod +x "$work/qmllint"
export LINT_FIXTURE="$work/result.json" LINT_STATUS=0

diagnostic() {
    jq -n --arg file "$work/source.qml" --arg severity "$1" --arg message "$2" --argjson line "${3:-1}" '
        {files: [{filename: $file, success: false,
                  warnings: [{line: $line, type: $severity, message: $message}]}]}
    ' > "$LINT_FIXTURE"
}
check() {
    local expected=$1 status=0
    bash ci/lint.sh "$work/qmllint" "$work/source.qml" > "$work/output" 2>&1 || status=$?
    if [[ $status != "$expected" ]]; then
        cat "$work/output"
        echo "lint regression: expected exit $expected, got $status" >&2
        exit 1
    fi
}

diagnostic warning 'Unqualified access'
check 0
LINT_STATUS=255 check 0
diagnostic warning 'Unqualified access' 2
check 0
diagnostic warning 'Unqualified access' 3
check 1
diagnostic warning 'Member "read" not found on type "QObject"'
LINT_STATUS=255 check 0
LINT_STATUS=42 check 42
diagnostic warning 'no matching signal found for handler "onMediaStatuChanged"'
check 1
# Even an otherwise allowed message must not hide a real error.
diagnostic critical 'Unqualified access'
check 1
printf '{"files": [{"filename": "source.qml", "warnings": []}]}' > "$LINT_FIXTURE"
LINT_STATUS=255 check 255
printf '{"files": []}\n' > "$LINT_FIXTURE"
check 1
: > "$LINT_FIXTURE"
LINT_STATUS=42 check 42
check 1
printf 'not-json\n' > "$LINT_FIXTURE"
check 5
echo "lint producer controls passed"
