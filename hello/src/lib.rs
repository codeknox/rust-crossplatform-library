// hello/src/lib.rs

pub mod greetings {
    use lazy_static::lazy_static;
    use num_format::{Locale, ToFormattedString};
    use std::sync::Mutex;

    lazy_static! {
        static ref COUNTER1: Mutex<u32> = Mutex::new(0);
        static ref COUNTER2: Mutex<u32> = Mutex::new(0);
    }

    pub fn get_greetings() -> String {
        let mut count = COUNTER1.lock().unwrap();
        *count += 1;
        format!(
            "Hello from Rust!\n{}x",
            count.to_formatted_string(&Locale::en)
        )
    }

    pub fn say_hello(recipient: &str) -> String {
        let mut count = COUNTER2.lock().unwrap();
        *count += 1;
        format!(
            "Hello, {}!\n{}x",
            recipient,
            count.to_formatted_string(&Locale::en)
        )
    }

    // Function to fetch a random image and return its bytes
    pub fn fetch_random_image() -> Result<Vec<u8>, Box<dyn std::error::Error>> {
        let url = "https://picsum.photos/200/300";
        let res = reqwest::blocking::get(url)?;
        let bytes = res.bytes()?.to_vec();
        Ok(bytes)
    }

    pub fn fetch_random_image_async<F>(callback: F)
    where
        F: FnOnce(Result<Vec<u8>, String>) + Send + 'static,
    {
        println!("Rust: started fetch_random_image_async...");
        let rt = tokio::runtime::Runtime::new().unwrap();
        println!("Rust: fetch_random_image_async: willl spawn...");
        rt.spawn(async move {
            println!("Rust: Starting image fetch...");
    
            // Debugging entry into the fetch_random_image_async_impl function
            println!("Rust: Entering fetch_random_image_async_impl...");
    
            let result = fetch_random_image_async_impl().await;
    
            // Debugging exit from the fetch_random_image_async_impl function
            println!("Rust: Exiting fetch_random_image_async_impl...");
    
            println!("Rust: Image fetch completed.");
    
            // Debugging the callback function call
            println!("Rust: Calling callback function...");
    
            callback(result.map_err(|e| {
                // Debugging error mapping
                println!("Rust: Error mapping: {}", e);
                e.to_string()
            }));
        });
    }
        
    async fn fetch_random_image_async_impl() -> Result<Vec<u8>, Box<dyn std::error::Error>> {
        let url = "https://picsum.photos/200/300";
        let res = reqwest::get(url).await?;
        let bytes = res.bytes().await?.to_vec();
        Ok(bytes)
    }
}
