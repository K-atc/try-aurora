memo
====


ソースコード解析
----
### AURORAのpredicate ranking生成箇所
aurora/root_cause_analysis/root_cause_analysis/src/traces.rs
```rust
pub fn analyze_traces(config: &Config) {
    let trace_analysis_output_dir = Some(config.eval_dir.to_string());
    let crash_blacklist_path = if config.blacklist_crashes() {
        Some(config.crash_blacklist_path.to_string())
    } else {
        None
    };
    let trace_analysis_config = trace_analysis::config::Config::default(
        &config.trace_dir,
        &trace_analysis_output_dir,
        &crash_blacklist_path,
    );
    let trace_analyzer = TraceAnalyzer::new(&trace_analysis_config);

    // 得られたpredicateすべてを linear_score に保存する。
    println!("dumping linear scores");
    trace_analyzer.dump_scores(&trace_analysis_config, false, false);

    let predicates = trace_analyzer.get_predicates_better_than(0.9);

    serialize_mnemonics(config, &predicates, &trace_analyzer);

    serialize_predicates(config, &predicates);
}
```