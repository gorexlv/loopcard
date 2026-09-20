import 'package:loopcard/models/card_models.dart';

const alignedPoem = StudyCard(
  id: 'aligned-poem',
  prompt: '静夜思',
  presentation: {
    'skill': 'poetry',
    'literary': {'author': '李白', 'dynasty': '唐'},
  },
  sections: [
    CardBackSection(
      title: '原文',
      heading: '',
      body: '床前明月光，\n疑是地上霜。\n举头望明月，\n低头思故乡。',
    ),
    CardBackSection(
      title: '释义',
      heading: '',
      body: '床前洒着明亮的月光，\n仿佛是地上铺了一层霜。\n抬头望向明月，\n低头思念故乡。',
    ),
    CardBackSection(
      title: '字词注释',
      heading: '',
      body: '【疑】以为，好像。\n【举头】抬头。\n【思】思念。',
    ),
  ],
);
const stanzaPoem = StudyCard(
  id: 'ci',
  prompt: '浣溪沙·一曲新词酒一杯',
  presentation: {
    'skill': 'poetry',
    'literary': {'author': '晏殊', 'dynasty': '北宋'},
  },
  sections: [
    CardBackSection(
      title: '上阕',
      heading: '',
      body: '一曲新词酒一杯，\n去年天气旧亭台。\n夕阳西下几时回？',
    ),
    CardBackSection(
      title: '下阕',
      heading: '',
      body: '无可奈何花落去，\n似曾相识燕归来。\n小园香径独徘徊。',
    ),
    CardBackSection(
      title: '上阕释义',
      heading: '',
      body: '听一曲新词，饮一杯美酒，\n还是去年的天气、旧日的亭台。\n西下的夕阳，何时再回来？',
    ),
    CardBackSection(
      title: '下阕释义',
      heading: '',
      body: '花儿凋落，让人无可奈何，\n归来的燕子仿佛曾经相识。\n独自在小园的花间小路上徘徊。',
    ),
  ],
);
const longWordBack = StudyCard(
  id: 'long-word-back',
  prompt: 'characteristically',
  sections: [],
  wordContent: WordCardContent(
    partOfSpeech: 'adv.',
    definition: '典型地；一贯地',
    englishDefinition: 'in a way that is typical of a person or thing',
    example: WordExample(
      sentence: 'She was characteristically calm.',
      translation: '她一如既往地冷静。',
    ),
    usagePatterns: ['characteristically + adjective'],
    collocations: ['characteristically calm', 'characteristically direct'],
  ),
);
