//! Gives a program in an APK its files. `hxn build` puts them in the APK's assets with a
//! list of their paths, `hxn-files.txt`, whose first line identifies the build. Before the
//! program starts, the files are copied into the app's data directory, which becomes the
//! working directory, so the program reads them by the same relative paths as elsewhere.

use std::ffi::{CString, c_void};
use std::io::Read;
use std::path::{Component, Path};
use std::sync::OnceLock;
use winit::platform::android::activity::AndroidApp;

const LIST: &str = "hxn-files.txt";

// The JavaVM and the activity, as addresses so that they can be shared between threads.
static CONTEXT: OnceLock<(usize, usize)> = OnceLock::new();

/// Keeps the JavaVM and the activity of `app` for `hxn_android_context`.
pub fn publish(app: &AndroidApp) {
    let _ = CONTEXT.set((app.vm_as_ptr() as usize, app.activity_as_ptr() as usize));
}

/// Gives other libraries in the program the JavaVM and the activity, which is an
/// `android.content.Context`. Each Rust library has its own copy of crates such as
/// ndk-context, so this C function is how they reach the activity that the host
/// started. Returns 0 before the activity starts, and 1 with both pointers set.
///
/// # Safety
///
/// `vm` and `activity` must be valid for writes.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn hxn_android_context(
    vm: *mut *mut c_void,
    activity: *mut *mut c_void,
) -> i32 {
    let Some(&(java, context)) = CONTEXT.get() else {
        return 0;
    };
    unsafe {
        *vm = java as *mut c_void;
        *activity = context as *mut c_void;
    }
    1
}

/// Copies the listed assets into the app's data directory when the list differs from the
/// one copied last, and makes that directory the working directory.
pub fn unpack(app: &AndroidApp) {
    let Some(dir) = app.internal_data_path() else {
        hxn::log::error!(target: "hxn.window", "the app has no data directory for its files");
        return;
    };
    let assets = app.asset_manager();
    let read = |name: &str| -> Option<Vec<u8>> {
        let mut asset = assets.open(&CString::new(name).ok()?)?;
        let mut bytes = Vec::new();
        asset.read_to_end(&mut bytes).ok()?;
        Some(bytes)
    };
    if let Some(list) = read(LIST) {
        let list = String::from_utf8_lossy(&list).into_owned();
        let copied = dir.join(LIST);
        let last = std::fs::read_to_string(&copied).unwrap_or_default();
        if last != list {
            // Files that the last build listed and this one does not are removed.
            let kept: Vec<&str> = list.lines().skip(1).collect();
            for name in last.lines().skip(1).filter(|name| !kept.contains(name)) {
                if safe(name) {
                    let _ = std::fs::remove_file(dir.join(name));
                }
            }
            for name in kept.iter().filter(|name| safe(name)) {
                let Some(bytes) = read(name) else {
                    hxn::log::error!(target: "hxn.window", "the APK has no asset {name}");
                    continue;
                };
                let path = dir.join(name);
                let written = path
                    .parent()
                    .map_or(Ok(()), std::fs::create_dir_all)
                    .and_then(|()| std::fs::write(&path, bytes));
                if let Err(error) = written {
                    hxn::log::error!(target: "hxn.window", "{}: {error}", path.display());
                }
            }
            // The list is written last, so that a copy cut short is made again.
            if let Err(error) = std::fs::write(&copied, &list) {
                hxn::log::error!(target: "hxn.window", "{}: {error}", copied.display());
            }
        }
    }
    if let Err(error) = std::env::set_current_dir(&dir) {
        hxn::log::error!(target: "hxn.window", "{}: {error}", dir.display());
    }
}

// Whether `name` is a relative path that stays inside the data directory.
fn safe(name: &str) -> bool {
    !name.is_empty()
        && Path::new(name)
            .components()
            .all(|part| matches!(part, Component::Normal(_)))
}
