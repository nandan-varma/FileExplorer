use raylib::prelude::*;

// Modern color scheme
pub struct ColorScheme {
    pub background: Color,
    pub surface: Color,
    pub surface_variant: Color,
    pub primary: Color,
    pub on_primary: Color,
    pub secondary: Color,
    pub on_background: Color,
    pub on_surface: Color,
    pub on_surface_variant: Color,
    pub outline: Color,
    pub selected: Color,
    pub hover: Color,
    pub folder_color: Color,
    pub file_color: Color,
}

impl ColorScheme {
    pub fn new() -> Self {
        Self {
            background: Color::new(248, 249, 250, 255),      // Light gray background
            surface: Color::new(255, 255, 255, 255),         // White surface
            surface_variant: Color::new(243, 244, 246, 255), // Lighter gray
            primary: Color::new(59, 130, 246, 255),          // Blue
            on_primary: Color::new(255, 255, 255, 255),      // White
            secondary: Color::new(156, 163, 175, 255),       // Gray
            on_background: Color::new(17, 24, 39, 255),      // Dark gray text
            on_surface: Color::new(31, 41, 55, 255),         // Dark text
            on_surface_variant: Color::new(107, 114, 128, 255), // Medium gray
            outline: Color::new(229, 231, 235, 255),         // Light border
            selected: Color::new(219, 234, 254, 255),        // Light blue
            hover: Color::new(243, 244, 246, 255),           // Light gray hover
            folder_color: Color::new(251, 191, 36, 255),     // Amber folder
            file_color: Color::new(209, 213, 219, 255),      // Gray file
        }
    }
}

impl Default for ColorScheme {
    fn default() -> Self {
        Self::new()
    }
}

// Layout constants
pub struct Layout {
    pub window_width: i32,
    pub window_height: i32,
    pub padding: i32,
    pub header_height: i32,
    pub toolbar_height: i32,
    pub status_bar_height: i32,
    pub row_height: i32,
    pub scrollbar_width: i32,
    pub icon_size: i32,
    pub border_radius: i32,
}

impl Layout {
    pub fn new() -> Self {
        Self {
            window_width: 1000,
            window_height: 700,
            padding: 16,
            header_height: 48,
            toolbar_height: 40,
            status_bar_height: 28,
            row_height: 32,
            scrollbar_width: 12,
            icon_size: 20,
            border_radius: 6,
        }
    }
    
    pub fn visible_rows(&self) -> usize {
        let content_height = self.window_height 
            - self.header_height 
            - self.toolbar_height 
            - self.status_bar_height 
            - (self.padding * 3);
        (content_height / self.row_height) as usize
    }
    
    pub fn list_start_y(&self) -> i32 {
        self.padding + self.header_height + self.toolbar_height
    }
    
    pub fn list_width(&self) -> i32 {
        self.window_width - (self.padding * 2) - self.scrollbar_width - 8
    }
}

impl Default for Layout {
    fn default() -> Self {
        Self::new()
    }
}

// Column configuration
pub struct ColumnConfig {
    pub name_x: i32,
    pub name_width: i32,
    pub type_x: i32,
    pub type_width: i32,
    pub size_x: i32,
    pub size_width: i32,
    pub modified_x: i32,
    pub modified_width: i32,
}

impl ColumnConfig {
    pub fn new(layout: &Layout) -> Self {
        let total_width = layout.list_width();
        Self {
            name_x: layout.padding + layout.icon_size + 12,
            name_width: (total_width as f32 * 0.45) as i32,
            type_x: layout.padding + (total_width as f32 * 0.50) as i32,
            type_width: (total_width as f32 * 0.15) as i32,
            size_x: layout.padding + (total_width as f32 * 0.70) as i32,
            size_width: (total_width as f32 * 0.15) as i32,
            modified_x: layout.padding + (total_width as f32 * 0.85) as i32,
            modified_width: (total_width as f32 * 0.15) as i32,
        }
    }
}

pub fn format_file_size(size: u64) -> String {
    const KB: u64 = 1024;
    const MB: u64 = KB * 1024;
    const GB: u64 = MB * 1024;
    
    if size >= GB {
        format!("{:.2} GB", size as f64 / GB as f64)
    } else if size >= MB {
        format!("{:.2} MB", size as f64 / MB as f64)
    } else if size >= KB {
        format!("{:.2} KB", size as f64 / KB as f64)
    } else {
        format!("{} B", size)
    }
}
