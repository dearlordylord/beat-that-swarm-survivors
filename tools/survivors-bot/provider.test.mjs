import test from 'node:test';
import assert from 'node:assert/strict';
import * as Effect from 'effect/Effect';
import * as Layer from 'effect/Layer';
import * as ConfigProvider from 'effect/ConfigProvider';
import * as Deferred from 'effect/Deferred';
import * as Fiber from 'effect/Fiber';
import * as TestClock from 'effect/testing/TestClock';
import { DecisionModel } from 'effect/ai';
import { TypeSafeClient, TypeSafeDecisionModel } from '@effect/ai-typesafe';
import { classifyDecisionEffect, liveModelLayer } from './provider.mjs';

const request = {
  runId: 'test-run', decisionSeq: 3, candidatesHash: 'fixture-hash', kind: 'upgrade',
  snapshot: { objective: 'survive to dawn', hp: 40, maxHp: 100 },
  candidates: [{ id: 'offer_0', description: 'Increase weapon damage', offerIndex: 0 },
    { id: 'offer_1', description: 'Heal and increase maximum health', offerIndex: 1 }],
};
const fakeLayer = (decide) => Layer.effect(DecisionModel.DecisionModel, DecisionModel.make({ decide }));
const run = (input, decide) => Effect.runPromise(Effect.result(
  classifyDecisionEffect(input).pipe(Effect.provide(fakeLayer(decide))),
));

for (const count of [2, 3]) test(`exactly ${count} legal criteria; selected label wins over argmax`, async () => {
  let calls = 0;
  const input = structuredClone(request);
  if (count === 3) input.candidates.push({ id: 'offer_2', description: 'Improve pickup range', offerIndex: 2 });
  const result = await run(input, ({ state, decisions }) => {
    calls++;
    assert.deepEqual(Object.keys(decisions.choice.criteria), input.candidates.map(({ id }) => id));
    assert.equal(decisions.choice._tag, 'Classify');
    assert.equal(state.snapshot.hp, 40);
    return Effect.succeed({ answers: { choice: { _tag: 'Classify', label: 'offer_1',
      probabilities: count === 2 ? { offer_0: .8, offer_1: .2 } : { offer_0: .7, offer_1: .2, offer_2: .1 } } },
      usage: { inputTokens: 20, outputTokens: 2 } });
  });
  assert.equal(result._tag, 'Success');
  assert.equal(result.success.selectedCandidateId, 'offer_1');
  assert.equal(result.success.runId, input.runId);
  assert.equal(result.success.decisionSeq, input.decisionSeq);
  assert.equal(result.success.candidatesHash, input.candidatesHash);
  assert.equal(result.success.usage.inputTokens, 20);
  assert.equal(calls, 1);
});

test('invalid selected label is rejected and error details stay sanitized', async () => {
  const result = await run(request, () => Effect.succeed({ answers: {
    choice: { _tag: 'Classify', label: 'secret-illegal-choice', probabilities: { offer_0: .5, offer_1: .5 } },
  } }));
  assert.equal(result._tag, 'Failure');
  assert.equal(result.failure.code, 'provider-unavailable');
  assert.doesNotMatch(result.failure.message, /secret/);
});

test('provider error has no retry and no raw details', async () => {
  let calls = 0;
  const result = await run(request, () => { calls++; return Effect.fail(new Error('secret HTTP body')); });
  assert.equal(calls, 1);
  assert.equal(result._tag, 'Failure');
  assert.equal(result.failure.code, 'provider-unavailable');
  assert.doesNotMatch(result.failure.message, /secret/);
});

test('malformed candidates are rejected before dispatch', async () => {
  let calls = 0;
  for (const candidates of [[], [request.candidates[0]], [request.candidates[0], request.candidates[0]]]) {
    const result = await run({ ...request, candidates }, () => { calls++; return Effect.never; });
    assert.equal(result._tag, 'Failure');
    assert.equal(result.failure.code, 'invalid-request');
  }
  assert.equal(calls, 0);
});

