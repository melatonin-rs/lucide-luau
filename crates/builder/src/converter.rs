use anyhow::{anyhow, Result};
use resvg::tiny_skia::{Pixmap, Transform};
use resvg::usvg::{Options, Tree};
use resvg::render;

use crate::config::OUT_DIR;
use crate::invert;

pub fn convert(svg_data: &[u8], size: u32, name: &str) -> Result<()> {
    let options = Options::default();

    let tree = Tree::from_data(svg_data, &options)
        .map_err(|e| anyhow!("SVG parse error: {:?}", e))?;

    let mut pixmap = Pixmap::new(size, size)
        .ok_or_else(|| anyhow!("Failed to create pixmap"))?;

    let view = tree.size();
    let scale = size as f32 / view.width().max(view.height());

    render(&tree, Transform::from_scale(scale, scale), &mut pixmap.as_mut());

    invert::apply(&mut pixmap);

    let output_path = format!("{}/{}_{}.png", OUT_DIR, name, size);
    pixmap
        .save_png(&output_path)
        .map_err(|e| anyhow!("PNG save error: {:?}", e))?;

    Ok(())
}