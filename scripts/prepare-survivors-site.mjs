import { prepareSite, argumentsFor } from './survivors-publication.mjs';
try { console.log(JSON.stringify(await prepareSite(argumentsFor(process.argv.slice(2))), null, 2)); }
catch (error) { console.error(error.message); process.exitCode = 1; }
