//! Generates the shared model, browser wire and native/browser adapters.
use std::path::{Path, PathBuf};

fn main() {
    let out = PathBuf::from(std::env::var_os("OUT_DIR").unwrap());
    xwindow_backend::install_scoped(&out, "crate::model").expect("installing the window backend");
    let api = xwindow_bindgen::window_api();
    let idl = xwindow_bindgen::browser_idl();
    let binding = x_idl::hxn::generate_with_agent(
        xwindow_bindgen::NAMESPACE,
        "hxn.window",
        api.as_str(),
        &idl,
        Some("crate::browser::agent"),
    )
    .expect("generating the window binding");
    std::fs::write(out.join("window.rs"), binding).unwrap();
    let wire = xwindow_bindgen::browser_wire().expect("generating the browser wire");
    std::fs::write(out.join("window_wire.rs"), wire.rust).unwrap();
    let web_path = out.join("xwindow_backend/web.rs");
    let web = std::fs::read_to_string(&web_path)
        .unwrap()
        .replace("crate::model::wire", "crate::wire");
    std::fs::write(web_path, web).unwrap();
    let backend = x_idl::hxn::web_backend(
        xwindow_bindgen::NAMESPACE,
        api.as_str(),
        &idl,
        xwindow_backend::WEB,
    )
    .expect("generating the browser forwarders");
    std::fs::write(out.join("window_web_backend.rs"), backend).unwrap();

    println!("cargo:rerun-if-env-changed=HXN_WINDOW_PAGE_OUT");
    if let Some(page) = std::env::var_os("HXN_WINDOW_PAGE_OUT") {
        let page = PathBuf::from(page);
        std::fs::create_dir_all(&page).unwrap();
        std::fs::write(
            page.join(xwindow_backend::AGENT_MODULE),
            xwindow_backend::AGENT,
        )
        .unwrap();
        std::fs::write(page.join(xwindow_backend::WIRE_MODULE), &wire.js).unwrap();
    }
    if std::env::var_os("HXN_WINDOW_PAGE_OUT").is_none() {
        let page = PathBuf::from(std::env::var_os("CARGO_MANIFEST_DIR").unwrap()).join("page");
        for (name, expected) in [
            (xwindow_backend::AGENT_MODULE, xwindow_backend::AGENT),
            (xwindow_backend::WIRE_MODULE, wire.js.as_str()),
        ] {
            println!("cargo:rerun-if-changed=page/{name}");
            assert_eq!(
                std::fs::read_to_string(page.join(name)).ok().as_deref(),
                Some(expected),
                "page/{name} is stale; run hxn build to regenerate the page modules"
            );
        }
    }
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() == Ok("emscripten") {
        let atomics = std::env::var("CARGO_CFG_TARGET_FEATURE")
            .unwrap_or_default()
            .split(',')
            .any(|feature| feature == "atomics");
        if atomics {
            println!("cargo:rerun-if-changed=c/agent.c");
            cc::Build::new()
                .file("c/agent.c")
                .flag("-pthread")
                .compile("xwindow_agent");
        } else {
            direct(&out, &wire.js);
        }
    }
}

fn direct(out: &Path, wire: &str) {
    // Both generated commands and DOM handlers run synchronously on the page.
    // The event ring remains the same as the shared-memory build's.
    let wire = wire.replace("export ", "");
    let agent = xwindow_backend::AGENT
        .lines()
        .filter(|line| !line.starts_with("import "))
        .collect::<Vec<_>>()
        .join("\n")
        .replace("export ", "");
    println!("cargo:rerun-if-changed=c/direct.c");
    let c = include_str!("c/direct.c")
        .replace("/*WIRE*/", &wire)
        .replace("/*AGENT*/", &agent);
    let path = out.join("direct.c");
    std::fs::write(&path, c).unwrap();
    cc::Build::new().file(path).compile("xwindow_direct");
}
