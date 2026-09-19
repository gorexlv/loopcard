"""Run the real hosted OCR integration test with a disposable iOS test account.
Usage: python3 supabase/tests/ocr/run_ios_visual.py --device <simulator-uuid>
Requires a booted iOS 18.5 simulator and an authenticated Supabase CLI.
"""
import argparse
import json
from pathlib import Path
import subprocess
import urllib.request
import uuid

parser = argparse.ArgumentParser()
parser.add_argument('--device', required=True)
parser.add_argument('--project-ref', default='hzntwddwaayzrgbwprif')
args = parser.parse_args()
root = Path(__file__).resolve().parents[3]
mobile = root / 'apps/mobile'
config = mobile / '.env.ios-ocr-test.json'
if config.exists():
    raise SystemExit('An existing test configuration is present; clean up its test user before retrying.')
keys = json.loads(subprocess.check_output(['supabase', 'projects', 'api-keys', '--project-ref', args.project_ref, '-o', 'json'], stderr=subprocess.DEVNULL))
admin = next(k['api_key'] for k in keys if k['name'] == 'service_role')
anon = next(k['api_key'] for k in keys if k['name'] == 'anon')
base = 'https://' + args.project_ref + '.supabase.co'
headers = {'apikey': anon, 'authorization': 'Bearer ' + admin, 'content-type': 'application/json'}
email = 'ios-ocr-' + uuid.uuid4().hex + '@loopcard.test'
password = uuid.uuid4().hex
req = urllib.request.Request(base + '/auth/v1/admin/users', data=json.dumps(dict(email=email, password=password, email_confirm=True)).encode(), headers=headers)
with urllib.request.urlopen(req, timeout=30) as response:
    user = json.load(response)
try:
    config.touch(mode=0o600)
    config.write_text(json.dumps({'TEST_ACCOUNT_EMAIL': email, 'TEST_ACCOUNT_PASSWORD': password, 'SUPABASE_URL': base, 'SUPABASE_ANON_KEY': anon}))
    result = subprocess.run(['flutter', 'drive', '--driver=test_driver/ocr_visual_driver.dart', '--target=integration_test/ocr_visual_test.dart', '-d', args.device, '--dart-define-from-file=' + config.name], cwd=mobile)
finally:
    req = urllib.request.Request(base + '/auth/v1/admin/users/' + user['id'], headers=headers, method='DELETE')
    with urllib.request.urlopen(req, timeout=30) as response:
        assert response.status == 200
    config.unlink(missing_ok=True)
raise SystemExit(result.returncode)
