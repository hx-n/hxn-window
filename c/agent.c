// The page starts the same DOM agent Ash starts through ash_host_agent.
#include <emscripten.h>
int hxn_window_agent(unsigned address) {
  return MAIN_THREAD_EM_ASM_INT({
    if (typeof document === "undefined") return 0;
    var canvas = Module.canvas || document.getElementById("canvas");
    if (!canvas) return 0;
    import(new URL("./xwindow.mjs", location.href))
      .then(function (shim) { shim.start({ memory: wasmMemory, address: $0, canvas: canvas }); })
      .catch(function (error) { abort("xwindow agent: " + error); });
    return 1;
  }, address);
}
