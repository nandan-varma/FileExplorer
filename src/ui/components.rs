use raylib::prelude::*;
use crate::file_system::{FileEntry, path_components};
use crate::input::Selection;
use crate::operations::ClipboardOperation;
use super::styles::{ColorScheme, Layout, ColumnConfig, format_file_size};
use std::path::PathBuf;

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum ContextMenuAction {
    Open,
    Copy,
    Cut,
    Paste,
    Delete,
    Rename,
    NewFolder,
    Properties,
    None,
}

#[derive(Debug, Clone, PartialEq)]
pub enum DialogType {
    None,
    Confirm { title: String, message: String, action: ContextMenuAction },
    Input { title: String, prompt: String, action: ContextMenuAction, default_value: String },
}

pub struct ContextMenu {
    pub x: i32,
    pub y: i32,
    pub visible: bool,
    pub items: Vec<(String, ContextMenuAction, bool)>, // (label, action, enabled)
}

impl ContextMenu {
    pub fn new() -> Self {
        Self {
            x: 0,
            y: 0,
            visible: false,
            items: Vec::new(),
        }
    }
    
    pub fn show(&mut self, x: i32, y: i32, has_selection: bool, clipboard_has_items: bool) {
        self.x = x;
        self.y = y;
        self.visible = true;
        self.items.clear();
        
        if has_selection {
            self.items.push(("Open".to_string(), ContextMenuAction::Open, true));
            self.items.push(("---".to_string(), ContextMenuAction::None, false));
            self.items.push(("Copy".to_string(), ContextMenuAction::Copy, true));
            self.items.push(("Cut".to_string(), ContextMenuAction::Cut, true));
        }
        
        self.items.push(("Paste".to_string(), ContextMenuAction::Paste, clipboard_has_items));
        
        if has_selection {
            self.items.push(("Delete".to_string(), ContextMenuAction::Delete, true));
            self.items.push(("Rename".to_string(), ContextMenuAction::Rename, true));
        }
        
        self.items.push(("---".to_string(), ContextMenuAction::None, false));
        self.items.push(("New Folder".to_string(), ContextMenuAction::NewFolder, true));
    }
    
    pub fn hide(&mut self) {
        self.visible = false;
    }
    
    pub fn get_height(&self) -> i32 {
        self.items.len() as i32 * 28 + 8
    }
}

pub fn draw_header(d: &mut RaylibDrawHandle, current_path: &PathBuf, layout: &Layout, colors: &ColorScheme) {
    // Draw header background
    d.draw_rectangle(0, 0, layout.window_width, layout.header_height, colors.surface);
    d.draw_rectangle(
        0,
        layout.header_height - 1,
        layout.window_width,
        1,
        colors.outline,
    );
    
    // Draw back button with better styling
    let btn_x = layout.padding;
    let btn_y = (layout.header_height - 32) / 2;
    d.draw_rectangle_rounded(
        Rectangle::new(btn_x as f32, btn_y as f32, 40.0, 32.0),
        0.2,
        10,
        colors.surface_variant,
    );
    d.draw_text("←", btn_x + 12, btn_y + 4, 24, colors.on_surface);
    
    // Draw path as breadcrumbs
    let breadcrumb_x = btn_x + 48;
    let breadcrumb_y = btn_y + 8;
    let components = path_components(current_path);
    let mut x = breadcrumb_x;
    
    for (i, component) in components.iter().enumerate() {
        // Draw component
        d.draw_text(component, x, breadcrumb_y, 16, colors.on_surface);
        x += d.measure_text(component, 16) as i32;
        
        // Draw separator
        if i < components.len() - 1 {
            d.draw_text(" / ", x, breadcrumb_y, 16, colors.on_surface_variant);
            x += d.measure_text(" / ", 16) as i32;
        }
    }
}

