"""Check actual returned cards against independent canonical text fixtures."""
import json
from pathlib import Path
import re

root = Path(__file__).resolve().parents[3]
folder = root / 'docs/testing/card-generation-e2e'
data = json.loads((folder / 'results.json').read_text())
def normalize(s):
    return re.sub(r'[^\w\u4e00-\u9fff]', '', s)
originals = {
    '静夜思': '床前明月光，疑是地上霜。举头望明月，低头思故乡。',
    '春晓': '春眠不觉晓，处处闻啼鸟。夜来风雨声，花落知多少。',
    '陋室铭': '山不在高，有仙则名。水不在深，有龙则灵。斯是陋室，惟吾德馨。苔痕上阶绿，草色入帘青。谈笑有鸿儒，往来无白丁。可以调素琴，阅金经。无丝竹之乱耳，无案牍之劳形。南阳诸葛庐，西蜀子云亭。孔子云：何陋之有？',
    '爱莲说': '水陆草木之花，可爱者甚蕃。晋陶渊明独爱菊。自李唐来，世人甚爱牡丹。予独爱莲之出淤泥而不染，濯清涟而不妖，中通外直，不蔓不枝，香远益清，亭亭净植，可远观而不可亵玩焉。予谓菊，花之隐逸者也；牡丹，花之富贵者也；莲，花之君子者也。噫！菊之爱，陶后鲜有闻。莲之爱，同予者何人？牡丹之爱，宜乎众矣。',
}
audit = []
for case in data['cases']:
    identifier = case['id']
    checks = {}
    calls = case['calls']
    checks['all_network_calls_succeeded'] = all(c.get('status') == 'success' for c in calls)
    response = calls[-1].get('response', {})
    cards = response.get('cards', [])
    text = json.dumps(cards, ensure_ascii=False)
    expected = {'W01': 3, 'P01': 2, 'P02': 2, 'C01': 2, 'C02': 3, 'A01': 0}
    checks['expected_card_count'] = len(cards) == expected[identifier]
    if identifier != 'A01':
        checks['real_generate_action'] = calls[-1]['request']['action'] == 'generate'
        checks['source_ids_preserved'] = bool(cards) and all(c['presentation']['source_ids'] == [identifier+'-photo-1'] for c in cards)
    if identifier == 'W01':
        checks['all_requested_words'] = {c['prompt'].lower() for c in cards} == {'borrow','lend','apple'}
        checks['word_only_front'] = bool(cards) and all(c.get('hint','') == '' for c in cards)
        checks['lexical_data_present'] = bool(cards) and all(c.get('word_data') for c in cards)
    if identifier in ('P01', 'C01'):
        for title in (['静夜思','春晓'] if identifier == 'P01' else ['陋室铭','爱莲说']):
            matches = [c for c in cards if title in c['prompt']]
            sections = matches[0]['sections'] if matches else []
            original = ''.join(s['heading']+s['body'] for s in sections if any(label in s['title']+s['heading'] for label in ['原文','原诗']))
            checks[title+'_complete_original'] = normalize(originals[title]) in normalize(original)
            checks[title+'_section_labels'] = bool(sections) and ('原文' in sections[0]['title'] or '原诗' in sections[0]['title']) and ('翻译' in sections[1]['title'] or '释义' in sections[1]['title'])
            author = {'静夜思':'李白','春晓':'孟浩然','陋室铭':'刘禹锡','爱莲说':'周敦颐'}[title]
            checks[title+'_author'] = bool(matches) and author in matches[0]['prompt']+matches[0].get('hint','')
        checks['agent_completion_disclosed'] = any(any(word in call.get('response',{}).get('reply','') for word in ['补齐','补全','补充']) for call in calls)
    if identifier == 'P02':
        for cue, answer in [('白日依山尽','黄河入海流'),('欲穷千里目','更上一层楼')]:
            matches = [c for c in cards if cue in c['prompt']]
            checks[cue+'_correct_recall'] = bool(matches) and answer not in matches[0]['prompt']+matches[0].get('hint','') and answer in json.dumps(matches[0]['sections'],ensure_ascii=False)
        checks['explanation_included'] = bool(cards) and all(any('释义' in s['title'] and normalize(s['body']) not in ['黄河入海流','更上一层楼'] for s in c['sections']) for c in cards)
    if identifier == 'C02':
        checks['three_sentences_complete'] = all(any(sentence in normalize(c['prompt']) for c in cards) for sentence in ['学而时习之不亦说乎','有朋自远方来不亦乐乎','人不知而不愠不亦君子乎'])
        checks['correct_yue_reading'] = 'yuè' in text
    if identifier == 'A01':
        checks['asks_for_disambiguation'] = not cards and any(w in response.get('reply','') for w in ['哪','作者','确认','多首','多位'])
    audit.append({'id':identifier,'passed':all(checks.values()),'checks':checks,'seconds':sum(c['seconds'] for c in calls)})
(folder / 'audit.json').write_text(json.dumps(audit, ensure_ascii=False,indent=2)+'\n')
for row in audit:
    print(row['id'], 'PASS' if row['passed'] else 'FAIL', [k for k,v in row['checks'].items() if not v])

raise SystemExit(0 if all(row["passed"] for row in audit) else 1)
