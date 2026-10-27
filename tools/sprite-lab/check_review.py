#!/usr/bin/env python3
"""Check style-review completeness and its association with actual artifacts."""
import argparse
import hashlib
import json
from pathlib import Path

AXES = {'silhouette','proportions','palette','garment_identity','face_expression','rendering_style','motion_identity'}


def accepted(axes):
    return set(axes) == AXES and all(
        isinstance(result,dict) and result.get('verdict') == 'pass'
        and isinstance(result.get('evidence'),str) and bool(result['evidence'].strip())
        for result in axes.values())


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('iteration',type=Path)
    args=parser.parse_args()
    review=json.loads((args.iteration/'style-review.json').read_text())
    validation=json.loads((args.iteration/'validation.json').read_text())
    current=hashlib.sha256((args.iteration/'comparison.png').read_bytes()).hexdigest()
    reasons=[]
    if review.get('artifact_sha256') != current:
        reasons.append('Review belongs to different rendered pixels')
    for name in ('comparison.png','fidelity-comparison.png','character-03.svg','orange-front-walk.gif'):
        artifact=args.iteration/name
        expected=review.get('artifact_sha256_by_file',{}).get(name)
        if not artifact.exists() or hashlib.sha256(artifact.read_bytes()).hexdigest() != expected:
            reasons.append(f'Review is missing or stale for artifact: {name}')
    if review.get('reference_sha256') != validation.get('reference_sha256'):
        reasons.append('Review and build use different references')
    contract=json.loads((args.iteration/'source/reference-contract.json').read_text())
    for reference in contract['references']:
        copied=args.iteration/'references'/Path(reference['path']).name
        actual=hashlib.sha256(copied.read_bytes()).hexdigest()
        if actual != reference['sha256'] or actual != review.get('reference_sha256',{}).get(reference['id']):
            reasons.append(f"Pinned reference content differs: {reference['id']}")
    if not isinstance(review.get('reviewer'),str) or not review['reviewer'].strip():
        reasons.append('No visual reviewer recorded')
    axes=review.get('axes',{})
    if not accepted(axes):
        reasons.append('Every required axis must pass with written visual evidence')
    print(json.dumps({'visual_acceptance':'pass' if not reasons else 'blocked','reasons':reasons},indent=2))
    raise SystemExit(bool(reasons))


if __name__=='__main__':
    main()
