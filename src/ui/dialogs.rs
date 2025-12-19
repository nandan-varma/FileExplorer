//! Dialog Components
//! 
//! Provides modal dialogs for user input and confirmation

use raylib::prelude::*;

use crate::constants::*;
use crate::ui::context_menu::ContextMenuAction;
use crate::ui::styles::{ColorScheme, Layout};

/// Types of dialogs that can be displayed
#[derive(Debug, Clone, PartialEq)]
pub enum DialogType {
    /// No dialog is shown
    None,
    
    /// Confirmation dialog with OK/Cancel buttons
    Confirm {
        title: String,
        message: String,
        action: ContextMenuAction,
    },
    
    /// Input dialog with text field and OK/Cancel buttons
    Input {
        title: String,
        prompt: String,
        action: ContextMenuAction,
        default_value: String,
    },
}

/// Renders a dialog on screen
pub fn draw_dialog(
    d: &mut RaylibDrawHandle,
    dialog: &DialogType,
    layout: &Layout,
    colors: &ColorScheme,
    input_text: &str,
) {
    match dialog {
        DialogType::None => {}
        DialogType::Confirm { title, message, .. } => {
            draw_confirm_dialog(d, title, message, layout, colors);
        }
        DialogType::Input { title, prompt, .. } => {
            draw_input_dialog(d, title, prompt, input_text, layout, colors);
        }
    }
}

/// Draws a confirmation dialog
fn draw_confirm_dialog(
    d: &mut RaylibDrawHandle,
    title: &str,
    message: &str,
    layout: &Layout,
    colors: &ColorScheme,
) {
    let dialog_x = (layout.window_width - CONFIRM_DIALOG_WIDTH) / 2;
    let dialog_y = (layout.window_height - CONFIRM_DIALOG_HEIGHT) / 2;

    // Draw modal overlay
    draw_modal_overlay(d, layout, colors);

    // Draw dialog box
    draw_dialog_box(d, dialog_x, dialog_y, CONFIRM_DIALOG_WIDTH, CONFIRM_DIALOG_HEIGHT, colors);

    // Draw title bar
    draw_title_bar(d, title, dialog_x, dialog_y, CONFIRM_DIALOG_WIDTH, colors);

    // Draw message
    d.draw_text(message, dialog_x + 16, dialog_y + 60, 16, colors.on_surface);

    // Draw buttons
    draw_dialog_buttons(d, dialog_x, dialog_y, CONFIRM_DIALOG_WIDTH, CONFIRM_DIALOG_HEIGHT, colors);
}

/// Draws an input dialog
fn draw_input_dialog(
    d: &mut RaylibDrawHandle,
    title: &str,
    prompt: &str,
    input_text: &str,
    layout: &Layout,
    colors: &ColorScheme,
) {
    let dialog_x = (layout.window_width - INPUT_DIALOG_WIDTH) / 2;
    let dialog_y = (layout.window_height - INPUT_DIALOG_HEIGHT) / 2;

    // Draw modal overlay
    draw_modal_overlay(d, layout, colors);

    // Draw dialog box
    draw_dialog_box(d, dialog_x, dialog_y, INPUT_DIALOG_WIDTH, INPUT_DIALOG_HEIGHT, colors);

    // Draw title bar
    draw_title_bar(d, title, dialog_x, dialog_y, INPUT_DIALOG_WIDTH, colors);

    // Draw prompt
    d.draw_text(prompt, dialog_x + 16, dialog_y + 60, 16, colors.on_surface);

    // Draw input field
    draw_input_field(d, dialog_x, dialog_y, INPUT_DIALOG_WIDTH, input_text, colors);

    // Draw buttons
    draw_dialog_buttons(d, dialog_x, dialog_y, INPUT_DIALOG_WIDTH, INPUT_DIALOG_HEIGHT, colors);
}

/// Draws the modal overlay (darkened background)
fn draw_modal_overlay(d: &mut RaylibDrawHandle, layout: &Layout, _colors: &ColorScheme) {
    d.draw_rectangle(
        0,
        0,
        layout.window_width,
        layout.window_height,
        Color::new(0, 0, 0, 128),
    );
}

/// Draws the dialog box with shadow
fn draw_dialog_box(
    d: &mut RaylibDrawHandle,
    x: i32,
    y: i32,
    width: i32,
    height: i32,
    colors: &ColorScheme,
) {
    // Draw shadow
    d.draw_rectangle(x + 4, y + 4, width, height, Color::new(0, 0, 0, 100));

    // Draw background
    d.draw_rectangle(x, y, width, height, colors.surface);
    d.draw_rectangle_lines(x, y, width, height, colors.outline);
}

/// Draws the title bar
fn draw_title_bar(
    d: &mut RaylibDrawHandle,
    title: &str,
    x: i32,
    y: i32,
    width: i32,
    colors: &ColorScheme,
) {
    d.draw_rectangle(x, y, width, 40, colors.primary);
    d.draw_text(title, x + 16, y + 12, 18, colors.on_primary);
}

