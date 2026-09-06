# LoopCard local backend

LoopCard reuses the Supabase Docker stack in `/Users/rexlv/Workspace/supabase-local`.
The API is available at `http://127.0.0.1:8000`; Studio is exposed through the
same Kong stack. Database migrations and pgTAP checks live in this repository's
`supabase/` directory.

## Start and migrate

```sh
cd /Users/rexlv/Workspace/supabase-local
docker compose up -d

cd /Users/rexlv/Workspace/github.com/gorexlv/loopcard
docker exec -i supabase-db psql -U postgres -d postgres \
  < supabase/migrations/20260902125429_initial_loopcard_schema.sql
docker exec -i supabase-db psql -U postgres -d postgres \
  < supabase/tests/database/rls.test.sql
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
