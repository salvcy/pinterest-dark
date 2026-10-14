// Registered by background.js to run in Pinterest's own JavaScript world at document_start,
// before any page script.
//
// Pinterest's web app ships a complete native dark mode that is gated behind the server-side
// experiment `dweb_dark_mode`. Its experiments client resolves a group with
//   (this.active[name] ?? this.triggerable[name]) || ""
// so a non-enumerable `dweb_dark_mode` on Object.prototype makes every experiments map the server
// hands the client (including the ones it swaps in after boot) report "enabled". Because the
// lookup in `active` succeeds, the client never sends an activation call for it, and the value
// stays invisible to Object.keys / JSON.stringify / for…in.
//
// Light / Dark / Auto is then Pinterest's own setting (Settings → Display settings), stored in
// its "theme" localStorage key. This script only seeds it on a fresh install and never overrides it.
(() => {
  'use strict';
  // Extension APIs only exist in the isolated world; if this ever lands there, defining the
  // property would be useless, so bail.
  if (globalThis.browser?.runtime?.id || globalThis.chrome?.runtime?.id) return;
  if (Object.prototype.hasOwnProperty('dweb_dark_mode')) return;

  Object.defineProperty(Object.prototype, 'dweb_dark_mode', {
    value: 'enabled',
    writable: true,
    configurable: true,
    enumerable: false,
  });

  try {
    // Same JSON encoding Pinterest's storage wrapper writes (`"dark"`).
    if (localStorage.getItem('theme') === null) localStorage.setItem('theme', JSON.stringify('dark'));
    localStorage.removeItem('pdm:mode'); // left by version 1.0's popup
  } catch {}
})();
