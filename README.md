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
- **Triage and decision.** Priority, assigned person, stage (New → In assessment → In progress → Closed) and decision status (Pending, Approved, On hold, Rejected), with assessment notes.

## Tech

- A single `index.html` file with no build step: plain HTML and CSS, plus [Preact](https://preactjs.com/) and [htm](https://github.com/developit/htm) loaded from a CDN.
- Data is kept in the browser's `localStorage`. All reads and writes go through one small `store` object, so it can be replaced with a real database later.
- Hosted for free on GitHub Pages.

## Run locally

Open `index.html` in a browser. If your browser blocks it when opened as a file, serve the folder instead:

```bash
npx serve .
```

## Roadmap

- [ ] Shared database (Supabase), so every visitor sees the same ideas
- [ ] Sign-in, with separate submitter and reviewer roles
- [ ] AI-powered assistant (Claude API through a Supabase Edge Function), with the API key kept on the server
- [ ] Status history and a "last updated" date on each idea
- [ ] Duplicate detection when raising a new idea
- [ ] Insight charts: time in each stage, ideas per month, approval rate
