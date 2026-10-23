#!/bin/sh
#
# Freetz-NG Package Manager — M1 host-side test runner
#
# Runs all test scripts under tests/pkgmanager/ and reports totals.
# Does not require a physical router or USB storage.
#

TESTDIR="$(cd "$(dirname "$0")" && pwd)"

TOTAL_PASS=0
TOTAL_FAIL=0
OVERALL=0

run_suite() {
	local script="$1"
	echo ""
	echo "Running: $script"
	echo "-----------------------------------------------------------"

	output=$(sh "$script" 2>&1) || true
	echo "$output"

	pass=$(echo "$output" | grep -c '  PASS:') || pass=0
	fail=$(echo "$output" | grep -c '  FAIL:') || fail=0

	TOTAL_PASS=$((TOTAL_PASS + pass))
	TOTAL_FAIL=$((TOTAL_FAIL + fail))
	if [ "$fail" -gt 0 ]; then
		OVERALL=1
	fi
}

for suite in \
	"$TESTDIR/test_storage.sh" \
	"$TESTDIR/test_install.sh" \
	"$TESTDIR/test_integrity.sh" \
	"$TESTDIR/test_path.sh" \
	"$TESTDIR/test_build.sh" \
	"$TESTDIR/test_edge_cases.sh" \
	"$TESTDIR/test_rc.sh"; do
	run_suite "$suite"
done

echo ""
echo "==========================================================="
echo "Total: $TOTAL_PASS passed, $TOTAL_FAIL failed"
echo "==========================================================="

echo ""
echo "Host-side coverage notes:"
echo "  NOT tested here (require router hardware or special environment):"
echo "    - Concurrent operation lock (needs two simultaneous processes)"
echo "    - Interrupted install recovery (needs power-loss simulation)"
echo "    - Disk-full write failure (needs controlled full filesystem)"
echo "    - runtime-pkg.mk make target (needs full Freetz-NG build env)"
echo "    - router smoke test: pkg on actual ARM router with USB storage"

exit $OVERALL
