// Throwaway: Four locked-survivor layouts in the existing menu shell at /?variant=A|B|C|D.
// Run: node examples/survivors/unlock-ux.prototype.mjs. All state is disposable.
import http from 'node:http';
import { readFile } from 'node:fs/promises';
import { dirname, resolve, extname } from 'node:path';
import { fileURLToPath } from 'node:url';
const root = dirname(fileURLToPath(import.meta.url));
const types={'.css':'text/css','.mjs':'text/javascript','.svg':'image/svg+xml','.png':'image/png','.html':'text/html'};
const server=http.createServer(async(req,res)=>{
 try {
 const path=new URL(req.url,'http://localhost').pathname;
 let body,type;
 if(path==='/') {
 body=(await readFile(resolve(root,'index.html'),'utf8')).replace('<script type="module" src="./browser.mjs"></script>','<script type="module" src="./unlock-ux.prototype.client.mjs"></script>').replace('</head>','<link rel="stylesheet" href="./unlock-ux.prototype.css"></head>');type='text/html';
 } else if(path==='/prototype-menu.mjs') {
 body=(await readFile(resolve(root,'expedition-menu.mjs'),'utf8')).replace(/^import \{ isUnlocked, purchaseStatus \}.*$/m,'');type='text/javascript';
 } else {
 const file=resolve(root,'.'+decodeURIComponent(path));
 if(!file.startsWith(root+'/'))throw Error('outside root');
 body=await readFile(file);type=types[extname(file)]||'application/octet-stream';
 }
 res.writeHead(200,{'Content-Type':type,'Cache-Control':'no-store'});res.end(body);
 } catch {res.writeHead(404);res.end('Not found');}
});
let port=Number(process.env.PORT||4179);
server.on('error',error=>{if(error.code==='EADDRINUSE')server.listen(++port,'127.0.0.1');else throw error;});
server.listen(port,'127.0.0.1',()=>console.log(`Unlock UX prototype: http://127.0.0.1:${port}/?variant=A`));
