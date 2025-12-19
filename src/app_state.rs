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

/// File sorting options
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum SortOrder {
    NameAsc,
    NameDesc,
    SizeAsc,
    SizeDesc,
    ModifiedAsc,
    ModifiedDesc,
    TypeAsc,
    TypeDesc,
}

/// Main application state container
pub struct AppState {
    // === File System State ===
    /// Current directory path
    pub current_path: PathBuf,

    /// List of files in current directory (unsorted)
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

    // === New Productivity Features ===
    /// Whether to show hidden files
    pub show_hidden_files: bool,

    /// Current sort order
    pub sort_order: SortOrder,

    /// Search/filter text
    pub search_text: String,

    /// Cached sorted and filtered file list (includes all files, just sorted)
    pub filtered_files: Vec<FileEntry>,

    /// Opacity values for each filtered file (0.0-1.0, for hidden file display)
    pub file_opacities: Vec<f32>,

    /// Whether search is active
    pub search_active: bool,

    /// Search input buffer for type-ahead
    pub search_buffer: String,

    /// Timestamp for clearing search buffer
    pub search_buffer_time: Instant,
}

impl AppState {
    /// Creates a new AppState with default values
    pub fn new() -> Self {
        let current_path = std::env::current_dir().unwrap_or_else(|_| ".".into());
        let files = list_files(current_path.to_str().unwrap());
        let (filtered_files, file_opacities) = Self::sort_and_filter_files(&files, false, SortOrder::NameAsc, "");

        Self {
            current_path,
            files,
            filtered_files,
            file_opacities,
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
            show_hidden_files: false,
            sort_order: SortOrder::NameAsc,
            search_text: String::new(),
            search_active: false,
            search_buffer: String::new(),
            search_buffer_time: Instant::now(),
        }
    }
    
    /// Refreshes the file list for the current directory
    pub fn refresh_files(&mut self) {
        self.files = list_files(self.current_path.to_str().unwrap());
        self.update_filtered_files();
        self.adjust_selection_after_refresh();
    }

    /// Updates the filtered and sorted file list
    pub fn update_filtered_files(&mut self) {
        let (filtered_files, file_opacities) = Self::sort_and_filter_files(
            &self.files,
            self.show_hidden_files,
            self.sort_order,
            &self.search_text,
        );
        self.filtered_files = filtered_files;
        self.file_opacities = file_opacities;
    }

