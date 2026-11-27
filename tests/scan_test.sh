#!/bin/bash
#
# Test for `project.sh scan`, with docker (and so Trivy) stubbed out. It runs
# project.sh on a temporary directory, with DOCKERFILES_DIR, so sbom/ is written there,
# and checks that
#   - every image given gets an SBOM, sbom/<image>.cdx.json, from the pinned
#     Trivy image
#   - only the SBOMs that were written are checked for vulnerabilities
#   - SEVERITY and IGNORE_UNFIXED reach Trivy
#   - without image names, every image of the directory is scanned
#   - FAIL_ON lists at SEVERITY but fails only at FAIL_ON, from the same
#     SBOM, as CI uses it: an image with only a HIGH vulnerability passes
#   - scan exits 1 and names the images with vulnerabilities and the ones
#     that could not be scanned, and exits 0 when all are clean
# and that `project.sh lint` runs Trivy's config check on the repository,
# read-only, at HIGH and CRITICAL unless SEVERITY says otherwise, and
# exits with its status.
#
# Usage: tests/scan_test.sh

# shellcheck source=tests/lib.sh
. "$(dirname "$0")/lib.sh"

# The image with a CRITICAL vulnerability, the one with only a HIGH one, and
# the one whose SBOM fails.
VULNERABLE=wine-debian
HIGH_ONLY=node-debian
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
    [ "\$image" != "$VULNERABLE" ] || exit 1
    [ "\$image" != "$HIGH_ONLY" ] || [[ "\$options" != *HIGH* ]]
fi
STUB
chmod +x "$TMP/bin/docker"

# scan <env...> -- <images...>: run scan with a fresh record, set $status
scan() {
    local env=()
    while [ "$1" != -- ]; do env+=("$1"); shift; done
    shift
    : > "$TMP/scans"
    : > "$TMP/calls"
    status=0
    env PATH="$TMP/bin:$PATH" XDG_CACHE_HOME="$TMP/cache" "${env[@]}" \
        DOCKERFILES_DIR="$TMP/work" "$ROOT/project.sh" scan "$@" > "$TMP/output" 2>&1 || status=$?
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
trivy=$(grep -oE 'aquasec/trivy:[^ ]+' "$ROOT/project.sh" | head -n1)
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

scan FAIL_ON=CRITICAL IGNORE_UNFIXED=1 -- "$HIGH_ONLY"
cat > "$TMP/expected" <<EOF
sbom $HIGH_ONLY
vuln $HIGH_ONLY --severity HIGH,CRITICAL --ignore-unfixed
vuln $HIGH_ONLY --severity CRITICAL --ignore-unfixed
EOF
if diff -u "$TMP/expected" "$TMP/scans"; then
    pass "FAIL_ON lists at SEVERITY, then checks the same SBOM at FAIL_ON"
else
    fail "FAIL_ON scans differ from expected (see diff above)"
fi
check "FAIL_ON=CRITICAL passes an image with only a HIGH vulnerability" \
    [ "$status" -eq 0 ]

scan FAIL_ON=CRITICAL -- "$VULNERABLE"
fails_critical() {
    [ "$status" -eq 1 ] &&
        grep -q "CRITICAL vulnerabilities in: $VULNERABLE$" "$TMP/output"
}
check "FAIL_ON=CRITICAL fails and names an image with a CRITICAL one" \
    fails_critical

# without images, scan scans every image of the directory
mkdir -p "$TMP/work/one/alpine" "$TMP/work/two/debian"
echo "FROM scratch" | tee "$TMP/work/one/alpine/Dockerfile" > "$TMP/work/two/debian/Dockerfile"
scan --
scans_all() {
    [ "$(grep '^sbom ' "$TMP/scans" | sort | paste -sd' ')" = "sbom one-alpine sbom two-debian" ]
}
check "without images, scans every image of the directory" scans_all

# lint: record the config call; fail when $LINT_FAILS is set
cat > "$TMP/bin/docker" <<STUB
#!/bin/bash
echo "\$*" >> "$TMP/calls"
[ -z "\${LINT_FAILS:-}" ]
STUB

# lint <env...>: run lint with a fresh record, set $status
lint() {
    : > "$TMP/calls"
    status=0
    env PATH="$TMP/bin:$PATH" XDG_CACHE_HOME="$TMP/cache" "$@" \
        DOCKERFILES_DIR="$TMP/work" "$ROOT/project.sh" lint > "$TMP/output" 2>&1 || status=$?
}

lint
config_once() {
    [ "$(grep -cx ".* $trivy --cache-dir /cache --quiet config .* /src" "$TMP/calls")" -eq 1 ]
}
check "lint runs the pinned Trivy's config check once" config_once
check "lint mounts the repository read-only" \
    grep -qF -- "-v $TMP/work:/src:ro" "$TMP/calls"
check "lint reports HIGH and CRITICAL by default and fails on them" \
    grep -qF -- "--severity HIGH,CRITICAL --exit-code 1" "$TMP/calls"
check "lint exits 0 when Trivy finds nothing" [ "$status" -eq 0 ]

lint SEVERITY=LOW,MEDIUM,HIGH,CRITICAL LINT_FAILS=1
check "lint passes SEVERITY to Trivy" \
    grep -qF -- "--severity LOW,MEDIUM,HIGH,CRITICAL" "$TMP/calls"
check "lint exits 1 when Trivy finds a misconfiguration" [ "$status" -eq 1 ]

finish
