import json
from optimize import WORK, make_profile, batch

coarse = json.loads((WORK/'search-results.json').read_text())
fine = json.loads((WORK/'refine-results.json').read_text())
assert len(coarse) == 28 and len(fine) == 15
winner = max(coarse+fine, key=lambda r:r['mean_dps'])['policy']
policies = [make_profile('default'), make_profile('heart8_margin2', 8, 2),
            make_profile('heart9_margin2', 9, 2)]
if winner not in policies:
    policies.append(winner)
jobs = []
for duration, seeds in [(300, [51001,51002,51003]), (180,[52001]), (450,[53001])]:
    for seed in seeds:
        for policy in policies:
            jobs.append(dict(phase='validation', policy=policy, duration=duration, seed=seed, health=0))
(WORK/'validation-plan.json').write_text(json.dumps(dict(training_winner=winner,
    primary_endpoint='300s mean total damage on held-out seeds; other durations are robustness checks.',
    interpretation='Choose a practical near-best if adjacent timing differences remain within noise. No global optimality claim.',
    jobs=jobs),indent=2))
batch(jobs, 'validation-results.json')
