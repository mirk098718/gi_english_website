const https = require("https");
const http = require("http");

const FEEDS = [
  {
    url: "https://www.theguardian.com/uk/travel/rss",
    category: "Travel",
    source: "The Guardian",
  },
  {
    url: "https://www.theguardian.com/food/rss",
    category: "Cooking",
    source: "The Guardian",
  },
  {
    url: "https://www.theguardian.com/fashion/beauty/rss",
    category: "Beauty",
    source: "The Guardian",
  },
  {
    url: "https://www.theguardian.com/science/rss",
    category: "Science",
    source: "The Guardian",
  },
  {
    url: "https://feeds.bbci.co.uk/news/science_and_environment/rss.xml",
    category: "Science",
    source: "BBC",
  },
  {
    url: "https://www.theguardian.com/lifeandstyle/rss",
    category: "Society",
    source: "The Guardian",
  },
  {
    url: "https://www.theguardian.com/culture/rss",
    category: "Entertainment",
    source: "The Guardian",
  },
  {
    url: "https://www.theguardian.com/film/rss",
    category: "Entertainment",
    source: "The Guardian",
  },
  {
    url: "https://feeds.bbci.co.uk/news/entertainment_and_arts/rss.xml",
    category: "Entertainment",
    source: "BBC",
  },
  {
    url: "https://www.theguardian.com/sport/rss",
    category: "Sports",
    source: "The Guardian",
  },
  {
    url: "https://feeds.bbci.co.uk/sport/rss.xml",
    category: "Sports",
    source: "BBC",
  },
  {
    url: "https://www.koreatimes.co.kr/www/rss/entertainment.xml",
    category: "Korea",
    source: "The Korea Times",
  },
  {
    url: "https://www.koreatimes.co.kr/www/rss/sports.xml",
    category: "Korea",
    source: "The Korea Times",
  },
  {
    url: "https://www.koreatimes.co.kr/www/rss/arts.xml",
    category: "Korea",
    source: "The Korea Times",
  },
];

function fetchText(url, redirects) {
  return new Promise((resolve, reject) => {
    const lib = url.startsWith("http://") ? http : https;
    const request = lib.get(
      url,
      {
        headers: {
          "User-Agent": "GleamIslandTalk/1.0",
          Accept: "application/rss+xml, application/xml, text/xml, */*",
        },
      },
      (response) => {
        const status = response.statusCode || 0;
        if (status >= 300 && status < 400 && response.headers.location && redirects < 3) {
          response.resume();
          const next = new URL(response.headers.location, url).href;
          resolve(fetchText(next, redirects + 1));
          return;
        }
        const chunks = [];
        response.on("data", (chunk) => chunks.push(chunk));
        response.on("end", () => {
          resolve(Buffer.concat(chunks).toString("utf8"));
        });
      }
    );
    request.setTimeout(8000, () => request.destroy(new Error("timeout")));
    request.on("error", reject);
  });
}

function tag(item, name) {
  const cdata = item.match(
    new RegExp(`<${name}[^>]*>\\s*<!\\[CDATA\\[([\\s\\S]*?)\\]\\]>\\s*</${name}>`, "i")
  );
  if (cdata) return cdata[1];
  const plain = item.match(new RegExp(`<${name}[^>]*>([\\s\\S]*?)</${name}>`, "i"));
  return plain ? plain[1] : "";
}

function clean(raw) {
  return raw
    .replace(/<[^>]+>/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&#(\d+);/g, (_, code) => String.fromCharCode(Number(code)))
    .replace(/\s+/g, " ")
    .trim();
}

function imageUrl(item) {
  const tags = [...item.matchAll(/<(?:media:content|media:thumbnail)\b([^>]*)>/gi)];
  let best = "";
  let bestWidth = -1;
  for (const tag of tags) {
    const attrs = tag[1];
    const url = (attrs.match(/\burl="([^"]+)"/i) || [])[1];
    if (!url) continue;
    const width = Number((attrs.match(/\bwidth="(\d+)"/i) || [])[1] || 0);
    if (width < bestWidth) continue;
    bestWidth = width;
    best = url;
  }
  if (!best) {
    const enclosed = item.match(/<enclosure\b[^>]*\burl="([^"]+)"/i);
    best = enclosed ? enclosed[1] : "";
  }
  return best
    .replace(/&amp;/g, "&")
    .replace("/ace/standard/240/", "/ace/standard/976/");
}

function itemsFrom(xml, feed) {
  const items = [];
  const matches = xml.match(/<item\b[^>]*>[\s\S]*?<\/item>/gi) || [];
  for (const item of matches.slice(0, 12)) {
    const title = clean(tag(item, "title"));
    const url = clean(tag(item, "link"));
    const pubDate = tag(item, "pubDate").trim();
    const description = tag(item, "description").slice(0, 1800);
    if (!title || !url || !pubDate) continue;
    items.push({
      category: feed.category,
      title,
      description,
      url,
      source: feed.source,
      pubDate,
      imageUrl: imageUrl(item),
    });
  }
  return items;
}

async function collectTalkTopics() {
  const batches = await Promise.all(
    FEEDS.map(async (feed) => {
      try {
        const xml = await fetchText(feed.url, 0);
        return itemsFrom(xml, feed);
      } catch (error) {
        console.warn("talk feed skipped", feed.url, error.message);
        return [];
      }
    })
  );
  return batches.flat();
}

module.exports = { collectTalkTopics, itemsFrom };
