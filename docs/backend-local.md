# LoopCard local backend

LoopCard can reuse the running local Supabase Docker stack. Database migrations,
Edge Functions and pgTAP checks live in this repository's `supabase/` directory.

## Start and migrate

```sh
cd /Users/rexlv/Workspace/github.com/gorexlv/loopcard
supabase start
supabase migration up --local
supabase test db
```

## Word-card generation

The phone performs OCR locally. Only the selected words are sent to the Edge
Function, which returns reviewable drafts and never writes cards automatically.

```sh
cp supabase/functions/.env.example supabase/functions/.env.local
# Add DEEPSEEK_API_KEY to .env.local, then:
supabase functions serve generate-word-cards \
  --env-file supabase/functions/.env.local
```

For a linked hosted project, set the secret and deploy the function separately:

```sh
supabase secrets set AI_PROVIDER=deepseek AI_MODEL=deepseek-flash \
  DEEPSEEK_API_KEY=<key>
supabase functions deploy generate-word-cards
```

Email/password auth is enabled and auto-confirms accounts locally. Google and
Apple provider wiring is present in the Docker stack; add the provider client ID
and secret in `/Users/rexlv/Workspace/supabase-local/.env`, then switch the
matching `ENABLE_*_SIGNIN` value to `true`. Both providers must allow the callback
`http://127.0.0.1:8000/auth/v1/callback`. The mobile return URL is
`io.loopcard.app://login-callback/`.

## Run Flutter

The emulator default is `http://10.0.2.2:8000`. A physical device needs the
Mac's LAN address:

```sh
flutter run \
  --dart-define=SUPABASE_URL=http://<mac-lan-ip>:8000 \
  --dart-define=SUPABASE_ANON_KEY=<local-anon-key>
```

Use HTTPS and production publishable keys for release builds. Cleartext HTTP is
enabled in the Android manifest solely for local Docker development.

For a debug-only APK that automatically signs in with a disposable test user:

```sh
flutter build apk --debug \
  --dart-define=SUPABASE_URL=http://<mac-lan-ip>:8000 \
  --dart-define=TEST_AUTO_LOGIN=true \
  --dart-define=TEST_ACCOUNT_EMAIL=<test-email> \
  --dart-define=TEST_ACCOUNT_PASSWORD=<test-password>
```

`TEST_AUTO_LOGIN` is ignored in profile and release builds. Test credentials
must never be reused for production data.

## CLI

```sh
cd apps/plugin
npm install
npm link
loopcard login --email you@example.com --password 'your-password'
loopcard decks list
loopcard decks create --title 'My deck' --kind generic
loopcard cards list --deck-id <deck-id>
loopcard cards create --deck-id <deck-id> --prompt 'Front'
```

The session is stored with mode `0600` at
`~/.config/loopcard/session.json`. Override the backend with
`LOOPCARD_SUPABASE_URL`, `LOOPCARD_SUPABASE_ANON_KEY`, and
`LOOPCARD_SESSION_PATH`.

The installed Codex plugin exposes the same operations as MCP tools:
`list_decks`, `get_deck`, `create_deck`, `list_cards`, `get_card`, and
`create_card`.

## Multi-photo Card Agent

The mobile photo entry now collects up to 10 photos and 4000 characters of
corrected OCR text. Photos stay on device; all text sources enter one chat.
Choose a front/back preset, customize it in conversation, then generate and
explicitly save the drafts. Unfinished conversations are restored on this device
and isolated by signed-in user. Starting a new capture replaces the current
saved conversation only after the new material is submitted.

Apply the new `card_agent_generation` migration after `structured_word_cards`.
The migration preserves presentation/source metadata and adds an idempotent
`create_agent_deck` RPC. Chat previews and saved study cards share the renderer.

```sh
supabase migration up --local
supabase functions serve card-agent --env-file supabase/functions/.env.local
```

The same AI provider settings as `generate-word-cards` are used. Missing provider
credentials return `503 generation_not_configured`; there is no fake response
fallback. Local CLI services use port **54321**; configure the mobile
`SUPABASE_URL` accordingly (Android emulator: `http://10.0.2.2:54321`). The
separate Docker stack on port 8000 needs its own migration/function deployment.

Runtime Skills live in `supabase/functions/card-agent/skills/`; the preset and
structured-response contract lives in `_shared/card_agent.ts`. Skill files are
bundled with the function through `static_files` in `config.toml`. To add a Skill,
register its id, version, presets and validation, add its instruction file, and
expose the corresponding preset metadata to the client. The first Skills are
English vocabulary and source-grounded knowledge questions. OCR retains the
existing Latin-script recognizer; adding other script recognition models is a
separate platform setup task.

```sh
deno test supabase/functions/_shared
supabase test db
cd apps/mobile
flutter test
```
