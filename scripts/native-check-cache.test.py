#!/usr/bin/env python3
"""Check compile reuse, input invalidation and failed/unstable build publication."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


class NativeCacheTest(unittest.TestCase):
    def test_cache_owns_binaries_but_never_caches_test_results(self):
        original = Path(__file__).resolve().parent.parent
        with tempfile.TemporaryDirectory() as temp:
            fixture = Path(temp)
            root = fixture / 'repo'
            app = root / 'examples/survivors'
            app.mkdir(parents=True)
            (root / 'scripts').mkdir()
            shutil.copyfile(original / 'examples/survivors/check-launcher-profile-ui.sh', app / 'check-launcher-profile-ui.sh')
            shutil.copyfile(original / 'scripts/native-check-cache-key.py', root / 'scripts/native-check-cache-key.py')
            (root / 'examples/common.sh').write_text('''example_repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BEND="$FAKE_BEND"
CLANG="$FAKE_BEND"
example_cpu=()
example_timeout() { shift; "$@"; }
example_cleanup_lock() { :; }
''')
            (app / 'native-launcher.test.sh').write_text('exit 0\n')
            for name in ('native-profile-io-check', 'native-test', 'native-loot-test'):
                (app / (name + '.bend')).write_text('source')
            tool = fixture / 'install/bin/bend'
            tool.parent.mkdir(parents=True)
            tool.write_text('''#!/bin/bash
set -euo pipefail
if [[ "$1" == --version ]]; then echo fake-v1; exit; fi
if [[ ! -e "$FAKE_PACKAGE_PATH" ]]; then echo downloaded-package > "$FAKE_PACKAGE_PATH"; fi
if [[ "${2:-}" == --check-only ]]; then exit; fi
echo build >> "$BUILD_LOG"
if [[ -n "${MUTATE_SOURCE:-}" ]]; then echo mutation >> "$MUTATE_SOURCE"; fi
if [[ "${FAIL_BUILD:-0}" == 1 ]]; then
  echo partial > "$3"; chmod +x "$3"; exit 42
fi
cat > "$3" <<'BINARY'
#!/bin/bash
set -euo pipefail
for name in menu gameplay upgrade map experience-piles; do touch "$name.ppm"; done
echo run >> "$RUN_LOG"
if [[ "${FAIL_RUN:-0}" == 1 ]]; then exit 42; fi
BINARY
chmod +x "$3"
''')
            tool.chmod(0o755)
            runtime = fixture / 'install/bend2/base.bend'
            runtime.parent.mkdir()
            runtime.write_text('runtime')
            hub = fixture / 'hub'
            hub.mkdir()
            package = hub / 'package.bend'
            cc = fixture / 'install/bin/clang'
            cc.write_text('#!/bin/sh\necho fake-clang-v1\n')
            cc.chmod(0o755)
            cache = fixture / 'cache'
            build_log, run_log = fixture / 'build.log', fixture / 'run.log'
            env = {**os.environ, 'FAKE_BEND': str(tool), 'BUILD_LOG': str(build_log),
                   'RUN_LOG': str(run_log), 'BEND_LIB': str(hub),
                   'CC': str(cc), 'FAKE_PACKAGE_PATH': str(package),
                   'NIGHTFALL_NATIVE_CHECK_CACHE': str(cache)}

            def run(code=0):
                result = subprocess.run(['bash', str(app / 'check-launcher-profile-ui.sh')], env=env,
                                        capture_output=True, text=True, timeout=30)
                self.assertEqual(result.returncode, code, result.stdout + result.stderr)

            def builds():
                return len(build_log.read_text().splitlines()) if build_log.exists() else 0

            def invalidated(change):
                before = builds()
                change()
                run()
                self.assertEqual(builds(), before + 3)

            run()
            self.assertEqual(builds(), 3)
            run()
            self.assertEqual(builds(), 3)
            self.assertEqual(len(run_log.read_text().splitlines()), 6)
            # A cache hit still executes the checks and reports runtime failure.
            env['FAIL_RUN'] = '1'
            run(42)
            del env['FAIL_RUN']
            run()
            self.assertEqual(builds(), 3)
            ignored = root / '.autoresearch/generated.bend'
            ignored.parent.mkdir()
            ignored.write_text('generated artifact')
            run()
            self.assertEqual(builds(), 3)
            runtime_dist = runtime.parent / 'dist/runtime.bend'
            runtime_dist.parent.mkdir()
            invalidated(lambda: runtime_dist.write_text('runtime dependency'))
            source = app / 'new-import.bend'
            invalidated(lambda: source.write_text('new dependency'))
            invalidated(lambda: runtime.write_text('changed runtime'))
            invalidated(lambda: package.write_text('changed Hub package outside the checkout'))
            invalidated(lambda: tool.write_text(tool.read_text() + '\n# changed compiler\n'))
            invalidated(lambda: cc.write_text('#!/bin/sh\necho fake-clang-v2\n'))
            builder = app / 'check-launcher-profile-ui.sh'
            invalidated(lambda: builder.write_text(builder.read_text() + '\n# changed build flags\n'))
            before = builds()
            source.write_text('changed again')
            env['FAIL_BUILD'] = '1'
            run(42)
            self.assertEqual(builds(), before + 1)
            self.assertFalse(list(cache.rglob('.build-*')), 'failed staging must be removed')
            self.assertFalse(any(p.read_text().startswith('partial') for p in cache.rglob('native-profile-io-check')))
            del env['FAIL_BUILD']
            run()
            self.assertEqual(builds(), before + 4)
            # A concurrently edited input cannot publish a binary under its old key.
            source.write_text('new stable source')
            env['MUTATE_SOURCE'] = str(source)
            before = builds()
            run(75)
            self.assertEqual(builds(), before + 1)
            self.assertFalse(list(cache.rglob('.build-*')))
            del env['MUTATE_SOURCE']
            run()
            self.assertEqual(builds(), before + 4)


if __name__ == '__main__':
    unittest.main()
