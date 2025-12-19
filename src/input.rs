// Abstractions for mouse and keyboard events, selection, and shortcuts

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MouseButton {
    Left,
    Right,
    Middle,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct MouseEvent {
    pub x: i32,
    pub y: i32,
    pub button: Option<MouseButton>,
    pub pressed: bool,
    pub released: bool,
    pub dragged: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SelectionMode {
    Single,
    Multi,
    Range,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Selection {
    pub indices: Vec<usize>,
    pub mode: SelectionMode,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Shortcut {
    Copy,
    Paste,
    Cut,
    Delete,
    Rename,
    SelectAll,
    NewFolder,
    Up,
    Down,
    Enter,
    Back,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct KeyboardEvent {
    pub key: Option<Shortcut>,
    pub ctrl: bool,
    pub shift: bool,
    pub alt: bool,
    pub pressed: bool,
    pub released: bool,
}
