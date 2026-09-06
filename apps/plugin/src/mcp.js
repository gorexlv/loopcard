import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { z } from 'zod';
import { createCard, createDeck, getCard, getDeck, listCards, listDecks } from './api.js';

const server = new McpServer({ name: 'loopcard', version: '0.1.0' });
const output = (value) => ({
  content: [{ type: 'text', text: JSON.stringify(value, null, 2) }],
  structuredContent: value,
});
const safe = (callback) => async (input) => {
  try {
    return output(await callback(input));
  } catch (error) {
    return { isError: true, content: [{ type: 'text', text: error.message }] };
  }
};

server.registerTool('list_decks', { description: 'List the signed-in user\'s LoopCard decks' }, safe(() => listDecks()));
server.registerTool(
  'get_deck',
  { description: 'Get a deck and its cards', inputSchema: { id: z.string().uuid() } },
  safe(({ id }) => getDeck(id)),
);
server.registerTool(
  'create_deck',
  {
    description: 'Create a LoopCard deck',
    inputSchema: {
      title: z.string().min(1).max(120),
      subtitle: z.string().optional(),
      kind: z.enum(['generic', 'word', 'formula', 'idiom', 'concept', 'equation']).optional(),
    },
  },
  safe((input) => createDeck(input)),
);
server.registerTool(
  'list_cards',
  { description: 'List cards, optionally within one deck', inputSchema: { deckId: z.string().uuid().optional() } },
  safe(({ deckId }) => listCards(deckId)),
);
server.registerTool(
  'get_card',
  { description: 'Get one card and all back sections', inputSchema: { id: z.string().uuid() } },
  safe(({ id }) => getCard(id)),
);
server.registerTool(
  'create_card',
  {
    description: 'Create a card and optional ordered back sections',
    inputSchema: {
      deckId: z.string().uuid(),
      prompt: z.string().min(1).max(1000),
      position: z.number().int().nonnegative().optional(),
      sections: z
        .array(
          z.object({
            title: z.string().min(1).max(80),
            heading: z.string().optional(),
            body: z.string().optional(),
            position: z.number().int().nonnegative().optional(),
          }),
        )
        .optional(),
    },
  },
  safe((input) => createCard(input)),
);

await server.connect(new StdioServerTransport());
