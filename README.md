# PT Helper — Agent Starter Kit

This repo is a jumpstart for an **App‑builder agent** that will deliver an iOS Physical Therapy Helper app.
It includes prompts for a multi‑role agent, a task schema, initial backlog issues, and CI scaffolding.

## What’s here
- `prompts/` — System and role prompts (Orchestrator, iOS Dev, Backend, QA).
- `.github/workflows/ci.yml` — CI with lint/test placeholders.
- `agent/tasks/` — Ticket schema and sample tasks.
- `backend/` — Option notes for Firebase or Supabase.
- `ios/` — SwiftUI module layout proposal (no Xcode project yet).
- `docs/` — Product Brief + JSON DSL for assessments + safety guidelines.

## Quick start
1. Create a **private GitHub repo** and push these files.
2. Provision secrets (example names in CI file): `APP_STORE_KEY_ID`, `APP_STORE_ISSUER_ID`, `APP_STORE_PRIVATE_KEY` (optional for TestFlight later).
3. Choose backend (Firebase or Supabase) and follow `backend/SETUP.md`.
4. Point your agent/orchestrator at `docs/brief.md`, `docs/ux_flows.md`, and `docs/dsl/` to ground generation.
5. Use the **sample tasks** under `agent/tasks/` to bootstrap delivery (Orchestrator will break down further).
6. Run CI locally: `make bootstrap && make test` (add real scripts in `Makefile`).

> Safety note: This app provides wellness guidance, not medical diagnosis. Keep red‑flag rules prominent and signpost urgent care when triggered.
