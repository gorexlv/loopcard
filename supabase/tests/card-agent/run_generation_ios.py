"""Run post-OCR generation against local real CardAgent; no mocked LLM data."""
import argparse
import os
import json
from pathlib import Path
import subprocess
import urllib.request
import uuid

parser = argparse.ArgumentParser()
parser.add_argument('--device', default='2D551701-1F8F-44DB-A5AD-A6AB05857AEF')
parser.add_argument('--only', default='')
parser.add_argument('--select-preset', action='store_true')
parser.add_argument('--output', default='docs/testing/card-generation-e2e')
args = parser.parse_args()
root = Path(__file__).resolve().parents[3]
mobile = root / 'apps/mobile'
config = mobile / '.env.card-generation-test.json'
if config.exists():
    raise SystemExit('Existing test configuration needs cleanup before running again')
status = json.loads(subprocess.check_output(['supabase', 'status', '-o', 'json'], stderr=subprocess.DEVNULL))
base, anon, admin = status['API_URL'], status['ANON_KEY'], status['SERVICE_ROLE_KEY']
assert base.startswith(('http://127.0.0.1:', 'http://localhost:'))
headers = {'apikey': anon, 'authorization': 'Bearer ' + admin, 'content-type': 'application/json'}
def admin_call(path, body=None, method='POST'):
    req = urllib.request.Request(base + path, data=json.dumps(body).encode() if body is not None else None, headers=headers, method=method)
    with urllib.request.urlopen(req, timeout=30) as response:
        return json.load(response)
email, password = 'generation-e2e-' + uuid.uuid4().hex + '@loopcard.test', uuid.uuid4().hex
user = admin_call('/auth/v1/admin/users', dict(email=email, password=password, email_confirm=True))
try:
    config.touch(mode=0o600)
    config.write_text(json.dumps({'TEST_ACCOUNT_EMAIL': email, 'TEST_ACCOUNT_PASSWORD': password, 'SUPABASE_URL': base, 'SUPABASE_ANON_KEY': anon, 'TEST_CASES': args.only, 'SELECT_PRESET': str(args.select_preset).lower()}))
    result = subprocess.run(['flutter', 'drive', '--no-pub', '--driver=test_driver/card_generation_driver.dart', '--target=integration_test/card_generation_e2e_test.dart', '-d', args.device, '--dart-define-from-file=' + config.name], cwd=mobile, env={**os.environ, 'CARD_GENERATION_OUTPUT': str((root / args.output).resolve())})
finally:
    admin_call('/auth/v1/admin/users/' + user['id'], method='DELETE')
    config.unlink(missing_ok=True)
raise SystemExit(result.returncode)
