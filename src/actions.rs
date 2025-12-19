//! Application Actions
//! 
//! This module contains all the high-level actions that can be performed
//! in the file explorer, such as navigation, file operations, and selection management.

use std::cmp;
use std::time::Instant;

use crate::app_state::AppState;
use crate::constants::*;
use crate::file_system::{get_parent_path, navigate_to};
use crate::input::{Selection, SelectionMode};
use crate::operations::{create_folder, delete_file, get_unique_name, paste_items, rename_file};
use crate::ui::context_menu::ContextMenuAction;
use crate::ui::dialogs::DialogType;

// === Navigation Actions ===

/// Navigates to a subfolder in the current directory
pub fn navigate_to_folder(state: &mut AppState, folder_name: &str) {
    if let Some(new_path) = navigate_to(&state.current_path, folder_name) {
        state.current_path = new_path;
        state.refresh_files();
    }
}

/// Navigates to the parent directory
pub fn navigate_up(state: &mut AppState) {
    if let Some(parent) = get_parent_path(&state.current_path) {
        state.current_path = parent;
        state.refresh_files();
    }
}

/// Opens the currently selected folder (if it's a directory)
pub fn enter_selected(state: &mut AppState) {
    if !state.files.is_empty() && state.selected < state.files.len() {
        let selected_entry = &state.files[state.selected];
        if selected_entry.is_dir {
            navigate_to_folder(state, &selected_entry.name.clone());
        }
    }
}

// === Selection Actions ===

/// Moves the selection down by one item
pub fn move_selection_down(state: &mut AppState, visible_rows: usize) {
    if state.selected + 1 < state.files.len() {
        state.selected += 1;
        
        // Auto-scroll if needed
        if state.selected >= state.scroll_offset + visible_rows {
            state.scroll_offset = cmp::min(
                state.scroll_offset + 1,
                state.files.len().saturating_sub(visible_rows),
            );
        }
        
        state.selection = Selection {
            indices: vec![state.selected],
            mode: SelectionMode::Single,
        };
    }
}

/// Moves the selection up by one item
pub fn move_selection_up(state: &mut AppState) {
    if state.selected > 0 {
        state.selected -= 1;
        
        // Auto-scroll if needed
        if state.selected < state.scroll_offset {
            state.scroll_offset = state.scroll_offset.saturating_sub(1);
        }
        
        state.selection = Selection {
            indices: vec![state.selected],
            mode: SelectionMode::Single,
        };
    }
}

/// Handles a mouse click on a file item
/// Returns true if this was a double-click
pub fn handle_item_click(state: &mut AppState, idx: usize, shift: bool, ctrl: bool) -> bool {
    let now = Instant::now();
    let is_double_click = state.last_click_index == Some(idx)
        && now.duration_since(state.last_click_time).as_millis() < DOUBLE_CLICK_THRESHOLD_MS;

    state.last_click_time = now;
    state.last_click_index = Some(idx);

    if shift {
        // Range selection
        handle_range_selection(state, idx);
    } else if ctrl {
        // Multi selection (toggle)
        handle_multi_selection(state, idx);
    } else {
        // Single selection
        state.selection = Selection {
            indices: vec![idx],
            mode: SelectionMode::Single,
        };
    }
    
    state.selected = idx;
    is_double_click
}

/// Handles range selection (Shift+Click)
fn handle_range_selection(state: &mut AppState, end_idx: usize) {
    let start = *state.selection.indices.first().unwrap_or(&state.selected);
    let range = if start <= end_idx {
        (start..=end_idx).collect()
    } else {
        (end_idx..=start).collect()
    };
    state.selection = Selection {
        indices: range,
        mode: SelectionMode::Range,
    };
}

/// Handles multi-selection (Ctrl+Click)
fn handle_multi_selection(state: &mut AppState, idx: usize) {
    let mut indices = state.selection.indices.clone();
    
    // Toggle selection
    if let Some(pos) = indices.iter().position(|&i| i == idx) {
        indices.remove(pos);
    } else {
        indices.push(idx);
    }
    
    // Ensure at least one item is selected
    if indices.is_empty() {
        indices.push(idx);
    }
    
    state.selection = Selection {
        indices,
        mode: SelectionMode::Multi,
    };
}

/// Selects all items in the current directory
pub fn select_all(state: &mut AppState) {
    state.selection = Selection {
        indices: (0..state.files.len()).collect(),
        mode: SelectionMode::Multi,
    };
    if !state.files.is_empty() {
        state.selected = 0;
    }
}

