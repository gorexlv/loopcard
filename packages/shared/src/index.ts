export type CardSection = { title: string; heading: string; body: string };
export type MemoryCard = { id: string; prompt: string; sections: CardSection[] };
export type PublicDeck = {
  slug: string;
  title: string;
  subtitle: string;
  description: string;
  category: string;
  author: string;
  saves: number;
  accent: string;
  cards: MemoryCard[];
};

const zodiacOrigins = [
  ['子鼠', '机敏居首', '鼠借牛渡河，在抵岸前跃下，抢先到达，因此排在十二生肖第一位。'],
  ['丑牛', '勤恳第二', '牛凭耐力最早接近终点，又载鼠过河；鼠先一步跃下后，牛随后抵达。'],
  ['寅虎', '勇猛第三', '虎凭力量穿过激流，但被水势阻慢，最终第三个到达。'],
  ['卯兔', '灵巧第四', '兔在河中借石跳跃，又攀上漂木渡过险处，凭灵巧取得第四名。'],
  ['辰龙', '行善第五', '龙途中降雨救助百姓，又吹送漂木帮助兔子，因此稍晚到达。'],
  ['巳蛇', '小龙第六', '蛇随马渡河，临近终点突然出现，使马受惊，先行一步取得第六名。'],
  ['午马', '奔腾第七', '马一路疾驰，却在终点前被蛇抢先，随后抵达，位列第七。'],
  ['未羊', '和善第八', '羊与猴、鸡合作乘木筏渡河，彼此谦让；上岸后羊先到终点。'],
  ['申猴', '聪慧第九', '猴与羊、鸡合力清除障碍、驾筏过河，随后到达终点。'],
  ['酉鸡', '协作第十', '鸡发现木筏并召集羊、猴共同渡河，因合作完成竞渡。'],
  ['戌狗', '忠诚第十一', '狗擅长游水，却因途中贪玩洗澡耽搁时间，较晚抵达。'],
  ['亥猪', '安逸第十二', '猪途中进食后睡了一觉，醒来继续赶路，最后到达终点。'],
] as const;

