use std::fs;
use std::path::PathBuf;
use std::time::SystemTime;

#[derive(Debug, Clone)]
pub struct FileEntry {
    pub name: String,
    pub is_dir: bool,
    pub size: u64,
    pub modified: Option<SystemTime>,
    pub extension: String,
}

impl FileEntry {
    pub fn new(name: String, is_dir: bool, size: u64, modified: Option<SystemTime>) -> Self {
        let extension = if !is_dir {
            std::path::Path::new(&name)
                .extension()
                .and_then(|e| e.to_str())
                .unwrap_or("")
                .to_lowercase()
        } else {
            String::new()
        };
        
        Self {
            name,
            is_dir,
            size,
            modified,
            extension,
        }
    }
}

pub fn list_files(path: &str) -> Vec<FileEntry> {
    let mut entries = Vec::new();
    
    if let Ok(read_dir) = fs::read_dir(path) {
        for entry in read_dir.flatten() {
            let file_name = entry.file_name().into_string().unwrap_or_default();
            let is_dir = entry.path().is_dir();
            
            let metadata = entry.metadata().ok();
            let size = if is_dir {
                0
            } else {
                metadata.as_ref().map(|m| m.len()).unwrap_or(0)
            };
            
            let modified = metadata.and_then(|m| m.modified().ok());
            
            entries.push(FileEntry::new(file_name, is_dir, size, modified));
        }
    }
    
    // Sort: directories first, then alphabetically
    entries.sort_by(|a, b| {
        match (a.is_dir, b.is_dir) {
            (true, false) => std::cmp::Ordering::Less,
            (false, true) => std::cmp::Ordering::Greater,
            _ => a.name.to_lowercase().cmp(&b.name.to_lowercase()),
        }
    });
    
    entries
}

pub fn get_parent_path(current: &PathBuf) -> Option<PathBuf> {
    current.parent().map(|p| p.to_path_buf())
}

pub fn navigate_to(current: &PathBuf, folder_name: &str) -> Option<PathBuf> {
    let mut new_path = current.clone();
    new_path.push(folder_name);
    if new_path.is_dir() {
        Some(new_path)
    } else {
        None
    }
}

pub fn path_components(path: &PathBuf) -> Vec<String> {
    let mut components = Vec::new();
    
    for component in path.components() {
        if let Some(s) = component.as_os_str().to_str() {
            components.push(s.to_string());
        }
    }
    
    components
}
