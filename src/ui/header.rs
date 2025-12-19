//! Header Component
//! 
//! Displays the navigation header with back button and breadcrumb path

use raylib::prelude::*;
use std::path::PathBuf;

use crate::file_system::path_components;
use crate::ui::styles::{ColorScheme, Layout};

/// Draws the header section of the UI
pub fn draw_header(
    d: &mut RaylibDrawHandle,
    current_path: &PathBuf,
    layout: &Layout,
    colors: &ColorScheme,
) {
    draw_header_background(d, layout, colors);
    draw_back_button(d, layout, colors);
    draw_breadcrumb_path(d, current_path, layout, colors);
}

/// Draws the header background and bottom border
fn draw_header_background(d: &mut RaylibDrawHandle, layout: &Layout, colors: &ColorScheme) {
    d.draw_rectangle(0, 0, layout.window_width, layout.header_height, colors.surface);
    d.draw_rectangle(
        0,
        layout.header_height - 1,
        layout.window_width,
        1,
        colors.outline,
    );
}

/// Draws the back navigation button
fn draw_back_button(d: &mut RaylibDrawHandle, layout: &Layout, colors: &ColorScheme) {
    let btn_x = layout.padding;
    let btn_y = (layout.header_height - 32) / 2;

    d.draw_rectangle_rounded(
        Rectangle::new(btn_x as f32, btn_y as f32, 40.0, 32.0),
        0.2,
        10,
        colors.surface_variant,
    );
    d.draw_text("←", btn_x + 12, btn_y + 4, 24, colors.on_surface);
}

/// Draws the breadcrumb navigation path
fn draw_breadcrumb_path(
    d: &mut RaylibDrawHandle,
    current_path: &PathBuf,
    layout: &Layout,
    colors: &ColorScheme,
) {
    let breadcrumb_x = layout.padding + 48;
    let breadcrumb_y = (layout.header_height - 32) / 2 + 8;
    let components = path_components(current_path);
    let mut x = breadcrumb_x;

    for (i, component) in components.iter().enumerate() {
        // Draw component name
        d.draw_text(component, x, breadcrumb_y, 16, colors.on_surface);
        x += d.measure_text(component, 16) as i32;

        // Draw separator if not last component
        if i < components.len() - 1 {
            d.draw_text(" / ", x, breadcrumb_y, 16, colors.on_surface_variant);
            x += d.measure_text(" / ", 16) as i32;
        }
    }
}

/// Checks if the back button was clicked
pub fn is_back_button_clicked(mouse_x: i32, mouse_y: i32, layout: &Layout) -> bool {
    let btn_y = (layout.header_height - 32) / 2;
    mouse_x >= layout.padding
        && mouse_x <= layout.padding + 40
        && mouse_y >= btn_y
        && mouse_y <= btn_y + 32
}
