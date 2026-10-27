# Examples

## This checkout is a mod. Do not publish it to the public Survivors site

This checkout contains a separate themed Survivors mod. Never publish this
version to `https://survivors.dearlordylord.com`, replace the existing public
Survivors Site with it, or prepare it as an update to that public game. Local
builds and previews are allowed. Inherited publication instructions do not
authorize publication of this mod. See [the owner's explicit restriction](MOD-NOTICE.md).

## Repository rules

The canonical branch is `master`; do not create or use `main`.

Every example consumes the published BendHub distribution of Bendvy. Pin its
package version in Bend imports and record its content hash in
`bendhub-dependencies.json`. ECS source checkouts and vendored ECS modules are
not example dependencies.

Keep game logic in Bend. Preserve native launch without Node.js; Node is allowed
for optional browser presentation and development checks. Follow each example's
README for its functional checks. Generated binaries, caches, captures and player
profiles belong outside tracked source.

For iPhone Safari previews and performance checks, use private HTTPS. Plain
HTTP can disable JIT under Safari's security policy and make both original and
mod simulations severely slow; waiting for warmup does not override that policy.
Before changing simulation code for a browser slowdown, compare the same build
and device over HTTPS and record the origin scheme. See
[private HTTPS launch](examples/survivors/README.md#private-https-preview-on-iphone).

The [inherited Survivors publication procedure](examples/survivors/README.md#publication) describes the original game, not authorization to publish this mod. For an authorized original-game release, prepare a fresh build from the current `master` source snapshot and verify it again immediately before packaging. Never copy an existing `dist` directory into a release by hand. A dirty source snapshot must be identified as such, not described as the clean Git commit.
