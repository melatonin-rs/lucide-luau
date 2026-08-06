use anyhow::Result;
use rayon::prelude::*;
use std::fs;
use std::path::Path;

mod config;
mod converter;
mod invert;

fn process_file(path: &Path) -> Vec<Result<()>> {
    let name = path
        .file_stem()
        .and_then(|s| s.to_str())
        .unwrap_or("unknown")
        .to_string();

    let svg_data = match fs::read(path) {
        Ok(data) => data,
        Err(e) => return vec![Err(e.into())],
    };

    config::SIZES
        .iter()
        .map(|&size| converter::convert(&svg_data, size, &name))
        .collect()
}

fn main() -> Result<()> {
    println!("lucide-builder v{}", env!("CARGO_PKG_VERSION"));

    fs::create_dir_all(config::OUT_DIR)?;

    let svg_files: Vec<_> = fs::read_dir(config::SVG_DIR)?
        .filter_map(|e| e.ok())
        .map(|e| e.path())
        .filter(|p| p.extension().map_or(false, |ext| ext == "svg"))
        .collect();

    let results: Vec<Result<()>> = svg_files
        .par_iter()
        .flat_map(|path| process_file(path))
        .collect();

    let success = results.iter().filter(|r| r.is_ok()).count();
    let failed = results.iter().filter(|r| r.is_err()).count();

    println!("Processed: {} icons, {} errors", success, failed);

    for result in &results {
        if let Err(e) = result {
            eprintln!("Error: {}", e);
        }
    }

    Ok(())
}