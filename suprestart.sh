#!/usr/bin/env bash

set -u
IFS=$'\n\t'

if ! command -v supabase >/dev/null 2>&1; then
  echo "supabase CLI not found in PATH" >&2
  exit 1
fi

if [ ! -f "supabase/config.toml" ]; then
  echo "supabase/config.toml not found in current directory; run this from a Supabase project root." >&2
  exit 1
fi

echo "Starting Supabase in $(pwd)..."

output=$(supabase start 2>&1)
status=$?

if [ "$status" -eq 0 ]; then
  printf '%s\n' "$output"
  exit 0
fi

printf '%s\n' "$output" >&2

project_id=$(
  printf '%s\n' "$output" \
    | sed -n 's/.*supabase stop --project-id \([^[:space:]]*\).*/\1/p' \
    | head -n1
)

if [ -z "$project_id" ]; then
  project_id=$(
    printf '%s\n' "$output" \
      | sed -n 's/.*supabase_db_\([^[:space:]]*\).*/\1/p' \
      | head -n1
  )
fi

if [ -z "$project_id" ]; then
  echo "Failed to start Supabase and could not detect a running project ID from the error output." >&2
  exit "$status"
fi

echo "Detected running Supabase project with ID: $project_id" >&2
echo "Stopping that project..." >&2
supabase stop --project-id "$project_id"

echo "Starting Supabase again in $(pwd)..." >&2
supabase start
