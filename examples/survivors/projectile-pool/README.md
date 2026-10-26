# Shared projectile assignment

[`projectile-pool.bend`](../projectile-pool.bend) owns the allocator API and
assignment rules. [`game.bend`](../game.bend) supplies world-derived availability
and integrates the returned plan. Physical identity and logical weapon position
have separate meanings; callers must provide availability from the same frame.

[`LAWS.bend`](LAWS.bend) and [`PROOF.bend`](PROOF.bend) specify and prove the pure
allocator contract. They do not prove that a caller supplied genuinely free
identities, whole-game equivalence or correctness of the Patricia index.

Run `bend examples/survivors/projectile-pool/PROOF.bend --verdict` from the
repository root. The ordinary `check.sh` also checks this proof.
