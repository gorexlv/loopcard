import json,subprocess,urllib.request,urllib.error,uuid
import argparse
parser=argparse.ArgumentParser()
parser.add_argument('--project-ref', help='Explicit hosted project to test; creates and removes a disposable user')
args=parser.parse_args()
if args.project_ref:
 keys=json.loads(subprocess.check_output(['supabase','projects','api-keys','--project-ref',args.project_ref,'-o','json'],stderr=subprocess.DEVNULL))
 admin=next(k['api_key'] for k in keys if k['name']=='service_role')
 anon=next(k['api_key'] for k in keys if k['name']=='anon')
 base='https://'+args.project_ref+'.supabase.co'
else:
 status=json.loads(subprocess.check_output(['supabase','status','-o','json'],stderr=subprocess.DEVNULL))
 base=status['API_URL']; admin=status['SERVICE_ROLE_KEY']; anon=status['ANON_KEY']
 assert base.startswith(('http://127.0.0.1:', 'http://localhost:'))
def request(path,payload=None,token=None,method='POST'):
    headers={'content-type':'application/json','apikey':anon}
    if token: headers['authorization']='Bearer '+token
    req=urllib.request.Request(base+path,data=json.dumps(payload).encode() if payload is not None else None,headers=headers,method=method)
    try:
        with urllib.request.urlopen(req,timeout=70) as r:return r.status,json.load(r)
    except urllib.error.HTTPError as e:return e.code,json.load(e)

from PIL import Image, ImageDraw, ImageFont
from pathlib import Path
import base64, io, time
cases = [
 ('英文单词', 'borrow: 借入\nlend: 借出\nMay I borrow your pen?'),
 ('诗词', '静夜思 李白\n床前明月光，疑是地上霜。\n举头望明月，低头思故乡。'),
 ('古文繁体', '學而時習之，不亦說乎？\n人不知而不慍，不亦君子乎？\n說：yuè，同「悅」。'),
]
font=ImageFont.truetype('/System/Library/Fonts/STHeiti Light.ttc', 40)
email='ocr-smoke-'+uuid.uuid4().hex+'@loopcard.test'; password=uuid.uuid4().hex
code,user=request('/auth/v1/admin/users',{'email':email,'password':password,'email_confirm':True},admin)
assert code==200,code
report={'endpoint':base,'fixture_type':'synthetic clean printed text, not camera photos','model':'qwen/qwen3-vl-235b-a22b-instruct','cases':[]}
try:
 code,login=request('/auth/v1/token?grant_type=password',{'email':email,'password':password});assert code==200
 token=login['access_token']
 code,_=request('/functions/v1/photo-ocr',{});assert code==401
 code,_=request('/functions/v1/photo-ocr',{'image':'https://example.com/image.jpg'},token);assert code==400
 report['authentication_and_validation']='passed'
 for name,source in cases:
  img=Image.new('RGB',(1100,400),'white');draw=ImageDraw.Draw(img);draw.multiline_text((40,40),source,font=font,fill='black',spacing=18)
  data=io.BytesIO();img.save(data,format='PNG')
  started=time.monotonic()
  code,body=request('/functions/v1/photo-ocr',{'image':'data:image/png;base64,'+base64.b64encode(data.getvalue()).decode()},token)
  record={'name':name,'expected':source,'status':code,'seconds':round(time.monotonic()-started,2),'response':body,'exact_match':body.get('text')==source}
  report['cases'].append(record);print(json.dumps(record,ensure_ascii=False),flush=True)
finally:
 code,_=request('/auth/v1/admin/users/'+user['id'],None,admin,'DELETE');report['test_user_deleted']=code==200
 Path('docs/testing/openrouter-ocr-hosted-results.json' if args.project_ref else 'docs/testing/openrouter-ocr-results.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')

assert all(c['status']==200 and c['exact_match'] for c in report['cases']), 'OCR fixture mismatch; inspect result artifact'
