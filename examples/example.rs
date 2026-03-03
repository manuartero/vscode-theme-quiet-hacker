// Quiet Hacker - Rust Preview
use std::collections::HashMap;
use std::fmt;
use std::sync::{Arc, Mutex};

const MAX_CAPACITY: usize = 256;

#[derive(Debug, Clone)]
pub enum Command {
    Get(String),
    Set(String, String),
    Delete(String),
    Flush,
}

#[derive(Debug)]
pub struct Cache {
    store: Arc<Mutex<HashMap<String, String>>>,
    capacity: usize,
    hits: u64,
    misses: u64,
}

impl Cache {
    pub fn new(capacity: usize) -> Self {
        Self {
            store: Arc::new(Mutex::new(HashMap::with_capacity(capacity))),
            capacity: capacity.min(MAX_CAPACITY),
            hits: 0,
            misses: 0,
        }
    }

    pub fn execute(&mut self, cmd: Command) -> Option<String> {
        match cmd {
            Command::Get(key) => {
                let store = self.store.lock().unwrap();
                match store.get(&key) {
                    Some(val) => {
                        self.hits += 1;
                        Some(val.clone())
                    }
                    None => {
                        self.misses += 1;
                        None
                    }
                }
            }
            Command::Set(key, value) => {
                let mut store = self.store.lock().unwrap();
                if store.len() >= self.capacity {
                    return None; // full
                }
                store.insert(key, value);
                Some("OK".to_string())
            }
            Command::Delete(key) => {
                let mut store = self.store.lock().unwrap();
                store.remove(&key).map(|_| "DELETED".to_string())
            }
            Command::Flush => {
                let mut store = self.store.lock().unwrap();
                let count = store.len();
                store.clear();
                Some(format!("FLUSHED {count}"))
            }
        }
    }

    pub fn hit_rate(&self) -> f64 {
        let total = self.hits + self.misses;
        if total == 0 { 0.0 } else { self.hits as f64 / total as f64 }
    }
}

impl fmt::Display for Cache {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let store = self.store.lock().unwrap();
        write!(
            f,
            "Cache(size={}, cap={}, hit_rate={:.1}%)",
            store.len(),
            self.capacity,
            self.hit_rate() * 100.0
        )
    }
}

fn main() {
    let mut cache = Cache::new(64);

    let commands = vec![
        Command::Set("host".into(), "127.0.0.1".into()),
        Command::Set("port".into(), "8080".into()),
        Command::Get("host".into()),
        Command::Get("missing".into()),
        Command::Delete("port".into()),
    ];

    for cmd in commands {
        let label = format!("{:?}", cmd);
        let result = cache.execute(cmd);
        println!("{label} -> {}", result.unwrap_or("(none)".into()));
    }

    println!("{cache}");
}
