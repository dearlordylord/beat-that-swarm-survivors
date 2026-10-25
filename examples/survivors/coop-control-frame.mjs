// Byte routing for the current plaintext connection-control protocol only.
// Snapshot decoding is compressed-only and does not interpret control bytes.
const prefix = new TextEncoder().encode('BSC-HS1|');
const decoder = new TextDecoder('utf-8', {fatal: true});
const MAX_CONTROL_BYTES = 160; // The existing Connection.decode byte-text limit.

export function decodeControlFrame(bytes, decode) {
  if (!(bytes instanceof Uint8Array)) throw new TypeError('Control input must be bytes.');
  if (bytes.byteLength < prefix.byteLength ||
      !prefix.every((value, index) => bytes[index] === value)) return {$: 'None'};
  if (bytes.byteLength > MAX_CONTROL_BYTES) throw new RangeError('Connection control is too large.');
  const control = decode(decoder.decode(bytes));
  if (control.$ !== 'Some') throw new TypeError('Invalid connection control.');
  return control;
}