const catalogBlueprints = [
  ['Language', '#2dbda6', 'Spanish Travel Essentials', 'Useful phrases for moving through a city with confidence.', ['¿Dónde está…?', 'Una mesa para dos', 'La cuenta, por favor']],
  ['Language', '#2dbda6', 'French Café Phrases', 'A compact set for ordering, asking, and responding naturally.', ['Je voudrais…', "L'addition", "C'est délicieux"]],
  ['Language', '#2dbda6', 'Japanese Hiragana', 'Recognize foundational kana by sound and shape.', ['あ · a', 'か · ka', 'さ · sa']],
  ['Language', '#2dbda6', 'Korean Travel Basics', 'Short Korean prompts for practical everyday exchanges.', ['안녕하세요', '감사합니다', '얼마예요?']],
  ['Language', '#2dbda6', 'Latin Roots', 'Decode unfamiliar words through high-value classical roots.', ['aqua', 'scrib', 'port']],
  ['Language', '#2dbda6', 'Business English', 'Clear vocabulary for meetings, decisions, and project updates.', ['alignment', 'constraint', 'milestone']],
  ['Science', '#5573d8', 'Human Anatomy', 'A visual vocabulary of systems, organs, and essential functions.', ['Heart', 'Alveoli', 'Neuron']],
  ['Science', '#5573d8', 'Astronomy Fundamentals', 'Orient yourself among stars, planets, and deep-space structures.', ['Light-year', 'Red giant', 'Galaxy']],
  ['Science', '#5573d8', 'Cell Biology', 'Core structures and processes inside living cells.', ['Mitochondrion', 'Ribosome', 'Cell membrane']],
  ['Science', '#5573d8', 'Physics Constants', 'Recall the constants that anchor common calculations.', ['c', 'G', 'h']],
  ['Science', '#5573d8', 'Organic Functional Groups', 'Recognize structural patterns and their chemical behavior.', ['Hydroxyl', 'Carbonyl', 'Carboxyl']],
  ['Science', '#5573d8', 'Weather Systems', 'Read the atmosphere through fronts, pressure, and clouds.', ['Cold front', 'Cumulonimbus', 'Isobar']],
  ['Culture', '#ef9f18', 'Greek Mythology', 'Gods, heroes, symbols, and the stories that connect them.', ['Athena', 'Odysseus', 'Labyrinth']],
  ['Culture', '#ef9f18', 'World Festivals', 'Remember traditions through objects, rituals, and seasons.', ['Diwali', 'Carnival', 'Obon']],
  ['Culture', '#ef9f18', 'Chinese Idioms', 'Compact stories behind widely used four-character idioms.', ['画龙点睛', '守株待兔', '刻舟求剑']],
  ['Culture', '#ef9f18', 'Coffee Origins', 'Regions, processing methods, and flavor vocabulary.', ['Ethiopia', 'Washed process', 'Natural process']],
  ['Culture', '#ef9f18', 'Architecture Landmarks', 'Recognize influential places by form, era, and intent.', ['Pantheon', 'Fallingwater', 'Salk Institute']],
  ['Culture', '#ef9f18', 'Cinema Language', 'The building blocks directors use to shape attention.', ['Match cut', 'Montage', 'Diegetic sound']],
  ['History', '#a675ce', 'Ancient Civilizations', 'People, inventions, and turning points from early societies.', ['Cuneiform', 'Indus Valley', 'Roman Republic']],
  ['History', '#a675ce', 'Silk Road', 'Trade routes, travelers, and ideas moving across continents.', ['Samarkand', 'Caravanserai', 'Paper making']],
  ['History', '#a675ce', 'Age of Exploration', 'Voyages, instruments, and consequences of global navigation.', ['Caravel', 'Astrolabe', 'Columbian Exchange']],
  ['History', '#a675ce', 'Industrial Revolution', 'Machines and systems that reshaped work and cities.', ['Steam engine', 'Spinning jenny', 'Urbanization']],
  ['History', '#a675ce', 'Women Who Changed History', 'Pioneers remembered through their work and impact.', ['Ada Lovelace', 'Wangari Maathai', 'Rachel Carson']],
  ['History', '#a675ce', 'History of Writing', 'From marks and scripts to movable type and digital text.', ['Papyrus', 'Movable type', 'Unicode']],
  ['Technology', '#258ea6', 'Git Essentials', 'Commands and concepts for confident version control.', ['commit', 'rebase', 'cherry-pick']],
  ['Technology', '#258ea6', 'HTTP Status Codes', 'Recognize what a response says before reading its body.', ['200', '404', '503']],
  ['Technology', '#258ea6', 'SQL Fundamentals', 'Queries, joins, and constraints in compact recall prompts.', ['SELECT', 'INNER JOIN', 'PRIMARY KEY']],
  ['Technology', '#258ea6', 'Cloud Architecture', 'Core patterns for reliable distributed systems.', ['Load balancer', 'Queue', 'Object storage']],
  ['Technology', '#258ea6', 'Cybersecurity Basics', 'Threats and defenses every digital citizen should know.', ['Phishing', 'MFA', 'Encryption']],
  ['Technology', '#258ea6', 'AI Vocabulary', 'A practical map of modern machine-learning concepts.', ['Token', 'Embedding', 'Inference']],
  ['Business', '#c77a38', 'Finance Fundamentals', 'Read basic statements, ratios, and cash movements.', ['Revenue', 'Margin', 'Cash flow']],
  ['Business', '#c77a38', 'Product Strategy', 'Concepts for choosing problems and measuring value.', ['Positioning', 'North-star metric', 'Opportunity cost']],
  ['Business', '#c77a38', 'Negotiation Moves', 'Tactics for preparing, listening, and finding agreement.', ['BATNA', 'Anchor', 'Trade-off']],
  ['Business', '#c77a38', 'Marketing Metrics', 'Recall the signals behind acquisition and retention.', ['CAC', 'LTV', 'Conversion rate']],
  ['Business', '#c77a38', 'Startup Vocabulary', 'Terms used across funding, growth, and operations.', ['Runway', 'Cap table', 'Product-market fit']],
  ['Business', '#c77a38', 'Leadership Principles', 'Small prompts for clearer decisions and healthier teams.', ['Context', 'Delegation', 'Feedback loop']],
  ['Arts', '#dc6d73', 'Color Theory', 'Relationships that make palettes feel deliberate.', ['Complementary', 'Saturation', 'Value']],
  ['Arts', '#dc6d73', 'Typography Anatomy', 'Name the details that give letterforms their character.', ['X-height', 'Serif', 'Counter']],
  ['Arts', '#dc6d73', 'Music Theory', 'Intervals, harmony, and rhythm in recall-sized pieces.', ['Perfect fifth', 'Cadence', 'Syncopation']],
  ['Arts', '#dc6d73', 'Photography Basics', 'Control light and composition with essential concepts.', ['Aperture', 'Shutter speed', 'Leading lines']],
  ['Arts', '#dc6d73', 'Modern Art Movements', 'Recognize movements by their ideas and visual language.', ['Cubism', 'Bauhaus', 'Surrealism']],
  ['Arts', '#dc6d73', 'Creative Writing', 'Techniques for sharper scenes, characters, and voice.', ['Point of view', 'Subtext', 'Concrete detail']],
  ['Wellness', '#6c9b6b', 'Mindfulness Cues', 'Brief prompts for attention, grounding, and reflection.', ['Notice breath', 'Name the feeling', 'Release tension']],
  ['Wellness', '#6c9b6b', 'Sleep Foundations', 'Habits and signals that support restorative sleep.', ['Circadian rhythm', 'Sleep pressure', 'Light exposure']],
  ['Wellness', '#6c9b6b', 'Nutrition Basics', 'Understand common nutrients and their roles.', ['Protein', 'Fiber', 'Hydration']],
  ['Wellness', '#6c9b6b', 'Running Vocabulary', 'Training language for pacing, recovery, and progress.', ['Easy pace', 'Tempo run', 'Cadence']],
  ['Wellness', '#6c9b6b', 'Strength Training', 'Movements, principles, and safe progression.', ['Squat', 'Progressive overload', 'Recovery']],
  ['Wellness', '#6c9b6b', 'Emotional Vocabulary', 'More precise words for naming internal experience.', ['Contentment', 'Apprehension', 'Resentment']],
] as const;

