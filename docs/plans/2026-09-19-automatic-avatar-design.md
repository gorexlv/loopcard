# Automatic profile avatars

New authenticated accounts without an existing avatar receive a individually generated Pixar-style 3D animal portrait. Generation begins after sign-in/session restoration and does not block onboarding. A bundled teal owl portrait is immediately visible, including offline and while generation is pending. Existing OAuth avatars are preserved. Old accounts without an avatar receive the same backfill behavior.

## Implementation

- `UserAvatar` replaces the fixed L on the profile page. It displays the bundled image underneath a remote image and retains it when a URL is blank, invalid or fails to load.
- `AutomaticAvatarService` keeps the existing AuthService interface compatible. AppEntry requests the avatar when the authenticated account changes; request identity checks discard stale results after sign-out or account switching.
- The authenticated `generate-avatar` function derives identity exclusively from the verified session. Only the server creates the prompt. Names, emails, and account IDs are not transmitted to the image provider.
- OpenRouter's Image API reuses `OPENROUTER_API_KEY`, defaulting to `openai/gpt-image-2`. If no OpenRouter key is available, the OpenAI Images API uses `OPENAI_API_KEY` and `gpt-image-2`. `AVATAR_IMAGE_MODEL` overrides the selected provider's model name.
- Generated avatars are stored in the public `generated-avatars` bucket. Only the service role writes files and the generated result table. Row-level security limits table reads to the owner. Mobile resolves generated storage URLs through its own Supabase host for local Docker compatibility.
- An atomic database lease prevents duplicate generation. Failed requests become retryable at the next login after ten minutes, with at most three total attempts per account. Successful images are reused across sessions/devices. After three failures, an operator can reset attempts after resolving the provider issue. A concurrent request returns pending and can retrieve the completed result on the next login.

## Running and release

Apply migration `20260919070712_generated_avatars.sql` and serve/deploy `generate-avatar` with JWT verification enabled. Configure `OPENROUTER_API_KEY` or `OPENAI_API_KEY` as a server secret. Do not put image provider credentials in the mobile app.

```sh
supabase functions serve generate-avatar --env-file supabase/functions/.env
# For the target hosted environment, apply migrations before deployment:
supabase functions deploy generate-avatar
```

The schema has been applied and its migration recorded in the local database. No hosted environment has been deployed. The currently running separate local Edge Functions container does not mount this repository; use the serve command above to run this function from the project.

## Validation

- Deno handler tests: unauthenticated rejection, existing avatars, concurrent claims, both provider request paths, failure sanitization.
- Eight database assertions: claim/retry/reuse semantics and owner-only access/server-only writes.
- Flutter component tests: missing/invalid URLs, network failure fallback. Profile screenshot checks the 72px circular image in context.
- Local live check: created a temporary authenticated account, generated through OpenRouter, uploaded and fetched its PNG, and verified a repeat call returns the same URL. Temporary account and files were deleted afterward.
- Relevant Dart analysis and local database security advisors passed.
- The broader mobile widget suite currently cannot compile because existing study/result screens pass `adaptiveLayout` to GradientPage, whose current constructor does not define that parameter. This is outside the avatar changes.

References: [OpenRouter image generation](https://openrouter.ai/docs/guides/overview/multimodal/image-generation), [Supabase Flutter function invocation](https://supabase.com/docs/reference/dart/functions-invoke).