pub fn draw_toolbar(d: &mut RaylibDrawHandle, layout: &Layout, colors: &ColorScheme) {
    let toolbar_y = layout.padding + layout.header_height;
    
    // Draw toolbar background
    d.draw_rectangle(
        layout.padding,
        toolbar_y,
        layout.list_width(),
        layout.toolbar_height,
        colors.surface,
    );
    
    // Draw column headers
    let columns = ColumnConfig::new(layout);
    let header_y = toolbar_y + (layout.toolbar_height - 20) / 2;
    
    d.draw_text("Name", columns.name_x, header_y, 16, colors.on_surface_variant);
    d.draw_text("Type", columns.type_x, header_y, 16, colors.on_surface_variant);
    d.draw_text("Size", columns.size_x, header_y, 16, colors.on_surface_variant);
    d.draw_text("Modified", columns.modified_x, header_y, 16, colors.on_surface_variant);
    
    // Draw bottom border
    d.draw_rectangle(
        layout.padding,
        toolbar_y + layout.toolbar_height - 1,
        layout.list_width(),
        1,
        colors.outline,
    );
}

pub fn draw_file_icon(d: &mut RaylibDrawHandle, x: i32, y: i32, entry: &FileEntry, colors: &ColorScheme) {
    if entry.is_dir {
        // Draw folder icon
        d.draw_rectangle(x + 2, y + 4, 16, 12, colors.folder_color);
        d.draw_rectangle(x + 2, y + 2, 8, 4, Color::new(234, 179, 8, 255)); // Darker amber for tab
        d.draw_rectangle_lines(x + 2, y + 4, 16, 12, Color::new(180, 130, 0, 255));
    } else {
        // Draw file icon with extension-based colors
        let file_color = match entry.extension.as_str() {
            "txt" | "md" | "doc" => Color::new(96, 165, 250, 255),  // Blue for text
            "jpg" | "png" | "gif" | "svg" => Color::new(244, 114, 182, 255), // Pink for images
            "mp3" | "wav" | "ogg" => Color::new(168, 85, 247, 255), // Purple for audio
            "mp4" | "avi" | "mov" => Color::new(251, 146, 60, 255), // Orange for video
            "zip" | "rar" | "7z" => Color::new(234, 179, 8, 255),   // Yellow for archives
            "rs" | "py" | "js" | "ts" => Color::new(52, 211, 153, 255), // Green for code
            _ => colors.file_color,
        };
        
        d.draw_rectangle(x + 4, y + 2, 12, 16, file_color);
        d.draw_rectangle(x + 4, y + 2, 12, 3, Color::WHITE); // Top highlight
        d.draw_rectangle_lines(x + 4, y + 2, 12, 16, Color::new(156, 163, 175, 255));
    }
}

pub fn draw_file_list(
    d: &mut RaylibDrawHandle,
    files: &[FileEntry],
    selection: &Selection,
    scroll_offset: usize,
    layout: &Layout,
    colors: &ColorScheme,
    hover_index: Option<usize>,
) {
    let list_y = layout.list_start_y();
    let columns = ColumnConfig::new(layout);
    let visible_rows = layout.visible_rows();
    
    // Draw list background
    d.draw_rectangle(
        layout.padding,
        list_y,
        layout.list_width(),
        (visible_rows as i32) * layout.row_height,
        colors.surface,
    );
    
    // Draw file entries
    for (i, entry) in files.iter().enumerate().skip(scroll_offset).take(visible_rows) {
        let idx = i;
        let row_y = list_y + ((i - scroll_offset) as i32) * layout.row_height;
        let is_selected = selection.indices.contains(&idx);
        let is_hovered = hover_index == Some(idx);
        
        // Draw row background
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
        
        // Draw icon
        let icon_x = layout.padding + 8;
        let icon_y = row_y + (layout.row_height - layout.icon_size) / 2;
        draw_file_icon(d, icon_x, icon_y, entry, colors);
        
        // Draw name
        let name_color = if is_selected {
            colors.primary
        } else {
            colors.on_surface
        };
        let name_display = truncate_text(&entry.name, columns.name_width - 8, 16);
        d.draw_text(&name_display, columns.name_x, row_y + 6, 16, name_color);
        
        // Draw type
        let type_str = if entry.is_dir {
            "Folder"
        } else if entry.extension.is_empty() {
            "File"
        } else {
            &entry.extension.to_uppercase()
        };
        d.draw_text(type_str, columns.type_x, row_y + 6, 16, colors.on_surface_variant);
        
        // Draw size
        let size_str = if entry.is_dir {
            "-".to_string()
        } else {
            format_file_size(entry.size)
        };
        d.draw_text(&size_str, columns.size_x, row_y + 6, 16, colors.on_surface_variant);
        
        // Draw modified date
        if let Some(_modified) = entry.modified {
            // For now, just show a placeholder
            d.draw_text("Today", columns.modified_x, row_y + 6, 16, colors.on_surface_variant);
        }
    }
    
    // Draw border
    d.draw_rectangle_lines(
        layout.padding,
        list_y,
        layout.list_width(),
        (visible_rows as i32) * layout.row_height,
        colors.outline,
    );
}

