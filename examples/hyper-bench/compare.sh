#!/usr/bin/env bash
# Run hyper benches baseline vs with dial9 telemetry, print per-bench overhead.
#
# Usage:
#   ./compare.sh                  # run all (non-ignored) benches
#   ./compare.sh http1_           # pass any substring to cargo bench as a filter

set -euo pipefail

cd "$(dirname "$0")"

FILTER="${1:-}"
BASE=$(mktemp)
TELE=$(mktemp)
trap 'rm -f "$BASE" "$TELE" "$BASE.tsv" "$TELE.tsv"' EXIT

echo ">>> baseline"
cargo +nightly bench -p hyper-bench -- $FILTER 2>&1 | tee "$BASE"

echo
echo ">>> telemetry"
cargo +nightly bench -p hyper-bench --features telemetry -- $FILTER 2>&1 | tee "$TELE"

# Extract "name  ns_per_iter" from lines like:
#   test some::name ... bench:  216.36 ns/iter (+/- 4.52) = 9259 MB/s
extract() {
  awk '/ns\/iter/ { gsub(",", "", $5); print $2 "\t" $5 }' "$1" | sort -u
}

extract "$BASE" > "$BASE.tsv"
extract "$TELE" > "$TELE.tsv"

echo
printf '%-58s %12s %12s %10s\n' "bench" "baseline(ns)" "telem(ns)" "overhead"
printf '%-58s %12s %12s %10s\n' "-----" "------------" "----------" "--------"

join -t $'\t' "$BASE.tsv" "$TELE.tsv" | \
  awk -F '\t' '
    {
      pct = ($3 - $2) / $2 * 100
      printf "%-58s %12.2f %12.2f %+9.1f%%\n", $1, $2, $3, pct
      sum += pct; n++
    }
    END {
      if (n > 0) {
        printf "\n%-58s %12s %12s %+9.1f%%  (mean over %d benches)\n",
               "TOTAL", "", "", sum/n, n
      } else {
        print "no matching benches found in both runs" > "/dev/stderr"
        exit 1
      }
    }'
