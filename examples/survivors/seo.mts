// Build-time metadata only. Static tags are readable without running the game.
export const SITE_ORIGIN = "https://survivors.dearlordylord.com"
const SITE_NAME = "B.T.S: Beat That Swarm - Survivors"
export const PAGE_META = Object.freeze({
  home: {
    path: "/",
    title: "B.T.S: Beat That Swarm - Survivors",
    description:
      "A playable Vampire Survivors clone built with Bendvy ECS. Play solo or invite a friend in your browser. No installation required.",
    image: "/social/survivors-v1.png",
    imageAlt:
      "Survivors, a Vampire Survivors clone built as a Bendvy ECS example, with a screenshot of the pixel-art arena."
  },
  coop: {
    path: "/coop.html",
    title: "B.T.S: Beat That Swarm - Survivors | Co-op",
    description:
      "Invite a friend to a shared run in this Vampire Survivors clone. Choose your survivors and play together in the browser with Bendvy ECS.",
    image: "/social/survivors-coop-v2.png",
    imageAlt: "Survivors co-op: invite a friend to play the Bendvy ECS example together in the browser."
  }
})
const escape = (value: unknown) =>
  String(value).replace(
    /[&<>"']/g,
    (char) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[char] ?? char
  )
function pageMetadata(key: keyof typeof PAGE_META) {
  const page = PAGE_META[key]
  if (!page) throw Error(`Unknown SEO page: ${key}`)
  const url = SITE_ORIGIN + page.path,
    image = SITE_ORIGIN + page.image
  const tags = [
    `<title>${escape(page.title)}</title>`,
    `<link rel="canonical" href="${url}" />`,
    `<meta name="description" content="${escape(page.description)}" />`,
    '<meta name="robots" content="index, follow, max-image-preview:large" />',
    '<meta name="application-name" content="B.T.S: Beat That Swarm - Survivors" />',
    '<meta property="og:type" content="website" />',
    '<meta property="og:locale" content="en_US" />',
    `<meta property="og:site_name" content="${SITE_NAME}" />`,
    `<meta property="og:title" content="${escape(page.title)}" />`,
    `<meta property="og:description" content="${escape(page.description)}" />`,
    `<meta property="og:url" content="${url}" />`,
    `<meta property="og:image" content="${image}" />`,
    `<meta property="og:image:secure_url" content="${image}" />`,
    '<meta property="og:image:type" content="image/png" />',
    '<meta property="og:image:width" content="1200" />',
    '<meta property="og:image:height" content="630" />',
    `<meta property="og:image:alt" content="${escape(page.imageAlt)}" />`,
    '<meta name="twitter:card" content="summary_large_image" />',
    `<meta name="twitter:title" content="${escape(page.title)}" />`,
    `<meta name="twitter:description" content="${escape(page.description)}" />`,
    `<meta name="twitter:image" content="${image}" />`,
    `<meta name="twitter:image:alt" content="${escape(page.imageAlt)}" />`
  ]
  const game = {
    "@type": "VideoGame",
    "@id": SITE_ORIGIN + "/#game",
    url: SITE_ORIGIN + "/",
    name: "B.T.S: Beat That Swarm - Survivors",
    description: PAGE_META.home.description,
    image: SITE_ORIGIN + PAGE_META.home.image,
    genre: "Survivors",
    applicationCategory: "GameApplication",
    gamePlatform: "Web browser",
    operatingSystem: "Web browser",
    playMode: ["https://schema.org/SinglePlayer", "https://schema.org/MultiPlayer"],
    isAccessibleForFree: true,
    isBasedOn: {
      "@type": "SoftwareSourceCode",
      codeRepository: "https://github.com/dearlordylord/bendvy-ecs-examples/tree/master/examples/survivors"
    }
  }
  const structured = {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "WebSite",
        "@id": SITE_ORIGIN + "/#website",
        url: SITE_ORIGIN + "/",
        name: SITE_NAME,
        inLanguage: "en"
      },
      game,
      {
        "@type": "WebPage",
        "@id": url + "#webpage",
        url,
        name: page.title,
        description: page.description,
        inLanguage: "en",
        isPartOf: { "@id": SITE_ORIGIN + "/#website" },
        about: { "@id": SITE_ORIGIN + "/#game" }
      }
    ]
  }
  tags.push(
    `<script id="site-structured-data" type="application/ld+json">${JSON.stringify(structured).replace(/</g, "\\u003c")}</script>`
  )
  return tags.join("\n")
}
export function withPageMetadata(html: string, key: keyof typeof PAGE_META) {
  const match = html.match(/<head\b[^>]*>([\s\S]*?)<\/head>/i)
  if (!match) throw Error("Page has no HTML head")
  // Replace existing SEO tags rather than introducing duplicate title/canonical values.
  const head = (match[1] ?? "")
    .replace(/<title\b[^>]*>[\s\S]*?<\/title>/gi, "")
    .replace(/<link\b(?=[^>]*\brel=["']canonical["'])[^>]*>/gi, "")
    .replace(
      /<meta\b(?=[^>]*\b(?:name|property)=["'](?:description|robots|application-name|og:[^"']+|twitter:[^"']+)["'])[^>]*>/gi,
      ""
    )
    .replace(/<script\b(?=[^>]*\bid=["']site-structured-data["'])[^>]*>[\s\S]*?<\/script>/gi, "")
  return html.replace(match[0], `<head>${head}\n${pageMetadata(key)}\n</head>`)
}
