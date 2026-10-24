import { verifySite, argumentsFor } from './survivors-publication.mjs';
try { console.log(JSON.stringify(await verifySite(argumentsFor(process.argv.slice(2))), null, 2)); }
catch (error) { console.error(error.message); process.exitCode = 1; }
