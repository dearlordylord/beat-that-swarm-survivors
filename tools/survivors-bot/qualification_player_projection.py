#!/usr/bin/env python3
"""Temporary GH8 oracle: compare frozen flat authority to split authority.

This is migration qualification only. Maintained runtime readers accept only the
new schema. The sole representation changes are named here; numerical values,
ordering, allocator identity, all physical metadata and frame data stay exact.
"""
import argparse
import copy
import json
from pathlib import Path
import sys

sys.setrecursionlimit(100000)  # Actual Bend lists in the preserved raw capture.

SESSION = 'phase tick xp xpNeed level kills gold seed stage bosses mode enemyKinds relicCollected'.split()
PERSONAL = 'px py hp maxHp character weapons passives invuln arcana meta revivals rerolls banishes skips bannedWeapons bannedPassives'.split()


def payload(value, fields, tag):
    assert set(value) == {'$', *fields}, (tag, set(value))
    assert value['$'] == tag
    return value


def split_run(value):
    payload(value, SESSION + PERSONAL, 'Run')
    return {'$': 'Run',
            'session': {'$': 'Session', **{key: value[key] for key in SESSION}},
            'player': {'$': 'PlayerState', **{key: value[key] for key in PERSONAL}}}


def current_run(value):
    payload(value, ['session', 'player'], 'Run')
    payload(value['session'], SESSION, 'Session')
    payload(value['player'], PERSONAL, 'PlayerState')
    return value


def record(value, baseline):
    if baseline:
        payload(value, ['id', 'run', 'connected'], 'PlayerRecord')
        personal = split_run(value['run'])['player']
    else:
        payload(value, ['id', 'player', 'connected'], 'PlayerRecord')
        personal = payload(value['player'], PERSONAL, 'PlayerState')
    return {'$': 'PlayerRecord', 'id': value['id'], 'player': personal,
            'connected': value['connected']}


def physical_records(value, baseline):
    if isinstance(value, dict):
        if value.get('$') == 'PlayerRecord':
            return record(value, baseline)
        return {key: physical_records(item, baseline) for key, item in value.items()}
    if isinstance(value, list):
        return [physical_records(item, baseline) for item in value]
    return value


def forecast_players(rows, baseline):
    if rows['$'] == 'Nil':
        assert set(rows) == {'$'}
        return rows
    payload(rows, ['head', 'tail'], 'Con')
    player = rows['head']
    payload(player, ['id', 'run', 'connected'],
            'PlayerRecord' if baseline else 'PlayerSnapshot')
    return {'$': 'Con', 'head': {'$': 'PlayerSnapshot', 'id': player['id'],
            'run': split_run(player['run']) if baseline else current_run(player['run']),
            'connected': player['connected']},
            'tail': forecast_players(rows['tail'], baseline)}


def project(capture, baseline):
    result = copy.deepcopy(capture)
    for row in result['rows']:
        if baseline:
            row['shared'] = split_run(row['shared'])['session']
            row['physical']['shared'] = split_run(row['physical']['shared'])['session']
        else:
            payload(row['shared'], SESSION, 'Session')
            payload(row['physical']['shared'], SESSION, 'Session')
        row['players'] = [record(player, baseline) for player in row['players']]
        row['physical'] = physical_records(row['physical'], baseline)
        scene = row['frame']['combatForecast']
        scene['players'] = forecast_players(scene['players'], baseline)
        assert scene['tick'] == row['tick'] == row['shared']['tick']
    return result


def compare(reference, candidate):
    # A canonical serialization avoids Python's recursive equality stack limit;
    # there are no ignored fields, numeric tolerances or order normalization.
    left = json.dumps(reference, sort_keys=True, separators=(',', ':'), allow_nan=False)
    right = json.dumps(candidate, sort_keys=True, separators=(',', ':'), allow_nan=False)
    if left != right:
        raise ValueError('Player authority qualification differs')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('baseline', type=Path)
    parser.add_argument('candidate', type=Path)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    reference = project(json.loads(args.baseline.read_text()), True)
    raw_current = json.loads(args.candidate.read_text())
    current = project(raw_current, False)
    compare(reference, current)
    raw_control = {**raw_current, 'rows': [raw_current['rows'][0]]}
    reference_control = {**reference, 'rows': [reference['rows'][0]]}
    for name, path in [('personal-health', ('player', 'hp')),
                       ('personal-revivals', ('player', 'revivals'))]:
        changed = copy.deepcopy(raw_control)
        values = changed['rows'][0]['physical']['world']['store']['players']['state']['state']['values']
        stored = next(slot['value'] for slot in values
                      if slot['$'] == 'Some' and slot['value']['id'] == 0)
        stored[path[0]][path[1]] += 1
        try:
            compare(reference_control, project(changed, False))
        except ValueError:
            pass
        else:
            raise AssertionError('Undetected ' + name)
    for name in ['xp', 'gold', 'tick']:
        changed = copy.deepcopy(raw_control)
        changed['rows'][0]['physical']['shared'][name] += 1
        try:
            compare(reference_control, project(changed, False))
        except ValueError:
            pass
        else:
            raise AssertionError('Undetected session-' + name)
    receipt = {'status': 'passed', 'checkpoints': len(current['rows']),
               'comparison': 'exact after explicit authority partition/tag changes',
               'physicalMetadataCompared': True,
               'controls': ['personal-health', 'personal-revivals',
                            'session-xp', 'session-gold', 'session-tick']}
    args.output.write_text(json.dumps(receipt, indent=2) + '\n')
    print(json.dumps(receipt))


if __name__ == '__main__':
    main()
