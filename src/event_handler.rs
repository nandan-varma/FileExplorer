//! Event Handler Module
//! 
//! Handles all user input events including keyboard shortcuts,
//! mouse clicks, and dialog interactions

use raylib::prelude::*;

use crate::actions::*;
use crate::app_state::AppState;
use crate::constants::*;
use crate::ui::context_menu::ContextMenuAction;
use crate::ui::dialogs::DialogType;
use crate::ui::{
    get_clicked_index, get_hover_index, is_back_button_clicked, is_cancel_button_clicked,
    is_ok_button_clicked,
};
use crate::ui::styles::Layout;

/// Handles all keyboard events
pub fn handle_keyboard_events(rl: &mut RaylibHandle, state: &mut AppState, visible_rows: usize) {
    let ctrl = rl.is_key_down(KeyboardKey::KEY_LEFT_CONTROL)
        || rl.is_key_down(KeyboardKey::KEY_RIGHT_CONTROL);

    if state.has_active_dialog() {
        handle_dialog_keyboard(rl, state);
    } else {
        handle_navigation_keyboard(rl, state, visible_rows);
        handle_shortcut_keyboard(rl, state, ctrl);
    }
}

/// Handles keyboard input for dialogs
fn handle_dialog_keyboard(rl: &mut RaylibHandle, state: &mut AppState) {
    // Handle text input for input dialogs
    if matches!(state.dialog, DialogType::Input { .. }) {
        handle_text_input(rl, state);
    }

    // Handle Enter key
    if rl.is_key_pressed(KeyboardKey::KEY_ENTER) {
        handle_dialog_confirm(state);
    }

    // Handle Escape key
    if rl.is_key_pressed(KeyboardKey::KEY_ESCAPE) {
        state.close_dialog();
    }
}

/// Handles text input for input dialogs
fn handle_text_input(rl: &mut RaylibHandle, state: &mut AppState) {
    // Handle character input
    if let Some(c) = rl.get_char_pressed() {
        if c.is_ascii() && !c.is_control() {
            state.dialog_input.push(c as u8 as char);
        }
    }

    // Handle backspace
    if rl.is_key_pressed(KeyboardKey::KEY_BACKSPACE) && !state.dialog_input.is_empty() {
        state.dialog_input.pop();
    }
}

/// Handles dialog confirmation
fn handle_dialog_confirm(state: &mut AppState) {
    match state.dialog.clone() {
        DialogType::Confirm { action, .. } => {
            if action == ContextMenuAction::Delete {
                confirm_delete(state);
            }
            state.close_dialog();
        }
        DialogType::Input { action, .. } => {
            match action {
                ContextMenuAction::Rename => confirm_rename(state),
                ContextMenuAction::NewFolder => confirm_new_folder(state),
                _ => {}
            }
            state.close_dialog();
        }
        DialogType::None => {}
    }
}

/// Handles navigation keyboard shortcuts
fn handle_navigation_keyboard(rl: &RaylibHandle, state: &mut AppState, visible_rows: usize) {
    if rl.is_key_pressed(KeyboardKey::KEY_DOWN) {
        move_selection_down(state, visible_rows);
    }
    if rl.is_key_pressed(KeyboardKey::KEY_UP) {
        move_selection_up(state);
    }
    if rl.is_key_pressed(KeyboardKey::KEY_ENTER) {
        enter_selected(state);
        state.context_menu.hide();
    }
    if rl.is_key_pressed(KeyboardKey::KEY_BACKSPACE) {
        navigate_up(state);
    }
    if rl.is_key_pressed(KeyboardKey::KEY_ESCAPE) {
        state.context_menu.hide();
    }
}

/// Handles keyboard shortcuts
fn handle_shortcut_keyboard(rl: &RaylibHandle, state: &mut AppState, ctrl: bool) {
    if ctrl && rl.is_key_pressed(KeyboardKey::KEY_C) {
        copy_selected(state);
    }
    if ctrl && rl.is_key_pressed(KeyboardKey::KEY_X) {
        cut_selected(state);
    }
    if ctrl && rl.is_key_pressed(KeyboardKey::KEY_V) {
        paste(state);
    }
    if ctrl && rl.is_key_pressed(KeyboardKey::KEY_A) {
        select_all(state);
    }
    if ctrl && rl.is_key_pressed(KeyboardKey::KEY_N) {
        initiate_new_folder(state);
    }
    if rl.is_key_pressed(KeyboardKey::KEY_DELETE) {
        if state.has_selection() {
            initiate_delete(state);
        }
    }
    if rl.is_key_pressed(KeyboardKey::KEY_F2) {
        initiate_rename(state);
    }
}

