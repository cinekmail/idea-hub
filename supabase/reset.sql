-- =====================================================================
-- Idea Hub — reset the demo data
-- Removes ALL ideas and restarts numbering at HS-1049.
-- After running this, run setup.sql again to restore the 7 sample ideas
-- (setup.sql is safe to re-run; it only adds what is missing).
-- =====================================================================
truncate table public.ideas;
alter sequence public.idea_number_seq restart with 1049;
