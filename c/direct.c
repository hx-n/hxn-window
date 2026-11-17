// Built with the generated wire and the shared DOM agent in place of the markers.
#include <emscripten.h>

EM_JS(int, hxn_window_start_js, (unsigned address), {
  if (typeof document === 'undefined') return 0;
  const canvas = Module.canvas || document.getElementById('canvas');
  if (!canvas) return 0;
  try {
  const api = (() => {
    /*WIRE*/
    return {Wire, Queue, execute, post_XwEvent};
  })();
  const {Wire, Queue, execute, post_XwEvent} = api;
  Module.hxnWindowExecute = execute;
  /*AGENT*/
  Module.hxnWindowWire = start({
    memory: {get buffer() {return HEAPU8.buffer;}},
    address,
    canvas,
    serveMailbox() {},
  });
  return 1;
  } catch (error) {
    console.error('xwindow agent:', error);
    return 0;
  }
});

EM_JS(void, hxn_window_execute_js, (unsigned address, unsigned len), {
  Module.hxnWindowExecute(Module.hxnWindowWire, address, len);
});

// Keep the EM_JS sections in the archive by referencing them from C definitions.
int hxn_window_agent(unsigned address) { return hxn_window_start_js(address); }
void hxn_window_execute(unsigned address, unsigned len) { hxn_window_execute_js(address, len); }
