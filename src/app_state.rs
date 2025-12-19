//! Application State Management
//! 
//! This module manages the entire application state including:
//! - Current directory and file listing
//! - Selection state
//! - Clipboard operations
//! - UI state (dialogs, menus, notifications)

use std::path::PathBuf;
use std::time::Instant;

use crate::file_system::{list_files, FileEntry};
use crate::input::{Selection, SelectionMode};
use crate::operations::Clipboard;
use crate::ui::context_menu::ContextMenu;
use crate::ui::dialogs::DialogType;

/// Main application state container
pub struct AppState {
    // === File System State ===
    /// Current directory path
    pub current_path: PathBuf,
    
    /// List of files in current directory
    pub files: Vec<FileEntry>,
    
    /// Currently selected file index
    pub selected: usize,
    
    /// Multi-selection state
    pub selection: Selection,
    
    /// Vertical scroll offset
    pub scroll_offset: usize,
    
    // === UI State ===
    /// Index of currently hovered item
    pub hover_index: Option<usize>,
    
    /// Context menu state
    pub context_menu: ContextMenu,
    
    /// Active dialog
    pub dialog: DialogType,
    
    /// Text input for dialogs
    pub dialog_input: String,
    
    // === Clipboard State ===
    /// Clipboard for copy/cut operations
    pub clipboard: Clipboard,
    
    // === Interaction State ===
    /// Timestamp of last mouse click
    pub last_click_time: Instant,
    
    /// Index of last clicked item (for double-click detection)
    pub last_click_index: Option<usize>,
    
    // === Notification State ===
    /// Current notification message
    pub notification: String,
    
    /// Timestamp when notification was shown
    pub notification_time: Instant,
}

impl AppState {
    /// Creates a new AppState with default values
    pub fn new() -> Self {
        let current_path = std::env::current_dir().unwrap_or_else(|_| ".".into());
        let files = list_files(current_path.to_str().unwrap());
        
        Self {
            current_path,
            files,
            selected: 0,
            selection: Selection {
                indices: vec![0],
                mode: SelectionMode::Single,
            },
            scroll_offset: 0,
            hover_index: None,
            clipboard: Clipboard::new(),
            context_menu: ContextMenu::new(),
            dialog: DialogType::None,
            dialog_input: String::new(),
            last_click_time: Instant::now(),
            last_click_index: None,
            notification: String::new(),
            notification_time: Instant::now(),
        }
    }
    
    /// Refreshes the file list for the current directory
    pub fn refresh_files(&mut self) {
        self.files = list_files(self.current_path.to_str().unwrap());
        self.selected = 0;
        self.selection = Selection {
            indices: vec![if self.files.is_empty() { 0 } else { 0 }],
            mode: SelectionMode::Single,
        };
        self.scroll_offset = 0;
    }
    
    /// Shows a notification message to the user
    pub fn show_notification(&mut self, message: &str) {
        self.notification = message.to_string();
        self.notification_time = Instant::now();
    }
    
    /// Clears the current notification
    pub fn clear_notification(&mut self) {
        self.notification.clear();
    }
    
    /// Returns true if a dialog is currently open
    pub fn has_active_dialog(&self) -> bool {
        !matches!(self.dialog, DialogType::None)
    }
    
    /// Closes any open dialog
    pub fn close_dialog(&mut self) {
        self.dialog = DialogType::None;
        self.dialog_input.clear();
    }
    
    /// Gets the currently selected file paths
    pub fn get_selected_paths(&self) -> Vec<PathBuf> {
        self.selection.indices.iter()
            .filter_map(|&i| {
                if i < self.files.len() {
                    let mut path = self.current_path.clone();
                    path.push(&self.files[i].name);
                    Some(path)
                } else {
                    None
                }
            })
            .collect()
    }
    
    /// Returns true if there is at least one selected item
    pub fn has_selection(&self) -> bool {
        !self.selection.indices.is_empty()
    }
    
    /// Returns the number of selected items
    pub fn selection_count(&self) -> usize {
        self.selection.indices.len()
    }
}

impl Default for AppState {
    fn default() -> Self {
        Self::new()
    }
}