/// Draws the input field
fn draw_input_field(
    d: &mut RaylibDrawHandle,
    dialog_x: i32,
    dialog_y: i32,
    dialog_width: i32,
    text: &str,
    colors: &ColorScheme,
) {
    let input_x = dialog_x + 16;
    let input_y = dialog_y + 90;
    let input_width = dialog_width - 32;
    let input_height = 32;

    // Draw input box
    d.draw_rectangle(input_x, input_y, input_width, input_height, Color::WHITE);
    d.draw_rectangle_lines(input_x, input_y, input_width, input_height, colors.outline);
    
    // Draw text
    d.draw_text(text, input_x + 8, input_y + 8, 16, colors.on_surface);

    // Draw cursor
    let cursor_x = input_x + 8 + d.measure_text(text, 16) as i32;
    d.draw_rectangle(cursor_x, input_y + 6, 2, 20, colors.primary);
}

/// Draws OK and Cancel buttons
fn draw_dialog_buttons(
    d: &mut RaylibDrawHandle,
    dialog_x: i32,
    dialog_y: i32,
    dialog_width: i32,
    dialog_height: i32,
    colors: &ColorScheme,
) {
    let btn_y = dialog_y + dialog_height - DIALOG_BUTTON_HEIGHT - 16;
    let cancel_x = dialog_x + dialog_width - DIALOG_BUTTON_WIDTH - 16;
    let ok_x = cancel_x - DIALOG_BUTTON_WIDTH - DIALOG_BUTTON_SPACING;

    // OK button
    d.draw_rectangle_rounded(
        Rectangle::new(
            ok_x as f32,
            btn_y as f32,
            DIALOG_BUTTON_WIDTH as f32,
            DIALOG_BUTTON_HEIGHT as f32,
        ),
        0.2,
        10,
        colors.primary,
    );
    d.draw_text(BUTTON_LABEL_OK, ok_x + 35, btn_y + 8, 16, colors.on_primary);

    // Cancel button
    d.draw_rectangle_rounded(
        Rectangle::new(
            cancel_x as f32,
            btn_y as f32,
            DIALOG_BUTTON_WIDTH as f32,
            DIALOG_BUTTON_HEIGHT as f32,
        ),
        0.2,
        10,
        colors.surface_variant,
    );
    d.draw_text(
        BUTTON_LABEL_CANCEL,
        cancel_x + 25,
        btn_y + 8,
        16,
        colors.on_surface,
    );
}

/// Checks if the OK button was clicked
pub fn is_ok_button_clicked(dialog: &DialogType, layout: &Layout, mouse_x: i32, mouse_y: i32) -> bool {
    if matches!(dialog, DialogType::None) {
        return false;
    }

    let (dialog_width, dialog_height) = get_dialog_dimensions(dialog);
    let dialog_x = (layout.window_width - dialog_width) / 2;
    let dialog_y = (layout.window_height - dialog_height) / 2;

    let btn_y = dialog_y + dialog_height - DIALOG_BUTTON_HEIGHT - 16;
    let cancel_x = dialog_x + dialog_width - DIALOG_BUTTON_WIDTH - 16;
    let ok_x = cancel_x - DIALOG_BUTTON_WIDTH - DIALOG_BUTTON_SPACING;

    mouse_x >= ok_x
        && mouse_x <= ok_x + DIALOG_BUTTON_WIDTH
        && mouse_y >= btn_y
        && mouse_y <= btn_y + DIALOG_BUTTON_HEIGHT
}

/// Checks if the Cancel button was clicked
pub fn is_cancel_button_clicked(
    dialog: &DialogType,
    layout: &Layout,
    mouse_x: i32,
    mouse_y: i32,
) -> bool {
    if matches!(dialog, DialogType::None) {
        return false;
    }

    let (dialog_width, dialog_height) = get_dialog_dimensions(dialog);
    let dialog_x = (layout.window_width - dialog_width) / 2;
    let dialog_y = (layout.window_height - dialog_height) / 2;

    let btn_y = dialog_y + dialog_height - DIALOG_BUTTON_HEIGHT - 16;
    let cancel_x = dialog_x + dialog_width - DIALOG_BUTTON_WIDTH - 16;

    mouse_x >= cancel_x
        && mouse_x <= cancel_x + DIALOG_BUTTON_WIDTH
        && mouse_y >= btn_y
        && mouse_y <= btn_y + DIALOG_BUTTON_HEIGHT
}

/// Gets the dimensions of a dialog based on its type
fn get_dialog_dimensions(dialog: &DialogType) -> (i32, i32) {
    match dialog {
        DialogType::Input { .. } => (INPUT_DIALOG_WIDTH, INPUT_DIALOG_HEIGHT),
        DialogType::Confirm { .. } => (CONFIRM_DIALOG_WIDTH, CONFIRM_DIALOG_HEIGHT),
        DialogType::None => (0, 0),
    }
}
