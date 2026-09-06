#!/usr/bin/env node
import { Command } from 'commander';
import {
  createCard,
  createDeck,
  getCard,
  getDeck,
  listCards,
  listDecks,
  login,
  logout,
} from '../src/api.js';

const program = new Command().name('loopcard').description('Manage LoopCard decks and cards');
const print = (value) => process.stdout.write(`${JSON.stringify(value, null, 2)}\n`);
const run = (callback) => async (...args) => {
  try {
    print(await callback(...args));
  } catch (error) {
    process.stderr.write(`${error.message}\n`);
    process.exitCode = 1;
  }
};

program
  .command('login')
  .requiredOption('--email <email>')
  .requiredOption('--password <password>')
  .action(run((options) => login(options.email, options.password)));
program.command('logout').action(run(() => logout()));

const decks = program.command('decks');
decks.command('list').action(run(() => listDecks()));
decks.command('get').argument('<id>').action(run((id) => getDeck(id)));
decks
  .command('create')
  .requiredOption('--title <title>')
  .option('--subtitle <subtitle>', '')
  .option('--kind <kind>', 'generic')
  .action(run((options) => createDeck(options)));

const cards = program.command('cards');
cards.command('list').option('--deck-id <id>').action(run((options) => listCards(options.deckId)));
cards.command('get').argument('<id>').action(run((id) => getCard(id)));
cards
  .command('create')
  .requiredOption('--deck-id <id>')
  .requiredOption('--front <text>')
  .option('--section-title <title>')
  .option('--heading <heading>', '')
  .option('--body <body>', '')
  .action(
    run((options) =>
      createCard({
        deckId: options.deckId,
        prompt: options.front,
        sections: options.sectionTitle
          ? [{ title: options.sectionTitle, heading: options.heading, body: options.body }]
          : [],
      }),
    ),
  );

await program.parseAsync();
