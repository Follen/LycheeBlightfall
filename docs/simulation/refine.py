import json
from optimize import WORK, make_profile, batch

rows = json.loads((WORK/'search-results.json').read_text())
assert len(rows) == 28
best = max((r for r in rows if r['policy']['heart_remaining'] is not None
            and r['policy']['margin'] >= 1.5), key=lambda r:r['mean_dps'])['policy']
heart, margin = best['heart_remaining'], best['margin']
policies = []
# Refine around the top coarse heart threshold, keeping normal bursts unchanged.
for h in (heart-.5, heart+.5):
    for m in (1.5, 2, 2.5):
        policies.append(make_profile(f'fine_h{str(h).replace(".","p")}_m{str(m).replace(".","p")}', h, m))
# Check whether the normal, unbuffed bursts should move independently.
for delay in (3, 5, 6, 8, 9, 10):
    policies.append(make_profile(f'fine_small{delay}', heart, margin, delay))
# Directly guard the trinket expiry, to test the risk of a delayed GCD.
for h in (8, 9, 10):
    policies.append(make_profile(f'cap_h{h}', h, 2, 7, True))
jobs = [dict(phase='refine', policy=p, duration=300, seed=41001, health=0) for p in policies]
(WORK/'refine-plan.json').write_text(json.dumps(dict(coarse_winner=best,jobs=jobs),indent=2))
batch(jobs,'refine-results.json')
