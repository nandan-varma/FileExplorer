//! Notification Component

use raylib::prelude::*;

use crate::constants::*;
use crate::operations::ClipboardOperation;
use crate::ui::styles::{ColorScheme, Layout};

/// Draws a notification toast at the bottom-right
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

    let x = layout.window_width - NOTIFICATION_WIDTH - 16;
    let y = layout.window_height - NOTIFICATION_HEIGHT - layout.status_bar_height - 16;

    draw_notification_shadow(d, x, y);
    draw_notification_background(d, x, y, clipboard_op, colors);
    draw_notification_text(d, message, x, y, colors);
}

/// Draws the notification shadow
fn draw_notification_shadow(d: &mut RaylibDrawHandle, x: i32, y: i32) {
    d.draw_rectangle(
        x + 2,
        y + 2,
        NOTIFICATION_WIDTH,
        NOTIFICATION_HEIGHT,
        Color::new(0, 0, 0, 80),
    );
}

/// Draws the notification background
fn draw_notification_background(
    d: &mut RaylibDrawHandle,
    x: i32,
    y: i32,
    clipboard_op: Option<&ClipboardOperation>,
    colors: &ColorScheme,
) {
    let bg_color = match clipboard_op {
        Some(ClipboardOperation::Cut) => Color::new(251, 191, 36, 255), // Amber for cut
        _ => colors.primary,
    };

    d.draw_rectangle_rounded(
        Rectangle::new(
            x as f32,
            y as f32,
            NOTIFICATION_WIDTH as f32,
            NOTIFICATION_HEIGHT as f32,
        ),
        0.15,
        10,
        bg_color,
    );
}

/// Draws the notification text
fn draw_notification_text(
    d: &mut RaylibDrawHandle,
    message: &str,
    x: i32,
    y: i32,
    colors: &ColorScheme,
) {
    d.draw_text(message, x + 16, y + 22, 16, colors.on_primary);
}
