cargo +nightly bench -p hyper-bench                       # baseline
cargo +nightly bench -p hyper-bench --features telemetry  # with dial9
  
examples/hyper-bench/compare.sh               # run everything non-ignored
examples/hyper-bench/compare.sh http1_        # substring filter passed to cargo bench
examples/hyper-bench/compare.sh throughput    # just server.rs

