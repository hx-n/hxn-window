//! Writes xwindow's binding for hxn and installs its native backend.

use std::path::PathBuf;

fn main() {
    let out = PathBuf::from(std::env::var_os("OUT_DIR").unwrap());
    xwindow_backend::install_scoped(&out, "crate::model").expect("installing the xwindow backend");
    let binding = x_idl::hxn::generate(
        xwindow_bindgen::NAMESPACE,
        "hxn.window",
        xwindow_bindgen::window_api(),
        &xwindow_bindgen::browser_idl(),
    )
    .expect("generating the window binding");
    std::fs::write(out.join("window.rs"), binding).expect("writing the window binding");
}
