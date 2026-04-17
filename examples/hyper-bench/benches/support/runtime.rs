//! Single seam for swapping a plain Tokio runtime for a dial9-instrumented one.
//!
//! Gate with the `telemetry` cargo feature:
//!   off → plain `tokio::runtime`
//!   on  → `TracedRuntime` writing to `DIAL9_TRACE_PATH`
//!         (default `/tmp/hyper_bench_trace.bin`)

use tokio::runtime::{Builder, Runtime};

#[cfg(not(feature = "telemetry"))]
pub type BenchGuard = ();

#[cfg(feature = "telemetry")]
pub type BenchGuard = dial9_tokio_telemetry::telemetry::TelemetryGuard;

#[cfg(not(feature = "telemetry"))]
pub fn build_rt(builder: Builder) -> (Runtime, BenchGuard) {
    let mut builder = builder;
    (builder.build().expect("rt build"), ())
}

#[cfg(feature = "telemetry")]
pub fn build_rt(builder: Builder) -> (Runtime, BenchGuard) {
    use dial9_tokio_telemetry::telemetry::{RotatingWriter, TracedRuntime};

    let path = std::env::var("DIAL9_TRACE_PATH")
        .unwrap_or_else(|_| "/tmp/hyper_bench_trace.bin".to_string());
    let writer = RotatingWriter::builder()
        .base_path(&path)
        .max_file_size(16 * 1024 * 1024)
        .max_total_size(64 * 1024 * 1024)
        .build()
        .expect("rotating writer");

    TracedRuntime::build_and_start(builder, writer).expect("traced rt build")
}
