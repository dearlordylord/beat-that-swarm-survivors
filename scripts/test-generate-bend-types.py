#!/usr/bin/env python3
"""Focused ABI coverage, including real compiler exports; artifacts stay in /tmp."""
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('bend_types', ROOT / 'scripts/generate-bend-types.py')
generator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(generator)


class GeneratorTests(unittest.TestCase):
    def generate(self, source, extra=None):
        with tempfile.TemporaryDirectory(prefix='bend-abi-') as directory:
            root = Path(directory)
            (root / 'fixture.bend').write_text(source)
            for name, text in (extra or {}).items():
                (root / name).write_text(text)
            return generator.generate(root)

    def test_unsupported_declarations_fail(self):
        for source in (
            'type Hidden = U32\n',
            'type Hidden<T:\n  Data> is Data: Hidden{}\n',
            'type Hidden is Data: Good{} garbage\n',
            'def value(x: U32): x\n',
            'def value(\n  x: U32) -> U32: x\n',
            'def value() ->\n  U32: 0\n',
            'def value() -> Typo: 0\n',
            'import other.bend as O\ndef value() -> O.Typo: 0\n',
            'def value() -> Typo(): 0\n',
            'def value() -> List: []\n',
            'type Hidden<T> is Data: Hidden{}\n',
        ):
            with self.subTest(source=source), self.assertRaises(ValueError):
                self.generate(source, {'other.bend': 'type Good is Data: Good{}\n'})

    def test_explicit_erasure_and_opacity(self):
        result = self.generate('''import Base
import storage@1.0.0 as S
type Box<T:Data> is Data: Box{value:T}
def World() -> Type: S.World
def proof(x:U32) -> {x == x : U32}: {==}
def identity(~T:Data,value:T) -> T: value
def template(fn:U32 -> U32) -> U32: 0
def storage(value:S.Column<U32>) -> World(): value
''')
        self.assertIn('identity<T = unknown>(arg_value: T): T;', result)
        self.assertNotIn('proof(', result)
        for reason in ('erased proof/type export', 'higher-order compiler template',
                       'external package storage/resource', 'computed compiler type'):
            self.assertIn('// Opaque ABI: ' + reason, result)

    def test_actual_project_is_consumed(self):
        result = generator.generate(generator.SOURCE)
        self.assertIn('namespace Game', result)
        self.assertIn('interface API', result)

    def test_real_bend_exports_and_adt_shape(self):
        source = '''import Base
type Choice is Data:
  Empty{}
  Value{count:U32,enabled:Bool}
def choose(enabled:Bool) -> Choice:
  match enabled:
    case True{}: Value{7,True{}}
    case False{}: Empty{}
def pair() -> U32 & Bool: (9,True{})
'''
        with tempfile.TemporaryDirectory(prefix='bend-abi-emission-') as directory:
            root = Path(directory)
            fixture = root / 'fixture.bend'
            fixture.write_text(source)
            emitted = root / 'fixture.mjs'
            subprocess.run([os.environ.get('BEND', 'bend'), str(fixture), '-o', str(emitted)], check=True, capture_output=True, text=True)
            result = subprocess.run(['node', '--input-type=module', '-e', '''
const {default: api} = await import(process.argv[1]);
console.log(JSON.stringify({keys:Object.keys(api),yes:api.choose(true),no:api.choose(false),pair:api.pair()}));
''', emitted.as_uri()], check=True, capture_output=True, text=True)
            values = json.loads(result.stdout)
            self.assertIn('choose', values['keys'])
            self.assertEqual(values['yes'], {'$': 'Value', 'count': 7, 'enabled': True})
            self.assertEqual(values['no'], {'$': 'Empty'})
            self.assertEqual(values['pair'], {'$': 'Tuple', 'fst': 9, 'snd': True})
            declarations = root / 'bend.d.ts'
            declarations.write_text(generator.generate(root))
            consumer = root / 'consumer.ts'
            consumer.write_text('''declare const api: BendABI.Fixture.API;
const choice = api.choose(true);
if (choice.$ === "Value") {
  const count: number = choice.count;
  const enabled: boolean = choice.enabled;
}
const pair: { $: "Tuple"; fst: number; snd: boolean } = api.pair();
// @ts-expect-error numeric arguments violate the generated Bend boundary
api.choose(1);
// @ts-expect-error ADT fields must retain their Bend types
const invalid: BendABI.Fixture.Choice = { $: "Value", count: "7", enabled: true };
''')
            subprocess.run([str(ROOT / 'node_modules/.bin/tsc'), '--ignoreConfig', '--strict', '--noEmit', '--skipLibCheck', 'false',
                            '--types', 'node', '--typeRoots', str(ROOT / 'node_modules/@types'),
                            str(declarations), str(consumer)], check=True, capture_output=True, text=True)


if __name__ == '__main__':
    unittest.main()
