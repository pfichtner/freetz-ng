#!/bin/sh
# Simple assertion helpers for pkgmanager tests

PASS=0
FAIL=0

assert_eq() {
	local desc="$1" expected="$2" actual="$3"
	if [ "$expected" = "$actual" ]; then
		PASS=$((PASS + 1))
		printf "  PASS: %s\n" "$desc"
	else
		FAIL=$((FAIL + 1))
		printf "  FAIL: %s\n" "$desc"
		printf "        expected: %s\n" "$expected"
		printf "        actual:   %s\n" "$actual"
	fi
}

assert_exit() {
	local desc="$1" expected_code="$2"
	shift 2
	"$@" >/dev/null 2>&1
	local actual_code=$?
	if [ "$actual_code" = "$expected_code" ]; then
		PASS=$((PASS + 1))
		printf "  PASS: %s\n" "$desc"
	else
		FAIL=$((FAIL + 1))
		printf "  FAIL: %s (expected exit %s, got %s)\n" "$desc" "$expected_code" "$actual_code"
	fi
}

assert_file_exists() {
	local desc="$1" path="$2"
	if [ -e "$path" ]; then
		PASS=$((PASS + 1))
		printf "  PASS: %s\n" "$desc"
	else
		FAIL=$((FAIL + 1))
		printf "  FAIL: %s (not found: %s)\n" "$desc" "$path"
	fi
}

assert_file_absent() {
	local desc="$1" path="$2"
	if [ ! -e "$path" ]; then
		PASS=$((PASS + 1))
		printf "  PASS: %s\n" "$desc"
	else
		FAIL=$((FAIL + 1))
		printf "  FAIL: %s (should not exist: %s)\n" "$desc" "$path"
	fi
}

assert_output_contains() {
	local desc="$1" needle="$2"
	shift 2
	local out
	out=$("$@" 2>&1)
	if echo "$out" | grep -qF "$needle"; then
		PASS=$((PASS + 1))
		printf "  PASS: %s\n" "$desc"
	else
		FAIL=$((FAIL + 1))
		printf "  FAIL: %s\n" "$desc"
		printf "        expected output to contain: %s\n" "$needle"
		printf "        actual output:\n%s\n" "$out"
	fi
}

summary() {
	echo ""
	echo "Results: $PASS passed, $FAIL failed"
	[ "$FAIL" -eq 0 ]
}
