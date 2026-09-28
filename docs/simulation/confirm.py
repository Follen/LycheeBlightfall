import json
from optimize import WORK, make_profile, batch

policies = [make_profile('default'), make_profile('fine_small5',9,2,5),
            make_profile('boundary_small0',9,2,0), make_profile('boundary_small1',9,2,1)]
jobs = [dict(phase='confirmation', policy=p, duration=d, seed=s, health=0)
        for d, seeds in [(300,[61001,61002,61003]),(180,[62001]),(450,[63001])]
        for s in seeds for p in policies]
(WORK/'confirmation-plan.json').write_text(json.dumps(dict(
    reason='Boundary training search found earlier no-Heart Soul Reaper may outperform 5s. Freeze four policies and test on entirely fresh seeds.',
    primary_endpoint='300s mean total damage; 180s/450s robustness. Prefer simpler early policy if neighboring timings indistinguishable.',
    jobs=jobs),indent=2))
batch(jobs,'confirmation-results.json')
