use lazy_static::lazy_static;
use std::sync::Mutex;

lazy_static! {
    static ref COUNTER1: Mutex<u32> = Mutex::new(0);
    static ref COUNTER2: Mutex<u32> = Mutex::new(0);
}

pub mod hello {
    use super::COUNTER1;
    use super::COUNTER2;
    use std::sync::MutexGuard;

    pub fn greetings_from_rust() -> String {
        let mut count: MutexGuard<u32> = COUNTER1.lock().unwrap();
        *count += 1;
        format!("1> From Rust! This function has been called {} times.", *count)
    }

    pub fn another_greetings_from_rust() -> String {
        let mut count: MutexGuard<u32> = COUNTER2.lock().unwrap();
        *count += 1;
        format!("2> From Rust! This function has been called {} times.", *count)
    }
}
