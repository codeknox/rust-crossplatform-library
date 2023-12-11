// hello/src/lib.rs

pub mod greetings {
   use hyper::body::HttpBody as _;
   use hyper::client::HttpConnector;
   use hyper::{Body, Client, StatusCode, Uri};
   use hyper_tls::HttpsConnector;
   use lazy_static::lazy_static;
   use num_format::{Locale, ToFormattedString};
   use std::fs;
   use std::path::Path;
   use std::sync::atomic::{AtomicBool, AtomicUsize, Ordering};
   use std::sync::{Arc, Mutex};
   use std::thread;
   use tokio::runtime::{Builder, Runtime};
   use tokio::time::Duration;
   use tokio::{
      fs::File,
      io::{AsyncWriteExt, BufWriter},
   };

   use uuid::Uuid;

   static IMAGE_URL: &str = "https://picsum.photos/200/300"; // https://rustacean.net/assets/rustacean-orig-noshadow.png

   lazy_static! {
       static ref TOKIO_RUNTIME: Runtime = {
           let rt = Builder::new_multi_thread()
               .worker_threads(4) // Adjust the number of worker threads as needed
               .enable_all()
               .build()
               .expect("Failed to create Tokio runtime");
           rt
       };
       static ref FETCH_STATE: Arc<FetchState> = Arc::new(FetchState::new());
   }

   // Shared state to control the image fetching loop
   struct FetchState {
      running:     AtomicBool,
      task_count:  AtomicUsize,
      image_count: AtomicUsize,
      client:      Client<HttpsConnector<HttpConnector>>,
   }

   impl FetchState {
      fn new() -> Self {
         let https = HttpsConnector::new();
         let client = Client::builder().build::<_, Body>(https);
         FetchState {
            running: AtomicBool::new(false),
            task_count: AtomicUsize::new(0),
            image_count: AtomicUsize::new(0),
            client,
         }
      }

      fn start(&self) {
         self.running.store(true, Ordering::SeqCst);
         self.task_count.fetch_add(1, Ordering::SeqCst);
      }

      fn stop(&self) {
         self.running.store(false, Ordering::SeqCst);
      }

      fn is_running(&self) -> bool {
         self.running.load(Ordering::SeqCst)
      }

      fn decrement_task_count(&self) {
         self.task_count.fetch_sub(1, Ordering::SeqCst);
      }

      fn reset_benchmark(&self) {
         self.image_count.store(0, Ordering::SeqCst);
      }

      fn increment_image_count(&self) {
         self.image_count.fetch_add(1, Ordering::SeqCst);
      }

      fn get_benchmark_result(&self) -> usize {
         self.image_count.load(Ordering::SeqCst)
      }
   }

   // Starts the fetching of random images and saves them to the folder path
   pub fn start_fetch_random_image(folder: &str) {
      // Validate the folder path
      // let folder_path = Path::new(folder);
      // if !folder_path.exists() {
      //     if let Err(e) = fs::create_dir_all(folder_path) {
      //         eprintln!("Error creating folder: {}", e);
      //         return;
      //     }
      // } else if !folder_path.is_dir() {
      //     eprintln!("Error: Provided path is not a directory");
      //     return;
      // }
      // if fs::write(folder_path.join("test.tmp"), b"test").is_err() {
      //     eprintln!("Error: Folder path is not writable");
      //     return;
      // }
      // let _ = fs::remove_file(folder_path.join("test.tmp"));
      let folder_path = folder.to_owned();

      let state = FETCH_STATE.clone();
      state.reset_benchmark();

      // Start a separate thread for benchmarking
      let state_for_benchmark = FETCH_STATE.clone();
      thread::spawn(move || {
         thread::sleep(Duration::from_secs(60)); // Wait for 1 minute
         let image_count = state_for_benchmark.get_benchmark_result();
         println!("Benchmark result: {} images downloaded in 1 minute.", image_count);
         stop_fetch_random_image()
      });

      // Start the fetching thread with panic recovery
      fn start_fetching(state: Arc<FetchState>, folder_path: String) {
         TOKIO_RUNTIME.spawn(async move {
            state.start();
            let mut count = 0;
            // let result = panic::catch_unwind(AssertUnwindSafe(|| {
            // println!("Rust: START: {}", state.get_task_count());
            while state.is_running() {
               match fetch_and_save_image(&state.client, IMAGE_URL, &folder_path).await {
                  Ok(_) => count += 1,
                  Err(e) => {
                     eprintln!("Error fetching image: {}", e);
                  }
               }
               // Sleep for a short duration before fetching the next image
               // thread::sleep(Duration::from_millis(50));
            }
            println!("Benchmark result: {} images downloaded in 1 minute.", count);
            // }));
            state.decrement_task_count();

            // if let Err(panic) = result {
            //     eprintln!("Rust: Panic caught in image fetching thread: {:?}", panic);
            //     println!("Rust: Active tasks: {}", state.get_task_count());
            //     if state.is_running() {
            //         // Restart the fetching process
            //         start_fetching(state.clone(), folder_path.clone());
            //     }
            // } else {
            //     println!("Rust: Task ended. Active tasks: {}", state.get_task_count());
            // }
         });
      }

      // Start the fetching process
      start_fetching(state, folder_path);
   }

   // Stops the fetching of random images
   pub fn stop_fetch_random_image() {
      println!("Rust: STOP");
      FETCH_STATE.stop();
      println!("Rust: state: {}", FETCH_STATE.is_running());
   }

   async fn fetch_and_save_image(client: &Client<HttpsConnector<HttpConnector>>, url: &str, folder: &str) -> Result<(), Box<dyn std::error::Error>> {
      let mut effective_url = url.to_string();

      loop {
         let uri: Uri = effective_url.parse()?;
         let response = client.get(uri).await?;

         match response.status() {
            StatusCode::MOVED_PERMANENTLY | StatusCode::FOUND | StatusCode::SEE_OTHER | StatusCode::TEMPORARY_REDIRECT => {
               if let Some(location) = response.headers().get(hyper::header::LOCATION) {
                  effective_url = location.to_str()?.to_string();
                  continue; // Follow the redirect
               } else {
                  return Err("Redirect without Location header".into());
               }
            }
            StatusCode::OK => {
               // Stream response directly to file
               let filename = format!("{}.jpg", Uuid::new_v4());
               let file_path = Path::new(folder).join(&filename);
               let file = File::create(&file_path).await?;
               let mut writer = BufWriter::new(file);

               let mut stream = response.into_body();
               while let Some(chunk) = stream.data().await {
                  writer.write_all(&chunk?).await?;
               }
               writer.flush().await?;
               // FETCH_STATE.increment_image_count();
               break;
            }
            _ => return Err(format!("Unexpected response status: {}", response.status()).into()),
         }
      }

      Ok(())
   }


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
}
