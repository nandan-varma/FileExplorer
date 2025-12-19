//! File List Component
//! 
//! Displays the list of files and folders with icons, selection, and hover effects

use raylib::prelude::*;
use std::time::{SystemTime, UNIX_EPOCH};

use crate::file_system::FileEntry;
use crate::input::Selection;
use crate::ui::styles::{format_file_size, ColorScheme, ColumnConfig, Layout};

/// Draws the file list
pub fn draw_file_list(
    d: &mut RaylibDrawHandle,
    files: &[FileEntry],
    opacities: &[f32],
    selection: &Selection,
    scroll_offset: usize,
    layout: &Layout,
    colors: &ColorScheme,
    hover_index: Option<usize>,
) {
    let list_y = layout.list_start_y();
    let visible_rows = layout.visible_rows();

    draw_list_background(d, list_y, visible_rows, layout, colors);
    draw_file_entries(d, files, opacities, selection, scroll_offset, list_y, visible_rows, layout, colors, hover_index);
    draw_list_border(d, list_y, visible_rows, layout, colors);
}

/// Draws the list background
fn draw_list_background(
    d: &mut RaylibDrawHandle,
    list_y: i32,
    visible_rows: usize,
    layout: &Layout,
    colors: &ColorScheme,
) {
    d.draw_rectangle(
        layout.padding,
        list_y,
        layout.list_width(),
        (visible_rows as i32) * layout.row_height,
        colors.surface,
    );
}

/// Draws all file entries
fn draw_file_entries(
    d: &mut RaylibDrawHandle,
    files: &[FileEntry],
    opacities: &[f32],
    selection: &Selection,
    scroll_offset: usize,
    list_y: i32,
    visible_rows: usize,
    layout: &Layout,
    colors: &ColorScheme,
    hover_index: Option<usize>,
) {
    let columns = ColumnConfig::new(layout);

    for (i, (entry, opacity)) in files
        .iter()
        .zip(opacities.iter())
        .enumerate()
        .skip(scroll_offset)
        .take(visible_rows)
    {
        let idx = i;
        let row_y = list_y + ((i - scroll_offset) as i32) * layout.row_height;
        let is_selected = selection.indices.contains(&idx);
        let is_hovered = hover_index == Some(idx);

        draw_row_background(d, row_y, is_selected, is_hovered, layout, colors);
        draw_file_icon_with_opacity(d, entry, row_y, layout, colors, *opacity);
        draw_file_info_with_opacity(d, entry, &columns, row_y, is_selected, colors, *opacity);
    }
}

/// Draws the row background (selection/hover highlight)
fn draw_row_background(
    d: &mut RaylibDrawHandle,
    row_y: i32,
    is_selected: bool,
    is_hovered: bool,
    layout: &Layout,
    colors: &ColorScheme,
) {
    if is_selected {
        d.draw_rectangle(
            layout.padding + 4,
            row_y + 2,
            layout.list_width() - 8,
            layout.row_height - 4,
            colors.selected,
        );
    } else if is_hovered {
        d.draw_rectangle(
            layout.padding + 4,
            row_y + 2,
            layout.list_width() - 8,
            layout.row_height - 4,
            colors.hover,
        );
    }
}

/// Draws the file/folder icon
fn draw_file_icon(
    d: &mut RaylibDrawHandle,
    entry: &FileEntry,
    row_y: i32,
    layout: &Layout,
    colors: &ColorScheme,
) {
    draw_file_icon_with_opacity(d, entry, row_y, layout, colors, 1.0);
}

/// Draws the file/folder icon with opacity
fn draw_file_icon_with_opacity(
    d: &mut RaylibDrawHandle,
    entry: &FileEntry,
    row_y: i32,
    layout: &Layout,
    colors: &ColorScheme,
    opacity: f32,
) {
    let icon_x = layout.padding + 8;
    let icon_y = row_y + (layout.row_height - layout.icon_size) / 2;

    if entry.is_dir {
        draw_folder_icon_with_opacity(d, icon_x, icon_y, colors, opacity);
    } else {
        draw_file_icon_by_extension_with_opacity(d, icon_x, icon_y, &entry.extension, colors, opacity);
    }
}

/// Draws a folder icon
fn draw_folder_icon(d: &mut RaylibDrawHandle, x: i32, y: i32, colors: &ColorScheme) {
    draw_folder_icon_with_opacity(d, x, y, colors, 1.0);
}

