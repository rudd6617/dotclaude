#!/usr/bin/env python3
"""Show the assistant reply that came right before a user message matching a pattern.

Use it to see what the model said just before a correction such as "用中文" or "看不懂".
Prints time, project, turn number, context size, model, and stats on the previous reply.

Run: python3 tools/usage-context.py '<regex on the user message>' <since YYYY-MM-DD> <max chars of reply to print>
e.g. python3 tools/usage-context.py '看不懂|講簡單' 2026-10-01 600
"""
import json,glob,os,re,sys
root=os.path.expanduser('~/.claude/projects')
pat=re.compile(sys.argv[1]); since=sys.argv[2]; lim=int(sys.argv[3])
for f in sorted(glob.glob(root+'/*/*.jsonl')):
    p=os.path.basename(os.path.dirname(f)).replace('-Users-rudolf-','')[:22]
    last=None; lastmodel=None; nturn=0; ctx=0
    for line in open(f):
        try:o=json.loads(line)
        except: continue
        if o.get('isSidechain'): continue
        if o.get('type')=='assistant':
            m=o['message']; lastmodel=m.get('model')
            u=m.get('usage') or {}
            ctx=(u.get('input_tokens',0)+u.get('cache_read_input_tokens',0)+u.get('cache_creation_input_tokens',0)) or ctx
            for b in m.get('content',[]):
                if b.get('type')=='text' and b['text'].strip(): last=b['text']
                if b.get('type')=='tool_use' and b['name']=='AskUserQuestion': last='[ASK] '+json.dumps(b['input'],ensure_ascii=False)
        elif o.get('type')=='user':
            c=o['message'].get('content')
            x=c if isinstance(c,str) else ' '.join(b.get('text','') for b in c if b.get('type')=='text')
            if o.get('origin',{}).get('kind')=='human' and not x.startswith('<'):
                nturn+=1
                if pat.search(x) and len(x)<60 and o.get('timestamp','')>=since and last:
                    en=len(re.findall(r'[A-Za-z]{3,}',last)); zh=len(re.findall(r'[一-鿿]',last))
                    print(f"\n##### {o['timestamp'][:16]} {p} turn={nturn} ctx={ctx//1000}k model={lastmodel} | USER: {x[:60]}\n  prev: len={len(last)} lines={last.count(chr(10))+1} q={last.count('？')+last.count('?')} enwords={en} zh={zh}\n  "+last[:lim].replace('\n','\n  '))
