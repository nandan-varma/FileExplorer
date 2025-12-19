//! Scrollbar Component

use raylib::prelude::*;

use crate::ui::styles::{ColorScheme, Layout};

/// Draws the vertical scrollbar
pub fn draw_scrollbar(
    d: &mut RaylibDrawHandle,
    files_count: usize,
    scroll_offset: usize,
    layout: &Layout,
    colors: &ColorScheme,
) {
    let visible_rows = layout.visible_rows();

    // Don't show scrollbar if all items are visible
    if files_count <= visible_rows {
        return;
    }

    let scrollbar_x = layout.window_width - layout.padding - layout.scrollbar_width;
    let scrollbar_y = layout.list_start_y();
    let scrollbar_height = (visible_rows as i32) * layout.row_height;

    draw_scrollbar_track(d, scrollbar_x, scrollbar_y, scrollbar_height, layout, colors);
    draw_scrollbar_thumb(
        d,
        scrollbar_x,
        scrollbar_y,
        scrollbar_height,
        files_count,
        scroll_offset,
        visible_rows,
        layout,
        colors,
    );
}

/// Draws the scrollbar track
fn draw_scrollbar_track(
    d: &mut RaylibDrawHandle,
    x: i32,
    y: i32,
    height: i32,
    layout: &Layout,
    colors: &ColorScheme,
) {
    d.draw_rectangle_rounded(
        Rectangle::new(
            x as f32,
            y as f32,
            layout.scrollbar_width as f32,
            height as f32,
        ),
        0.5,
        10,
        colors.surface_variant,
    );
}

/// Draws the scrollbar thumb
fn draw_scrollbar_thumb(
    d: &mut RaylibDrawHandle,
    scrollbar_x: i32,
    scrollbar_y: i32,
    scrollbar_height: i32,
    files_count: usize,
    scroll_offset: usize,
    visible_rows: usize,
    layout: &Layout,
    colors: &ColorScheme,
) {
    let thumb_ratio = visible_rows as f32 / files_count as f32;
    let thumb_height = (scrollbar_height as f32 * thumb_ratio).max(32.0) as i32;
    let max_scroll = files_count.saturating_sub(visible_rows);

    let thumb_y = if max_scroll > 0 {
        scrollbar_y
            + ((scrollbar_height - thumb_height) * scroll_offset as i32 / max_scroll as i32)
    } else {
        scrollbar_y
    };

    d.draw_rectangle_rounded(
        Rectangle::new(
            (scrollbar_x + 2) as f32,
            thumb_y as f32,
            (layout.scrollbar_width - 4) as f32,
            thumb_height as f32,
        ),
        0.5,
        10,
        colors.secondary,
    );
}
