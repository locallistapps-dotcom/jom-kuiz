-- Migration: create quiz_sessions, quiz_answers, quiz_results tables
-- Applied directly to production via Supabase Management API.
-- This file documents the change for version control.

-- ── quiz_sessions ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.quiz_sessions (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_id         uuid REFERENCES public.topics(id) ON DELETE SET NULL,
  child_id         uuid REFERENCES public.children(id) ON DELETE SET NULL,
  question_count   integer NOT NULL DEFAULT 0,
  started_at       timestamptz NOT NULL DEFAULT now(),
  completed_at     timestamptz,
  is_completed     boolean NOT NULL DEFAULT false,
  created_at       timestamptz NOT NULL DEFAULT now()
);

-- ── quiz_answers ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.quiz_answers (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id     uuid REFERENCES public.quiz_sessions(id) ON DELETE CASCADE,
  question_id    uuid REFERENCES public.questions(id) ON DELETE SET NULL,
  given_answer   text,
  correct_answer text NOT NULL,
  is_correct     boolean NOT NULL DEFAULT false,
  created_at     timestamptz NOT NULL DEFAULT now()
);

-- ── quiz_results ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.quiz_results (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id          uuid REFERENCES public.quiz_sessions(id) ON DELETE CASCADE,
  topic_id            uuid REFERENCES public.topics(id) ON DELETE SET NULL,
  child_id            uuid REFERENCES public.children(id) ON DELETE SET NULL,
  total_questions     integer NOT NULL DEFAULT 0,
  correct_count       integer NOT NULL DEFAULT 0,
  wrong_count         integer NOT NULL DEFAULT 0,
  skipped_count       integer NOT NULL DEFAULT 0,
  percentage          numeric(5,2) NOT NULL DEFAULT 0,
  time_taken_seconds  integer NOT NULL DEFAULT 0,
  completed_at        timestamptz NOT NULL DEFAULT now(),
  created_at          timestamptz NOT NULL DEFAULT now()
);

-- ── Grants ────────────────────────────────────────────────────────────────
GRANT SELECT, INSERT ON public.quiz_sessions TO anon, authenticated;
GRANT SELECT, INSERT ON public.quiz_answers  TO anon, authenticated;
GRANT SELECT, INSERT ON public.quiz_results  TO anon, authenticated;

-- ── RLS ──────────────────────────────────────────────────────────────────
ALTER TABLE public.quiz_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_answers  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_results  ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow insert quiz_sessions" ON public.quiz_sessions
  FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Allow select quiz_sessions" ON public.quiz_sessions
  FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "Allow insert quiz_answers" ON public.quiz_answers
  FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Allow select quiz_answers" ON public.quiz_answers
  FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "Allow insert quiz_results" ON public.quiz_results
  FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Allow select quiz_results" ON public.quiz_results
  FOR SELECT TO anon, authenticated USING (true);

-- ── RLS for anon on catalog (student session uses anon key, no JWT) ───────
CREATE POLICY "Anon read active subjects" ON public.subjects
  FOR SELECT TO anon USING (is_active = true);
CREATE POLICY "Anon read active chapters" ON public.chapters
  FOR SELECT TO anon USING (is_active = true);
CREATE POLICY "Anon read active topics" ON public.topics
  FOR SELECT TO anon USING (is_active = true);
CREATE POLICY "Anon read active questions" ON public.questions
  FOR SELECT TO anon USING (is_active = true);
CREATE POLICY "Anon read active years" ON public.years
  FOR SELECT TO anon USING (is_active = true);
