-- =====================================================================
-- Idea Hub — Supabase setup for the public prototype
-- Run once in Supabase: SQL Editor → New query → paste → Run.
--
-- What it creates
--   • ideas table with HS-#### IDs, WSJF fields and input checks
--   • a hard limit of 100 ideas (extra inserts are refused)
--   • access rules for the public (anon) key:
--       - anyone can read ideas, but NOT submitters' email addresses
--       - anyone can add an idea through submit_idea() (submission fields only)
--       - anyone can triage (WSJF, notes, priority, owner, stage, decision)
--       - nobody can delete or change an idea's ID, text or submitter
--   • ideas_by_email(): lets the assistant find a person's ideas by email
--     without exposing the email column
--   • the 7 sample ideas
-- =====================================================================

-- ---------- Table ----------------------------------------------------
create sequence if not exists public.idea_number_seq start 1049;

create table if not exists public.ideas (
  id          text primary key default ('HS-' || nextval('public.idea_number_seq')),
  title       text not null check (char_length(title) between 4 and 120),
  category    text not null check (category in (
                'Compute & VMs', 'Storage & Backup', 'Network & DNS', 'Monitoring & Alerting',
                'Automation & Self-service', 'Security & Compliance', 'Cost optimisation', 'Other')),
  urgency     text not null default 'medium' check (urgency in ('low', 'medium', 'high')),
  description text not null check (char_length(description) between 15 and 2000),
  benefit     text not null default '' check (char_length(benefit) <= 1000),
  affected    text not null default '' check (char_length(affected) <= 300),
  name        text not null check (char_length(name) between 2 and 80),
  email       text not null check (char_length(email) <= 120
                and email ~* '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'),
  team        text not null default '' check (char_length(team) <= 80),
  -- WSJF (Fibonacci scale); null = not scored yet
  bv          smallint check (bv in (1, 2, 3, 5, 8, 13, 20)),  -- user / business value
  tc          smallint check (tc in (1, 2, 3, 5, 8, 13, 20)),  -- time criticality
  rr          smallint check (rr in (1, 2, 3, 5, 8, 13, 20)),  -- risk reduction / opportunity enablement
  js          smallint check (js in (1, 2, 3, 5, 8, 13, 20)),  -- job size
  notes       text not null default '' check (char_length(notes) <= 2000),
  priority    text not null default '' check (priority in ('', 'critical', 'high', 'medium', 'low')),
  assignee    text not null default '' check (char_length(assignee) <= 80),
  stage       text not null default 'new' check (stage in ('new', 'assessment', 'progress', 'closed')),
  decision    text not null default 'pending' check (decision in ('pending', 'approved', 'hold', 'rejected')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

alter sequence public.idea_number_seq owned by public.ideas.id;

-- ---------- 100-idea limit -------------------------------------------
create or replace function public.ideas_enforce_cap()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select count(*) from public.ideas) >= 100 then
    raise exception 'IDEA_LIMIT_REACHED: this demo holds at most 100 ideas';
  end if;
  return new;
end;
$$;

drop trigger if exists ideas_cap on public.ideas;
create trigger ideas_cap
  before insert on public.ideas
  for each row execute function public.ideas_enforce_cap();

-- ---------- Keep updated_at current ----------------------------------
create or replace function public.ideas_touch()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists ideas_touch on public.ideas;
create trigger ideas_touch
  before update on public.ideas
  for each row execute function public.ideas_touch();

-- ---------- Access for the public key --------------------------------
alter table public.ideas enable row level security;

revoke all on public.ideas from anon, authenticated;

-- Read everything except email
grant select (id, title, category, urgency, description, benefit, affected, name, team,
              bv, tc, rr, js, notes, priority, assignee, stage, decision, created_at, updated_at)
  on public.ideas to anon, authenticated;

-- Triage: assessment and decision fields only
grant update (bv, tc, rr, js, notes, priority, assignee, stage, decision)
  on public.ideas to anon, authenticated;

-- New ideas are added only through submit_idea() below (no direct inserts),
-- so ID, status and dates are always set by the database.

drop policy if exists "demo: anyone can read ideas" on public.ideas;
create policy "demo: anyone can read ideas"
  on public.ideas for select to anon, authenticated using (true);

drop policy if exists "demo: anyone can triage ideas" on public.ideas;
create policy "demo: anyone can triage ideas"
  on public.ideas for update to anon, authenticated using (true) with check (true);

-- No delete policy → deletes are refused.

-- ---------- Submit a new idea ----------------------------------------
-- Returns the new idea's ID (e.g. 'HS-1049'). Table checks and the
-- 100-idea limit still apply.
create or replace function public.submit_idea(
  p_title text, p_category text, p_urgency text, p_description text,
  p_benefit text, p_affected text, p_name text, p_email text, p_team text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_id text;
begin
  insert into public.ideas (title, category, urgency, description, benefit, affected, name, email, team)
  values (trim(p_title), p_category, coalesce(nullif(p_urgency, ''), 'medium'), trim(p_description),
          coalesce(trim(p_benefit), ''), coalesce(trim(p_affected), ''), trim(p_name),
          lower(trim(p_email)), coalesce(trim(p_team), ''))
  returning id into new_id;
  return new_id;
end;
$$;

revoke all on function public.submit_idea(text, text, text, text, text, text, text, text, text) from public;
grant execute on function public.submit_idea(text, text, text, text, text, text, text, text, text) to anon, authenticated;

-- ---------- Look up ideas by submitter email -------------------------
create or replace function public.ideas_by_email(p_email text)
returns setof text
language sql
stable
security definer
set search_path = ''
as $$
  select id
  from public.ideas
  where lower(email) = lower(trim(p_email))
  order by created_at desc
  limit 20;
$$;

revoke all on function public.ideas_by_email(text) from public;
grant execute on function public.ideas_by_email(text) to anon, authenticated;

-- ---------- Sample data ----------------------------------------------
insert into public.ideas
  (id, title, category, urgency, description, benefit, affected, name, email, team,
   bv, tc, rr, js, notes, priority, assignee, stage, decision, created_at)
values
  ('HS-1042', 'Self-service DNS record requests', 'Network & DNS', 'low',
   'Form-driven A/CNAME record creation for internal zones with automatic validation and approval by zone owner.',
   'Removes a frequent manual ticket type.', 'Internal DNS zones',
   'Tomasz Lewandowski', 'tomasz.lewandowski@example.com', 'Network',
   5, 2, 2, 2, 'Delivered 2026-10-01.', 'low', 'Tomasz Lewandowski', 'closed', 'approved', '2026-09-03 09:00+02'),
  ('HS-1043', 'Self-service VM provisioning from the service catalogue', 'Automation & Self-service', 'high',
   'Standard VM sizes orderable from the service catalogue, built automatically with baseline hardening, backup and monitoring.',
   'Provisioning time from days to under an hour.', 'All requesting teams',
   'Anna Nowak', 'anna.nowak@example.com', 'Hosting Services',
   20, 13, 8, 13, 'Phase 1: Windows and Linux standard sizes only.', 'critical', 'Anna Nowak', 'progress', 'approved', '2026-09-15 09:00+02'),
  ('HS-1044', 'Unified monitoring dashboards for hosted applications', 'Monitoring & Alerting', 'medium',
   'One standard dashboard per hosted application showing availability, CPU, memory, disk and recent alerts.',
   'Faster triage; app owners self-serve status instead of raising tickets.', 'App owners, Service Desk',
   'Paweł Szymański', 'pawel.szymanski@example.com', 'Service Desk',
   8, 5, 8, 5, 'Approved at CAB. Template built on existing monitoring stack.', 'medium', 'Katarzyna Zielińska', 'progress', 'approved', '2026-09-24 09:00+02'),
  ('HS-1045', 'Automated patching windows for Windows Server fleet', 'Automation & Self-service', 'high',
   'Let app owners pick a recurring maintenance window per server group; patching, reboot and health checks run automatically within it.',
   'Fewer manual change requests and missed patch cycles.', 'Windows Server VMs, all regions',
   'Agnieszka Wójcik', 'agnieszka.wojcik@example.com', 'Infrastructure Ops',
   13, 8, 13, 8, '', 'high', 'Piotr Wiśniewski', 'assessment', 'pending', '2026-10-02 09:00+02'),
  ('HS-1046', 'Rightsizing report for idle and oversized VMs', 'Cost optimisation', 'medium',
   'Monthly report to app owners listing VMs with sustained low CPU and memory use, with a suggested smaller size.',
   'Reduce wasted compute; make costs visible to owners.', 'App owners, FinOps',
   'Michał Dąbrowski', 'michal.dabrowski@example.com', 'FinOps',
   8, 3, 5, 3, 'Depends on monitoring data retention of 30+ days.', 'medium', 'Marta Kamińska', 'assessment', 'hold', '2026-10-06 09:00+02'),
  ('HS-1047', 'Storage tiering for cold backup data', 'Storage & Backup', 'medium',
   'Automatically move backups older than 90 days to a cheaper archive tier while keeping restore SLAs for recent data.',
   'Lower storage cost for long-retention backups.', 'All backup policies',
   'Ewa Krawczyk', 'ewa.krawczyk@example.com', 'Finance IT',
   null, null, null, null, '', '', '', 'new', 'pending', '2026-10-08 09:00+02'),
  ('HS-1048', 'Bare-metal hosting option for GPU workloads', 'Compute & VMs', 'medium',
   'Offer dedicated bare-metal hosts with GPUs for teams running model training, instead of them buying their own hardware.',
   'Keeps GPU workloads inside managed hosting with standard patching and monitoring.', 'Data science teams',
   'Jakub Mazur', 'jakub.mazur@example.com', 'Analytics',
   5, 2, 3, 20, 'Capacity and power constraints in current DC. Revisit with the cloud GPU offering.', 'low', 'Tomasz Lewandowski', 'closed', 'rejected', '2026-10-09 09:00+02')
on conflict (id) do nothing;

-- Quick check: should return 7
select count(*) as ideas_in_database from public.ideas;
