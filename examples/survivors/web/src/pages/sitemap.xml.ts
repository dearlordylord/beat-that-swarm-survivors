import { SITE_ORIGIN, PAGE_META } from "../../../seo.mts"
export const prerender = true
export function GET() {
  const entries = Object.values(PAGE_META)
    .map((page) => `<url><loc>${SITE_ORIGIN}${page.path}</loc></url>`)
    .join("")
  return new Response(
    `<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">${entries}</urlset>`,
    { headers: { "Content-Type": "application/xml; charset=utf-8" } }
  )
}
