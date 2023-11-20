// helloios/src/lib.rs

use std::ffi::{CStr, CString};
use std::os::raw::c_char;

use hello::greetings;

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
    let recipient = if to.is_null() {
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
            ImageData { data: raw_ptr, length }
        },
        Err(_) => ImageData { data: std::ptr::null(), length: 0 },
    }
}
