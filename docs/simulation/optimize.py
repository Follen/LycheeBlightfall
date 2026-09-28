"""Bounded APL timing search; each job has 3,000 measured iterations."""
from pathlib import Path
import concurrent.futures as futures
import hashlib
import json
import math
import re
import subprocess
import sys
import time

WORK = Path(__file__).resolve().parent
PREVIOUS = WORK.parent / 'reaper-sim-20260928'
SOURCE = json.loads((PREVIOUS / 'manifest.json').read_text(encoding='utf-8'))
BASE = (PREVIOUS / 'default_7s.simc').read_text(encoding='utf-8')
HEART = 'buff.voracious_heart_of_ulatek'
OLD_SR = next(s for s in BASE.splitlines() if s.startswith('actions.single_target+=/soul_reaper'))
OLD_BF = 'debuff.soul_reaper_debuff.up&debuff.soul_reaper_debuff.remains<gcd*2'
assert BASE.count(OLD_BF) == 1

def label(number):
    return str(number).replace('.', 'p')

def make_profile(name, heart_remaining=None, margin=2, small_delay=7, cap=False):
    gate = 'cooldown.dark_transformation.remains<' + str(45-small_delay)
    if heart_remaining is not None:
        gate = f'({HEART}.up&{HEART}.remains<={heart_remaining}|!{HEART}.up&{gate})'
    sr = 'actions.single_target+=/soul_reaper,target_if=min:health.pct,if=buff.dark_transformation.up&' + gate + '|target.health.pct<35'
    bf = f'debuff.soul_reaper_debuff.up&debuff.soul_reaper_debuff.remains<gcd*{margin}'
    if cap:
        bf = f'debuff.soul_reaper_debuff.up&(debuff.soul_reaper_debuff.remains<gcd*{margin}|{HEART}.up&{HEART}.remains<gcd*{margin})'
    profile = BASE.replace(OLD_SR, sr).replace(OLD_BF, bf).replace('deathknight="default_7s"', f'deathknight="{name}"')
    path = WORK / (name + '.simc')
    if path.exists():
        assert path.read_text(encoding='utf-8') == profile, 'Refusing to replace prior profile'
    else:
        path.write_text(profile, encoding='utf-8')
    return dict(name=name, heart_remaining=heart_remaining, margin=margin,
                small_delay=small_delay, cap=cap,
                profile_sha256=hashlib.sha256(profile.encode()).hexdigest())

def run_job(job):
    name = job['policy']['name']
    stem = f"{job['phase']}__{name}__{job['duration']}s__{job['seed']}"
    result_path = WORK / (stem + '.json')
    args = [SOURCE['executable'], name+'.simc', 'iterations=3001', 'threads=1',
            'deterministic=1', 'target_error=0', 'max_time='+str(job['duration']),
            'vary_combat_length=0', 'fixed_time=1', 'optimal_raid=1',
            'desired_targets=1', 'seed='+str(job['seed']),
            'enemy=Target', 'enemy_fixed_health_percentage='+str(job.get('health', 0)),
            'json2='+stem+'.json', 'output='+stem+'.txt']
    request = dict(job, command=args)
    request_path = WORK / (stem + '.request.json')
    if request_path.exists():
        assert json.loads(request_path.read_text()) == request, 'Existing request mismatch'
    else:
        request_path.write_text(json.dumps(request, indent=2), encoding='utf-8')
    started = time.monotonic()
    if not result_path.exists():
        p = subprocess.run(args, cwd=WORK, capture_output=True, text=True)
        (WORK / (stem+'.log')).write_text(p.stdout+'\n'+p.stderr, encoding='utf-8')
        if p.returncode:
            raise RuntimeError(stem + ': ' + p.stderr[-1000:])
    report = json.loads(result_path.read_text(encoding='utf-8'))
    player = report['sim']['players'][0]
    data = player['collected_data']
    dps = data['dps']
    assert dps['count'] == 3000
    assert abs(data['fight_length']['mean'] - job['duration']) < .001
    assert report['git_revision'] == '4c7c736'
    text = (WORK / (stem+'.txt')).read_text(encoding='utf-8')
    casts = re.search(r'^\s+blightfall\s+Count=\s*([\d.]+)', text, re.M)
    sequence = [dict(time=a['time'], name=a['name']) for a in data.get('action_sequence', [])
                if a.get('name') in ('army_of_the_dead', 'dark_transformation', 'soul_reaper',
                                     'use_item_voracious_heart_of_ulatek')]
    return dict(job, iterations=dps['count'], mean_dps=dps['mean'],
                dps_stddev=dps['std_dev'], dps_sem=dps['mean_std_dev'],
                mean_damage=data['compound_dmg']['mean'],
                blightfall_count=float(casts.group(1)) if casts else None,
                runtime=time.monotonic()-started, report=stem+'.json', sample_sequence=sequence)

def batch(jobs, filename):
    results = []
    with futures.ThreadPoolExecutor(max_workers=4) as pool:
        pending = {pool.submit(run_job, job): job for job in jobs}
        for future in futures.as_completed(pending):
            r = future.result()
            results.append(r)
            (WORK/filename).write_text(json.dumps(results, indent=2), encoding='utf-8')
            print(f"{len(results)}/{len(jobs)} {r['policy']['name']} {r['duration']}s seed={r['seed']}: "
                  f"DPS {r['mean_dps']:.2f}, SE {r['dps_sem']:.2f}, swallow {r['blightfall_count']}", flush=True)
    return results

def search():
    policies = [make_profile('default')]
    for heart in (6, 7, 8, 9, 10, 11):
        for margin in (1, 1.5, 2, 2.5):
            policies.append(make_profile(f'heart{heart}_margin{label(margin)}', heart, margin))
    for margin in (1, 1.5, 2.5):
        policies.append(make_profile(f'default_margin{label(margin)}', margin=margin))
    jobs = [dict(phase='search', policy=p, duration=300, seed=41001, health=0) for p in policies]
    (WORK/'search-plan.json').write_text(json.dumps(dict(source=SOURCE, jobs=jobs,
        intent='Optimize whole-fight single-target damage for the fixed template, then validate with independent seeds and durations.'), indent=2), encoding='utf-8')
    batch(jobs, 'search-results.json')

if __name__ == '__main__':
    search()
