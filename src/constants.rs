/// Application-wide constants
/// Centralizes all magic numbers and string literals for easy maintenance

// === Timing Constants ===
/// Double-click detection threshold in milliseconds
pub const DOUBLE_CLICK_THRESHOLD_MS: u128 = 500;

/// Notification display duration in seconds
pub const NOTIFICATION_DURATION_SECS: u64 = 3;

/// Target frames per second for the application
pub const TARGET_FPS: u32 = 60;

// === Scrolling Constants ===
/// Number of items to scroll when using mouse wheel
pub const WHEEL_SCROLL_AMOUNT: usize = 3;

// === Dialog Constants ===
/// Width of confirmation dialogs
pub const CONFIRM_DIALOG_WIDTH: i32 = 400;

/// Height of confirmation dialogs
pub const CONFIRM_DIALOG_HEIGHT: i32 = 180;

/// Width of input dialogs
pub const INPUT_DIALOG_WIDTH: i32 = 450;

/// Height of input dialogs
pub const INPUT_DIALOG_HEIGHT: i32 = 200;

/// Width of dialog buttons
pub const DIALOG_BUTTON_WIDTH: i32 = 100;

/// Height of dialog buttons
pub const DIALOG_BUTTON_HEIGHT: i32 = 32;

/// Spacing between dialog buttons
pub const DIALOG_BUTTON_SPACING: i32 = 12;

// === Context Menu Constants ===
/// Width of the context menu
pub const CONTEXT_MENU_WIDTH: i32 = 180;

/// Height of each context menu item
pub const CONTEXT_MENU_ITEM_HEIGHT: i32 = 28;

// === Notification Constants ===
/// Width of notification toast
pub const NOTIFICATION_WIDTH: i32 = 300;

/// Height of notification toast
pub const NOTIFICATION_HEIGHT: i32 = 60;

// === UI Text Constants ===
/// Label for separator in context menu
pub const MENU_SEPARATOR: &str = "---";

// === Dialog Titles ===
pub const DIALOG_TITLE_DELETE: &str = "Delete Items";
pub const DIALOG_TITLE_RENAME: &str = "Rename";
pub const DIALOG_TITLE_NEW_FOLDER: &str = "New Folder";

// === Dialog Prompts ===
pub const DIALOG_PROMPT_RENAME: &str = "Enter new name:";
pub const DIALOG_PROMPT_NEW_FOLDER: &str = "Enter folder name:";

// === Default Values ===
pub const DEFAULT_NEW_FOLDER_NAME: &str = "New Folder";

// === Button Labels ===
pub const BUTTON_LABEL_OK: &str = "OK";
pub const BUTTON_LABEL_CANCEL: &str = "Cancel";
