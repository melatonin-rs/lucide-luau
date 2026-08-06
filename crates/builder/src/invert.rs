use resvg::tiny_skia::{ColorU8, Pixmap};

pub fn apply(pixmap: &mut Pixmap) {
    for pixel in pixmap.pixels_mut() {
        let color = pixel.demultiply();
        let alpha = color.alpha();

        if alpha == 0 {
            continue;
        }

        let inverted = ColorU8::from_rgba(
            255 - color.red(),
            255 - color.green(),
            255 - color.blue(),
            alpha,
        );

        *pixel = inverted.premultiply();
    }
}