test('timeout interrupts the in-flight provider using virtual time', async () => {
  let interrupted = false;
  const result = await Effect.runPromise(Effect.gen(function* () {
    const entered = yield* Deferred.make();
    const model = fakeLayer(() => Deferred.succeed(entered, undefined).pipe(
      Effect.andThen(Effect.never), Effect.ensuring(Effect.sync(() => { interrupted = true; })),
    ));
    const fiber = yield* classifyDecisionEffect(request, { timeoutMs: 2000 }).pipe(
      Effect.provide(model), Effect.result, Effect.forkChild,
    );
    yield* Deferred.await(entered);
    yield* TestClock.adjust('2 seconds');
    return yield* Fiber.join(fiber);
  }).pipe(Effect.provide(TestClock.layer())));
  assert.equal(result._tag, 'Failure');
  assert.equal(result.failure.code, 'timeout');
  assert.equal(interrupted, true);
});

test('missing credentials are reported without acquiring an HTTP request', async () => {
  const result = await Effect.runPromise(Effect.result(classifyDecisionEffect(request).pipe(
    Effect.provide(liveModelLayer),
    Effect.provide(ConfigProvider.layer(ConfigProvider.fromUnknown({}))),
  )));
  assert.equal(result._tag, 'Failure');
  assert.equal(result.failure.code, 'missing-credential');
});

test('real TypeSafe model adapter emits a single categorical request and decodes its selected label', async () => {
  let calls = 0;
  const model = TypeSafeDecisionModel.model('jev-latest').pipe(Layer.provide(
    Layer.succeed(TypeSafeClient.TypeSafeClient, {
      systemOne: (wire) => {
        calls++;
        assert.equal(wire.model, 'jev-latest');
        assert.equal(wire.questions.choice.type, 'choice');
        assert.deepEqual(Object.keys(wire.questions.choice.criteria), ['offer_0', 'offer_1']);
        assert.equal(wire.state.runId, request.runId);
        return Effect.succeed({ model: 'jev-latest', answers: { choice: {
          type: 'choice', choice: 'offer_1', probabilities: { offer_0: .8, offer_1: .2 }, confidence: .2,
        } }, usage: { input_tokens: 42, output_tokens: 1 } });
      },
      listModels: () => Effect.die('unexpected model discovery'),
    }),
  ));
  const result = await Effect.runPromise(classifyDecisionEffect(request).pipe(Effect.provide(model)));
  assert.equal(result.selectedCandidateId, 'offer_1');
  assert.equal(result.usage.inputTokens, 42);
  assert.equal(calls, 1);
});

test('goal decisions accept up to eight candidates without offer indices', async () => {
  const input = { ...request, kind: 'goal', snapshot: { objective: 'survive as long as possible', mode: 'Endless' },
    candidates: Array.from({ length: 8 }, (_, index) => ({ id: `goal_${index}`, description: `Move toward safe point ${index}` })) };
  let calls = 0;
  const model = TypeSafeDecisionModel.model('jev-latest').pipe(Layer.provide(
    Layer.succeed(TypeSafeClient.TypeSafeClient, {
      systemOne: (wire) => {
        calls++;
        assert.equal(wire.questions.choice.type, 'choice');
        assert.equal(Object.keys(wire.questions.choice.criteria).length, 8);
        assert.match(wire.questions.choice.instructions, /movement goal/);
        assert.match(wire.questions.choice.instructions, /snapshot.objective/);
        assert.equal(wire.state.snapshot.mode, 'Endless');
        return Effect.succeed({ model: 'jev-latest', answers: { choice: {
          type: 'choice', choice: 'goal_6', probabilities: Object.fromEntries(input.candidates.map(({ id }) => [id, .125])), confidence: .2,
        } } });
      },
      listModels: () => Effect.die('unexpected discovery'),
    }),
  ));
  const result = await Effect.runPromise(classifyDecisionEffect(input).pipe(Effect.provide(model)));
  assert.equal(result.selectedCandidateId, 'goal_6');
  assert.equal(calls, 1);
});

test('kind-specific request constraints reject missing upgrade index and oversized goal sets', async () => {
  let calls = 0;
  const noIndices = request.candidates.map(({ id, description }) => ({ id, description }));
  const oversized = Array.from({ length: 9 }, (_, index) => ({ id: `g${index}`, description: 'Goal' }));
  for (const input of [{ ...request, candidates: noIndices }, { ...request, kind: 'goal', candidates: oversized }, { ...request, kind: 'invented' }]) {
    const result = await run(input, () => { calls++; return Effect.never; });
    assert.equal(result._tag, 'Failure');
    assert.equal(result.failure.code, 'invalid-request');
  }
  assert.equal(calls, 0);
});
