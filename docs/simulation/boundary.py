import json
from optimize import WORK, make_profile, batch

# Check the remaining normal-burst boundary and local interactions around the
# validated training winner. Candidate selection still uses training seed 41001.
policies=[]
for delay in (0,1,2,4,11,12):
    policies.append(make_profile(f'boundary_small{delay}',9,2,delay))
for heart in (8,10):
    policies.append(make_profile(f'boundary_h{heart}_small5',heart,2,5))
for margin in (1.5,2.5):
    policies.append(make_profile(f'boundary_m{str(margin).replace(".","p")}_small5',9,margin,5))
jobs=[dict(phase='boundary',policy=p,duration=300,seed=41001,health=0) for p in policies]
(WORK/'boundary-plan.json').write_text(json.dumps(dict(jobs=jobs,
    followup_reason='Normal-burst optimum may lie earlier than the previously tested 3s boundary; verify the unexplored boundary and nearby interactions.'),indent=2))
batch(jobs,'boundary-results.json')
