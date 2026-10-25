// Trusted local Bend ABI. Only reshape collections for the existing renderer.
// Network and file input must be checked before it reaches this adapter.
export function rows(list) {
  const values = [];
  for (let node = list; node.$ === 'Con'; node = node.tail) values.push(node.head);
  return values;
}
function fields({$, ...value}) { return value; }
function observation(value) {
  const {$, bodies, offers, weapons, passives, enemiesKilled, ...scalars} = value;
  return {...scalars, bodies:rows(bodies).map(b => [b.x,b.y,b.kind,b.variant,b.hp,b.maxHp,b.age,b.seed,b.radius]),
    offers:rows(offers).map(fields), weapons:rows(weapons),passives:rows(passives),enemiesKilled:rows(enemiesKilled)};
}
/** @param {import('./observation-schema.generated').BendMaybe<import('./observation-schema.generated').GameObservation>} maybe */
export function gameFrame(maybe) {
  return maybe.$ === 'None' ? null : observation(maybe.value);
}
/** @param {import('./observation-schema.generated').BendMaybe<import('./observation-schema.generated').CoopCoreObservation>} maybe */
export function coreFrame(maybe) {
  if (maybe.$ === 'None') return null;
  const value = maybe.value;
  if (value.$ === 'Clock') return fields(value);
  const {$, players, requiredPlayers, ...scalars} = value.details;
  return {...observation(value.base),...scalars,players:rows(players).map(fields),requiredPlayers:rows(requiredPlayers)};
}

export function projectileFrame(value) {
  return {shots:rows(value.shots).map(fields),contacts:rows(value.contacts).map(fields),corpses:rows(value.corpses).map(fields)};
}
