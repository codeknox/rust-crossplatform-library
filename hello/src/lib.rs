// hello/src/lib.rs

pub mod greetings {
    use lazy_static::lazy_static;
    use std::sync::Mutex;
    use num_format::{Locale, ToFormattedString};
    
    lazy_static! {
        static ref COUNTER1: Mutex<u32> = Mutex::new(0);
        static ref COUNTER2: Mutex<u32> = Mutex::new(0);
    }

    pub fn get_greetings() -> String {
        let mut count = COUNTER1.lock().unwrap();
        *count += 1;
        format!("Hello from Rust!\n{}x", count.to_formatted_string(&Locale::en))
    }

    pub fn say_hello(recipient: &str) -> String {
        let mut count = COUNTER2.lock().unwrap();
        *count += 1;
        format!("Hello, {}!\n{}x", recipient, count.to_formatted_string(&Locale::en))
    }}
