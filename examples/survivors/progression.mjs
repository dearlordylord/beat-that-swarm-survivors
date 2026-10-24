// Presentation/storage adapter. Every game decision is made by the Bend core.
import Core from "./dist/menu-progression.mjs";
import * as Catalog from "./content.mjs";

const KEY = "nightfall-survivors-v1";
const NAT_MAX = 281474976710655;
const list = values => values.reduceRight((tail, head) => ({ $: "Con", head, tail }), { $: "Nil" });
const array = values => {
  const result = [];
  for (let row = values; row?.$ === "Con"; row = row.tail) result.push(row.head);
  return result;
};

// Generic JSON-value transport, with no game-specific fields or rules.
export function toBend(value) {
  if (value === null || value === undefined) return { $: "JNull" };
  if (typeof value === "boolean") return { $: "JBoolean", value };
  if (typeof value === "string") return { $: "JText", value };
  if (typeof value === "number") {
    if (!Number.isFinite(value)) return { $: "JNull" };
    const source = String(Math.abs(value));
    const [mantissa, exponent = "0"] = source.split("e");
    const [whole, fraction = ""] = mantissa.split(".");
    const scale = fraction.length - Number(exponent);
    let numerator = Number(whole + fraction), denominator = 1;
    if (scale >= 0) denominator = 10 ** scale;
    else numerator *= 10 ** -scale;
    if (numerator > NAT_MAX || denominator > NAT_MAX) {
      const numeratorDigits = (whole + fraction + (scale < 0 ? "0".repeat(-scale) : "")).replace(/^0+/, "") || "0";
      const denominatorDigits = scale > 0 ? "1" + "0".repeat(scale) : "1";
      const digits = source => list([...source].reverse().map(Number));
      return { $: "JDecimal", value: String(value), numerator: digits(numeratorDigits), denominator: digits(denominatorDigits), negative: value < 0 };
    }
    return { $: "JNumber", numerator, denominator, negative: value < 0 };
  }
  if (Array.isArray(value)) return { $: "JSequence", values: list(value.map(toBend)) };
  if (typeof value === "object") {
    const entries = Object.entries(value);
    return { $: "JObject", keys: list(entries.map(([key]) => key)), values: list(entries.map(([, item]) => toBend(item))) };
  }
  throw new TypeError("Bend menu transport expects a JSON value");
}
export function fromBend(value) {
  switch (value?.$) {
    case "JNull": return null;
    case "JBoolean": case "JText": return value.value;
    case "JDecimal": return Number(value.value);
    case "JRatio": {
      const numerator = array(value.numerator).reverse().join("") || "0";
      const denominator = array(value.denominator).reverse().join("") || "1";
      const n = Number(numerator), d = Number(denominator);
      if (Number.isFinite(n) && Number.isFinite(d)) return n / d;
      // Avoid Infinity/Infinity and premature underflow when decoding an exact ratio.
      // This is a generic numeric codec, independent of all game rules.
      const shift = 40 + denominator.length - numerator.length;
      const scaled = shift >= 0
        ? BigInt(numerator) * 10n ** BigInt(shift) / BigInt(denominator)
        : BigInt(numerator) / (BigInt(denominator) * 10n ** BigInt(-shift));
      return Number(`${scaled}e${-shift}`);
    }
    case "JNumber": return (value.negative ? -1 : 1) * value.numerator / value.denominator;
    case "JSequence": return array(value.values).map(fromBend);
    case "JObject": {
      const keys = array(value.keys), values = array(value.values);
      return Object.fromEntries(keys.map((key, index) => [key, fromBend(values[index])]));
    }
    default: throw new TypeError("Unknown Bend menu transport value");
  }
}
const catalog = toBend(Catalog);
const decode = fromBend;
export const freshProfile = () => decode(Core.fresh());
export function loadProfile() {
  try {
    return decode(Core.normalize(toBend(JSON.parse(localStorage.getItem(KEY) || "null")), catalog));
  } catch {
    return freshProfile();
  }
}
export function saveProfile(profile) {
  try {
    localStorage.setItem(KEY, JSON.stringify(profile));
    return true;
  } catch { return false; }
}
export function upgradeCost(profile, id) {
  return decode(Core.upgrade_cost(toBend(profile), toBend(id), catalog)) ?? Infinity;
}
export function upgradeStatus(profile, id) {
  return decode(Core.upgrade_status(toBend(profile), toBend(id), catalog));
}
export function purchaseStatus(profile, kind, id) {
  return decode(Core.purchase_status(toBend(profile), kind, toBend(id), catalog));
}
export function validateSetup(profile, setup) {
  return decode(Core.validate_setup(toBend(profile), toBend(setup), catalog));
}
function apply(profile, outcome) {
  if (outcome.$ === "JNull") return false;
  Object.assign(profile, decode(outcome));
  saveProfile(profile);
  return true;
}
export function buyUpgrade(profile, id) {
  return apply(profile, Core.buy_upgrade(toBend(profile), toBend(id), catalog));
}
export const metaCode = profile => Core.meta_code(toBend(profile));
export const requirementsMet = (profile, item) => Core.requirements_met(toBend(profile), toBend(item));
export const allowedWeapons = profile => Core.allowed_weapons(toBend(profile), catalog);
export const isUnlocked = (profile, kind, id) => Core.unlocked(toBend(profile), kind, toBend(id), catalog);
export function unlock(profile, kind, id) {
  return apply(profile, Core.purchase(toBend(profile), kind, toBend(id), catalog));
}
export function observeRun(history, frame) {
  return decode(Core.observe_run(toBend(history), toBend(frame)));
}
export function recordRun(profile, frame) {
  const result = decode(Core.record_run(toBend(profile), toBend(frame), catalog));
  Object.assign(profile, result.profile);
  saveProfile(profile);
  return result.added;
}
