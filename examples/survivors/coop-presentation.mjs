// Browser data adapter. Bend owns admission, clocks, lifetimes and interpolation.
import Playback from './dist/coop-playback.mjs';
import Wire from './dist/coop-playback-wire.mjs';
import Contacts from './dist/coop-contact-playback.mjs';
import HitJournal from './dist/coop-hit-journal.mjs';
import HitEffects from './dist/coop-hit-effects.mjs';

const array = list => {
  const rows = [];
  for (; list.$ === 'Con'; list = list.tail) rows.push(list.head);
  return rows;
};
const list = rows => {
  let result = {$:'Nil'};
  for (let index = rows.length - 1; index >= 0; index--)
    result = {$:'Con',head:rows[index],tail:result};
  return result;
};
const micros = now => {
  const value = Math.floor(now * 1000);
  if (!Number.isSafeInteger(value) || value < 0) throw Error('Invalid local presentation clock.');
  return value;
};
function actorMetadata(actor, frame) {
  if (actor.kind === 0) {
    const enemy = frame.enemies.find(value => value.identity === actor.key);
    if (!enemy) throw Error('An enemy actor has no named render metadata.');
    return {type:'enemy', value:{...enemy,x:actor.x,y:actor.y,lifetime:actor.generation,tick:frame.tick}};
  }
  if (actor.kind === 1 || actor.kind === 7) {
    const projectile = frame.projectiles.find(value => value.identity === actor.key);
    if (!projectile) throw Error('A projectile actor has no named render metadata.');
    return {type:'projectile', value:{...projectile,x:actor.x,y:actor.y,lifetime:actor.generation,owner:actor.owner,tick:frame.tick}};
  }
  if ([2,3,4,5,9].includes(actor.kind)) {
    const pickup = frame.pickups.find(value => value.slot === actor.key);
    if (!pickup) throw Error('A pickup actor has no named render metadata.');
    return {type:'pickup',value:{...pickup,x:actor.x,y:actor.y,lifetime:actor.generation,tick:frame.tick}};
  }
  const body = frame.bodies.find(value => value[7] === actor.key);
  if (!body) throw Error('An item actor has no render metadata.');
  const value=body.slice(); value[0]=actor.x; value[1]=actor.y;
  value[9]=actor.generation; value[10]=actor.owner; value[11]=frame.tick;
  return {type:'body',value};
}
function positionedMetadata(metadata, point) {
  if (metadata.type === 'body') {
    const value=metadata.value.slice(); value[0]=point.x; value[1]=point.y;
    return {type:'body',value};
  }
  return {type:metadata.type,value:{...metadata.value,x:point.x,y:point.y}};
}
function observations(records, order) {
  const bodies=[],enemies=[],projectiles=[],pickups=[];
  for(const record of records) {
    if(record.type==='body') bodies.push(record.value);
    else if(record.type==='enemy') enemies.push(record.value);
    else if(record.type==='pickup') pickups.push(record.value);
    else projectiles.push(record.value);
  }
  const bodyIds=new Set(bodies.map(value=>value[7]));
  const enemyIds=new Set(enemies.map(value=>value.identity));
  const pickupIds=new Set(pickups.map(value=>value.slot));
  const projectileIds=new Set(projectiles.map(value=>value.identity));
  const actorOrder=order.filter(reference=>Object.hasOwn(reference,'enemy')?enemyIds.has(reference.enemy):
    Object.hasOwn(reference,'projectile')?projectileIds.has(reference.projectile):
    Object.hasOwn(reference,'pickup')?pickupIds.has(reference.pickup):bodyIds.has(reference.body));
  return {bodies,enemies,projectiles,pickups,actorOrder};
}
export class ObservationPresentation {
  constructor() { this.reset(); }
  reset() {
    this.state = Playback.fresh(); this.frames = new Map(); this.metadata = new Map();
    this.currentSample = null; this.journal = HitJournal.fresh(0);
    this.contacts = Contacts.prepare(this.journal); this.effects = HitEffects.fresh();
  }
  push(frame, receivedAt = performance.now()) {
    if (!frame.combatForecast || !Number.isInteger(frame.observationSeq))
      throw Error('The authoritative frame is missing its combat state or observation identity.');
    if (!this.frames.size) this.state = Playback.fresh_for(frame.ownPlayerId);
    const extras = [];
    for (const body of frame.bodies || []) {
      const projected = Wire.extra_actor(body[7],body[2],body[3],body[0],body[1],body[6],body[4],frame.tick);
      if (projected.$ === 'Some') extras.push(projected.value);
    }
    for (const pickup of frame.pickups) {
      const item=pickup.item;
      const payload=item.kind==='xp'?{$:'Xp',amount:item.amount,accumulator:item.accumulator}:
        item.kind==='gold'?{$:'Gold',coins:item.coins}:
        item.kind==='healing'?{$:'Healing',health:item.health}:
        item.kind==='chest'?{$:'Chest'}:{$:'Relic',stage:item.stage};
      extras.push(Wire.pickup_actor({$:'State',spatial:{$:'Spatial',x:pickup.x,y:pickup.y,age:pickup.age,radius:pickup.radius},
        payload:{$:'Payload',item:payload,generation:pickup.generation,active:pickup.active},identity:pickup.slot}));
    }
    const projected = Wire.project(frame.combatForecast,frame.observationSeq,micros(receivedAt),list(extras));
    if (!Playback.accepts(this.state,projected)) return;
    const records = array(projected.bodies).map(actor=>actorMetadata(actor,frame));
    this.frames.set(frame.observationSeq,{...frame,...observations(records,frame.actorOrder)});
    this.metadata.set(frame.observationSeq,new Map(array(projected.bodies).map((actor,index)=>
      [`${actor.key}:${actor.generation}`,records[index]])));
    this.state = Playback.push(this.state,projected);
    const retained = new Set(array(Playback.observations(this.state)));
    for (const observation of this.frames.keys())
      if (!retained.has(observation)) { this.frames.delete(observation); this.metadata.delete(observation); }
    if (frame.contactJournal) {
      this.effects = HitEffects.receive(this.effects,frame.contactJournal);
      this.journal = frame.contactJournal; this.contacts = Contacts.prepare(this.journal);
    }
  }
  sample(now = performance.now()) {
    this.state = Playback.advance(this.state,micros(now));
    const selected = Playback.sample(this.state);
    if (selected.$ !== 'Some') return null;
    const corrected = Contacts.project(this.state,selected.value,this.contacts);
    const sample = corrected.sample, source = this.frames.get(sample.baseObservation);
    this.currentSample = sample;
    this.effects = HitEffects.advance(this.effects,this.journal,sample);
    if (!source) throw Error('The selected authoritative frame is no longer retained.');
    const playerPositions = new Map(array(sample.players).map(actor => [actor.key,actor]));
    const players = source.players?.map(player => {
      const point = playerPositions.get(player.id);
      return point ? {...player,px:point.x,py:point.y} : player;
    });
    const records = array(sample.bodies).map(point => {
      const metadata=this.metadata.get(sample.baseObservation)?.get(`${point.key}:${point.generation}`);
      if(!metadata) throw Error('A displayed actor has no retained lifetime metadata.');
      return positionedMetadata(metadata,point);
    });
    const actors=observations(records,source.actorOrder);
    const own = playerPositions.get(source.ownPlayerId);
    return {...source,...actors,tick:sample.tick,players,combatImpacts:array(HitEffects.render(this.effects,sample)),
      px:own?.x ?? source.px,py:own?.y ?? source.py,
      remotePresentation:{sampledAt:now,sourceTick:source.tick,tick:sample.tick,fraction:sample.fraction,alpha:sample.alpha,
        baseObservation:sample.baseObservation,nextObservation:sample.nextObservation,
        retainedFrames:this.frames.size,recovered:this.state.recovered,buffering:Playback.is_buffering(this.state)}};
  }
  enemyMetadata(identity,generation) {
    for(const metadata of this.metadata.values()) {
      const record=metadata.get(`${identity}:${generation}`);
      if(record?.type==='enemy') return record.value;
    }
    return null;
  }
}
