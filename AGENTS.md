# Examples

Every example consumes the published BendHub distribution of Bendvy. Pin its
package version in Bend imports and record its content hash in
`bendhub-dependencies.json`. ECS source checkouts and vendored ECS modules are
not example dependencies.

After changing imports or adding an example, run
`python3 scripts/check-dependencies.py`; each example must reach the declared
BendHub package through its import graph. Use `--registry` when changing the
package pin to verify the public name and manifest hash.

Keep game logic in Bend. Preserve native launch without Node.js; Node is allowed
for optional browser presentation and development checks. Follow each example's
README for its functional checks. Generated binaries, caches, captures and player
profiles belong outside tracked source.
