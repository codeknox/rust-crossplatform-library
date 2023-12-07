// hello/src/lib.rs

pub mod greetings {
    use lazy_static::lazy_static;
    use num_format::{Locale, ToFormattedString};
    use reqwest;
    use std::fs::File;
    use std::io::Write;
    use std::path::Path;
    use std::sync::atomic::{AtomicBool, Ordering};
    use std::sync::{Arc, Mutex};
    use std::thread;
    use std::time::Duration;
    use tokio::runtime::Runtime;
    use uuid::Uuid;

    static IMAGE_URL: &str = "https://picsum.photos/200/300";

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

    // Shared state to control the image fetching loop
    struct FetchState {
        running: AtomicBool,
    }

    impl FetchState {
        fn new() -> Self {
            FetchState {
                running: AtomicBool::new(false),
            }
        }

        fn start(&self) {
            self.running.store(true, Ordering::SeqCst);
        }

        fn stop(&self) {
            self.running.store(false, Ordering::SeqCst);
        }

        fn is_running(&self) -> bool {
            self.running.load(Ordering::SeqCst)
        }
    }

    // Global shared state (uses Mutex for thread safety)
    lazy_static::lazy_static! {
        static ref FETCH_STATE: Arc<Mutex<FetchState>> = Arc::new(Mutex::new(FetchState::new()));
    }

    // Starts the fetching of random images
    // they will be saved on the folder path
    pub fn start_fetch_random_image(folder: &str) {
        let state = FETCH_STATE.clone();
        let folder_path = folder.to_owned();

        // Create the Tokio runtime once outside the loop
        let rt = Runtime::new().unwrap();

        // Start the fetching thread
        thread::spawn(move || {
            let state = state.lock().unwrap();
            state.start();
            while state.is_running() {
                // Fetch and save an image using the single runtime instance
                if let Err(e) = rt.block_on(fetch_and_save_image(IMAGE_URL, &folder_path)) {
                    eprintln!("Error fetching image: {}", e);
                }
                else {
                    let mut count = COUNTER1.lock().unwrap();
                    *count += 1;
                    println!("Rust: count: {}", count);
                }
                // Sleep for a short duration before fetching the next image
                // thread::sleep(Duration::from_secs(5));
            }
        });
    }

    // Stops the fetching of random images
    pub fn stop_fetch_random_image() {
        let state = FETCH_STATE.lock().unwrap();
        state.stop();
    }

    // Helper function to fetch and save the image
    async fn fetch_and_save_image(
        url: &str,
        folder: &str,
    ) -> Result<(), Box<dyn std::error::Error>> {
        let response = reqwest::get(url).await?;
        let bytes = response.bytes().await?;

        // Generate a random UUID for the filename
        let filename = format!("{}.jpg", Uuid::new_v4());
        let file_path = Path::new(folder).join(filename);

        let mut file = File::create(file_path)?;
        file.write_all(&bytes)?;
        Ok(())
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
