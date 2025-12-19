//! Toolbar Component
//! 
//! Displays the column headers for the file list

use raylib::prelude::*;

use crate::ui::styles::{ColorScheme, ColumnConfig, Layout};

/// Draws the toolbar with column headers
pub fn draw_toolbar(d: &mut RaylibDrawHandle, layout: &Layout, colors: &ColorScheme) {
    let toolbar_y = layout.padding + layout.header_height;

    // Draw background
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
    d.draw_text(
        "Modified",
        columns.modified_x,
        header_y,
        16,
        colors.on_surface_variant,
    );

    // Draw bottom border
    d.draw_rectangle(
        layout.padding,
        toolbar_y + layout.toolbar_height - 1,
        layout.list_width(),
        1,
        colors.outline,
    );
}
