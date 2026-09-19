"""Exercise the actual local Card Agent with a disposable authenticated user.
No mocked model responses; credentials never enter the result artifact.
Start `supabase functions serve` with a configured AI provider first.
"""
import argparse
import datetime
import json
from pathlib import Path
import subprocess
import time
import urllib.error
import urllib.request
import uuid

parser = argparse.ArgumentParser()
parser.add_argument('--only', default='')
parser.add_argument('--output', default='docs/testing/card-agent-scenario-results.json')
args = parser.parse_args()
status = json.loads(subprocess.check_output(['supabase', 'status', '-o', 'json'], stderr=subprocess.DEVNULL))
base = status['API_URL']
assert base.startswith(('http://127.0.0.1:', 'http://localhost:')), 'Local test endpoints only'
anon = status['ANON_KEY']
admin = status['SERVICE_ROLE_KEY']

def call(path, body=None, token=None, method='POST'):
    headers = {'content-type': 'application/json', 'apikey': anon}
    if token:
        headers['authorization'] = 'Bearer ' + token
    request = urllib.request.Request(base + path, data=json.dumps(body, ensure_ascii=False).encode() if body is not None else None, headers=headers, method=method)
    started = time.monotonic()
    try:
        with urllib.request.urlopen(request, timeout=70) as result:
            return result.status, json.load(result), round(time.monotonic()-started, 2)
    except urllib.error.HTTPError as error:
        return error.code, json.load(error), round(time.monotonic()-started, 2)
    except (urllib.error.URLError, TimeoutError) as error:
        return 0, {'error': type(error).__name__}, round(time.monotonic()-started, 2)

presets = {
    'word-simple': {'preset': 'word-simple', 'skill': 'word', 'front': '单词居中，音标与词性作为辅助信息', 'back': '释义在上，例句在下', 'layout': 'centered'},
    'knowledge-qa': {'preset': 'knowledge-qa', 'skill': 'knowledge', 'front': '突出问题，必要背景作为辅助信息', 'back': '先给简短答案，再解释或分步推导', 'layout': 'stacked'},
}
for skill, preset, front, back, layout in [
    ('poetry','poetry-overview','题目和作者居中','原文、白话释义分区排列','centered'),
    ('poetry','poetry-recall','展示上一句，不泄露下一句','下一句原文在上，释义在下','centered'),
    ('classical','classical-translation','展示古文原句','白话翻译、重点字词、句式或句意依次排列','stacked'),
    ('classical','classical-words','展示字词，必要时附语境','原句、读音、文中古义依次排列','centered'),
]:
    presets[preset] = dict(skill=skill, preset=preset, front=front, back=back, layout=layout)
cases = json.loads(Path(__file__).with_name('scenarios.json').read_text())
if args.only:
    cases = [c for c in cases if c['id'] in args.only.split(',')]
result = {'executed_at': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'endpoint':base+'/functions/v1/card-agent', 'model':'server-configured (not independently verified)', 'mocked':False, 'cases':[]}
output = Path(args.output)
output.parent.mkdir(parents=True, exist_ok=True)
def persist():
    output.write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n')
email = 'card-agent-scenarios-'+uuid.uuid4().hex+'@loopcard.test'
password = uuid.uuid4().hex
code, user, _ = call('/auth/v1/admin/users', {'email':email, 'password':password, 'email_confirm':True}, admin)
assert code == 200, 'Could not create local test user'
try:
    code, login, _ = call('/auth/v1/token?grant_type=password', {'email':email, 'password':password})
    assert code == 200, 'Could not sign in test user'
    token = login['access_token']
    for case in cases:
        record = {'id':case['id'], 'category':case['category'], 'sources':case['sources'], 'steps':[]}
        result['cases'].append(record)
        rules = dict(presets[case['preset']])
        messages = []
        actions = [('chat', text) for text in case['turns']]
        if case['generate']:
            actions.append(('generate', '按当前规则生成整批卡片。'))
        for action, text in actions:
            messages.append({'role':'user', 'content':text})
            payload = {'action':action, 'sources':case['sources'], 'rules':rules, 'messages':messages, 'locale':'zh-Hans'}
            code, body, elapsed = call('/functions/v1/card-agent', payload, token)
            record['steps'].append({'action':action, 'input':text, 'request_rules':dict(rules), 'status':code, 'seconds':elapsed, 'response':body})
            print(case['id'], action, 'HTTP',code, 'seconds',elapsed, 'cards', len(body.get('cards',[])), flush=True)
            persist()
            if code != 200:
                break
            rules = body['rules']
            messages.append({'role':'assistant','content':body['reply']})
    for identifier, payload, expected in [
        ('B01', {'action':'chat','sources':[{'id':'p','text':'word'}],'rules':{**presets['word-simple'],'preset':'unknown-poetry','skill':'unknown-poetry'},'messages':[]},400),
        ('B02', {'action':'chat','sources':[{'id':'p','text':'a'*4001}],'rules':presets['word-simple'],'messages':[]},400),
    ]:
        code,body,elapsed=call('/functions/v1/card-agent',payload,token)
        result.setdefault('boundary_checks',[]).append({'id':identifier,'status':code,'expected':expected,'seconds':elapsed,'response':body})
    persist()
finally:
    code,_,_=call('/auth/v1/admin/users/'+user['id'],token=admin,method='DELETE')
    result['test_user_deleted']=code==200
    persist()
