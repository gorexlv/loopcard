"""Build a local screenshot gallery from recorded real iOS test output."""
import html
import json
from pathlib import Path

root = Path(__file__).resolve().parents[3]
folder = root / 'docs/testing/card-generation-e2e'
results = json.loads((folder / 'results.json').read_text())
audit = {r['id']: r for r in json.loads((folder / 'audit.json').read_text())}
reviews = json.loads((folder / 'review.json').read_text())
names = {'W01':'单词列表 → 释义与例句','P01':'诗词题目列表 → 全篇卡','P02':'诗词题目 → 接句卡','C01':'古文篇目列表 → 全篇卡','C02':'古文篇目 → 逐句卡','A01':'同名题目 → 澄清'}
parts = ['''<!doctype html><html lang="zh"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>CardAgent 真实生成截图</title><style>body{margin:0;padding:32px;font:16px/1.65 system-ui;background:#f5f3f8;color:#24212c}main{max-width:1180px;margin:auto}h1{font-size:28px}h2{margin-top:48px}pre{white-space:pre-wrap;background:white;padding:16px;border-radius:12px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:20px}figure{margin:0}img{width:100%;border-radius:18px}figcaption{font-size:13px;color:#625a70}a{color:#176b60}.note{max-width:78ch}.bad{color:#9e3030}.good{color:#176b60}</style><main><h1>CardAgent 内容补全与生成测试</h1><p class="note">2026-09-19 · iPhone 16 Pro / iOS 18.5 · 本地 Supabase CardAgent → 真实 OpenRouter qwen/qwen3-vl-235b-a22b-instruct。输入只有 OCR 后的名称列表，没有提供原文，也没有模拟模型响应。本轮先在界面选择对应排版，再发送内容要求和点击生成；截图为原始模拟器截图。</p><p class="note">自动切换规则的独立测试发现不稳定，详见 auto-routing-results.json；不能将本轮已选排版的结果视为自动路由验收通过。长卡背面可在卡内滚动，另附底部截图。本测试到生成草稿为止，不包含保存入库。</p>''']
for case in results['cases']:
    ident = case['id']; a = audit[ident]
    parts += [f'<section><h2>{ident} · {names[ident]}</h2>', '<pre>OCR 输入：'+html.escape(case['source'])+'</pre>', f'<p class="{"good" if a["passed"] else "bad"}">检查：{"通过" if a["passed"] else "存在未通过项"} · 网络耗时 {a["seconds"]:.1f}s</p>']
    review = reviews[ident]
    parts += ['<p><strong>人工内容评审：'+html.escape(review['status'])+'</strong> · '+html.escape(review['notes'])+'</p>']
    failures=[k for k,v in a['checks'].items() if not v]
    if failures: parts += ['<p>'+html.escape('、'.join(failures))+'</p>']
    for call in case['calls']:
        resp=call.get('response',{})
        parts += ['<details><summary>'+html.escape(call['request']['action'])+' · 实际回复</summary><pre>'+html.escape(resp.get('reply',call.get('error','')))+'</pre></details>']
        if resp.get('cards'):
            parts += ['<details><summary>完整模型输出卡片内容</summary><pre>'+html.escape(json.dumps(resp['cards'],ensure_ascii=False,indent=2))+'</pre></details>']
    selected=[name for name in case['screenshots'] if '-chat' not in name]
    if not selected: selected=case['screenshots']
    parts += ['<div class="grid">']
    for name in selected:
        parts += [f'<figure><a href="{html.escape(name)}"><img loading="lazy" src="{html.escape(name)}" alt="{html.escape(name)}"></a><figcaption>{html.escape(name)}</figcaption></figure>']
    parts += ['</div></section>']
parts += ['</main></html>']
(folder / 'index.html').write_text('\n'.join(parts))
print(folder / 'index.html')
