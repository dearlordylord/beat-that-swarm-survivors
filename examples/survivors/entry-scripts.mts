function selectTab(tabs: readonly string[]) {
  const tab = new URLSearchParams(location.search).get("tab")
  document.documentElement.dataset.menuTab = tab !== null && tabs.includes(tab) ? tab : "expedition"
}
function activateTab() {
  document.querySelector('#tabs [data-tab="' + document.documentElement.dataset.menuTab + '"]')?.classList.add("active")
}
function selectEntry() {
  document.documentElement.dataset.entry =
    new URLSearchParams(location.search).has("join") || new URLSearchParams(location.hash.slice(1)).has("join")
      ? "guest"
      : "host"
}
// Serialize compiled functions so pre-paint scripts share TypeScript's checks.
export const initialTabScript = (tabs: readonly string[]) =>
  `<script>(${selectTab.toString()})(${JSON.stringify(tabs)});</script>`
export const activeTabScript = `<script>(${activateTab.toString()})();</script>`
export const coopEntryScript = `<script>(${selectEntry.toString()})();</script>`
