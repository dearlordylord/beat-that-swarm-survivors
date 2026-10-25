# Static share images

Both 1200×630 PNG cards use the production Moon Seal palette and the actual
menu portraits. gameplay-source.png was captured from the public solo game,
15 seconds into a run, on 2026-10-25. It is background texture, not a fabricated
benchmark or a claim about a particular build.

The normal web build copies these authored PNGs; no screenshot browser is needed
in the release toolchain. Its social check verifies the resulting static HTML,
metadata, image dimensions, robots and sitemap before replacing the served tree.

To regenerate the artwork after a deliberate visual update:

```sh
PLAYWRIGHT_MODULE=/absolute/path/to/playwright/index.mjs node examples/survivors/generate-social-cards.mjs
```

Increment image filename versions and update seo.mjs when changing published
artwork, so social crawlers fetch a new image URL. Page preview caches are owned
by the sharing platforms; existing posts may continue to show a cached card.

Verify a build or the public site:

```sh
node examples/survivors/check-social.mjs
node examples/survivors/check-social.mjs --base https://survivors.dearlordylord.com
```

The remote check fetches both pages and images as Twitterbot, Discordbot and
Slackbot, including an invitation-shaped URL. It does not post messages to these
services or claim to exercise their private card-rendering pipelines.
