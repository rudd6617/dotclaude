#!/usr/bin/env python3
"""Per-project summary of Claude Code usage on this machine.

Reads ~/.claude/projects/*/*.jsonl and prints, per project: sessions, typed prompts,
cost, interrupts, compactions, tool counts, skill and slash-command counts, models,
and SessionStart hook output sizes.

Also writes every typed prompt to a TSV (time, project, session, text) in the system
temp dir, never in the repo: the prompts are private.

Run: python3 tools/usage-report.py
"""
import json,glob,os,collections,re
root=os.path.expanduser('~/.claude/projects')
C=collections.Counter
proj=collections.defaultdict(lambda:dict(sess=0,prompts=0,cost=0.0,tools=C(),skills=C(),slash=C(),interrupt=0,reject=0,compact=0,ask=0,agents=C(),models=C(),hookchars=[],dur=0,added=0,removed=0,perm=C(),hookerr=0))
import tempfile
PROMPTS=os.path.join(tempfile.gettempdir(),'claude-usage-prompts.tsv')
out=open(PROMPTS,'w')
for f in glob.glob(root+'/*/*.jsonl'):
    p=os.path.basename(os.path.dirname(f)).replace('-Users-rudolf-','')
    P=proj[p]; P['sess']+=1
    sid=os.path.basename(f)[:8]
    lastcost=None; seenmsg=set()
    for line in open(f):
        try:o=json.loads(line)
        except: continue
        t=o.get('type')
        if t=='cost-state': lastcost=o
        elif t=='permission-mode': P['perm'][o.get('permissionMode')]+=1
        elif t=='attachment':
            a=o.get('attachment',{})
            if a.get('hookEvent')=='SessionStart' and a.get('type')=='hook_success':
                P['hookchars'].append(len(a.get('stdout','')))
            if 'hook' in str(a.get('type')) and a.get('type') not in('hook_success','hook_additional_context'):
                P['hookerr']+=1
        elif t=='system':
            if o.get('subtype')=='compact_boundary': P['compact']+=1
        elif t=='user' and not o.get('isSidechain'):
            c=o['message'].get('content')
            texts=[]
            if isinstance(c,str): texts=[c]
            else:
                for b in c:
                    if b.get('type')=='text': texts.append(b['text'])
                    elif b.get('type')=='tool_result':
                        s=json.dumps(b.get('content'),ensure_ascii=False)
                        if "doesn't want to proceed" in s or 'user rejected' in s.lower(): P['reject']+=1
            for x in texts:
                if '[Request interrupted' in x: P['interrupt']+=1; continue
                m=re.search(r'<command-name>(/[\w:-]+)',x)
                if m: P['slash'][m.group(1)]+=1; 
                if o.get('origin',{}).get('kind')=='human' and not o.get('isMeta') and not x.startswith('<'):
                    P['prompts']+=1
                    out.write('\t'.join([o.get('timestamp','')[:16],p,sid,x.replace('\n',' ⏎ ').replace('\t',' ')[:1500]])+'\n')
                elif m:
                    a=re.search(r'<command-args>(.*?)</command-args>',x,re.S)
                    out.write('\t'.join([o.get('timestamp','')[:16],p,sid,m.group(1)+' '+(a.group(1) if a else '').replace('\n',' ⏎ ')[:1500]])+'\n')
        elif t=='assistant' and not o.get('isSidechain'):
            m=o['message']
            if m.get('id') in seenmsg: pass
            seenmsg.add(m.get('id'))
            P['models'][m.get('model')]+=1
            for b in m.get('content',[]):
                if b.get('type')=='tool_use':
                    n=b['name']; P['tools'][n if not n.startswith('mcp__') else 'mcp:'+n.split('__')[1]]+=1
                    if n=='Skill': P['skills'][b['input'].get('skill')]+=1
                    if n=='AskUserQuestion': P['ask']+=1
                    if n=='Agent': P['agents'][b['input'].get('subagent_type','default')]+=1
    if lastcost:
        P['cost']+=lastcost.get('totalCostUSD',0); P['dur']+=lastcost.get('totalDuration',0)
        P['added']+=lastcost.get('totalLinesAdded',0); P['removed']+=lastcost.get('totalLinesRemoved',0)
out.close()
print('typed prompts written to',PROMPTS)
for p,P in sorted(proj.items(),key=lambda x:-x[1]['cost']):
    print(f"\n### {p}: sess={P['sess']} prompts={P['prompts']} cost=${P['cost']:.0f} hrs={P['dur']/3.6e6:.0f} +{P['added']}/-{P['removed']} interrupt={P['interrupt']} reject={P['reject']} compact={P['compact']} ask={P['ask']} hookerr={P['hookerr']}")
    print(' perm',dict(P['perm'].most_common(4)),' hookchars',sorted(set(P['hookchars']))[-3:] if P['hookchars'] else None, 'n',len(P['hookchars']))
    print(' tools',dict(P['tools'].most_common(14)))
    print(' skills',dict(P['skills']),' slash',dict(P['slash'].most_common(15)))
    print(' agents',dict(P['agents']),' models',dict(P['models']))
