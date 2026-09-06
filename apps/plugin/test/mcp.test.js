import assert from 'node:assert/strict';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StdioClientTransport } from '@modelcontextprotocol/sdk/client/stdio.js';

const projectRoot = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  '..',
);

test('MCP server advertises the complete LoopCard tool surface', async () => {
  const transport = new StdioClientTransport({
    command: process.execPath,
    args: [path.join(projectRoot, 'src/mcp.js')],
    cwd: projectRoot,
    stderr: 'pipe',
  });
  const client = new Client({ name: 'loopcard-test', version: '0.1.0' });
  try {
    await client.connect(transport);
    const result = await client.listTools();
    assert.deepEqual(
      result.tools.map((tool) => tool.name).sort(),
      [
        'create_card',
        'create_deck',
        'get_card',
        'get_deck',
        'list_cards',
        'list_decks',
      ],
    );
  } finally {
    await client.close();
  }
});
