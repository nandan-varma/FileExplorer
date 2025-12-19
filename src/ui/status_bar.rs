//! Status Bar Component

use raylib::prelude::*;

use crate::file_system::FileEntry;
use crate::input::Selection;
use crate::ui::styles::{ColorScheme, Layout};

/// Draws the status bar at the bottom of the window
pub fn draw_status_bar(
    d: &mut RaylibDrawHandle,
    files: &[FileEntry],
    selection: &Selection,
    layout: &Layout,
    colors: &ColorScheme,
    search_active: bool,
    sort_order: &str,
) {
    let status_y = layout.window_height - layout.status_bar_height;

    draw_status_background(d, status_y, layout, colors);
    draw_status_text(d, files, selection, search_active, sort_order, status_y, layout, colors);
}

/// Draws the status bar background
fn draw_status_background(
    d: &mut RaylibDrawHandle,
    status_y: i32,
    layout: &Layout,
    colors: &ColorScheme,
) {
    d.draw_rectangle(0, status_y, layout.window_width, layout.status_bar_height, colors.surface);
    d.draw_rectangle(0, status_y, layout.window_width, 1, colors.outline);
}

/// Draws the status text
fn draw_status_text(
    d: &mut RaylibDrawHandle,
    files: &[FileEntry],
    selection: &Selection,
    search_active: bool,
    sort_order: &str,
    status_y: i32,
    layout: &Layout,
    colors: &ColorScheme,
) {
    let (folder_count, file_count) = count_items(files);
    let mut status_parts = Vec::new();

    // Selection info
    if selection.indices.len() > 1 {
        status_parts.push(format!("{} items selected", selection.indices.len()));
    }

    // Item counts
    status_parts.push(format!("{} folders, {} files", folder_count, file_count));

    // Search indicator
    if search_active {
        status_parts.push("🔍 SEARCH".to_string());
    }

    // Sort order
    status_parts.push(format!("Sort: {}", sort_order));

    let status_text = status_parts.join("  |  ");

    d.draw_text(
        &status_text,
        layout.padding,
        status_y + 6,
        14,
        colors.on_surface_variant,
    );
}

/// Counts folders and files
fn count_items(files: &[FileEntry]) -> (usize, usize) {
    let folder_count = files.iter().filter(|f| f.is_dir).count();
    let file_count = files.len() - folder_count;
    (folder_count, file_count)
}

/// Formats the status text
fn format_status_text(selection: &Selection, folder_count: usize, file_count: usize) -> String {
    if selection.indices.len() > 1 {
        format!(
            "{} items selected  |  {} folders, {} files",
            selection.indices.len(),
            folder_count,
            file_count
        )
    } else {
        format!("{} folders, {} files", folder_count, file_count)
    }
}
