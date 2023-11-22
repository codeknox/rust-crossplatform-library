// hello/src/lib.rs

pub mod greetings {
    use lazy_static::lazy_static;
    use tokio::runtime::Runtime;
    use num_format::{Locale, ToFormattedString};
    use std::sync::Mutex;

    lazy_static! {
        static ref COUNTER1: Mutex<u32> = Mutex::new(0);
        static ref COUNTER2: Mutex<u32> = Mutex::new(0);

        static ref TOKIO_RUNTIME: Runtime = {
            let rt = Runtime::new().expect("Failed to create Tokio runtime");
            rt
        };
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
        let result = TOKIO_RUNTIME.block_on(fetch_random_image_async_impl());
        result
    }

    pub fn fetch_random_image_async<F>(callback: F)
    where
        F: FnOnce(Result<Vec<u8>, String>) + Send + 'static,
    {
        println!("Rust: started fetch_random_image_async with tokio...");
        TOKIO_RUNTIME.spawn(async move {
            println!("Rust: Starting image fetch with tokio...");
            let result = fetch_random_image_async_impl().await;
            println!("Rust: Image fetch completed with tokio, going into callback.");
            callback(result.map_err(|e| {
                println!("Rust: Error occurred: {}", e);
                e.to_string()
            }));
            println!("Rust: Image fetch completed with tokio, callback returned.");
        });
    }

    async fn fetch_random_image_async_impl() -> Result<Vec<u8>, Box<dyn std::error::Error>> {
        println!("Rust: fetch_random_image_async_impl: starting...");
        let url = "https://picsum.photos/200/300";
        // let url = "https://rustacean.net/assets/rustacean-orig-noshadow.png";
        println!("Rust: fetch_random_image_async_impl: get...");

        // Create a client with default settings (including follow redirects)
        let client = reqwest::Client::builder()
            .redirect(reqwest::redirect::Policy::default())
            .build()?;

        let res = client.get(url).send().await?;
        println!("HTTP Status: {}", res.status());
        println!("Response Headers: {:?}", res.headers());

        if res.status().is_success() {
            println!("Rust: fetch_random_image_async_impl: bytes...");
            let bytes = res.bytes().await?.to_vec();
            println!(
                "Rust: fetch_random_image_async_impl: returning OK, with length {}",
                bytes.len()
            );
            Ok(bytes)
        } else {
            println!("Rust: HTTP error: {}", res.status());
            Err(Box::new(
                std::io::Error::new(std::io::ErrorKind::Other, "HTTP request failed")
            ))
        }
    }
}
