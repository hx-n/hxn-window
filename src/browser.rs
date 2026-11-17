//! Platform startup and transport for xwindow's shared DOM backend.
#[cfg(target_os = "wasi")]
unsafe extern "C" {
    fn ash_host_agent(name: *const u8, len: u32, address: u32) -> i32;
}
#[cfg(target_os = "emscripten")]
unsafe extern "C" {
    fn hxn_window_agent(address: u32) -> i32;
}

pub fn agent(_name: &str, address: usize) -> bool {
    #[cfg(target_os = "wasi")]
    return unsafe { ash_host_agent(_name.as_ptr(), _name.len() as u32, address as u32) != 0 };
    #[cfg(target_os = "emscripten")]
    return unsafe { hxn_window_agent(address as u32) != 0 };
    #[cfg(not(target_family = "wasm"))]
    {
        let _ = (_name, address);
        false
    }
}

#[cfg(all(target_os = "emscripten", not(target_feature = "atomics")))]
pub fn send(_: &crate::wire::Mailbox, bytes: &[u8]) {
    unsafe extern "C" {
        fn hxn_window_execute(address: u32, len: u32);
    }
    unsafe { hxn_window_execute(bytes.as_ptr() as u32, bytes.len() as u32) }
}
