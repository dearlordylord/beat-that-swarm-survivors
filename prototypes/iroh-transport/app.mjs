import { initialize, BendIrohChannel } from './channel.mjs';
const $ = id => document.getElementById(id);
let channel, endpointTask, epoch = 0, connected = false, busy = false, ready = false, eventCount = 0;
const short = value => value ? value.slice(0, 12) + '…' : 'not connected';
function status(text) { $('status').textContent = text; }
function notice(error) { $('notice').textContent = error?.message || String(error); $('notice').hidden = false; }
function controls() {
  const pending = channel?.snapshot().pendingSends || 0;
  $('create').disabled = !ready || busy || connected;
  $('join').disabled = !ready || busy || connected;
  $('disconnect').disabled = !channel && !endpointTask;
  $('send').disabled = !connected || pending >= 16;
  $('message').disabled = !connected;
  $('signal').classList.toggle('online', connected);
}
function counters(state = channel?.snapshot()) {
  for (const key of ['sent', 'received', 'rejected']) $(key).textContent = state?.protocol[key] || 0;
  $('diagnostics').textContent = JSON.stringify({ transport: 'Iroh 1.4.1', path: 'browser relay (platform constraint)', ...state, events: eventCount }, null, 2);
}
function journal(direction, text, seq) {
  $('messages').querySelector('.empty')?.remove();
  const row = document.createElement('li'); row.className = direction;
  const label = document.createElement('small'); label.textContent = `${direction === 'incoming' ? 'RECEIVED' : direction === 'outgoing' ? 'SENT' : 'EVENT'}${seq ? ' #' + seq : ''}`;
  const body = document.createElement('span'); body.className = 'message-text'; body.textContent = text;
  row.append(label, body); $('messages').append(row);
  while ($('messages').children.length > 80) $('messages').firstElementChild.remove();
  $('messages').scrollTop = $('messages').scrollHeight;
}
function event(value) {
  eventCount++;
  switch (value.type) {
    case 'ready': status('Relay ready · share an invitation or join'); break;
    case 'connecting': status('Connecting to peer…'); break;
    case 'connected':
      connected = true; busy = false; $('notice').hidden = true; $('peer-id').textContent = short(value.peerId);
      status('Connected · messages travel through Iroh'); journal('event', 'Connected to ' + short(value.peerId)); requestAnimationFrame(() => document.querySelector('.exchange').scrollIntoView({ block: 'start' })); break;
    case 'received': journal('incoming', value.text, value.seq); break;
    case 'sent': journal('outgoing', value.text, value.seq); break;
    case 'rejected': journal('event', 'Bend rejected a message: ' + value.reason); break;
    case 'disconnected':
      connected = false; busy = false; $('peer-id').textContent = 'not connected';
      status('Peer disconnected · invite or join again'); journal('event', 'Peer disconnected.'); break;
    case 'closed': connected = false; break;
    case 'error': notice(value.message || 'Transport error'); busy = false; break;
  }
  controls(); counters(value.state);
}
async function endpoint() {
  if (channel) return channel;
  if (endpointTask) return endpointTask;
  const generation = ++epoch; status('Opening an encrypted Iroh endpoint…');
  const task = BendIrohChannel.create(value => { if (generation === epoch) event(value); }).then(value => {
    if (generation !== epoch) { value.close(); throw Error('Endpoint creation was cancelled.'); }
    channel = value; $('self-id').textContent = short(value.endpointId()); controls(); counters(); return value;
  }).finally(() => { if (endpointTask === task) endpointTask = undefined; controls(); });
  endpointTask = task; controls(); return task;
}
function inviteFrom(text) {
  const value = text.trim();
  if (value.startsWith('bendvy-iroh-v1:')) return value;
  const invite = new URLSearchParams(new URL(value).hash.slice(1)).get('invite');
  if (!invite) throw Error('This link has no Iroh invitation. Ask the host to copy their invitation.');
  return invite;
}
$('create').addEventListener('click', async () => {
  busy = true; controls(); $('notice').hidden = true;
  let generation = epoch;
  try {
    const opening = endpoint(); generation = epoch; const peer = await opening;
    if (generation !== epoch) return;
    const link = new URL(location.href);
    link.hash = new URLSearchParams({ invite: peer.invitation() }).toString();
    $('invitation').value = link.href; $('host-invite').hidden = false; status('Invitation ready · waiting for a friend');
  } catch (error) { if (generation === epoch) { notice(error); status('Could not open endpoint · try again'); } }
  finally { if (generation === epoch) busy = false; controls(); }
});
$('copy').addEventListener('click', async () => {
  try { await navigator.clipboard.writeText($('invitation').value); $('copy-status').textContent = 'Copied'; }
  catch { $('invitation').focus(); $('invitation').select(); $('copy-status').textContent = 'Select and copy the link'; }
});
$('join-form').addEventListener('submit', async e => {
  e.preventDefault(); busy = true; controls(); $('notice').hidden = true;
  let generation = epoch;
  try { const invite = inviteFrom($('join-invite').value); const opening = endpoint(); generation = epoch; const peer = await opening; if (generation !== epoch) return; await peer.join(invite); }
  catch (error) { if (generation === epoch) { notice(error); status('Could not connect · check the invitation'); } }
  finally { if (generation === epoch) busy = false; controls(); counters(); }
});
$('message-form').addEventListener('submit', async e => {
  e.preventDefault(); if (!connected) return;
  const generation = epoch, session = channel.snapshot().connectionEpoch, text = $('message').value; $('message').value = '';
  const sending = channel.send(text); controls();
  try { await sending; } catch (error) { if (generation === epoch && channel?.snapshot().connectionEpoch === session) notice(error); }
  finally { controls(); counters(); }
});
$('disconnect').addEventListener('click', () => {
  epoch++; channel?.close(); channel = undefined; endpointTask = undefined; connected = false; busy = false;
  $('self-id').textContent = 'not started'; $('peer-id').textContent = 'not connected';
  $('host-invite').hidden = true; $('invitation').value = '';
  status('Disconnected · create or join another session'); journal('event', 'You disconnected.'); controls(); counters();
});
addEventListener('pagehide', () => { channel?.close(); });
const suggested = new URLSearchParams(location.hash.slice(1)).get('invite');
if (suggested) $('join-invite').value = suggested;
try { await initialize(); ready = true; status('Ready · create an invitation or join a friend'); controls(); counters(); }
catch (error) { notice(error); status('Transport failed to load · reload to retry'); }
