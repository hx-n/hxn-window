//! Give Ash's futures and timers a turn before the page's event wait.
unsafe extern "C" {
    fn ash_host_wait(timeout: f64, wake: unsafe extern "C" fn()) -> f64;
    fn ash_host_resumed();
    fn ash_host_wake_word() -> *const u32;
}

unsafe extern "C" fn wake() {
    unsafe {
        crate::web::window_wake();
    }
}

pub struct Wait {
    pub timeout: f64,
}
impl Wait {
    pub fn begin(timeout: f64) -> Self {
        crate::web::set_runtime_wake(unsafe { ash_host_wake_word() } as u32);
        Self {
            timeout: unsafe { ash_host_wait(timeout, wake) },
        }
    }
}
impl Drop for Wait {
    fn drop(&mut self) {
        unsafe {
            ash_host_resumed();
        }
    }
}