/// Handles all mouse events
pub fn handle_mouse_events(
    rl: &RaylibHandle,
    state: &mut AppState,
    layout: &Layout,
    visible_rows: usize,
) {
    let mouse_x = rl.get_mouse_x();
    let mouse_y = rl.get_mouse_y();

    // Update hover state (only if no dialog)
    if !state.has_active_dialog() {
        state.hover_index = get_hover_index(
            mouse_x,
            mouse_y,
            layout,
            state.scroll_offset,
            state.files.len(),
        );
    }

    handle_left_click(rl, state, layout, mouse_x, mouse_y);
    handle_right_click(rl, state, layout, mouse_x, mouse_y);
    handle_mouse_wheel(rl, state, visible_rows);
}

/// Handles left mouse button clicks
fn handle_left_click(
    rl: &RaylibHandle,
    state: &mut AppState,
    layout: &Layout,
    mouse_x: i32,
    mouse_y: i32,
) {
    if !rl.is_mouse_button_pressed(raylib::consts::MouseButton::MOUSE_BUTTON_LEFT) {
        return;
    }

    if state.has_active_dialog() {
        handle_dialog_click(state, layout, mouse_x, mouse_y);
    } else {
        handle_ui_click(rl, state, layout, mouse_x, mouse_y);
    }
}

/// Handles clicks on dialog buttons
fn handle_dialog_click(state: &mut AppState, layout: &Layout, mouse_x: i32, mouse_y: i32) {
    if is_ok_button_clicked(&state.dialog, layout, mouse_x, mouse_y) {
        handle_dialog_confirm(state);
    } else if is_cancel_button_clicked(&state.dialog, layout, mouse_x, mouse_y) {
        state.close_dialog();
    }
}

/// Handles clicks on UI elements (file list, buttons, etc.)
fn handle_ui_click(
    rl: &RaylibHandle,
    state: &mut AppState,
    layout: &Layout,
    mouse_x: i32,
    mouse_y: i32,
) {
    state.context_menu.hide();

    if is_back_button_clicked(mouse_x, mouse_y, layout) {
        navigate_up(state);
    } else if let Some(idx) = get_clicked_index(mouse_x, mouse_y, layout, state.scroll_offset) {
        if idx < state.files.len() {
            let shift = rl.is_key_down(KeyboardKey::KEY_LEFT_SHIFT);
            let ctrl = rl.is_key_down(KeyboardKey::KEY_LEFT_CONTROL)
                || rl.is_key_down(KeyboardKey::KEY_RIGHT_CONTROL);

            let is_double_click = handle_item_click(state, idx, shift, ctrl);

            if is_double_click {
                enter_selected(state);
            }
        }
    }
}

/// Handles right mouse button clicks
fn handle_right_click(
    rl: &RaylibHandle,
    state: &mut AppState,
    layout: &Layout,
    mouse_x: i32,
    mouse_y: i32,
) {
    if !rl.is_mouse_button_pressed(raylib::consts::MouseButton::MOUSE_BUTTON_RIGHT) {
        return;
    }

    if state.has_active_dialog() {
        return;
    }

    // Select item under cursor if not already selected
    if let Some(idx) = get_clicked_index(mouse_x, mouse_y, layout, state.scroll_offset) {
        if idx < state.files.len() && !state.selection.indices.contains(&idx) {
            handle_item_click(state, idx, false, false);
        }
    }

    // Show context menu
    state.context_menu.show(
        mouse_x,
        mouse_y,
        state.has_selection(),
        !state.clipboard.is_empty(),
    );
}

/// Handles mouse wheel scrolling
fn handle_mouse_wheel(rl: &RaylibHandle, state: &mut AppState, visible_rows: usize) {
    if state.has_active_dialog() {
        return;
    }

    let wheel = rl.get_mouse_wheel_move();
    if wheel != 0.0 {
        if wheel > 0.0 {
            scroll_up(state, WHEEL_SCROLL_AMOUNT);
        } else {
            let max_scroll = state.files.len().saturating_sub(visible_rows);
            scroll_down(state, WHEEL_SCROLL_AMOUNT, max_scroll);
        }
    }
}

/// Handles context menu item selection
pub fn handle_context_menu_action(state: &mut AppState, action: ContextMenuAction) {
    match action {
        ContextMenuAction::Open => enter_selected(state),
        ContextMenuAction::Copy => copy_selected(state),
        ContextMenuAction::Cut => cut_selected(state),
        ContextMenuAction::Paste => paste(state),
        ContextMenuAction::Delete => initiate_delete(state),
        ContextMenuAction::Rename => initiate_rename(state),
        ContextMenuAction::NewFolder => initiate_new_folder(state),
        _ => {}
    }
    state.context_menu.hide();
}