pub fn draw_scrollbar(
    d: &mut RaylibDrawHandle,
    files_count: usize,
    scroll_offset: usize,
    layout: &Layout,
    colors: &ColorScheme,
) {
    let visible_rows = layout.visible_rows();
    if files_count <= visible_rows {
        return; // No scrollbar needed
    }
    
    let scrollbar_x = layout.window_width - layout.padding - layout.scrollbar_width;
    let scrollbar_y = layout.list_start_y();
    let scrollbar_height = (visible_rows as i32) * layout.row_height;
    
    // Draw scrollbar track
    d.draw_rectangle_rounded(
        Rectangle::new(
            scrollbar_x as f32,
            scrollbar_y as f32,
            layout.scrollbar_width as f32,
            scrollbar_height as f32,
        ),
        0.5,
        10,
        colors.surface_variant,
    );
    
    // Calculate thumb size and position
    let thumb_ratio = visible_rows as f32 / files_count as f32;
    let thumb_height = (scrollbar_height as f32 * thumb_ratio).max(32.0) as i32;
    let max_scroll = files_count.saturating_sub(visible_rows);
    let thumb_y = if max_scroll > 0 {
        scrollbar_y + ((scrollbar_height - thumb_height) * scroll_offset as i32 / max_scroll as i32)
    } else {
        scrollbar_y
    };
    
    // Draw scrollbar thumb
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

pub fn draw_status_bar(
    d: &mut RaylibDrawHandle,
    files: &[FileEntry],
    selection: &Selection,
    layout: &Layout,
    colors: &ColorScheme,
) {
    let status_y = layout.window_height - layout.status_bar_height;
    
    // Draw status bar background
    d.draw_rectangle(0, status_y, layout.window_width, layout.status_bar_height, colors.surface);
    d.draw_rectangle(0, status_y, layout.window_width, 1, colors.outline);
    
    // Count files and folders
    let folder_count = files.iter().filter(|f| f.is_dir).count();
    let file_count = files.len() - folder_count;
    
    // Draw status text
    let status_text = if selection.indices.len() > 1 {
        format!(
            "{} items selected  |  {} folders, {} files",
            selection.indices.len(),
            folder_count,
            file_count
        )
    } else {
        format!("{} folders, {} files", folder_count, file_count)
    };
    
    d.draw_text(
        &status_text,
        layout.padding,
        status_y + 6,
        14,
        colors.on_surface_variant,
    );
}

pub fn get_clicked_index(mouse_x: i32, mouse_y: i32, layout: &Layout, scroll_offset: usize) -> Option<usize> {
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

pub fn get_hover_index(mouse_x: i32, mouse_y: i32, layout: &Layout, scroll_offset: usize, files_count: usize) -> Option<usize> {
    if let Some(idx) = get_clicked_index(mouse_x, mouse_y, layout, scroll_offset) {
        if idx < files_count {
            return Some(idx);
        }
    }
    None
}

pub fn is_back_button_clicked(mouse_x: i32, mouse_y: i32, layout: &Layout) -> bool {
    let btn_y = (layout.header_height - 32) / 2;
    mouse_x >= layout.padding
        && mouse_x <= layout.padding + 40
        && mouse_y >= btn_y
        && mouse_y <= btn_y + 32
}

fn truncate_text(text: &str, max_width: i32, font_size: i32) -> String {
    // Simple truncation without text measurement
    // This is a placeholder - in a real implementation you'd measure the text
    let max_chars = (max_width / (font_size / 2)).max(3) as usize;
    if text.len() <= max_chars {
        text.to_string()
    } else {
        format!("{}...", &text[..max_chars.saturating_sub(3)])
    }
}

pub fn draw_context_menu(
    d: &mut RaylibDrawHandle,
    menu: &ContextMenu,
    colors: &ColorScheme,
    mouse_x: i32,
    mouse_y: i32,
) -> Option<ContextMenuAction> {
    if !menu.visible {
        return None;
    }
    
    let width = 180;
    let item_height = 28;
    let height = menu.get_height();
    
    // Draw shadow
    d.draw_rectangle(menu.x + 4, menu.y + 4, width, height, Color::new(0, 0, 0, 50));
    
    // Draw menu background
    d.draw_rectangle(menu.x, menu.y, width, height, colors.surface);
    d.draw_rectangle_lines(menu.x, menu.y, width, height, colors.outline);
    
    let mut action = None;
    
    for (i, (label, item_action, enabled)) in menu.items.iter().enumerate() {
        let item_y = menu.y + 4 + (i as i32 * item_height);
        
        // Check if separator
        if label == "---" {
            d.draw_rectangle(menu.x + 8, item_y + 13, width - 16, 1, colors.outline);
            continue;
        }
        
        // Check hover
        let is_hovered = mouse_x >= menu.x
            && mouse_x <= menu.x + width
            && mouse_y >= item_y
            && mouse_y < item_y + item_height
            && *enabled;
        
        if is_hovered {
            d.draw_rectangle(menu.x + 2, item_y, width - 4, item_height, colors.hover);
            action = Some(*item_action);
        }
        
        // Draw text
        let text_color = if *enabled {
            colors.on_surface
        } else {
            colors.on_surface_variant
        };
        
        d.draw_text(label, menu.x + 12, item_y + 6, 16, text_color);
    }
    
    action
}

pub fn draw_dialog(
    d: &mut RaylibDrawHandle,
    dialog: &DialogType,
    layout: &Layout,
    colors: &ColorScheme,
    input_text: &str,
) -> (bool, bool) {
    // Returns (should_confirm, should_cancel)
    match dialog {
        DialogType::None => (false, false),
        DialogType::Confirm { title, message, .. } => {
            draw_confirm_dialog(d, title, message, layout, colors)
        }
        DialogType::Input { title, prompt, .. } => {
            draw_input_dialog(d, title, prompt, input_text, layout, colors)
        }
    }
}

fn draw_confirm_dialog(
    d: &mut RaylibDrawHandle,
    title: &str,
    message: &str,
    layout: &Layout,
    colors: &ColorScheme,
) -> (bool, bool) {
    let dialog_width = 400;
    let dialog_height = 180;
    let dialog_x = (layout.window_width - dialog_width) / 2;
    let dialog_y = (layout.window_height - dialog_height) / 2;
    
    // Draw overlay
    d.draw_rectangle(0, 0, layout.window_width, layout.window_height, Color::new(0, 0, 0, 128));
    
    // Draw dialog shadow
    d.draw_rectangle(dialog_x + 4, dialog_y + 4, dialog_width, dialog_height, Color::new(0, 0, 0, 100));
    
    // Draw dialog background
    d.draw_rectangle(dialog_x, dialog_y, dialog_width, dialog_height, colors.surface);
    d.draw_rectangle_lines(dialog_x, dialog_y, dialog_width, dialog_height, colors.outline);
    
    // Draw title bar
    d.draw_rectangle(dialog_x, dialog_y, dialog_width, 40, colors.primary);
    d.draw_text(title, dialog_x + 16, dialog_y + 12, 18, colors.on_primary);
    
    // Draw message
    d.draw_text(message, dialog_x + 16, dialog_y + 60, 16, colors.on_surface);
    
    // Draw buttons
    let btn_width = 100;
    let btn_height = 32;
    let btn_y = dialog_y + dialog_height - btn_height - 16;
    let cancel_x = dialog_x + dialog_width - btn_width - 16;
    let ok_x = cancel_x - btn_width - 12;
    
    // OK button
    d.draw_rectangle_rounded(
        Rectangle::new(ok_x as f32, btn_y as f32, btn_width as f32, btn_height as f32),
        0.2,
        10,
        colors.primary,
    );
    d.draw_text("OK", ok_x + 35, btn_y + 8, 16, colors.on_primary);
    
    // Cancel button
    d.draw_rectangle_rounded(
        Rectangle::new(cancel_x as f32, btn_y as f32, btn_width as f32, btn_height as f32),
        0.2,
        10,
        colors.surface_variant,
    );
    d.draw_text("Cancel", cancel_x + 25, btn_y + 8, 16, colors.on_surface);
    
    (false, false) // Will be handled by mouse clicks
}

fn draw_input_dialog(
    d: &mut RaylibDrawHandle,
    title: &str,
    prompt: &str,
    input_text: &str,
    layout: &Layout,
    colors: &ColorScheme,
) -> (bool, bool) {
    let dialog_width = 450;
    let dialog_height = 200;
    let dialog_x = (layout.window_width - dialog_width) / 2;
    let dialog_y = (layout.window_height - dialog_height) / 2;
    
    // Draw overlay
    d.draw_rectangle(0, 0, layout.window_width, layout.window_height, Color::new(0, 0, 0, 128));
    
    // Draw dialog shadow
    d.draw_rectangle(dialog_x + 4, dialog_y + 4, dialog_width, dialog_height, Color::new(0, 0, 0, 100));
    
    // Draw dialog background
    d.draw_rectangle(dialog_x, dialog_y, dialog_width, dialog_height, colors.surface);
    d.draw_rectangle_lines(dialog_x, dialog_y, dialog_width, dialog_height, colors.outline);
    
    // Draw title bar
    d.draw_rectangle(dialog_x, dialog_y, dialog_width, 40, colors.primary);
    d.draw_text(title, dialog_x + 16, dialog_y + 12, 18, colors.on_primary);
    
    // Draw prompt
    d.draw_text(prompt, dialog_x + 16, dialog_y + 60, 16, colors.on_surface);
    
    // Draw input field
    let input_x = dialog_x + 16;
    let input_y = dialog_y + 90;
    let input_width = dialog_width - 32;
    let input_height = 32;
    
    d.draw_rectangle(input_x, input_y, input_width, input_height, Color::WHITE);
    d.draw_rectangle_lines(input_x, input_y, input_width, input_height, colors.outline);
    d.draw_text(input_text, input_x + 8, input_y + 8, 16, colors.on_surface);
    
    // Draw cursor
    let cursor_x = input_x + 8 + d.measure_text(input_text, 16) as i32;
    d.draw_rectangle(cursor_x, input_y + 6, 2, 20, colors.primary);
    
    // Draw buttons
    let btn_width = 100;
    let btn_height = 32;
    let btn_y = dialog_y + dialog_height - btn_height - 16;
    let cancel_x = dialog_x + dialog_width - btn_width - 16;
    let ok_x = cancel_x - btn_width - 12;
    
    // OK button
    d.draw_rectangle_rounded(
        Rectangle::new(ok_x as f32, btn_y as f32, btn_width as f32, btn_height as f32),
        0.2,
        10,
        colors.primary,
    );
    d.draw_text("OK", ok_x + 35, btn_y + 8, 16, colors.on_primary);
    
    // Cancel button
    d.draw_rectangle_rounded(
        Rectangle::new(cancel_x as f32, btn_y as f32, btn_width as f32, btn_height as f32),
        0.2,
        10,
        colors.surface_variant,
    );
    d.draw_text("Cancel", cancel_x + 25, btn_y + 8, 16, colors.on_surface);
    
    (false, false)
}

pub fn is_dialog_ok_clicked(dialog: &DialogType, layout: &Layout, mouse_x: i32, mouse_y: i32) -> bool {
    match dialog {
        DialogType::None => false,
        DialogType::Confirm { .. } | DialogType::Input { .. } => {
            let dialog_width = if matches!(dialog, DialogType::Input { .. }) { 450 } else { 400 };
            let dialog_height = if matches!(dialog, DialogType::Input { .. }) { 200 } else { 180 };
            let dialog_x = (layout.window_width - dialog_width) / 2;
            let dialog_y = (layout.window_height - dialog_height) / 2;
            
            let btn_width = 100;
            let btn_height = 32;
            let btn_y = dialog_y + dialog_height - btn_height - 16;
            let cancel_x = dialog_x + dialog_width - btn_width - 16;
            let ok_x = cancel_x - btn_width - 12;
            
            mouse_x >= ok_x && mouse_x <= ok_x + btn_width
                && mouse_y >= btn_y && mouse_y <= btn_y + btn_height
        }
    }
}

pub fn is_dialog_cancel_clicked(dialog: &DialogType, layout: &Layout, mouse_x: i32, mouse_y: i32) -> bool {
    match dialog {
        DialogType::None => false,
        DialogType::Confirm { .. } | DialogType::Input { .. } => {
            let dialog_width = if matches!(dialog, DialogType::Input { .. }) { 450 } else { 400 };
            let dialog_height = if matches!(dialog, DialogType::Input { .. }) { 200 } else { 180 };
            let dialog_x = (layout.window_width - dialog_width) / 2;
            let dialog_y = (layout.window_height - dialog_height) / 2;
            
            let btn_width = 100;
            let btn_height = 32;
            let btn_y = dialog_y + dialog_height - btn_height - 16;
            let cancel_x = dialog_x + dialog_width - btn_width - 16;
            
            mouse_x >= cancel_x && mouse_x <= cancel_x + btn_width
                && mouse_y >= btn_y && mouse_y <= btn_y + btn_height
        }
    }
}

pub fn draw_notification(
    d: &mut RaylibDrawHandle,
    message: &str,
    layout: &Layout,
    colors: &ColorScheme,
    clipboard_op: Option<&ClipboardOperation>,
) {
    if message.is_empty() {
        return;
    }
    
    let width = 300;
    let height = 60;
    let x = layout.window_width - width - 16;
    let y = layout.window_height - height - layout.status_bar_height - 16;
    
    // Draw shadow
    d.draw_rectangle(x + 2, y + 2, width, height, Color::new(0, 0, 0, 80));
    
    // Draw background
    let bg_color = match clipboard_op {
        Some(ClipboardOperation::Cut) => Color::new(251, 191, 36, 255), // Amber for cut
        _ => colors.primary,
    };
    d.draw_rectangle_rounded(
        Rectangle::new(x as f32, y as f32, width as f32, height as f32),
        0.15,
        10,
        bg_color,
    );
    
    // Draw text
    d.draw_text(message, x + 16, y + 22, 16, colors.on_primary);
}
