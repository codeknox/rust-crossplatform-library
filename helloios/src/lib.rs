// helloios/src/lib.rs

use std::ffi::CStr;
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

