#!/bin/bash
#
# Test for `project.sh scan`, with docker (and so Trivy) stubbed out. It runs
# a copy of project.sh in a temporary directory, so sbom/ is written there,
# and checks that
#   - every image given gets an SBOM, sbom/<image>.cdx.json, from the pinned
#     Trivy image
#   - only the SBOMs that were written are checked for vulnerabilities
#   - SEVERITY and IGNORE_UNFIXED reach Trivy
#   - scan exits 1 and names the images with vulnerabilities and the ones
#     that could not be scanned, and exits 0 when all are clean
#
# Usage: tests/scan_test.sh

# shellcheck source=tests/lib.sh
. "$(dirname "$0")/lib.sh"

# The image with a vulnerability, and the one whose SBOM fails.
VULNERABLE=wine-debian
NO_SBOM=x11-alpine

# Stub docker: for `run ... <trivy> ... image ... --output /sbom/<image>...`
# record "sbom <image>" and fail for $NO_SBOM; for `run ... sbom ...
# /sbom/<image>.cdx.json` record "vuln <image> <options>" and fail for
# $VULNERABLE.
mkdir -p "$TMP/bin" "$TMP/work" "$TMP/cache"
cat > "$TMP/bin/docker" <<STUB
#!/bin/bash
[ "\$1" = run ] || exit 0
echo "\$*" >> "$TMP/calls"
for arg in "\$@"; do
    [[ "\$arg" =~ ^/sbom/(.+)\.cdx\.json$ ]] && image=\${BASH_REMATCH[1]}
done
if [[ " \$* " == *" image --format cyclonedx "* ]]; then
    echo "sbom \$image" >> "$TMP/scans"
    [ "\$image" != "$NO_SBOM" ]
elif [[ " \$* " == *" sbom --scanners vuln "* ]]; then
    options=\$(grep -oE -- '--severity [A-Z,]+|--ignore-unfixed' <<< "\$*" | paste -sd' ')
    echo "vuln \$image \$options" >> "$TMP/scans"
    [ "\$image" != "$VULNERABLE" ]
fi
STUB
chmod +x "$TMP/bin/docker"
cp "$ROOT/project.sh" "$TMP/work/"

# scan <env...> -- <images...>: run scan with a fresh record, set $status
scan() {
    local env=()
    while [ "$1" != -- ]; do env+=("$1"); shift; done
    shift
    : > "$TMP/scans"
    : > "$TMP/calls"
    status=0
    env PATH="$TMP/bin:$PATH" XDG_CACHE_HOME="$TMP/cache" "${env[@]}" \
        "$TMP/work/project.sh" scan "$@" > "$TMP/output" 2>&1 || status=$?
}

scan -- blender-alpine "$VULNERABLE" "$NO_SBOM"
cat > "$TMP/expected" <<EOF
sbom blender-alpine
vuln blender-alpine --severity HIGH,CRITICAL
sbom $VULNERABLE
vuln $VULNERABLE --severity HIGH,CRITICAL
sbom $NO_SBOM
EOF
if diff -u "$TMP/expected" "$TMP/scans"; then
    pass "writes an SBOM of every image and checks only the SBOMs written"
else
    fail "scans differ from expected (see diff above)"
fi
trivy=$(grep -oE 'aquasec/trivy:[^ ]+' "$TMP/work/project.sh" | head -n1)
only_pinned_trivy() {
    [ -n "$trivy" ] && ! grep -vqF " $trivy " "$TMP/calls"
}
check "runs the pinned Trivy image, $trivy" only_pinned_trivy
check "writes the SBOMs to sbom/ next to project.sh" [ -d "$TMP/work/sbom" ]
reports_both() {
    [ "$status" -eq 1 ] &&
        grep -q "vulnerabilities in: $VULNERABLE$" "$TMP/output" &&
        grep -q "not scanned: $NO_SBOM$" "$TMP/output"
}
check "exits 1 and names $VULNERABLE and $NO_SBOM" reports_both

scan SEVERITY=CRITICAL IGNORE_UNFIXED=1 -- blender-alpine
check "passes SEVERITY and IGNORE_UNFIXED to Trivy" \
    grep -qx "vuln blender-alpine --severity CRITICAL --ignore-unfixed" "$TMP/scans"
check "exits 0 when every image is clean" [ "$status" -eq 0 ]

finish