const discoveryDecks: PublicDeck[] = catalogBlueprints.map(([category, accent, title, description, prompts], deckIndex) => ({
  slug: `${category.toLowerCase()}-${deckIndex + 1}-${title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')}`,
  title,
  subtitle: `${18 + (deckIndex % 5) * 4} cards · ${category}`,
  description,
  category,
  author: deckIndex % 3 === 0 ? 'LoopCard Studio' : deckIndex % 3 === 1 ? 'Open Memory Lab' : 'Community Curator',
  saves: 620 + ((deckIndex * 487) % 8900),
  accent,
  cards: prompts.map((prompt, cardIndex) => ({
    id: `catalog-${deckIndex + 1}-${cardIndex + 1}`,
    prompt,
    sections: [
      { title: 'Core', heading: `Remember ${prompt}`, body: `${description} This card keeps the essential idea concise and recallable.` },
      { title: 'Context', heading: 'Connect the idea', body: `Place ${prompt} in a practical context, then recall it again without looking.` },
    ],
  })),
}));

export const publicDecks: PublicDeck[] = [
  {
    slug: 'chinese-zodiac-origins',
    title: '十二生肖的来历',
    subtitle: '12 张卡 · 民间文化',
    description: '从子鼠到亥猪，用一轮卡片记住十二生肖竞渡传说。',
    category: '文化', author: 'LoopCard 编辑部', saves: 2480, accent: '#ef9f18',
    cards: zodiacOrigins.map(([prompt, heading, body], index) => ({
      id: `zodiac-${index + 1}`, prompt,
      sections: [
        { title: '来历', heading, body: `民间传说中，${body}` },
        { title: '象征', heading: prompt.slice(1), body: '生肖故事版本众多，这组卡片采用流传较广的竞渡叙事。' },
      ],
    })),
  },
  {
    slug: 'everyday-english-core', title: 'Everyday English',
    subtitle: '20 cards · Language',
    description: 'High-frequency words with compact meanings, examples, and distinctions.',
    category: 'Language', author: 'LoopCard Studio', saves: 3920, accent: '#2dbda6',
    cards: [
      { id: 'borrow', prompt: 'borrow', sections: [
        { title: 'Meaning', heading: 'v. take and use temporarily', body: 'Borrow focuses on receiving something with the intention of returning it.' },
        { title: 'Example', heading: 'borrow a book', body: 'May I borrow this book for the weekend?' },
        { title: 'Distinction', heading: 'borrow vs. lend', body: 'You borrow from someone; they lend something to you.' },
      ] },
      { id: 'serene', prompt: 'serene', sections: [
        { title: 'Meaning', heading: 'calm and peaceful', body: 'A quiet state without disturbance or anxiety.' },
        { title: 'Example', heading: 'a serene morning', body: 'The lake looked serene before sunrise.' },
      ] },
      { id: 'retain', prompt: 'retain', sections: [
        { title: 'Meaning', heading: 'continue to have', body: 'To keep possession, memory, or control of something.' },
        { title: 'Example', heading: 'retain information', body: 'Short review sessions help you retain information.' },
      ] },
    ],
  },
  {
    slug: 'chemistry-formulas', title: 'Common Chemical Formulas',
    subtitle: '20 cards · Science',
    description: 'Essential formulas, names, structure notes, and everyday uses.',
    category: 'Science', author: 'Open Study Lab', saves: 1870, accent: '#5573d8',
    cards: [
      { id: 'h2o', prompt: 'H₂O', sections: [
        { title: 'Name', heading: 'Water', body: 'Two hydrogen atoms bonded to one oxygen atom.' },
        { title: 'Structure', heading: 'Bent molecule', body: 'Its polar geometry enables hydrogen bonding.' },
      ] },
      { id: 'co2', prompt: 'CO₂', sections: [
        { title: 'Name', heading: 'Carbon dioxide', body: 'One carbon atom double-bonded to two oxygen atoms.' },
        { title: 'Context', heading: 'Carbon cycle', body: 'Produced by respiration and used by plants during photosynthesis.' },
      ] },
      { id: 'nacl', prompt: 'NaCl', sections: [{ title: 'Name', heading: 'Sodium chloride', body: 'An ionic compound commonly known as table salt.' }] },
    ],
  },
  {
    slug: 'design-principles', title: 'Principles of Good Design',
    subtitle: '16 cards · Design',
    description: 'A practical vocabulary for hierarchy, rhythm, contrast, and restraint.',
    category: 'Design', author: 'Form & Memory', saves: 1260, accent: '#dc6d73',
    cards: [
      { id: 'hierarchy', prompt: 'Hierarchy', sections: [{ title: 'Definition', heading: 'Order attention', body: 'Visual hierarchy tells the eye where to begin and what matters next.' }] },
      { id: 'rhythm', prompt: 'Rhythm', sections: [{ title: 'Definition', heading: 'Repeat with intent', body: 'Spacing, type, and shape create a predictable visual cadence.' }] },
    ],
  },
  ...discoveryDecks,
];

export const getPublicDeck = (slug: string) => publicDecks.find((deck) => deck.slug === slug);
