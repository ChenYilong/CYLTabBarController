#!/usr/bin/env python3
"""Swift migration (docs/Swift-Migration.md): groups the Objective-C files of the core layer that import each other
(strongly connected components of the #import graph), leaves first, with their size in lines. A group can move to
Swift once everything it imports is Swift; a group of several files has to move together."""
import os,re,sys,collections
root='CYLTabBarController'
scope_dirs=[root+'/CYLUtils',root+'/CYLBadgeView',root+'/CYLFlatDesignTabBar']
files={}
for d,fs,ns in os.walk(root):
    if any(x in d for x in ['/Swift','LottieSwift','RiveSwift','/include','Resources','CYLTabBarItemAnimation']): continue
    in_scope = d==root or any(d.startswith(s) for s in scope_dirs)
    if not in_scope: continue
    for n in ns:
        if n.startswith('.') or not n.endswith(('.h','.m')): continue
        files[n]=os.path.join(d,n)
lines={n:sum(1 for _ in open(p,errors='replace')) for n,p in files.items()}
# unit = basename without extension
units=collections.defaultdict(list)
for n in files: units[n.rsplit('.',1)[0]].append(n)
imp=re.compile(r'#\s*import\s+[<"](?:[\w/]*/)?([\w+\-]+)\.h[>"]')
edges=collections.defaultdict(set)
for u,ns in units.items():
    for n in ns:
        for m in imp.findall(open(files[n],errors='replace').read()):
            if m in units and m!=u: edges[u].add(m)
# Tarjan SCC
idx={};low={};st=[];on=set();sccs=[];c=[0]
sys.setrecursionlimit(10000)
def sc(v):
    idx[v]=low[v]=c[0];c[0]+=1;st.append(v);on.add(v)
    for w in edges[v]:
        if w not in idx: sc(w);low[v]=min(low[v],low[w])
        elif w in on: low[v]=min(low[v],idx[w])
    if low[v]==idx[v]:
        comp=[]
        while True:
            w=st.pop();on.discard(w);comp.append(w)
            if w==v: break
        sccs.append(comp)
for v in units:
    if v not in idx: sc(v)
def size(comp): return sum(lines[n] for u in comp for n in units[u])
# sccs come out in reverse topological order (leaves first)
for comp in sccs:
    deps=set(w for u in comp for w in edges[u] if w not in comp)
    print(f"{size(comp):6d}  {len(comp):3d} units  {', '.join(sorted(comp))[:150]}  <- needs: {', '.join(sorted(deps))[:120]}")
