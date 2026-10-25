# Co-op ownership traversal stack overflow

The host report from revision `35d8c4a` failed at world tick 6 with
`Maximum call stack size exceeded` and repeated `owned_rows_run` frames.
The previous implementation constructed each output cons around a recursive
call. Consequently the generated JavaScript retained one call frame per ECS
row. This traversal visits allocated rows, including inactive pool slots;
the failure did not require a large visible enemy crowd.

`owned_rows_run` now uses a Bend context map with a tail-recursive accumulator
and a final reverse. Both traversals emit JavaScript `for (;;)` loops. Mapping
still calls the existing ownership function, and preserves every row and its
position. There is no generated-code patch, pool reduction or JavaScript game
implementation in this fix.

## Checks

- The original emitted ownership traversal fails at 1,456 rows under Node's
  `--stack_size=192`, reproducing its repeated recursive stack frames.
- The replacement processes the same rows under that limit and also passes
  100,000 rows. The normal-stack original and small-stack replacement produce
  the same 1,456-row digest:
  `99fe22ed70760773431242d8d1a92c4d35c354d1b3f146da3bb2b83737f2c40c`.
- Two universal Bend laws equate the accumulator and public map with an
  independent direct recursive specification. Mutants that skip a row or
  reverse the result are rejected. These prove values and order; they do not
  prove properties of a JavaScript compiler or browser stack.
- A controlled worker replay on Bun/JavaScriptCore reaches tick 1,004 and one
  shared reward cycle. All 700 host/guest observations, including frames,
  receipts and admission records, are byte-identical before and after the
  change. Both complete observation files have SHA-256
  `c4359f31b185f157a6e816b1992199512f3a8929898791cf01d028ec0e413947`.
- A real Iroh Chromium check starts with the guest heading's question mark,
  connects, and moves both players for five seconds: host tick 132, guest tick
  125, no worker or page errors. This is not a physical Safari qualification.

The original generated core digest is
`e84903bf1719958348284291fe60bb61957bd39f9528a423a87ae8f1dfcd61a5`;
the checked replacement digest is
`db4ca500240d43bffe186b909731e05349fdf017d3ff1cb100c484ec20f3b311`.
Temporary replay scripts and output were used for diagnosis; the new laws and
mutation checks remain in the repository's existing Bend gates.

Joining while the guest heading says “Your place is ready?” initiates the
normal readiness handshake. The reported exception occurred during an already
running game step and identifies the ownership traversal, not that UI action.
