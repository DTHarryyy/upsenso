#!/bin/bash
set -e

# ── 1. Install Flutter ────────────────────────────────────────────────────────
git clone https://github.com/flutter/flutter.git --depth 1 -b stable
export PATH="$PATH:$(pwd)/flutter/bin"

flutter config --enable-web
flutter pub get

# ── 2. Write dart-define file from Cloudflare environment variables ───────────
# Cloudflare injects SUPABASE_URL and SUPABASE_ANON_KEY as env vars.
# CF_PAGES_URL is auto-set by Cloudflare to the deployment URL.
mkdir -p flavors
cat > flavors/cf_build.json <<EOF
{
  "SUPABASE_URL": "${SUPABASE_URL}",
  "SUPABASE_ANON_KEY": "${SUPABASE_ANON_KEY}",
  "SUPABASE_OAUTH_REDIRECT_URL": "posauth://login-callback/",
  "SUPABASE_WEB_OAUTH_REDIRECT_URL": "${CF_PAGES_URL:-https://your-project.pages.dev}",
  "FLAVOR": "prod",
  "LOG_LEVEL": "warn",
  "ENABLE_ANALYTICS": "true"
}
EOF

# ── 3. Build Flutter web ──────────────────────────────────────────────────────
flutter build web \
  --release \
  --dart-define-from-file=flavors/cf_build.json
