#!/bin/sh
# Smoke-tests a freshly built ./ace binary: parsing, generation, and
# transfer/rule-loading (trigger-rule/idiom-rule/fixup-rule/cleanup-rule/
# transfer-rule all funnel through transfer.c's dg_to_transfer_rule() and
# dag.c's walk_dg(), which is exactly what broke on Apple Silicon -- see
# the trigger-rule crash and the freeze-time realloc-of-unallocated-pointer
# bug this fixture is designed to catch a regression of).
#
# Run from the repo root, after `make ace`:
#   .github/scripts/smoke-test.sh
set -eu

ACE=./ace
FIXTURES=.github/fixtures

if [ ! -x "$ACE" ]; then
	echo "FAIL: $ACE not found or not executable (build it first with 'make ace')" >&2
	exit 1
fi

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

fail() {
	echo "FAIL: $1" >&2
	exit 1
}

echo "== compiling toy grammar =="
"$ACE" -g "$FIXTURES/toy-grammar/config.tdl" -G "$WORKDIR/toy.dat"

echo
echo "== parsing =="
PARSE_OUT=$(echo "n1 iv" | "$ACE" -g "$WORKDIR/toy.dat" 2>&1)
echo "$PARSE_OUT"
echo "$PARSE_OUT" | grep -q '"_n1_n_rel"' || fail "parse did not produce expected predicate _n1_n_rel"
echo "$PARSE_OUT" | grep -q '"_iv_v_rel"' || fail "parse did not produce expected predicate _iv_v_rel"
echo "$PARSE_OUT" | grep -q '1 readings' || fail "parse did not report exactly 1 reading"

echo
echo "== generation (round-trip the parsed MRS back through -e) =="
MRS=$(echo "$PARSE_OUT" | grep '^\[')
GEN_OUT=$(echo "$MRS" | "$ACE" -e -g "$WORKDIR/toy.dat" 2>&1)
echo "$GEN_OUT"
echo "$GEN_OUT" | grep -qi '^n1 iv$' || fail "generation did not realize the sentence 'n1 iv'"
echo "$GEN_OUT" | grep -q '\[1 results\]' || fail "generation reported an unexpected result count"

echo
echo "== transfer/rule-loading (grammar with a trigger-rule under generation-trigger-rules) =="
"$ACE" -g "$FIXTURES/toy-grammar-transfer/config.tdl" -G "$WORKDIR/transfer.dat"
RELOAD_OUT=$(echo "n1 iv" | "$ACE" -g "$WORKDIR/transfer.dat" 2>&1)
echo "$RELOAD_OUT"
echo "$RELOAD_OUT" | grep -q '"_n1_n_rel"' || fail "parse after reloading the trigger-rule grammar failed"

echo
echo "ALL CHECKS PASSED"
