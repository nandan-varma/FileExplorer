use std::path::PathBuf;
use std::fs;
use std::io;

#[derive(Debug, Clone, PartialEq)]
pub enum ClipboardOperation {
    Copy,
    Cut,
}

#[derive(Debug, Clone)]
pub struct Clipboard {
    pub items: Vec<PathBuf>,
    pub operation: ClipboardOperation,
    pub source_dir: PathBuf,
}

impl Clipboard {
    pub fn new() -> Self {
        Self {
            items: Vec::new(),
            operation: ClipboardOperation::Copy,
            source_dir: PathBuf::new(),
        }
    }
    
    pub fn copy(&mut self, items: Vec<PathBuf>, source_dir: PathBuf) {
        self.items = items;
        self.operation = ClipboardOperation::Copy;
        self.source_dir = source_dir;
    }
    
    pub fn cut(&mut self, items: Vec<PathBuf>, source_dir: PathBuf) {
        self.items = items;
        self.operation = ClipboardOperation::Cut;
        self.source_dir = source_dir;
    }
    
    pub fn is_empty(&self) -> bool {
        self.items.is_empty()
    }
    
    pub fn clear(&mut self) {
        self.items.clear();
    }
}

impl Default for Clipboard {
    fn default() -> Self {
        Self::new()
    }
}

// File operations
pub fn copy_file(src: &PathBuf, dest: &PathBuf) -> io::Result<()> {
    if src.is_dir() {
        copy_dir_recursive(src, dest)
    } else {
        fs::copy(src, dest)?;
        Ok(())
    }
}

fn copy_dir_recursive(src: &PathBuf, dest: &PathBuf) -> io::Result<()> {
    if !dest.exists() {
        fs::create_dir(dest)?;
    }
    
    for entry in fs::read_dir(src)? {
        let entry = entry?;
        let file_type = entry.file_type()?;
        let src_path = entry.path();
        let dest_path = dest.join(entry.file_name());
        
        if file_type.is_dir() {
            copy_dir_recursive(&src_path, &dest_path)?;
        } else {
            fs::copy(&src_path, &dest_path)?;
        }
    }
    
    Ok(())
}

pub fn move_file(src: &PathBuf, dest: &PathBuf) -> io::Result<()> {
    fs::rename(src, dest)
}

pub fn delete_file(path: &PathBuf) -> io::Result<()> {
    if path.is_dir() {
        fs::remove_dir_all(path)
    } else {
        fs::remove_file(path)
    }
}

pub fn rename_file(old_path: &PathBuf, new_name: &str) -> io::Result<()> {
    let mut new_path = old_path.clone();
    new_path.set_file_name(new_name);
    fs::rename(old_path, &new_path)
}

pub fn create_folder(parent: &PathBuf, name: &str) -> io::Result<PathBuf> {
    let mut new_path = parent.clone();
    new_path.push(name);
    fs::create_dir(&new_path)?;
    Ok(new_path)
}

pub fn paste_items(clipboard: &Clipboard, dest_dir: &PathBuf) -> io::Result<usize> {
    let mut count = 0;
    
    for item in &clipboard.items {
        let file_name = item.file_name().ok_or_else(|| {
            io::Error::new(io::ErrorKind::InvalidInput, "Invalid file name")
        })?;
        let dest_path = dest_dir.join(file_name);
        
        match clipboard.operation {
            ClipboardOperation::Copy => {
                copy_file(item, &dest_path)?;
                count += 1;
            }
            ClipboardOperation::Cut => {
                move_file(item, &dest_path)?;
                count += 1;
            }
        }
    }
    
    Ok(count)
}

pub fn get_unique_name(dir: &PathBuf, base_name: &str) -> String {
    let mut name = base_name.to_string();
    let mut counter = 1;
    
    loop {
        let mut test_path = dir.clone();
        test_path.push(&name);
        
        if !test_path.exists() {
            return name;
        }
        
        // Split name and extension
        if let Some(dot_pos) = base_name.rfind('.') {
            let (prefix, ext) = base_name.split_at(dot_pos);
            name = format!("{} ({}){}", prefix, counter, ext);
        } else {
            name = format!("{} ({})", base_name, counter);
        }
        
        counter += 1;
    }
}
