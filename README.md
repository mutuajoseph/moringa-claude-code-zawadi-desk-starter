# Zawadi Desk Starter

Starter repository for the Moringa Claude Code live workshop.

**New here? Read [`docs/tour.md`](docs/tour.md)** — a guided walk through the code, the
agent guard rails in `.claude/`, the documents, and the mistakes that produced each rule.

Finding your way around: [`docs/graft.md`](docs/graft.md) — a local index that answers
"where does this live" and "what breaks if I change it". One command to set up, optional.

Zawadi Desk is a small Next.js operations tool designed to deploy cleanly on Vercel. It already has a complete `projects` feature and the start of an `actions` feature. During the workshop, pairs agree the `actions` contract, build one side each, review each other, and merge.

## Setup

```bash
npm install
npm test
npm run lint
npm run build
```

The normal test suite is green before the workshop starts. The action contract tests are intentionally separate:

```bash
npm run test:actions
```

Those tests describe the feature you will build. Do not edit them to make the feature pass.

## Run locally

```bash
npm run dev
```

Open `http://localhost:3000`.

## Deploy to Vercel

Import this repository in Vercel and keep the detected framework as Next.js. No environment variables are required for the starter. `.env.example` contains dummy values only.

## Shape

- `app/` contains the Next.js routes and pages.
- `app/api/projects/route.ts` is the complete reference API route.
- `app/api/projects/[projectId]/actions/route.ts` is intentionally incomplete.
- `lib/projects.ts` is the finished reference data layer. Copy its patterns.
- `lib/actions.ts` is the starter data layer for the workshop feature.
- `components/` contains the UI pieces Dev B can extend.
- `docs/contract/actions.yaml` is the seam between Dev A and Dev B.
- `docs/handover/` is the UI handover for Dev B.
- `TASKS.md` has the small first-run tasks.

No real credentials belong in this repository. `.env.example` contains dummy values only.