/// Draws a folder icon with opacity
fn draw_folder_icon_with_opacity(d: &mut RaylibDrawHandle, x: i32, y: i32, colors: &ColorScheme, opacity: f32) {
    let alpha = (255.0 * opacity) as u8;
    let folder_color = Color::new(colors.folder_color.r, colors.folder_color.g, colors.folder_color.b, alpha);
    let tab_color = Color::new(234, 179, 8, alpha);
    let outline_color = Color::new(180, 130, 0, alpha);

    d.draw_rectangle(x + 2, y + 4, 16, 12, folder_color);
    d.draw_rectangle(x + 2, y + 2, 8, 4, tab_color); // Tab
    d.draw_rectangle_lines(x + 2, y + 4, 16, 12, outline_color);
}

/// Draws a file icon with color based on extension
fn draw_file_icon_by_extension(
    d: &mut RaylibDrawHandle,
    x: i32,
    y: i32,
    extension: &str,
    colors: &ColorScheme,
) {
    draw_file_icon_by_extension_with_opacity(d, x, y, extension, colors, 1.0);
}

/// Draws a file icon with color based on extension and opacity
fn draw_file_icon_by_extension_with_opacity(
    d: &mut RaylibDrawHandle,
    x: i32,
    y: i32,
    extension: &str,
    colors: &ColorScheme,
    opacity: f32,
) {
    let file_color = get_file_color_by_extension(extension, colors);
    let alpha = (255.0 * opacity) as u8;
    let adjusted_file_color = Color::new(file_color.r, file_color.g, file_color.b, alpha);
    let white_highlight = Color::new(255, 255, 255, alpha);
    let outline_color = Color::new(156, 163, 175, alpha);

    d.draw_rectangle(x + 4, y + 2, 12, 16, adjusted_file_color);
    d.draw_rectangle(x + 4, y + 2, 12, 3, white_highlight); // Top highlight
    d.draw_rectangle_lines(x + 4, y + 2, 12, 16, outline_color);
}

/// Gets the color for a file based on its extension
fn get_file_color_by_extension(extension: &str, colors: &ColorScheme) -> Color {
    match extension {
        "txt" | "md" | "doc" => Color::new(96, 165, 250, 255),        // Blue for text
        "jpg" | "png" | "gif" | "svg" => Color::new(244, 114, 182, 255), // Pink for images
        "mp3" | "wav" | "ogg" => Color::new(168, 85, 247, 255),       // Purple for audio
        "mp4" | "avi" | "mov" => Color::new(251, 146, 60, 255),       // Orange for video
        "zip" | "rar" | "7z" => Color::new(234, 179, 8, 255),         // Yellow for archives
        "rs" | "py" | "js" | "ts" => Color::new(52, 211, 153, 255),   // Green for code
        _ => colors.file_color,
    }
}

/// Draws file information (name, type, size, modified date)
fn draw_file_info(
    d: &mut RaylibDrawHandle,
    entry: &FileEntry,
    columns: &ColumnConfig,
    row_y: i32,
    is_selected: bool,
    colors: &ColorScheme,
) {
    draw_file_info_with_opacity(d, entry, columns, row_y, is_selected, colors, 1.0);
}

/// Draws file information with opacity
fn draw_file_info_with_opacity(
    d: &mut RaylibDrawHandle,
    entry: &FileEntry,
    columns: &ColumnConfig,
    row_y: i32,
    is_selected: bool,
    colors: &ColorScheme,
    opacity: f32,
) {
    let text_y = row_y + 6;
    let alpha = (255.0 * opacity) as u8;

    // Name
    let mut name_color = if is_selected {
        colors.primary
    } else {
        colors.on_surface
    };
    name_color.a = alpha;

    let name_display = truncate_text(&entry.name, columns.name_width - 8, 16);
    d.draw_text(&name_display, columns.name_x, text_y, 16, name_color);

    // Type
    let mut type_color = colors.on_surface_variant;
    type_color.a = alpha;

    let type_str = if entry.is_dir {
        "Folder"
    } else if entry.extension.is_empty() {
        "File"
    } else {
        &entry.extension.to_uppercase()
    };
    d.draw_text(type_str, columns.type_x, text_y, 16, type_color);

    // Size
    let size_str = if entry.is_dir {
        "-".to_string()
    } else {
        format_file_size(entry.size)
    };
    d.draw_text(&size_str, columns.size_x, text_y, 16, type_color);

    // Modified date
    let modified_text = if let Some(modified_time) = &entry.modified {
        format_modified_date(modified_time)
    } else {
        "-".to_string()
    };
    let modified_display = truncate_text(&modified_text, columns.modified_width - 8, 16);
    d.draw_text(&modified_display, columns.modified_x, text_y, 16, type_color);
}

