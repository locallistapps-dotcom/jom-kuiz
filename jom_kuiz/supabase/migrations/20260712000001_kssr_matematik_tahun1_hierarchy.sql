-- ═══════════════════════════════════════════════════════════════════════════
-- Migration: KSSR Matematik Tahun 1 — full chapter & topic hierarchy
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Populates the complete KSSR (Kurikulum Standard Sekolah Rendah) 2017
-- Mathematics Year 1 chapter and topic hierarchy for:
--   Subject : Matematik  (a0000000-0000-0000-0000-000000000001)
--   Year    : Tahun 1    (a0000000-0000-0000-0000-000000000002)
--
-- Rules:
--   • If a Chapter already exists (matched by subject_id + year_id + chapter_name)
--     → UPDATE description and display_order only; UUID is never changed.
--   • If a Chapter does not exist → INSERT with a new gen_random_uuid().
--   • Same idempotent logic for Topics (matched by chapter_id + topic_name).
--   • Existing questions continue pointing to their topic_id; no data loss.
--
-- Safe to re-run; all operations use existence checks.
-- ═══════════════════════════════════════════════════════════════════════════

DO $$
DECLARE
  v_math_id  uuid := 'a0000000-0000-0000-0000-000000000001'; -- Matematik
  v_yr1_id   uuid := 'a0000000-0000-0000-0000-000000000002'; -- Tahun 1

  -- Chapter UUIDs (existing or newly created)
  v_ch_nombor   uuid := 'a0000000-0000-0000-0000-000000000003'; -- already exists
  v_ch_masa     uuid;
  v_ch_panjang  uuid;
  v_ch_jisim    uuid;
  v_ch_isipadu  uuid;
  v_ch_ruang    uuid;
  v_ch_wang     uuid;
  v_ch_data     uuid;

  -- Topic UUIDs (existing or newly created)
  v_tp_tambah   uuid := 'a0000000-0000-0000-0000-000000000004'; -- already exists

