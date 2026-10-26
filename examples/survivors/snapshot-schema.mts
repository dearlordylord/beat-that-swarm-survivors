// Temporary explicit wire schema while the network boundary replacement is designed.
import type { Schema } from "./observation-schema.mts"
export const roots = {
  game: { ref: "GameObservation" },
  core: { ref: "CoopCoreObservation" },
  journal: { ref: "CoopHitJournalState" },
  admission: { ref: "CoopSessionState" },
  receipt: { ref: "CoopSessionReceipt" }
}
export const schema: Schema = {
  BodyIndexIndexu32: {
    Empty: [],
    Fork: [
      ["sample", "u32"],
      ["mask", "u32"],
      ["zero", { ref: "BodyIndexIndexu32" }],
      ["one", { ref: "BodyIndexIndexu32" }]
    ],
    Item: [
      ["key", "u32"],
      ["value", "u32"]
    ]
  },
  CoopCombatPredictionPolicyWitness: {
    Witness: [
      ["kind", "u32"],
      ["tick", "u32"],
      ["shot", "u32"],
      ["target", "u32"],
      ["shotBirth", "u32"],
      ["targetBirth", "u32"],
      ["x0", "f32"],
      ["y0", "f32"],
      ["x1", "f32"],
      ["y1", "f32"],
      ["ex0", "f32"],
      ["ey0", "f32"],
      ["ex1", "f32"],
      ["ey1", "f32"],
      ["radius", "f32"],
      ["time", "f32"]
    ]
  },
  CoopCombatPredictionScene: {
    Scene: [
      ["own", "u32"],
      ["players", { list: { ref: "GamePlayerSnapshot" } }],
      ["snapshots", { list: { ref: "GameSnapshot" } }],
      ["births", { ref: "BodyIndexIndexu32" }],
      ["directions", { ref: "CoopSessionDirections" }],
      ["contacts", { list: { ref: "CoopCombatPredictionPolicyWitness" } }],
      ["tick", "u32"],
      ["diagnostics", "bool"]
    ]
  },
  CoopCoreObservation: {
    NoObservation: [],
    StepObservation: [
      ["tick", "u32"],
      ["phase", "u32"],
      ["advanced", "bool"],
      ["contacts", { list: { ref: "CoopHitJournalHitEvent" } }],
      ["contactsOmitted", "u32"]
    ],
    ViewObservation: [
      ["game", { ref: "GameObservation" }],
      ["predictionAllowed", "bool"],
      ["stepDistance", "f32"],
      ["ownPlayerId", "u32"],
      ["choicePending", "bool"],
      ["round", "u32"],
      ["required", { list: "u32" }],
      ["players", { list: { ref: "GameComponentsPlayerRecord" } }],
      ["forecast", { ref: "CoopCombatPredictionScene" }]
    ]
  },
  CoopHitJournalHitEvent: {
    HitEvent: [
      ["id", "string"],
      ["tick", "u32"],
      ["kind", "u32"],
      ["shotId", "string"],
      ["shotSeed", "u32"],
      ["targetSeed", "u32"],
      ["targetGeneration", "u32"],
      ["fraction", "f32"],
      ["impactX", "f32"],
      ["impactY", "f32"],
      ["targetAtImpactX", "f32"],
      ["targetAtImpactY", "f32"],
      ["radius", "f32"],
      ["outcome", "u32"]
    ]
  },
  CoopHitJournalState: {
    State: [
      ["epoch", "u32"],
      ["now", "u32"],
      ["events", { list: { ref: "CoopHitJournalHitEvent" } }],
      ["overflow", "u32"],
      ["expired", "u32"]
    ]
  },
  CoopSessionDirections: {
    Directions: [
      ["x0", "f32"],
      ["y0", "f32"],
      ["x1", "f32"],
      ["y1", "f32"]
    ]
  },
  CoopSessionLane: {
    Lane: [
      ["lastSeq", "u32"],
      ["inputSeq", "u32"],
      ["appliedSeq", "u32"],
      ["appliedTick", "u32"],
      ["receivedAt", "u32"],
      ["x", "u32"],
      ["y", "u32"]
    ]
  },
  CoopSessionReceipt: {
    Receipt: [
      ["seq", "u32"],
      ["worldTick", "u32"],
      ["x", "u32"],
      ["y", "u32"],
      ["applied", "bool"]
    ]
  },
  CoopSessionState: {
    State: [
      ["session", "u32"],
      ["clock", "u32"],
      ["host", { ref: "CoopSessionLane" }],
      ["guest", { ref: "CoopSessionLane" }],
      ["guestConnected", "bool"],
      ["ended", "bool"]
    ]
  },
  EnemyCombatState: {
    State: [
      ["spatial", { ref: "EnemySpatialSpatial" }],
      ["archetype", "u32"],
      ["identity", "u32"],
      ["vitals", { ref: "GameComponentsVitals" }],
      ["status", { ref: "GameComponentsStatus" }]
    ]
  },
  EnemyEffectsBurn: {
    Burn: [
      ["ticks", "u32"],
      ["sourcePlayer", { ref: "Maybeu32" }]
    ]
  },
  EnemyEffectsSlow: {
    Slow: [
      ["ticks", "u32"],
      ["frozen", "bool"]
    ]
  },
  EnemySpatialSpatial: {
    Spatial: [
      ["x", "f32"],
      ["y", "f32"],
      ["age", "u32"],
      ["radius", "f32"]
    ]
  },
  GameActorRef: {
    EnemyRef: [["identity", "u32"]],
    PickupRef: [["identity", "u32"]],
    ProjectileRef: [["identity", "u32"]]
  },
  GameComponentsPlayerRecord: {
    PlayerRecord: [
      ["id", "u32"],
      ["player", { ref: "RunStatePlayerState" }],
      ["connected", "bool"]
    ]
  },
  GameComponentsShotPayload: {
    ShotPayload: [
      ["weapon", "u32"],
      ["damage", "u32"],
      ["active", "bool"]
    ]
  },
  GameComponentsStatus: {
    Status: [
      ["slow", { ref: "EnemyEffectsSlow" }],
      ["burn", { ref: "EnemyEffectsBurn" }]
    ]
  },
  GameComponentsTrajectory: {
    Trajectory: [
      ["vx", "f32"],
      ["vy", "f32"],
      ["life", "u32"],
      ["pierce", "u32"],
      ["visited", { list: "u32" }],
      ["weaponOwner", "u32"],
      ["logicalSlot", "u32"],
      ["sourcePlayer", { ref: "Maybeu32" }]
    ]
  },
  GameComponentsVitals: {
    Vitals: [
      ["health", "u32"],
      ["maximum", "u32"]
    ]
  },
  GameObservation: {
    Observation: [
      ["presentation", { ref: "GamePresentationContext" }],
      ["run", { ref: "GameRun" }],
      ["offers", { list: { ref: "GameOffer" } }],
      ["enemies", { list: { ref: "EnemyCombatState" } }],
      ["order", { list: { ref: "GameActorRef" } }],
      ["projectiles", { list: { ref: "ProjectileStateState" } }],
      ["pickups", { list: { ref: "PickupStateState" } }]
    ]
  },
  GameOffer: {
    Offer: [
      ["kind", "u32"],
      ["id", "u32"],
      ["level", "u32"]
    ]
  },
  GamePlayerSnapshot: {
    PlayerSnapshot: [
      ["id", "u32"],
      ["run", { ref: "GameRun" }],
      ["connected", "bool"]
    ]
  },
  GamePresentationContext: {
    PresentationContext: [
      ["worldSize", "f32"],
      ["worldMargin", "f32"],
      ["relicX", "f32"],
      ["relicY", "f32"],
      ["runLength", "u32"]
    ]
  },
  GameRun: {
    Run: [
      ["session", { ref: "RunStateSession" }],
      ["player", { ref: "RunStatePlayerState" }]
    ]
  },
  GameSnapshot: {
    EnemySnapshot: [["enemy", { ref: "EnemyCombatState" }]],
    PickupSnapshot: [["pickup", { ref: "PickupStateState" }]],
    ProjectileSnapshot: [["projectile", { ref: "ProjectileStateState" }]]
  },
  Maybeu32: { None: [], Some: [["value", "u32"]] },
  PickupStateItem: {
    Chest: [],
    Gold: [["coins", "u32"]],
    Healing: [["health", "u32"]],
    Relic: [["stage", "u32"]],
    Xp: [
      ["amount", "u32"],
      ["accumulator", "bool"]
    ]
  },
  PickupStatePayload: {
    Payload: [
      ["item", { ref: "PickupStateItem" }],
      ["generation", "u32"],
      ["active", "bool"]
    ]
  },
  PickupStateState: {
    State: [
      ["spatial", { ref: "EnemySpatialSpatial" }],
      ["payload", { ref: "PickupStatePayload" }],
      ["identity", "u32"]
    ]
  },
  ProjectileStateSide: { HostileShot: [], PlayerShot: [] },
  ProjectileStateState: {
    State: [
      ["spatial", { ref: "EnemySpatialSpatial" }],
      ["identity", "u32"],
      ["side", { ref: "ProjectileStateSide" }],
      ["payload", { ref: "GameComponentsShotPayload" }],
      ["trajectory", { ref: "GameComponentsTrajectory" }]
    ]
  },
  RunStatePlayerState: {
    PlayerState: [
      ["px", "f32"],
      ["py", "f32"],
      ["hp", "u32"],
      ["maxHp", "u32"],
      ["character", "u32"],
      ["weapons", { list: "u32" }],
      ["passives", { list: "u32" }],
      ["invuln", "u32"],
      ["arcana", "u32"],
      ["meta", "u32"],
      ["revivals", "u32"],
      ["rerolls", "u32"],
      ["banishes", "u32"],
      ["skips", "u32"],
      ["bannedWeapons", "u32"],
      ["bannedPassives", "u32"]
    ]
  },
  RunStateSession: {
    Session: [
      ["phase", "u32"],
      ["tick", "u32"],
      ["xp", "u32"],
      ["xpNeed", "u32"],
      ["level", "u32"],
      ["kills", "u32"],
      ["gold", "u32"],
      ["seed", "u32"],
      ["stage", "u32"],
      ["bosses", "u32"],
      ["mode", "u32"],
      ["enemyKinds", { list: "u32" }],
      ["relicCollected", "u32"]
    ]
  }
}
