use std::ffi::CString;
use std::os::raw::c_char;

/// A function that returns "Hello, from rust!" as a C style string.
#[no_mangle]
pub extern "C" fn hello() -> *mut c_char {
    let s = CString::new("Hello, from rust!").unwrap();
    s.into_raw()
}