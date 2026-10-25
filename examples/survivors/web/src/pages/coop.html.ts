import template from "../../../coop.html?raw"
import { coopEntryScript } from "../../../entry-scripts.mts"
import { withPageMetadata } from "../../../seo.mts"
import { renderCoopSetup } from "../../../expedition-menu.mts"
import { freshProfile, validateSetup } from "../../../progression.mts"
export const prerender = true
export function GET() {
  const profile = freshProfile()
  const setup = { profile, ...validateSetup(profile, {}), openPanel: null, pendingUnlock: null }
  return new Response(
    withPageMetadata(template.replace("<!--coop-entry-script-->", coopEntryScript), "coop").replace(
      '<div id="coop-setup-preview"></div>',
      `<div id="coop-setup-preview"><div data-host-ui>${renderCoopSetup(setup)}</div><div data-guest-ui>${renderCoopSetup(setup, true)}</div></div>`
    ),
    { headers: { "Content-Type": "text/html; charset=utf-8" } }
  )
}
