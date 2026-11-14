//! xwindow's `window` API for Haxe through hxn: x-idl writes the binding
//! from xwindow's declaration, over xwindow's native backend.

#[allow(dead_code)]
mod backend {
    include!(concat!(env!("OUT_DIR"), "/xwindow_backend/native.rs"));
}

include!(concat!(env!("OUT_DIR"), "/window.rs"));