/// Formats a SystemTime into a readable date string
fn format_modified_date(system_time: &SystemTime) -> String {

    // Get current time for comparison
    let now = SystemTime::now();

    match now.duration_since(*system_time) {
        Ok(duration) => {
            let secs = duration.as_secs();

            // Show relative time for recent files
            if secs < 60 {
                "Just now".to_string()
            } else if secs < 3600 {
                let minutes = secs / 60;
                format!("{}m ago", minutes)
            } else if secs < 86400 {
                let hours = secs / 3600;
                format!("{}h ago", hours)
            } else if secs < 604800 { // 7 days
                let days = secs / 86400;
                format!("{}d ago", days)
            } else {
                // For older files, show date
                // Convert to local time components (simplified)
                if let Ok(duration_since_epoch) = system_time.duration_since(UNIX_EPOCH) {
                    let total_days = duration_since_epoch.as_secs() / 86400;

                    // Calculate approximate date (this is a rough calculation)
                    // In a real application, you'd use a proper date/time library
                    let mut year = 1970;
                    let mut remaining_days = total_days;

                    // Subtract days for each year (accounting for leap years roughly)
                    while remaining_days >= 365 {
                        let days_in_year = if is_leap_year(year) { 366 } else { 365 };
                        if remaining_days >= days_in_year {
                            remaining_days -= days_in_year;
                            year += 1;
                        } else {
                            break;
                        }
                    }

                    // Calculate month and day (rough approximation)
                    let month_days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
                    let mut month = 1;
                    let mut day = remaining_days + 1; // +1 because days are 1-indexed

                    for (i, &days_in_month) in month_days.iter().enumerate() {
                        if day <= days_in_month {
                            month = i + 1;
                            break;
                        }
                        day -= days_in_month;
                    }

                    format!("{:04}-{:02}-{:02}", year, month, day as u32)
                } else {
                    "Unknown".to_string()
                }
            }
        }
        Err(_) => {
            // File is in the future (shouldn't happen normally)
            "Future".to_string()
        }
    }
}

/// Check if a year is a leap year (simplified)
fn is_leap_year(year: u64) -> bool {
    (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
}

/// Draws the border around the file list
fn draw_list_border(
    d: &mut RaylibDrawHandle,
    list_y: i32,
    visible_rows: usize,
    layout: &Layout,
    colors: &ColorScheme,
) {
    d.draw_rectangle_lines(
        layout.padding,
        list_y,
        layout.list_width(),
        (visible_rows as i32) * layout.row_height,
        colors.outline,
    );
}

/// Truncates text to fit within a maximum width
fn truncate_text(text: &str, max_width: i32, font_size: i32) -> String {
    let max_chars = (max_width / (font_size / 2)).max(3) as usize;
    if text.len() <= max_chars {
        text.to_string()
    } else {
        format!("{}...", &text[..max_chars.saturating_sub(3)])
    }
}

/// Gets the index of the clicked file
pub fn get_clicked_index(
    mouse_x: i32,
    mouse_y: i32,
    layout: &Layout,
    scroll_offset: usize,
) -> Option<usize> {
    let list_y = layout.list_start_y();
    let list_end_y = list_y + (layout.visible_rows() as i32) * layout.row_height;

    if mouse_x >= layout.padding
        && mouse_x <= layout.padding + layout.list_width()
        && mouse_y >= list_y
        && mouse_y < list_end_y
    {
        let row = ((mouse_y - list_y) / layout.row_height) as usize;
        Some(row + scroll_offset)
    } else {
        None
    }
}

/// Gets the index of the hovered file
pub fn get_hover_index(
    mouse_x: i32,
    mouse_y: i32,
    layout: &Layout,
    scroll_offset: usize,
    files_count: usize,
) -> Option<usize> {
    if let Some(idx) = get_clicked_index(mouse_x, mouse_y, layout, scroll_offset) {
        if idx < files_count {
            return Some(idx);
        }
    }
    None
}
