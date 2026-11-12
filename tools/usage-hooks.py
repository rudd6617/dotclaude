#!/usr/bin/env python3
"""Count hook events per project and measure what the SessionStart hook injected.

For each project prints every (hook type, hook name) with its count, one example of each
non-success event, and the smallest / latest / largest injected size in characters with the
channel used: "ac" = additionalContext (reaches the model), "sysmsg" = systemMessage (user only).

Run: python3 tools/usage-hooks.py
"""
import json,glob,os,collections
root=os.path.expanduser('~/.claude/projects')
C=collections.Counter(); ex={}
size=collections.defaultdict(list)
for f in glob.glob(root+'/*/*.jsonl'):
    p=os.path.basename(os.path.dirname(f)).replace('-Users-rudolf-','')[:40]
    for line in open(f):
        if '"attachment"' not in line[:200] and '"type":"attachment"' not in line: continue
        try:o=json.loads(line)
        except: continue
        a=o.get('attachment',{})
        if not a: continue
        ty=a.get('type')
        if 'hook' in str(ty):
            k=(p,ty,a.get('hookName'))
            C[k]+=1
            if ty not in('hook_success',) and k not in ex: ex[k]=json.dumps(a,ensure_ascii=False)[:400]
            if a.get('hookEvent')=='SessionStart' and ty=='hook_success':
                try:
                    j=json.loads(a['stdout']); s=j.get('hookSpecificOutput',{}).get('additionalContext') or j.get('systemMessage','')
                    size[p].append((o.get('timestamp','')[:10],len(s),'ac' if 'hookSpecificOutput' in j else 'sysmsg'))
                except Exception as e: size[p].append((o.get('timestamp','')[:10],len(a.get('stdout','')),'raw'))
for k,v in sorted(C.items()): print(v,k)
for k,v in ex.items(): print('EX',k,v)
for p,v in size.items(): print(p,sorted(v)[0],sorted(v)[-1],max(x[1] for x in v))
