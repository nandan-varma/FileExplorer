//! File Explorer Application
//! 
//! A modern, feature-rich file explorer built with Raylib.
//! 
//! ## Features
//! - Breadcrumb navigation
//! - File operations (copy, cut, paste, delete, rename)
//! - Multi-selection support
//! - Context menus
//! - Keyboard shortcuts
//! - Modern UI with hover effects
//! 
//! ## Architecture
//! The application is organized into focused modules:
//! - `app_state`: Application state management
//! - `actions`: High-level application actions
//! - `event_handler`: Input event handling
//! - `file_system`: File operations and navigation
//! - `operations`: Clipboard and file manipulation
//! - `ui`: All UI components and rendering
//! - `constants`: Application-wide constants

use raylib::prelude::*;

mod actions;
mod app_state;
mod constants;
mod event_handler;
mod file_system;
mod input;
mod operations;
mod ui;

use app_state::AppState;
use constants::*;
use event_handler::*;
use ui::*;

fn main() {
    // Initialize layout and color scheme
    let layout = Layout::new();
    let colors = ColorScheme::new();

    // Initialize Raylib window
    let (mut rl, thread) = raylib::init()
        .size(layout.window_width, layout.window_height)
        .title("File Explorer")
        .build();

    rl.set_target_fps(TARGET_FPS);

    // Initialize application state
    let mut state = AppState::new();
    let visible_rows = layout.visible_rows();

    // Main application loop
    while !rl.window_should_close() {
        // === Input Handling ===
        handle_keyboard_events(&mut rl, &mut state, visible_rows);
        handle_mouse_events(&rl, &mut state, &layout, visible_rows);

        // Handle context menu selection (must check after mouse events)
        if state.context_menu.visible
            && rl.is_mouse_button_pressed(raylib::consts::MouseButton::MOUSE_BUTTON_LEFT)
        {
            let mouse_x = rl.get_mouse_x();
            let mouse_y = rl.get_mouse_y();
            let mut d = rl.begin_drawing(&thread);
            
            if let Some(action) = draw_context_menu(&mut d, &state.context_menu, &colors, mouse_x, mouse_y) {
                drop(d); // Release draw handle before mutating state
                handle_context_menu_action(&mut state, action);
            }
        }

        // Clear old notifications
        if !state.notification.is_empty()
            && state.notification_time.elapsed().as_secs() > NOTIFICATION_DURATION_SECS
        {
            state.clear_notification();
        }

        // Clear search buffer if expired
        state.clear_search_buffer_if_expired();

        // === Rendering ===
        let mut d = rl.begin_drawing(&thread);
        d.clear_background(colors.background);

        // Draw main UI components
        draw_header(&mut d, &state.current_path, &layout, &colors);
        draw_toolbar(&mut d, &layout, &colors);
        draw_file_list(
            &mut d,
            &state.filtered_files,
            &state.file_opacities,
            &state.selection,
            state.scroll_offset,
            &layout,
            &colors,
            state.hover_index,
        );
        draw_scrollbar(&mut d, state.filtered_files.len(), state.scroll_offset, &layout, &colors);
        draw_status_bar(
            &mut d,
            &state.filtered_files,
            &state.selection,
            &layout,
            &colors,
            state.search_active,
            &format!("{:?}", state.sort_order),
        );

        // Draw notification if present
        if !state.notification.is_empty() {
            let clipboard_op = if !state.clipboard.is_empty() {
                Some(&state.clipboard.operation)
            } else {
                None
            };
            draw_notification(&mut d, &state.notification, &layout, &colors, clipboard_op);
        }

        // Draw context menu if visible
        if state.context_menu.visible {
            let mouse_x = d.get_mouse_x();
            let mouse_y = d.get_mouse_y();
            draw_context_menu(&mut d, &state.context_menu, &colors, mouse_x, mouse_y);
        }

        // Draw dialog if active
        if state.has_active_dialog() {
            draw_dialog(&mut d, &state.dialog, &layout, &colors, &state.dialog_input);
        }
    }
}