BEGIN

  -- ── Chapter 1 : Nombor Bulat hingga 100 ────────────────────────────────────
  -- Already exists; update description and display_order to canonical values.
  UPDATE public.chapters
     SET chapter_name  = 'Nombor Bulat hingga 100',
         description   = 'Bab Nombor Bulat hingga 100 - KSSR Matematik Tahun 1',
         display_order = 1
   WHERE id = v_ch_nombor;

  -- Topics under Nombor
  -- 1a. Nilai Nombor 0 hingga 10
  IF NOT EXISTS (
    SELECT 1 FROM public.topics
    WHERE chapter_id = v_ch_nombor AND topic_name = 'Nilai Nombor 0 hingga 10'
  ) THEN
    INSERT INTO public.topics (chapter_id, topic_name, description, display_order, is_active)
    VALUES (v_ch_nombor, 'Nilai Nombor 0 hingga 10',
            'Membaca, menulis dan mengenal nilai nombor 0 hingga 10', 1, true);
  ELSE
    UPDATE public.topics SET display_order = 1
    WHERE chapter_id = v_ch_nombor AND topic_name = 'Nilai Nombor 0 hingga 10';
  END IF;

  -- 1b. Nilai Nombor 11 hingga 20
  IF NOT EXISTS (
    SELECT 1 FROM public.topics
    WHERE chapter_id = v_ch_nombor AND topic_name = 'Nilai Nombor 11 hingga 20'
  ) THEN
    INSERT INTO public.topics (chapter_id, topic_name, description, display_order, is_active)
    VALUES (v_ch_nombor, 'Nilai Nombor 11 hingga 20',
            'Membaca, menulis dan mengenal nilai nombor 11 hingga 20', 2, true);
  ELSE
    UPDATE public.topics SET display_order = 2
    WHERE chapter_id = v_ch_nombor AND topic_name = 'Nilai Nombor 11 hingga 20';
  END IF;

  -- 1c. Nilai Nombor 21 hingga 100
  IF NOT EXISTS (
    SELECT 1 FROM public.topics
    WHERE chapter_id = v_ch_nombor AND topic_name = 'Nilai Nombor 21 hingga 100'
  ) THEN
    INSERT INTO public.topics (chapter_id, topic_name, description, display_order, is_active)
    VALUES (v_ch_nombor, 'Nilai Nombor 21 hingga 100',
            'Membaca, menulis dan mengenal nilai nombor 21 hingga 100', 3, true);
  ELSE
    UPDATE public.topics SET display_order = 3
    WHERE chapter_id = v_ch_nombor AND topic_name = 'Nilai Nombor 21 hingga 100';
  END IF;

  -- 1d. Tambah (existing topic — update display_order only, preserve UUID)
  UPDATE public.topics SET display_order = 4
  WHERE id = v_tp_tambah;

  -- 1e. Tolak
  IF NOT EXISTS (
    SELECT 1 FROM public.topics
    WHERE chapter_id = v_ch_nombor AND topic_name = 'Tolak'
  ) THEN
    INSERT INTO public.topics (chapter_id, topic_name, description, display_order, is_active)
    VALUES (v_ch_nombor, 'Tolak',
            'Operasi Tolak dalam lingkungan 100 - KSSR Matematik Tahun 1', 5, true);
  ELSE
    UPDATE public.topics SET display_order = 5
    WHERE chapter_id = v_ch_nombor AND topic_name = 'Tolak';
  END IF;

  -- 1f. Gabungan Tambah dan Tolak
  IF NOT EXISTS (
    SELECT 1 FROM public.topics
    WHERE chapter_id = v_ch_nombor AND topic_name = 'Gabungan Tambah dan Tolak'
  ) THEN
    INSERT INTO public.topics (chapter_id, topic_name, description, display_order, is_active)
    VALUES (v_ch_nombor, 'Gabungan Tambah dan Tolak',
            'Gabungan operasi tambah dan tolak - KSSR Matematik Tahun 1', 6, true);
  ELSE
    UPDATE public.topics SET display_order = 6
    WHERE chapter_id = v_ch_nombor AND topic_name = 'Gabungan Tambah dan Tolak';
  END IF;

  -- ── Chapter 2 : Masa ───────────────────────────────────────────────────────
  SELECT id INTO v_ch_masa
  FROM public.chapters
  WHERE subject_id = v_math_id AND year_id = v_yr1_id AND chapter_name = 'Masa';

  IF v_ch_masa IS NULL THEN
    v_ch_masa := gen_random_uuid();
    INSERT INTO public.chapters (id, subject_id, year_id, chapter_name, description, display_order, is_active)
    VALUES (v_ch_masa, v_math_id, v_yr1_id, 'Masa',
            'Bab Masa - KSSR Matematik Tahun 1', 2, true);
  ELSE
    UPDATE public.chapters SET display_order = 2
    WHERE id = v_ch_masa;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.topics WHERE chapter_id = v_ch_masa AND topic_name = 'Membaca Jam') THEN
    INSERT INTO public.topics (chapter_id, topic_name, description, display_order, is_active)
    VALUES (v_ch_masa, 'Membaca Jam', 'Membaca masa menggunakan jam', 1, true);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.topics WHERE chapter_id = v_ch_masa AND topic_name = 'Waktu dalam Sehari') THEN
    INSERT INTO public.topics (chapter_id, topic_name, description, display_order, is_active)
    VALUES (v_ch_masa, 'Waktu dalam Sehari', 'Pagi, tengahari, petang dan malam', 2, true);
  END IF;

  -- ── Chapter 3 : Panjang ────────────────────────────────────────────────────
  SELECT id INTO v_ch_panjang
  FROM public.chapters
  WHERE subject_id = v_math_id AND year_id = v_yr1_id AND chapter_name = 'Panjang';

  IF v_ch_panjang IS NULL THEN
    v_ch_panjang := gen_random_uuid();
    INSERT INTO public.chapters (id, subject_id, year_id, chapter_name, description, display_order, is_active)
    VALUES (v_ch_panjang, v_math_id, v_yr1_id, 'Panjang',
            'Bab Panjang - KSSR Matematik Tahun 1', 3, true);
  ELSE
    UPDATE public.chapters SET display_order = 3 WHERE id = v_ch_panjang;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.topics WHERE chapter_id = v_ch_panjang AND topic_name = 'Perbandingan Panjang') THEN
    INSERT INTO public.topics (chapter_id, topic_name, description, display_order, is_active)
    VALUES (v_ch_panjang, 'Perbandingan Panjang', 'Membandingkan panjang objek', 1, true);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.topics WHERE chapter_id = v_ch_panjang AND topic_name = 'Mengukur Panjang') THEN
    INSERT INTO public.topics (chapter_id, topic_name, description, display_order, is_active)
    VALUES (v_ch_panjang, 'Mengukur Panjang', 'Mengukur panjang menggunakan unit bukan piawai', 2, true);
  END IF;

  -- ── Chapter 4 : Jisim ──────────────────────────────────────────────────────
  SELECT id INTO v_ch_jisim
  FROM public.chapters
  WHERE subject_id = v_math_id AND year_id = v_yr1_id AND chapter_name = 'Jisim';

  IF v_ch_jisim IS NULL THEN
    v_ch_jisim := gen_random_uuid();
    INSERT INTO public.chapters (id, subject_id, year_id, chapter_name, description, display_order, is_active)
    VALUES (v_ch_jisim, v_math_id, v_yr1_id, 'Jisim',
            'Bab Jisim - KSSR Matematik Tahun 1', 4, true);
  ELSE
    UPDATE public.chapters SET display_order = 4 WHERE id = v_ch_jisim;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.topics WHERE chapter_id = v_ch_jisim AND topic_name = 'Perbandingan Jisim') THEN
    INSERT INTO public.topics (chapter_id, topic_name, description, display_order, is_active)
    VALUES (v_ch_jisim, 'Perbandingan Jisim', 'Membandingkan jisim objek', 1, true);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.topics WHERE chapter_id = v_ch_jisim AND topic_name = 'Mengukur Jisim') THEN
    INSERT INTO public.topics (chapter_id, topic_name, description, display_order, is_active)
    VALUES (v_ch_jisim, 'Mengukur Jisim', 'Mengukur jisim menggunakan unit bukan piawai', 2, true);
  END IF;

  -- ── Chapter 5 : Isi Padu Cecair ────────────────────────────────────────────
  SELECT id INTO v_ch_isipadu
  FROM public.chapters
  WHERE subject_id = v_math_id AND year_id = v_yr1_id AND chapter_name = 'Isi Padu Cecair';

  IF v_ch_isipadu IS NULL THEN
    v_ch_isipadu := gen_random_uuid();
    INSERT INTO public.chapters (id, subject_id, year_id, chapter_name, description, display_order, is_active)
    VALUES (v_ch_isipadu, v_math_id, v_yr1_id, 'Isi Padu Cecair',
            'Bab Isi Padu Cecair - KSSR Matematik Tahun 1', 5, true);
  ELSE
    UPDATE public.chapters SET display_order = 5 WHERE id = v_ch_isipadu;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.topics WHERE chapter_id = v_ch_isipadu AND topic_name = 'Perbandingan Isi Padu') THEN
    INSERT INTO public.topics (chapter_id, topic_name, description, display_order, is_active)
    VALUES (v_ch_isipadu, 'Perbandingan Isi Padu', 'Membandingkan isi padu cecair', 1, true);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.topics WHERE chapter_id = v_ch_isipadu AND topic_name = 'Mengukur Isi Padu') THEN
    INSERT INTO public.topics (chapter_id, topic_name, description, display_order, is_active)
    VALUES (v_ch_isipadu, 'Mengukur Isi Padu', 'Mengukur isi padu cecair menggunakan unit bukan piawai', 2, true);
  END IF;

  -- ── Chapter 6 : Bentuk dan Ruang ───────────────────────────────────────────
  SELECT id INTO v_ch_ruang
  FROM public.chapters
  WHERE subject_id = v_math_id AND year_id = v_yr1_id AND chapter_name = 'Bentuk dan Ruang';

  IF v_ch_ruang IS NULL THEN
    v_ch_ruang := gen_random_uuid();
    INSERT INTO public.chapters (id, subject_id, year_id, chapter_name, description, display_order, is_active)
    VALUES (v_ch_ruang, v_math_id, v_yr1_id, 'Bentuk dan Ruang',
            'Bab Bentuk dan Ruang - KSSR Matematik Tahun 1', 6, true);
  ELSE
    UPDATE public.chapters SET display_order = 6 WHERE id = v_ch_ruang;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.topics WHERE chapter_id = v_ch_ruang AND topic_name = 'Bentuk 3 Dimensi') THEN
    INSERT INTO public.topics (chapter_id, topic_name, description, display_order, is_active)
    VALUES (v_ch_ruang, 'Bentuk 3 Dimensi', 'Mengenal bentuk 3D (kiub, kuboid, kon, silinder, sfera)', 1, true);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.topics WHERE chapter_id = v_ch_ruang AND topic_name = 'Bentuk 2 Dimensi') THEN
    INSERT INTO public.topics (chapter_id, topic_name, description, display_order, is_active)
    VALUES (v_ch_ruang, 'Bentuk 2 Dimensi', 'Mengenal bentuk 2D (segiempat, segitiga, bulatan)', 2, true);
  END IF;

  -- ── Chapter 7 : Wang ───────────────────────────────────────────────────────
  SELECT id INTO v_ch_wang
  FROM public.chapters
  WHERE subject_id = v_math_id AND year_id = v_yr1_id AND chapter_name = 'Wang';

  IF v_ch_wang IS NULL THEN
    v_ch_wang := gen_random_uuid();
    INSERT INTO public.chapters (id, subject_id, year_id, chapter_name, description, display_order, is_active)
    VALUES (v_ch_wang, v_math_id, v_yr1_id, 'Wang',
            'Bab Wang - KSSR Matematik Tahun 1', 7, true);
  ELSE
    UPDATE public.chapters SET display_order = 7 WHERE id = v_ch_wang;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.topics WHERE chapter_id = v_ch_wang AND topic_name = 'Mengenal Wang') THEN
    INSERT INTO public.topics (chapter_id, topic_name, description, display_order, is_active)
    VALUES (v_ch_wang, 'Mengenal Wang', 'Mengenal nilai syiling dan not Malaysia', 1, true);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.topics WHERE chapter_id = v_ch_wang AND topic_name = 'Menggunakan Wang') THEN
    INSERT INTO public.topics (chapter_id, topic_name, description, display_order, is_active)
    VALUES (v_ch_wang, 'Menggunakan Wang', 'Operasi tambah dan tolak wang', 2, true);
  END IF;

  -- ── Chapter 8 : Data ───────────────────────────────────────────────────────
  SELECT id INTO v_ch_data
  FROM public.chapters
  WHERE subject_id = v_math_id AND year_id = v_yr1_id AND chapter_name = 'Data';

  IF v_ch_data IS NULL THEN
    v_ch_data := gen_random_uuid();
    INSERT INTO public.chapters (id, subject_id, year_id, chapter_name, description, display_order, is_active)
    VALUES (v_ch_data, v_math_id, v_yr1_id, 'Data',
            'Bab Data - KSSR Matematik Tahun 1', 8, true);
  ELSE
    UPDATE public.chapters SET display_order = 8 WHERE id = v_ch_data;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.topics WHERE chapter_id = v_ch_data AND topic_name = 'Mengumpul dan Merekod Data') THEN
    INSERT INTO public.topics (chapter_id, topic_name, description, display_order, is_active)
    VALUES (v_ch_data, 'Mengumpul dan Merekod Data',
            'Mengumpul, mengelas dan merekod data', 1, true);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.topics WHERE chapter_id = v_ch_data AND topic_name = 'Mewakil Data') THEN
    INSERT INTO public.topics (chapter_id, topic_name, description, display_order, is_active)
    VALUES (v_ch_data, 'Mewakil Data',
            'Mewakil data menggunakan gambarajah blok', 2, true);
  END IF;

END
$$;
