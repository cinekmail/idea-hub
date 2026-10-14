# Idea Hub — Hosting Services

A demo web app for raising, scoring and tracking improvement ideas for an IT Hosting Services team. Ideas can be raised through a guided chat assistant or a form, then prioritised with **WSJF (Weighted Shortest Job First)** and tracked to a decision.

**Live demo:** https://cinekmail.github.io/idea-hub/

> All names and ideas in the demo are fictional. Data is stored only in your own browser, and the "Reset demo data" link restores the sample set.

## Features

- **Idea assistant (main page).** A guided chat that walks you through raising a new idea step by step, and looks up an idea's status by ID (e.g. `HS-1045`) or by the email it was submitted with.
- **Submit form.** Title, service area, description, expected benefit, affected services, urgency and submitter details, with validation.
- **Idea dashboard.** Summary counts, filters by stage, decision and priority, search, and sorting by newest or highest WSJF.
- **WSJF scoring.** Each idea is scored on User/business value, Time criticality and Risk reduction/opportunity enablement (together the Cost of Delay), and on Job size, using a Fibonacci scale.
  `WSJF = Cost of Delay ÷ Job Size`
- **Voting.** One vote per idea per browser, and clicking again takes the vote back. Vote from the dashboard, the idea panel, the assistant's status card, or by typing "vote for HS-1047" in the chat. The dashboard can sort by most votes.
- **Triage and decision.** Priority, assigned person, stage (New → In assessment → In progress → Closed) and decision status (Pending, Approved, On hold, Rejected), with assessment notes.

## Tech

- A single `index.html` file with no build step: plain HTML and CSS, plus [Preact](https://preactjs.com/) and [htm](https://github.com/developit/htm) loaded from a CDN.
- Data is stored in Supabase (Postgres) through its REST API, or in `localStorage` when no database is configured.
- Hosted for free on GitHub Pages.

## Database (Supabase)

With no database configured, the app runs in browser-only mode, keeping ideas in `localStorage`. To share ideas between visitors:

1. Create a free Supabase project.
2. Run [`supabase/setup.sql`](supabase/setup.sql) in the SQL Editor. It creates the `ideas` table, the access rules, the 100-idea limit and the sample data.
3. Put the Project URL and Publishable key into `SUPABASE_URL` and `SUPABASE_KEY` at the top of the script in `index.html`.

What the public key can and can't do:

| Action | Allowed? |
|---|---|
| Read ideas | Yes, except submitters' email addresses |
| Add an idea | Yes, through `submit_idea()`, up to 100 ideas in total |
| Triage (WSJF, notes, priority, owner, stage, decision) | Yes |
| Change an idea's text, submitter or ID, or delete an idea | No |
| Look up your own ideas by email | Yes, through `ideas_by_email()`, which returns idea IDs only |
| Vote, or remove your vote | Yes, through `toggle_vote()`: one vote per idea per voter ID, enforced by the database |
| See who voted, or change vote counts directly | No |

Voting doesn't require sign-in. Each browser creates a random voter ID and keeps it in `localStorage`, so someone could vote again from another browser or a private window. That's acceptable for a demo, and real sign-in can be added later.

To start over, run [`supabase/reset.sql`](supabase/reset.sql) and then `setup.sql` again.

## Run locally

Open `index.html` in a browser. If your browser blocks it when opened as a file, serve the folder instead:

```bash
npx serve .
```

## Roadmap

- [x] Shared database (Supabase), so every visitor sees the same ideas
- [ ] Sign-in, with separate submitter and reviewer roles
- [ ] AI-powered assistant (Claude API through a Supabase Edge Function), with the API key kept on the server
- [ ] Status history and a "last updated" date on each idea
- [ ] Duplicate detection when raising a new idea
- [ ] Insight charts: time in each stage, ideas per month, approval rate