    /// Adjusts selection after file list changes
    fn adjust_selection_after_refresh(&mut self) {
        if self.filtered_files.is_empty() {
            self.selected = 0;
            self.selection = Selection {
                indices: vec![0],
                mode: SelectionMode::Single,
            };
        } else {
            self.selected = self.selected.min(self.filtered_files.len().saturating_sub(1));
            self.selection.indices = self.selection.indices
                .iter()
                .filter(|&&i| i < self.filtered_files.len())
                .cloned()
                .collect();

            if self.selection.indices.is_empty() {
                self.selection.indices.push(self.selected);
            }
        }
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
                if i < self.filtered_files.len() {
                    let mut path = self.current_path.clone();
                    path.push(&self.filtered_files[i].name);
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

    /// Sorts and filters the file list, returning files with opacity values
    /// All files are included but hidden files have reduced opacity
    fn sort_and_filter_files(
        files: &[FileEntry],
        show_hidden: bool,
        sort_order: SortOrder,
        search_text: &str,
    ) -> (Vec<FileEntry>, Vec<f32>) {
        let mut filtered_with_opacity: Vec<(FileEntry, f32)> = files.iter().filter_map(|file| {
            let mut opacity = 1.0;

            // Set opacity for hidden files
            if file.name.starts_with('.') {
                opacity = if show_hidden { 1.0 } else { 0.5 };
            }

            // Filter by search text (only show matching items)
            if !search_text.is_empty() {
                if !file.name.to_lowercase().contains(&search_text.to_lowercase()) {
                    return None;
                }
            }

            Some((file.clone(), opacity))
        }).collect();

        // Sort the filtered files
        filtered_with_opacity.sort_by(|(a, _), (b, _)| match sort_order {
            SortOrder::NameAsc => a.name.to_lowercase().cmp(&b.name.to_lowercase()),
            SortOrder::NameDesc => b.name.to_lowercase().cmp(&a.name.to_lowercase()),
            SortOrder::SizeAsc => a.size.cmp(&b.size),
            SortOrder::SizeDesc => b.size.cmp(&a.size),
            SortOrder::ModifiedAsc => a.modified.cmp(&b.modified),
            SortOrder::ModifiedDesc => b.modified.cmp(&a.modified),
            SortOrder::TypeAsc => a.extension.cmp(&b.extension),
            SortOrder::TypeDesc => b.extension.cmp(&a.extension),
        });

        // Always sort directories first, then files
        filtered_with_opacity.sort_by_key(|(file, _)| !file.is_dir);

        // Separate into files and opacities
        let files: Vec<FileEntry> = filtered_with_opacity.iter().map(|(f, _)| f.clone()).collect();
        let opacities: Vec<f32> = filtered_with_opacity.iter().map(|(_, o)| *o).collect();

        (files, opacities)
    }

    /// Toggles hidden files visibility
    pub fn toggle_hidden_files(&mut self) {
        self.show_hidden_files = !self.show_hidden_files;
        self.update_filtered_files();
        self.adjust_selection_after_refresh();
        self.show_notification(&format!("Hidden files {}", if self.show_hidden_files { "shown" } else { "hidden" }));
    }

    /// Changes the sort order
    pub fn set_sort_order(&mut self, sort_order: SortOrder) {
        self.sort_order = sort_order;
        self.update_filtered_files();
        self.adjust_selection_after_refresh();
    }

    /// Sets search text and updates filtered files
    pub fn set_search_text(&mut self, text: String) {
        self.search_text = text.clone();
        self.search_active = !text.is_empty();
        self.update_filtered_files();
        self.adjust_selection_after_refresh();
    }

    /// Clears search and shows all files
    pub fn clear_search(&mut self) {
        self.search_text.clear();
        self.search_active = false;
        self.update_filtered_files();
        self.adjust_selection_after_refresh();
    }

    /// Adds a character to the search buffer for type-ahead search
    pub fn add_to_search_buffer(&mut self, c: char) {
        self.search_buffer.push(c);
        self.search_buffer_time = Instant::now();
        self.set_search_text(self.search_buffer.clone());
    }

    /// Clears the search buffer if enough time has passed
    pub fn clear_search_buffer_if_expired(&mut self) {
        if self.search_buffer_time.elapsed().as_millis() > 1000 {
            self.search_buffer.clear();
        }
    }

    /// Gets the index in filtered files for a given file name
    pub fn get_filtered_index(&self, file_name: &str) -> Option<usize> {
        self.filtered_files.iter().position(|f| f.name == file_name)
    }

    /// Selects the first item that starts with the given character (type-ahead)
    pub fn select_by_character(&mut self, c: char) {
        if self.filtered_files.is_empty() {
            return;
        }

        let start_index = if self.selected < self.filtered_files.len() {
            (self.selected + 1) % self.filtered_files.len()
        } else {
            0
        };

        // Look for item starting with this character
        for i in 0..self.filtered_files.len() {
            let idx = (start_index + i) % self.filtered_files.len();
            if self.filtered_files[idx].name.to_lowercase().starts_with(&c.to_lowercase().to_string()) {
                self.selected = idx;
                self.selection = Selection {
                    indices: vec![idx],
                    mode: SelectionMode::Single,
                };
                self.ensure_selection_visible(20); // Assuming 20 visible rows
                return;
            }
        }
    }

    /// Ensures the selected item is visible in the viewport
    pub fn ensure_selection_visible(&mut self, visible_rows: usize) {
        if self.selected < self.scroll_offset {
            self.scroll_offset = self.selected;
        } else if self.selected >= self.scroll_offset + visible_rows {
            self.scroll_offset = self.selected.saturating_sub(visible_rows - 1);
        }
    }

    /// Handles improved selection logic with click-to-deselect
    pub fn handle_selection_click(&mut self, idx: usize, shift: bool, ctrl: bool, alt: bool) -> bool {
        let now = Instant::now();
        let is_double_click = self.last_click_index == Some(idx)
            && now.duration_since(self.last_click_time).as_millis() < 500;

        self.last_click_time = now;
        self.last_click_index = Some(idx);

        if shift {
            // Range selection
            self.handle_range_selection(idx);
        } else if ctrl || alt {
            // Multi selection (toggle)
            self.handle_multi_selection(idx);
        } else {
            // Single selection or deselect if already selected
            if self.selection.indices.len() == 1 && self.selection.indices[0] == idx {
                // Click on already selected item - deselect
                self.selection = Selection {
                    indices: vec![],
                    mode: SelectionMode::Single,
                };
            } else {
                // Select new item
                self.selection = Selection {
                    indices: vec![idx],
                    mode: SelectionMode::Single,
                };
            }
        }

        self.selected = idx;
        is_double_click
    }

    /// Handles range selection (Shift+Click)
    fn handle_range_selection(&mut self, end_idx: usize) {
        let start = *self.selection.indices.first().unwrap_or(&self.selected);
        let range = if start <= end_idx {
            (start..=end_idx).collect()
        } else {
            (end_idx..=start).collect()
        };
        self.selection = Selection {
            indices: range,
            mode: SelectionMode::Range,
        };
    }

    /// Handles multi-selection (Ctrl+Click)
    fn handle_multi_selection(&mut self, idx: usize) {
        let mut indices = self.selection.indices.clone();

        // Toggle selection
        if let Some(pos) = indices.iter().position(|&i| i == idx) {
            indices.remove(pos);
        } else {
            indices.push(idx);
        }

        // Ensure at least one item is selected (unless deselecting all)
        if indices.is_empty() {
            indices.push(idx);
        }

        self.selection = Selection {
            indices,
            mode: SelectionMode::Multi,
        };
    }
}

impl Default for AppState {
    fn default() -> Self {
        Self::new()
    }
}