// === Clipboard Actions ===

/// Copies the selected items to the clipboard
pub fn copy_selected(state: &mut AppState) {
    let paths = state.get_selected_paths();
    
    if !paths.is_empty() {
        state.clipboard.copy(paths, state.current_path.clone());
        state.show_notification(&format!("Copied {} item(s)", state.clipboard.items.len()));
    }
}

/// Cuts the selected items to the clipboard
pub fn cut_selected(state: &mut AppState) {
    let paths = state.get_selected_paths();
    
    if !paths.is_empty() {
        state.clipboard.cut(paths, state.current_path.clone());
        state.show_notification(&format!("Cut {} item(s)", state.clipboard.items.len()));
    }
}

/// Pastes items from the clipboard to the current directory
pub fn paste(state: &mut AppState) {
    if !state.clipboard.is_empty() {
        match paste_items(&state.clipboard, &state.current_path) {
            Ok(count) => {
                state.show_notification(&format!("Pasted {} item(s)", count));
                state.clipboard.clear();
                state.refresh_files();
            }
            Err(e) => {
                state.show_notification(&format!("Error: {}", e));
            }
        }
    }
}

// === File Operation Actions ===

/// Initiates the delete operation (shows confirmation dialog)
pub fn initiate_delete(state: &mut AppState) {
    state.dialog = DialogType::Confirm {
        title: DIALOG_TITLE_DELETE.to_string(),
        message: format!("Delete {} item(s)?", state.selection_count()),
        action: ContextMenuAction::Delete,
    };
}

/// Confirms and executes the delete operation
pub fn confirm_delete(state: &mut AppState) {
    let mut success_count = 0;
    
    for &i in &state.selection.indices {
        if i < state.files.len() {
            let mut path = state.current_path.clone();
            path.push(&state.files[i].name);
            
            if delete_file(&path).is_ok() {
                success_count += 1;
            }
        }
    }
    
    state.show_notification(&format!("Deleted {} item(s)", success_count));
    state.refresh_files();
}

/// Initiates the rename operation (shows input dialog)
pub fn initiate_rename(state: &mut AppState) {
    if state.selection.indices.len() == 1 && state.selected < state.files.len() {
        state.dialog_input = state.files[state.selected].name.clone();
        state.dialog = DialogType::Input {
            title: DIALOG_TITLE_RENAME.to_string(),
            prompt: DIALOG_PROMPT_RENAME.to_string(),
            action: ContextMenuAction::Rename,
            default_value: state.dialog_input.clone(),
        };
    }
}

/// Confirms and executes the rename operation
pub fn confirm_rename(state: &mut AppState) {
    if !state.dialog_input.is_empty() && state.selected < state.files.len() {
        let mut old_path = state.current_path.clone();
        old_path.push(&state.files[state.selected].name);

        match rename_file(&old_path, &state.dialog_input) {
            Ok(_) => {
                state.show_notification("Renamed successfully");
                state.refresh_files();
            }
            Err(e) => {
                state.show_notification(&format!("Error: {}", e));
            }
        }
    }
}

/// Initiates the new folder operation (shows input dialog)
pub fn initiate_new_folder(state: &mut AppState) {
    state.dialog_input = DEFAULT_NEW_FOLDER_NAME.to_string();
    state.dialog = DialogType::Input {
        title: DIALOG_TITLE_NEW_FOLDER.to_string(),
        prompt: DIALOG_PROMPT_NEW_FOLDER.to_string(),
        action: ContextMenuAction::NewFolder,
        default_value: state.dialog_input.clone(),
    };
}

/// Confirms and executes the new folder operation
pub fn confirm_new_folder(state: &mut AppState) {
    if !state.dialog_input.is_empty() {
        let unique_name = get_unique_name(&state.current_path, &state.dialog_input);
        
        match create_folder(&state.current_path, &unique_name) {
            Ok(_) => {
                state.show_notification("Folder created");
                state.refresh_files();
            }
            Err(e) => {
                state.show_notification(&format!("Error: {}", e));
            }
        }
    }
}

// === Scrolling Actions ===

/// Scrolls up by the specified amount
pub fn scroll_up(state: &mut AppState, amount: usize) {
    state.scroll_offset = state.scroll_offset.saturating_sub(amount);
}

/// Scrolls down by the specified amount
pub fn scroll_down(state: &mut AppState, amount: usize, max_scroll: usize) {
    state.scroll_offset = cmp::min(state.scroll_offset + amount, max_scroll);
}
