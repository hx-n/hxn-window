//! One window API over xwindow's native and DOM backends.
#![cfg_attr(
    all(target_arch = "wasm32", target_feature = "atomics"),
    feature(stdarch_wasm_atomic_wait)
)]

mod browser;

#[cfg(not(target_family = "wasm"))]
#[allow(dead_code, clippy::all)]
mod backend {
    mod platform {
        include!(concat!(env!("OUT_DIR"), "/xwindow_backend/native.rs"));
    }
    pub use platform::*;
    pub unsafe fn window_open(attributes: &crate::model::WindowAttributes) -> i32 {
        hxn::log::debug!(target: "hxn.window", "opening a native window");
        unsafe { platform::window_open(attributes) }
    }
}

/// The entry that winit's native activity calls on Android, on the activity's thread. It
/// gives the activity to the window backend, then runs the program, which defines its entry
/// as `xwindow_main`. Ash defines that entry in each program that it builds for Android.
#[cfg(target_os = "android")]
#[unsafe(no_mangle)]
fn android_main(app: winit::platform::android::activity::AndroidApp) {
    unsafe extern "C" {
        fn xwindow_main();
    }
    backend::android_app(app);
    unsafe { xwindow_main() }
}

#[cfg(target_family = "wasm")]
#[allow(dead_code, non_camel_case_types, unused_variables, clippy::all)]
mod wire {
    include!(concat!(env!("OUT_DIR"), "/window_wire.rs"));
}

#[cfg(target_family = "wasm")]
#[allow(dead_code, non_snake_case, clippy::all)]
mod web {
    mod page {
        include!(concat!(env!("OUT_DIR"), "/xwindow_backend/web.rs"));
    }
    pub use page::*;

    pub unsafe fn window_open(attributes: &crate::model::WindowAttributes) -> i32 {
        #[cfg(all(target_os = "emscripten", not(target_feature = "atomics")))]
        page::set_dispatch(crate::browser::send);
        hxn::log::debug!(target: "hxn.window", "opening a browser window");
        unsafe { page::window_open(attributes) }
    }

    pub unsafe fn window_wait(handle: i32, timeout: f64) -> crate::model::Event {
        #[cfg(target_os = "wasi")]
        let wait = crate::runtime_wait::Wait::begin(timeout);
        #[cfg(target_os = "wasi")]
        let timeout = wait.timeout;
        unsafe { page::window_wait(handle, timeout) }
    }
}

#[cfg(target_os = "wasi")]
mod runtime_wait;

#[cfg(target_family = "wasm")]
#[allow(dead_code, unused_variables, clippy::all)]
mod backend {
    use crate::model::*;
    include!(concat!(env!("OUT_DIR"), "/window_web_backend.rs"));
}

include!(concat!(env!("OUT_DIR"), "/window.rs"));
