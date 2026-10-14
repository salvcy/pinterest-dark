// Safari ignores the manifest's content_scripts "world" key, but scripting.registerContentScripts
// accepts world: "MAIN". Register main.js there so it runs in Pinterest's own JS world at
// document_start, on the Pinterest sites listed in the manifest's host_permissions.
const api = globalThis.browser ?? globalThis.chrome;
const ID = 'pdm-main';
const DISPLAY_SETTINGS = '/settings/edit/display-settings/';

// Pinterest subdomains that aren't the consumer web app.
const EXCLUDE = ['ads', 'analytics', 'business', 'help', 'developers', 'newsroom', 'policy', 'about',
  'investor', 'investors', 'careers', 'status', 'partners', 'engineering', 'create']
  .map((sub) => `*://${sub}.pinterest.com/*`);

async function registerMainWorldHook({ replace = false } = {}) {
  try {
    if (replace) await api.scripting.unregisterContentScripts({ ids: [ID] }).catch(() => {});
    else if ((await api.scripting.getRegisteredContentScripts({ ids: [ID] })).length) return;
    await api.scripting.registerContentScripts([{
      id: ID,
      js: ['main.js'],
      matches: api.runtime.getManifest().host_permissions,
      excludeMatches: EXCLUDE,
      runAt: 'document_start',
      world: 'MAIN',
    }]);
  } catch (error) {
    console.warn('Pinterest Dark: MAIN-world registration failed', error);
  }
}

api.runtime.onInstalled.addListener(() => registerMainWorldHook({ replace: true }));
api.runtime.onStartup.addListener(() => registerMainWorldHook());

// Toolbar button: open Pinterest's own Display settings (Light / Dark / Auto). On a Pinterest tab
// it navigates that tab, keeping the user's country domain; elsewhere it opens a new tab.
api.action.onClicked.addListener((tab) => {
  const onPinterest = tab?.url && /^https:\/\/([\w-]+\.)*pinterest\.[a-z.]+\//.test(tab.url);
  if (onPinterest) api.tabs.update(tab.id, { url: new URL(DISPLAY_SETTINGS, tab.url).href });
  else api.tabs.create({ url: `https://www.pinterest.com${DISPLAY_SETTINGS}` });
});
