// Validate the delivered static artifact, not just the metadata-rendering helper.
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { SITE_ORIGIN } from './seo.mjs';
const args=process.argv.slice(2), option=name=>args[args.indexOf(name)+1];
const base=args.includes('--base')?option('--base'):null;
const directory=path.resolve(args.includes('--directory')?option('--directory'):new URL('./dist/web/',import.meta.url).pathname);
const agents=base?['Twitterbot/1.0','Mozilla/5.0 (compatible; Discordbot/2.0; +https://discordapp.com)','Slackbot-LinkExpanding 1.0 (+https://api.slack.com/robots)']:['static-build'];
const unescape=value=>value.replace(/&quot;/g,'"').replace(/&#39;/g,"'").replace(/&lt;/g,'<').replace(/&gt;/g,'>').replace(/&amp;/g,'&');
async function get(route,agent){
 if(!base){const name=route==='/'?'/index.html':route;return readFile(path.join(directory,name));}
 const response=await fetch(new URL(route,base),{headers:{'user-agent':agent}});
 assert.equal(response.status,200,`${agent} can fetch ${route}`);
 if(new URL(route,base).pathname.endsWith('.png'))assert.match(response.headers.get('content-type')||'',/^image\/png(?:;|$)/,'share image MIME type');
 return Buffer.from(await response.arrayBuffer());
}
function headTags(html){
 const head=html.match(/<head\b[^>]*>([\s\S]*?)<\/head>/i)?.[1];assert.ok(head,'static HTML head exists');
 const tags=[];
 for(const match of head.matchAll(/<(meta|link)\b([^>]*)>/gi)){
  const attrs=Object.fromEntries([...match[2].matchAll(/([\w:-]+)\s*=\s*["']([^"']*)["']/g)].map(m=>[m[1].toLowerCase(),unescape(m[2])]));
  tags.push({tag:match[1],...attrs});
 }
 const one=(kind,key)=>{const values=tags.filter(tag=>tag[kind]===key);assert.equal(values.length,1,`exactly one ${key}`);return values[0];};
 return {head,one};
}
for(const agent of agents){
 for(const route of ['/','/coop.html']){
  const html=(await get(route,agent)).toString('utf8');const {head,one}=headTags(html);
  const titles=[...head.matchAll(/<title\b[^>]*>([^<]*)<\/title>/gi)];assert.equal(titles.length,1);
  assert.ok(titles[0][1].includes('Bendvy'),'example identity is explicit');
  assert.ok(titles[0][1].length>=20&&titles[0][1].length<=70,'useful search title length');
  const canonical=one('rel','canonical').href;assert.equal(canonical,SITE_ORIGIN+route);
  const description=one('name','description').content;assert.ok(description.length>=80&&description.length<=170);
  assert.ok(one('name','robots').content.includes('index'));assert.ok(!one('name','robots').content.includes('noindex'));
  assert.equal(one('property','og:url').content,canonical);assert.equal(one('property','og:type').content,'website');
  assert.equal(one('property','og:title').content,unescape(titles[0][1]));assert.equal(one('property','og:description').content,description);
  assert.equal(one('name','twitter:card').content,'summary_large_image');
  assert.equal(one('name','twitter:title').content,one('property','og:title').content);
  assert.equal(one('name','twitter:description').content,description);
  const image=one('property','og:image').content;const imageURL=new URL(image);assert.equal(imageURL.origin,SITE_ORIGIN);
  assert.match(imageURL.pathname,/^\/social\/[a-z-]+-v\d+\.png$/);assert.equal(imageURL.search,'');
  assert.equal(one('property','og:image:secure_url').content,image);assert.equal(one('name','twitter:image').content,image);
  assert.ok(one('property','og:image:alt').content.length>30);assert.equal(one('name','twitter:image:alt').content,one('property','og:image:alt').content);
  assert.equal(one('property','og:image:width').content,'1200');assert.equal(one('property','og:image:height').content,'630');
  assert.equal(one('property','og:image:type').content,'image/png');
  const png=await get(imageURL.pathname,agent);assert.equal(png.subarray(0,8).toString('hex'),'89504e470d0a1a0a');
  assert.equal(png.readUInt32BE(16),1200);assert.equal(png.readUInt32BE(20),630);assert.ok(png.length<2*1024*1024,'preview stays below2MiB');
  const structured=[...head.matchAll(/<script\b[^>]*type="application\/ld\+json"[^>]*>([\s\S]*?)<\/script>/gi)];
  assert.equal(structured.length,1);const graph=JSON.parse(structured[0][1]);assert.equal(graph['@context'],'https://schema.org');
  assert.ok(graph['@graph'].some(entry=>entry['@type']==='VideoGame'));
  console.log(`PASS ${agent} ${route}: canonical, static SEO/OG/Twitter, JSON-LD, PNG1200x630 (${png.length}bytes)`);
 }
 if(base){const invitation=(await get('/coop.html?session=42&join=share-preview-check',agent)).toString('utf8');assert.equal(headTags(invitation).one('rel','canonical').href,SITE_ORIGIN+'/coop.html');}
}
const robots=(await get('/robots.txt',agents[0])).toString('utf8');assert.ok(robots.includes('Allow: /'));assert.ok(robots.includes('Sitemap: '+SITE_ORIGIN+'/sitemap.xml'));
const sitemap=(await get('/sitemap.xml',agents[0])).toString('utf8');assert.ok(sitemap.includes('http://www.sitemaps.org/schemas/sitemap/0.9'));
assert.deepEqual([...sitemap.matchAll(/<loc>([^<]+)<\/loc>/g)].map(match=>match[1]).sort(),[SITE_ORIGIN+'/',SITE_ORIGIN+'/coop.html'].sort());
console.log('PASS robots.txt and sitemap.xml');
