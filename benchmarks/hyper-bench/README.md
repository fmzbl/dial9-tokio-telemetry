cargo +nightly bench -p hyper-bench                                    # baseline
cargo +nightly bench -p hyper-bench --features telemetry               # dial9 + RotatingWriter (writes trace to disk)
cargo +nightly bench -p hyper-bench --features telemetry,null-writer   # dial9 + NullWriter (no disk I/O, isolates hook overhead)

benchmarks/hyper-bench/compare.sh               # run everything non-ignored
benchmarks/hyper-bench/compare.sh http1_        # substring filter passed to cargo bench
benchmarks/hyper-bench/compare.sh throughput    # just server.rs

FEATURES=telemetry,null-writer benchmarks/hyper-bench/compare.sh   # compare vs NullWriter

