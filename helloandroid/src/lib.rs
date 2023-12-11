extern crate jni;

use std::ffi::CString;
use std::os::raw::c_char;

use jni::objects::{JClass, JObject, JValue, JString};
use jni::JNIEnv;

use hello::greetings;

pub type Callback = unsafe extern "C" fn(*const c_char) -> ();

#[no_mangle]
#[allow(non_snake_case)]
pub extern "C" fn invokeCallbackViaJNA(callback: Callback) {
   let s = CString::new(greetings::get_greetings()).unwrap();
   unsafe {
      callback(s.as_ptr());
   }
}

#[no_mangle]
#[allow(non_snake_case)]
pub extern "C" fn Java_com_rc_rustspike_myapplication_MainActivity_invokeCallbackViaJNI(env: JNIEnv, _class: JClass, callback: JObject) {
   let s = greetings::say_hello("");
   let response = env.new_string(&s).expect("Couldn't create java string!");
   env.call_method(callback, "callback", "(Ljava/lang/String;)V", &[JValue::from(JObject::from(response))]).unwrap();
}

#[no_mangle]
pub unsafe extern "C" fn Java_com_rc_rustspike_MainActivity_startFetchRandomImage(env: JNIEnv, _: JClass, folder: JString) {
   let folder_str = {
      let raw_folder_str = env.get_string(folder).expect("Couldn't get java string!");
      raw_folder_str.to_str().expect("Couldn't convert java string to rust string!").to_owned()
   };

   greetings::start_fetch_random_image(&folder_str);
}

#[no_mangle]
pub extern "C" fn Java_com_rc_rustspike_MainActivity_stopFetchRandomImage(
    _: JNIEnv,
    _: JClass,
) {
    greetings::stop_fetch_random_image();
}
