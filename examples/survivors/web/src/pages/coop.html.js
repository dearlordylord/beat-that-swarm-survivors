import template from '../../../coop.html?raw';
import { withPageMetadata } from '../../../seo.mjs';
import { renderCoopSetup } from '../../../expedition-menu.mjs';
import { freshProfile, validateSetup } from '../../../progression.mjs';
export const prerender = true;
export function GET() {
  const profile = freshProfile();
  const setup = { profile, ...validateSetup(profile, {}), openPanel: null, pendingUnlock: null };
  return new Response(withPageMetadata(template, 'coop').replace('<div id="coop-setup-preview"></div>', `<div id="coop-setup-preview"><div data-host-ui>${renderCoopSetup(setup)}</div><div data-guest-ui>${renderCoopSetup(setup, true)}</div></div>`), { headers: { 'Content-Type': 'text/html; charset=utf-8' } });
}
