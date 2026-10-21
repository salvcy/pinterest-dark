// Background script: a service worker in Chromium browsers and Safari, an event page in Firefox.
//
// 1. Registers main.js to run in Pinterest's own JavaScript world at document_start. It is
//    registered here rather than declared in the manifest because Safari ignores the manifest's
//    content_scripts "world" key; scripting.registerContentScripts honours it in every browser.
// 2. Makes the toolbar button open Pinterest's own Display settings.
const api = globalThis.browser ?? globalThis.chrome;

const SCRIPT_ID = 'pdm-main';
const DISPLAY_SETTINGS = '/settings/edit/display-settings/';
const HOSTS = api.runtime.getManifest().host_permissions; // "*://*.pinterest.com/*", …
const DOMAINS = HOSTS.map((pattern) => pattern.split('/')[2].replace('*.', '')); // "pinterest.com", …

// Pinterest subdomains that aren't the consumer web app.
const NON_APP_SUBDOMAINS = ['ads', 'analytics', 'business', 'help', 'developers', 'newsroom', 'policy',
  'about', 'investor', 'investors', 'careers', 'status', 'partners', 'engineering', 'create'];

const MAIN_WORLD_SCRIPT = {
  id: SCRIPT_ID,
  js: ['main.js'],
  matches: HOSTS,
  excludeMatches: NON_APP_SUBDOMAINS.map((sub) => `*://${sub}.pinterest.com/*`),
  runAt: 'document_start',
  world: 'MAIN',
};

// Registrations persist across browser restarts. Calls are queued so the install-time
// re-registration and the start-up check never race on the same script ID.
let queue = Promise.resolve();
function registerMainWorldScript({ replace = false } = {}) {
  queue = queue.then(async () => {
    const [existing] = await api.scripting.getRegisteredContentScripts({ ids: [SCRIPT_ID] });
    if (existing && !replace) return;
    if (existing) await api.scripting.unregisterContentScripts({ ids: [SCRIPT_ID] });
    await api.scripting.registerContentScripts([MAIN_WORLD_SCRIPT]);
  }).catch((error) => console.error('Pinterest Dark: could not register main.js', error));
  return queue;
}

// Install and update replace the registration with this version's; any other start of the
// background script (browser launch, re-enabling the extension) restores it only if it's missing.
api.runtime.onInstalled.addListener(() => registerMainWorldScript({ replace: true }));
api.runtime.onStartup.addListener(() => registerMainWorldScript());
registerMainWorldScript();

function isPinterestApp(url) {
  const { protocol, hostname } = new URL(url);
  return protocol === 'https:'
    && DOMAINS.some((domain) => hostname === domain || hostname.endsWith(`.${domain}`))
    && !NON_APP_SUBDOMAINS.includes(hostname.split('.')[0]);
}

// Opens Pinterest's own Display settings (Light / Dark / Auto). On a Pinterest tab it navigates
// that tab, keeping the user's country domain; elsewhere it opens a new tab.
function openDisplaySettings(tab) {
  if (tab?.url && isPinterestApp(tab.url)) {
    return api.tabs.update(tab.id, { url: new URL(DISPLAY_SETTINGS, tab.url).href });
  }
  return api.tabs.create({ url: `https://www.pinterest.com${DISPLAY_SETTINGS}` });
}

// Firefox and Chromium browsers let people withdraw an extension's site access after install.
// Asking again from the click restores it; the browser shows no prompt while access is granted.
// Safari manages website access in its own UI, so the button only opens the settings there.
const ASKS_FOR_ACCESS = !api.runtime.getURL('').startsWith('safari-web-extension:');

api.action.onClicked.addListener((tab) => {
  if (!ASKS_FOR_ACCESS) {
    openDisplaySettings(tab);
    return;
  }
  // Must be called directly in the click handler: Firefox only allows it during a user action.
  api.permissions.request({ origins: HOSTS })
    .catch(() => false)
    .then(() => openDisplaySettings(tab));
});
