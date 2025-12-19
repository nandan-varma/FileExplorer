//! Context Menu Component
//! 
//! Provides a right-click context menu with file operations

use crate::constants::*;

/// Actions that can be performed from the context menu
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum ContextMenuAction {
    Open,
    Copy,
    Cut,
    Paste,
    Delete,
    Rename,
    NewFolder,
    Properties,
    None,
}

/// Context menu state and configuration
pub struct ContextMenu {
    /// X position on screen
    pub x: i32,
    
    /// Y position on screen
    pub y: i32,
    
    /// Whether the menu is currently visible
    pub visible: bool,
    
    /// Menu items: (label, action, enabled)
    pub items: Vec<(String, ContextMenuAction, bool)>,
}

impl ContextMenu {
    /// Creates a new context menu
    pub fn new() -> Self {
        Self {
            x: 0,
            y: 0,
            visible: false,
            items: Vec::new(),
        }
    }

    /// Shows the context menu at the specified position
    pub fn show(&mut self, x: i32, y: i32, has_selection: bool, clipboard_has_items: bool) {
        self.x = x;
        self.y = y;
        self.visible = true;
        self.items.clear();

        // Build menu items based on context
        if has_selection {
            self.add_item("Open", ContextMenuAction::Open, true);
            self.add_separator();
            self.add_item("Copy", ContextMenuAction::Copy, true);
            self.add_item("Cut", ContextMenuAction::Cut, true);
        }

        self.add_item("Paste", ContextMenuAction::Paste, clipboard_has_items);

        if has_selection {
            self.add_item("Delete", ContextMenuAction::Delete, true);
            self.add_item("Rename", ContextMenuAction::Rename, true);
        }

        self.add_separator();
        self.add_item("New Folder", ContextMenuAction::NewFolder, true);
    }

    /// Hides the context menu
    pub fn hide(&mut self) {
        self.visible = false;
    }

    /// Gets the total height of the menu
    pub fn get_height(&self) -> i32 {
        self.items.len() as i32 * CONTEXT_MENU_ITEM_HEIGHT + 8
    }

    /// Adds a menu item
    fn add_item(&mut self, label: &str, action: ContextMenuAction, enabled: bool) {
        self.items.push((label.to_string(), action, enabled));
    }

    /// Adds a separator line
    fn add_separator(&mut self) {
        self.items.push((MENU_SEPARATOR.to_string(), ContextMenuAction::None, false));
    }
}

impl Default for ContextMenu {
    fn default() -> Self {
        Self::new()
    }
}
