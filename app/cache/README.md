# Markdown pages

Bundled seed documents use `pages_<page_url>_<language>.md`.
For example, `/about` uses `pages_about_en.md`. Supply the page route without
country/language prefixes. Leading/trailing slashes and query strings are removed;
nested routes are URL-encoded (`/help/navigation` -> `pages_help%2Fnavigation_en.md`).

Each document has YAML front matter with `title`, `description`, `seoTitle`, and
`seoDescription`, followed by the Markdown body. Register new seed files in
`pubspec.yaml`. The About page preserves its existing header, styling and links.

`MarkdownPageCache.load` reads `https://pages.freeopenocean.com/pages/<filename>`.
A saved copy checked within the last day is used as-is. A copy checked within
30 days is revalidated with `If-None-Match`. A copy older than 30 days is
replaced. If the request fails, a copy younger than 30 days is still shown,
then the bundled seed. Silent and Disable connection modes are low-data mode:
a saved copy is shown with no freshness check and may be kept past 30 days.
The requested language is tried before English. Invalid stored content is
discarded so the bundled copy remains usable.

On web and mobile, runtime content is stored in SharedPreferences under
`app/cache/<filename>`, plus `.etag` and `.checked`. It does not modify
packaged asset files. The Worker allows `https://freeopenocean.com`.
`DEV_MODE = "On"` also allows `http://localhost` and `http://127.0.0.1` on ports 65500 through 65550. Native builds send
that site origin. The browser sends its own origin, so a local web port outside
that range receives 403 and keeps the bundled seed.

## Public SEO and crawler access

The front matter is also the source for canonical URLs, language alternatives,
robots directives, Open Graph/Twitter metadata and AboutPage structured data.
SEO title/description are reused for social cards. No fabricated publication dates,
ratings or FAQ schema are generated.

Run `npm run pages:generate` after editing Markdown before local development.
Publish using `npm run build:web` and upload **all of build/web**. This generates
ten static About/Contact entry documents plus `/pages/pages_<slug>_<language>.md`,
`/sitemap.xml`, `/robots.txt` and `/llms.txt`. Static pages contain the complete
article for everyone before Flutter starts; no user-agent detection is used.
After loading, the shared content widget renders a visible native HTML article
inside the Flutter shell. Only then is the initial article removed. Browser
selection, copy, headings and links remain available. Native app builds use
SelectionArea. Future content pages should reuse MarkdownContentPage and be
registered in the generator to receive both HTML and Markdown entry points.

Hosting must serve existing static files (including directory index.html) BEFORE
its SPA fallback. `/USA/en/about` must resolve to `/USA/en/about/index.html`, and
likewise for the other languages. Other country variants remain app routes and
canonicalize to USA because the content is country-independent. Serve `.md` as
`text/markdown; charset=utf-8` (text/plain also works). Do not apply an HTML SPA
fallback to existing Markdown, XML or text files. On Cloudflare, allow public
crawlers through applicable WAF/Bot rules; repository robots.txt cannot override
an account-level challenge or block. llms.txt is supplemental discovery, not an
indexing guarantee. The live host must be deployed and HTTP-checked separately.

Future remotely cached content must also be published through this generation
step/server rendering to keep public HTML and client cache content in sync.
