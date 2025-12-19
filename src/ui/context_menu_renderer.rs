//! Context Menu Rendering

use raylib::prelude::*;

use crate::constants::*;
use crate::ui::context_menu::{ContextMenu, ContextMenuAction};
use crate::ui::styles::ColorScheme;

/// Draws the context menu and returns the action if an item is hovered
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

    let height = menu.get_height();

    draw_menu_shadow(d, menu.x, menu.y, height);
    draw_menu_background(d, menu.x, menu.y, height, colors);

    draw_menu_items(d, menu, colors, mouse_x, mouse_y)
}

/// Draws the menu shadow
fn draw_menu_shadow(d: &mut RaylibDrawHandle, x: i32, y: i32, height: i32) {
    d.draw_rectangle(
        x + 4,
        y + 4,
        CONTEXT_MENU_WIDTH,
        height,
        Color::new(0, 0, 0, 50),
    );
}

/// Draws the menu background
fn draw_menu_background(
    d: &mut RaylibDrawHandle,
    x: i32,
    y: i32,
    height: i32,
    colors: &ColorScheme,
) {
    d.draw_rectangle(x, y, CONTEXT_MENU_WIDTH, height, colors.surface);
    d.draw_rectangle_lines(x, y, CONTEXT_MENU_WIDTH, height, colors.outline);
}

/// Draws menu items and returns hovered action
fn draw_menu_items(
    d: &mut RaylibDrawHandle,
    menu: &ContextMenu,
    colors: &ColorScheme,
    mouse_x: i32,
    mouse_y: i32,
) -> Option<ContextMenuAction> {
    let mut action = None;

    for (i, (label, item_action, enabled)) in menu.items.iter().enumerate() {
        let item_y = menu.y + 4 + (i as i32 * CONTEXT_MENU_ITEM_HEIGHT);

        // Handle separators
        if label == MENU_SEPARATOR {
            draw_separator(d, menu.x, item_y, colors);
            continue;
        }

        // Check if hovered
        let is_hovered = is_item_hovered(mouse_x, mouse_y, menu.x, item_y, *enabled);

        if is_hovered {
            draw_hover_highlight(d, menu.x, item_y, colors);
            action = Some(*item_action);
        }

        draw_item_text(d, label, menu.x, item_y, *enabled, colors);
    }

    action
}

/// Checks if a menu item is hovered
fn is_item_hovered(mouse_x: i32, mouse_y: i32, menu_x: i32, item_y: i32, enabled: bool) -> bool {
    enabled
        && mouse_x >= menu_x
        && mouse_x <= menu_x + CONTEXT_MENU_WIDTH
        && mouse_y >= item_y
        && mouse_y < item_y + CONTEXT_MENU_ITEM_HEIGHT
}

/// Draws hover highlight for a menu item
fn draw_hover_highlight(d: &mut RaylibDrawHandle, menu_x: i32, item_y: i32, colors: &ColorScheme) {
    d.draw_rectangle(
        menu_x + 2,
        item_y,
        CONTEXT_MENU_WIDTH - 4,
        CONTEXT_MENU_ITEM_HEIGHT,
        colors.hover,
    );
}

/// Draws a separator line
fn draw_separator(d: &mut RaylibDrawHandle, menu_x: i32, item_y: i32, colors: &ColorScheme) {
    d.draw_rectangle(
        menu_x + 8,
        item_y + 13,
        CONTEXT_MENU_WIDTH - 16,
        1,
        colors.outline,
    );
}

/// Draws menu item text
fn draw_item_text(
    d: &mut RaylibDrawHandle,
    label: &str,
    menu_x: i32,
    item_y: i32,
    enabled: bool,
    colors: &ColorScheme,
) {
    let text_color = if enabled {
        colors.on_surface
    } else {
        colors.on_surface_variant
    };

    d.draw_text(label, menu_x + 12, item_y + 6, 16, text_color);
}
