//! User Interface Module
//! 
//! This module contains all UI-related components and rendering logic.
//! Each component is separated into its own module for better maintainability.

pub mod context_menu;
pub mod context_menu_renderer;
pub mod dialogs;
pub mod file_list;
pub mod header;
pub mod notifications;
pub mod scrollbar;
pub mod status_bar;
pub mod styles;
pub mod toolbar;

// Re-export commonly used items
pub use context_menu::ContextMenuAction;
pub use context_menu_renderer::draw_context_menu;
pub use dialogs::{draw_dialog, is_cancel_button_clicked, is_ok_button_clicked};
pub use file_list::{draw_file_list, get_clicked_index, get_hover_index};
pub use header::{draw_header, is_back_button_clicked};
pub use notifications::draw_notification;
pub use scrollbar::draw_scrollbar;
pub use status_bar::draw_status_bar;
pub use styles::{ColorScheme, Layout};
pub use toolbar::draw_toolbar;
