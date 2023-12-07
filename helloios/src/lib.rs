// helloios/src/lib.rs

use std::ffi::{CStr, CString};
use std::os::raw::c_char;

use hello::greetings;

/// Starts the fetching of random images and saves them to the specified folder.
///
/// # Safety
/// This function is unsafe because it dereferences a raw pointer (`folder`).
/// The caller must ensure that `folder` is a valid pointer to a null-terminated
/// string. Passing an invalid pointer (not null-terminated or pointing to unallocated
/// memory) can lead to undefined behavior.
///
/// # Arguments
/// * `folder` - A pointer to a null-terminated string representing the folder path.
#[no_mangle]
pub unsafe extern "C" fn start_fetch_random_image(folder: *const c_char) {
    // Safety: Ensure the folder string pointer is valid
    let folder_str = {
        assert!(!folder.is_null());
        CStr::from_ptr(folder).to_string_lossy().into_owned()
    };

    greetings::start_fetch_random_image(&folder_str);
}

#[no_mangle]
pub extern "C" fn stop_fetch_random_image() {
    greetings::stop_fetch_random_image();
}

#[no_mangle]
pub extern "C" fn get_greetings() -> *mut c_char {
    let str = greetings::get_greetings();
    CString::new(str).unwrap().into_raw()
}

/// Gets a personalized greeting from Rust.
///
/// # Safety
/// This function is unsafe because it dereferences a raw pointer. The caller
/// must ensure that `to` is a valid pointer to a null-terminated string or is null.
/// Passing an invalid pointer (not null-terminated or pointing to unallocated memory)
/// can lead to undefined behavior.
#[no_mangle]
pub unsafe extern "C" fn say_hello(to: *const c_char) -> *mut c_char {
    let recipient =
        if to.is_null() {
            "there"
        } else {
            match CStr::from_ptr(to).to_str() {
                Err(_) => "there",
                Ok(string) => string,
            }
        };

    let str = greetings::say_hello(recipient);
    CString::new(str).unwrap().into_raw()
}

/// Frees a string that was sent to platform library.
///
/// # Safety
/// This function is unsafe because it dereferences a raw pointer. The caller
/// must ensure that `str` is a valid pointer to a null-terminated string or is null.
/// Passing an invalid pointer (not null-terminated or pointing to unallocated memory)
/// can lead to undefined behavior.
#[no_mangle]
pub unsafe extern "C" fn free_string(str: *mut c_char) {
    if str.is_null() {
        return;
    }
    let _ = CString::from_raw(str);
}

#[repr(C)]
pub struct ImageData {
    data: *const u8,
    length: usize,
}

#[no_mangle]
pub extern "C" fn fetch_random_image() -> ImageData {
    match greetings::fetch_random_image() {
        Ok(bytes) => {
            let length = bytes.len();
            let boxed_slice = bytes.into_boxed_slice();
            let raw_ptr = boxed_slice.as_ptr();
            std::mem::forget(boxed_slice);
            ImageData {
                data: raw_ptr,
                length,
            }
        }
        Err(_) => ImageData {
            data: std::ptr::null(),
            length: 0,
        },
    }
}

// Define the type for the callback function
type ImageFetchCallback = extern "C" fn(*const u8, usize);

#[no_mangle]
pub extern "C" fn fetch_random_image_async(callback: ImageFetchCallback) {
    println!("Rust: calling fetch_random_image_async...");
    greetings::fetch_random_image_async(move |result| match result {
        Ok(bytes) => {
            println!("Rust: fetch_random_image_async got OK...");
            let ptr = bytes.as_ptr();
            let len = bytes.len();
            println!(
                "Rust: fetch_random_image_async received image with length {}",
                len
            );
            std::mem::forget(bytes); // Prevent Rust from freeing the memory
            callback(ptr, len); // Pass data to the callback
        }
        Err(err) => {
            println!("Rust: fetch_random_image_async got Err: {}", err);
            callback(std::ptr::null(), 0)
        } // Pass null/zero to sign an error
    });
}
