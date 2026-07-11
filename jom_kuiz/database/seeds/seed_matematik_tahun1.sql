-- ============================================================
-- SEED: Matematik Tahun 1 — Bab Nombor, Topik Tambah
-- Kurikulum: KSSR Malaysia
-- Boleh dijalankan berkali-kali (idempoten).
-- ============================================================

-- ── Subject ──────────────────────────────────────────────────
INSERT INTO public.subjects (id, subject_name, description, icon, display_order, is_active)
VALUES (
  'a0000000-0000-0000-0000-000000000001',
  'Matematik',
  'Mata pelajaran Matematik KSSR Malaysia',
  '🔢',
  1,
  true
)
ON CONFLICT (id) DO NOTHING;

-- ── Year ─────────────────────────────────────────────────────
INSERT INTO public.years (id, year_name, display_order, is_active)
VALUES (
  'a0000000-0000-0000-0000-000000000002',
  'Tahun 1',
  1,
  true
)
ON CONFLICT (id) DO NOTHING;

-- ── Chapter ──────────────────────────────────────────────────
INSERT INTO public.chapters (id, subject_id, year_id, chapter_name, description, display_order, is_active)
VALUES (
  'a0000000-0000-0000-0000-000000000003',
  'a0000000-0000-0000-0000-000000000001',
  'a0000000-0000-0000-0000-000000000002',
  'Nombor',
  'Bab Nombor - KSSR Matematik Tahun 1',
  1,
  true
)
ON CONFLICT (id) DO NOTHING;

-- ── Topic ─────────────────────────────────────────────────────
INSERT INTO public.topics (id, chapter_id, topic_name, description, display_order, is_active)
VALUES (
  'a0000000-0000-0000-0000-000000000004',
  'a0000000-0000-0000-0000-000000000003',
  'Tambah',
  'Operasi Tambah - KSSR Matematik Tahun 1',
  1,
  true
)
ON CONFLICT (id) DO NOTHING;

-- ── Questions: MUDAH (40 soalan) ─────────────────────────────
INSERT INTO public.questions
  (id, topic_id, question_text, question_type, difficulty,
   option_a, option_b, option_c, option_d, correct_answer, explanation, is_active)
VALUES
-- Q1-Q25: Tambah terus (nombor 1-10)
('b0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000004','Berapakah 1 + 1?','multiple_choice','easy','3','4','2','5','c','1 + 1 = 2. Kita tambah 1 dengan 1 untuk mendapat 2.',true),
('b0000000-0000-0000-0000-000000000002','a0000000-0000-0000-0000-000000000004','Berapakah 2 + 1?','multiple_choice','easy','2','3','4','5','b','2 + 1 = 3. Kita tambah 2 dengan 1 untuk mendapat 3.',true),
('b0000000-0000-0000-0000-000000000003','a0000000-0000-0000-0000-000000000004','Berapakah 3 + 1?','multiple_choice','easy','4','5','6','3','a','3 + 1 = 4. Kita tambah 3 dengan 1 untuk mendapat 4.',true),
('b0000000-0000-0000-0000-000000000004','a0000000-0000-0000-0000-000000000004','Berapakah 4 + 1?','multiple_choice','easy','3','4','6','5','d','4 + 1 = 5. Kita tambah 4 dengan 1 untuk mendapat 5.',true),
('b0000000-0000-0000-0000-000000000005','a0000000-0000-0000-0000-000000000004','Berapakah 5 + 1?','multiple_choice','easy','5','6','4','7','b','5 + 1 = 6. Kita tambah 5 dengan 1 untuk mendapat 6.',true),
('b0000000-0000-0000-0000-000000000006','a0000000-0000-0000-0000-000000000004','Berapakah 6 + 1?','multiple_choice','easy','7','8','9','6','a','6 + 1 = 7. Kita tambah 6 dengan 1 untuk mendapat 7.',true),
('b0000000-0000-0000-0000-000000000007','a0000000-0000-0000-0000-000000000004','Berapakah 7 + 1?','multiple_choice','easy','6','7','8','9','c','7 + 1 = 8. Kita tambah 7 dengan 1 untuk mendapat 8.',true),
('b0000000-0000-0000-0000-000000000008','a0000000-0000-0000-0000-000000000004','Berapakah 8 + 1?','multiple_choice','easy','7','9','10','8','b','8 + 1 = 9. Kita tambah 8 dengan 1 untuk mendapat 9.',true),
('b0000000-0000-0000-0000-000000000009','a0000000-0000-0000-0000-000000000004','Berapakah 9 + 1?','multiple_choice','easy','8','9','11','10','d','9 + 1 = 10. Kita tambah 9 dengan 1 untuk mendapat 10.',true),
('b0000000-0000-0000-0000-000000000010','a0000000-0000-0000-0000-000000000004','Berapakah 2 + 2?','multiple_choice','easy','3','5','4','6','c','2 + 2 = 4. Kita tambah 2 dengan 2 untuk mendapat 4.',true),
('b0000000-0000-0000-0000-000000000011','a0000000-0000-0000-0000-000000000004','Berapakah 3 + 2?','multiple_choice','easy','5','4','6','7','a','3 + 2 = 5. Kita tambah 3 dengan 2 untuk mendapat 5.',true),
('b0000000-0000-0000-0000-000000000012','a0000000-0000-0000-0000-000000000004','Berapakah 4 + 2?','multiple_choice','easy','5','6','7','8','b','4 + 2 = 6. Kita tambah 4 dengan 2 untuk mendapat 6.',true),
('b0000000-0000-0000-0000-000000000013','a0000000-0000-0000-0000-000000000004','Berapakah 5 + 2?','multiple_choice','easy','5','6','8','7','d','5 + 2 = 7. Kita tambah 5 dengan 2 untuk mendapat 7.',true),
('b0000000-0000-0000-0000-000000000014','a0000000-0000-0000-0000-000000000004','Berapakah 6 + 2?','multiple_choice','easy','8','7','6','9','a','6 + 2 = 8. Kita tambah 6 dengan 2 untuk mendapat 8.',true),
('b0000000-0000-0000-0000-000000000015','a0000000-0000-0000-0000-000000000004','Berapakah 7 + 2?','multiple_choice','easy','7','8','9','10','c','7 + 2 = 9. Kita tambah 7 dengan 2 untuk mendapat 9.',true),
('b0000000-0000-0000-0000-000000000016','a0000000-0000-0000-0000-000000000004','Berapakah 8 + 2?','multiple_choice','easy','9','10','11','12','b','8 + 2 = 10. Kita tambah 8 dengan 2 untuk mendapat 10.',true),
('b0000000-0000-0000-0000-000000000017','a0000000-0000-0000-0000-000000000004','Berapakah 3 + 3?','multiple_choice','easy','5','7','9','6','d','3 + 3 = 6. Kita tambah 3 dengan 3 untuk mendapat 6.',true),
('b0000000-0000-0000-0000-000000000018','a0000000-0000-0000-0000-000000000004','Berapakah 4 + 3?','multiple_choice','easy','7','8','6','9','a','4 + 3 = 7. Kita tambah 4 dengan 3 untuk mendapat 7.',true),
('b0000000-0000-0000-0000-000000000019','a0000000-0000-0000-0000-000000000004','Berapakah 5 + 3?','multiple_choice','easy','6','7','8','9','c','5 + 3 = 8. Kita tambah 5 dengan 3 untuk mendapat 8.',true),
('b0000000-0000-0000-0000-000000000020','a0000000-0000-0000-0000-000000000004','Berapakah 6 + 3?','multiple_choice','easy','8','9','7','10','b','6 + 3 = 9. Kita tambah 6 dengan 3 untuk mendapat 9.',true),
('b0000000-0000-0000-0000-000000000021','a0000000-0000-0000-0000-000000000004','Berapakah 7 + 3?','multiple_choice','easy','10','11','9','8','a','7 + 3 = 10. Kita tambah 7 dengan 3 untuk mendapat 10.',true),
('b0000000-0000-0000-0000-000000000022','a0000000-0000-0000-0000-000000000004','Berapakah 4 + 4?','multiple_choice','easy','6','8','7','9','b','4 + 4 = 8. Kita tambah 4 dengan 4 untuk mendapat 8.',true),
('b0000000-0000-0000-0000-000000000023','a0000000-0000-0000-0000-000000000004','Berapakah 5 + 4?','multiple_choice','easy','7','8','10','9','d','5 + 4 = 9. Kita tambah 5 dengan 4 untuk mendapat 9.',true),
('b0000000-0000-0000-0000-000000000024','a0000000-0000-0000-0000-000000000004','Berapakah 6 + 4?','multiple_choice','easy','8','9','10','11','c','6 + 4 = 10. Kita tambah 6 dengan 4 untuk mendapat 10.',true),
('b0000000-0000-0000-0000-000000000025','a0000000-0000-0000-0000-000000000004','Berapakah 5 + 5?','multiple_choice','easy','10','11','9','8','a','5 + 5 = 10. Kita tambah 5 dengan 5 untuk mendapat 10.',true),
-- Q26-Q40: Soalan cerita mudah
('b0000000-0000-0000-0000-000000000026','a0000000-0000-0000-0000-000000000004','Ali ada 3 biji epal. Ibu beri 2 biji lagi. Berapakah jumlah epal Ali sekarang?','multiple_choice','easy','4','5','6','7','b','3 + 2 = 5. Ali ada 3 biji, ditambah 2 biji lagi, jumlahnya 5 biji epal.',true),
('b0000000-0000-0000-0000-000000000027','a0000000-0000-0000-0000-000000000004','Siti ada 4 biji guli. Raju beri 3 biji lagi. Berapa jumlah guli Siti?','multiple_choice','easy','7','6','8','9','a','4 + 3 = 7. Siti ada 4 biji, ditambah 3 biji, jumlahnya 7 biji.',true),
('b0000000-0000-0000-0000-000000000028','a0000000-0000-0000-0000-000000000004','Terdapat 2 ekor ayam di kandang. Petani tambah 5 ekor lagi. Berapa jumlah ayam?','multiple_choice','easy','5','6','7','8','c','2 + 5 = 7. Jumlah ayam ialah 7 ekor.',true),
('b0000000-0000-0000-0000-000000000029','a0000000-0000-0000-0000-000000000004','Zara ada 1 pen. Dia beli 6 pen lagi. Berapa jumlah pen Zara?','multiple_choice','easy','5','6','8','7','d','1 + 6 = 7. Jumlah pen Zara ialah 7 batang.',true),
('b0000000-0000-0000-0000-000000000030','a0000000-0000-0000-0000-000000000004','Dalam bakul ada 4 oren. Emak letak 4 oren lagi. Berapa jumlah oren dalam bakul?','multiple_choice','easy','6','8','7','9','b','4 + 4 = 8. Jumlah oren dalam bakul ialah 8 biji.',true),
('b0000000-0000-0000-0000-000000000031','a0000000-0000-0000-0000-000000000004','Pak Cik Ali ada 5 ekor itik. Dia beli 3 ekor lagi. Berapa jumlah itik Pak Cik Ali?','multiple_choice','easy','8','7','9','10','a','5 + 3 = 8. Jumlah itik ialah 8 ekor.',true),
('b0000000-0000-0000-0000-000000000032','a0000000-0000-0000-0000-000000000004','Pelajar lelaki ada 3 orang. Pelajar perempuan ada 6 orang. Berapa jumlah pelajar?','multiple_choice','easy','7','8','9','10','c','3 + 6 = 9. Jumlah pelajar ialah 9 orang.',true),
('b0000000-0000-0000-0000-000000000033','a0000000-0000-0000-0000-000000000004','Dalam tin ada 6 biskut. Adik tambah 2 biskut lagi. Berapa jumlah biskut?','multiple_choice','easy','6','7','9','8','d','6 + 2 = 8. Jumlah biskut dalam tin ialah 8 keping.',true),
('b0000000-0000-0000-0000-000000000034','a0000000-0000-0000-0000-000000000004','Azim ada 2 buku cerita. Dia pinjam 7 buku lagi. Berapa jumlah buku Azim?','multiple_choice','easy','7','9','8','10','b','2 + 7 = 9. Jumlah buku cerita Azim ialah 9 buah.',true),
('b0000000-0000-0000-0000-000000000035','a0000000-0000-0000-0000-000000000004','Pokok mangga ada 5. Pokok rambutan ada 5. Berapa jumlah pokok?','multiple_choice','easy','10','9','11','8','a','5 + 5 = 10. Jumlah pokok ialah 10 batang.',true),
('b0000000-0000-0000-0000-000000000036','a0000000-0000-0000-0000-000000000004','Berapakah 0 + 8?','multiple_choice','easy','0','7','8','9','c','0 + 8 = 8. Sebarang nombor ditambah 0 hasilnya nombor itu sendiri.',true),
('b0000000-0000-0000-0000-000000000037','a0000000-0000-0000-0000-000000000004','Berapakah 0 + 10?','multiple_choice','easy','0','9','11','10','d','0 + 10 = 10. Nombor 10 ditambah 0 tetap 10.',true),
('b0000000-0000-0000-0000-000000000038','a0000000-0000-0000-0000-000000000004','Berapakah 1 + 9?','multiple_choice','easy','9','10','11','8','b','1 + 9 = 10. Kita tambah 1 dengan 9 untuk mendapat 10.',true),
('b0000000-0000-0000-0000-000000000039','a0000000-0000-0000-0000-000000000004','Berapakah 2 + 8?','multiple_choice','easy','10','9','11','6','a','2 + 8 = 10. Kita tambah 2 dengan 8 untuk mendapat 10.',true),
('b0000000-0000-0000-0000-000000000040','a0000000-0000-0000-0000-000000000004','Berapakah 3 + 7?','multiple_choice','easy','9','11','10','8','c','3 + 7 = 10. Kita tambah 3 dengan 7 untuk mendapat 10.',true)
ON CONFLICT (id) DO NOTHING;

-- ── Questions: SEDERHANA (40 soalan) ─────────────────────────
INSERT INTO public.questions
  (id, topic_id, question_text, question_type, difficulty,
   option_a, option_b, option_c, option_d, correct_answer, explanation, is_active)
VALUES
-- Q41-Q60: Tambah terus (nombor 11-20)
('b0000000-0000-0000-0000-000000000041','a0000000-0000-0000-0000-000000000004','Berapakah 9 + 2?','multiple_choice','medium','10','11','12','13','b','9 + 2 = 11. Kita tambah 9 dengan 2 dan jawapannya ialah 11.',true),
('b0000000-0000-0000-0000-000000000042','a0000000-0000-0000-0000-000000000004','Berapakah 9 + 3?','multiple_choice','medium','12','13','11','10','a','9 + 3 = 12. Kita tambah 9 dengan 3 dan jawapannya ialah 12.',true),
('b0000000-0000-0000-0000-000000000043','a0000000-0000-0000-0000-000000000004','Berapakah 9 + 4?','multiple_choice','medium','11','12','13','14','c','9 + 4 = 13. Kita tambah 9 dengan 4 dan jawapannya ialah 13.',true),
('b0000000-0000-0000-0000-000000000044','a0000000-0000-0000-0000-000000000004','Berapakah 9 + 5?','multiple_choice','medium','12','13','15','14','d','9 + 5 = 14. Kita tambah 9 dengan 5 dan jawapannya ialah 14.',true),
('b0000000-0000-0000-0000-000000000045','a0000000-0000-0000-0000-000000000004','Berapakah 9 + 6?','multiple_choice','medium','14','15','13','16','b','9 + 6 = 15. Kita tambah 9 dengan 6 dan jawapannya ialah 15.',true),
('b0000000-0000-0000-0000-000000000046','a0000000-0000-0000-0000-000000000004','Berapakah 9 + 7?','multiple_choice','medium','16','17','15','14','a','9 + 7 = 16. Kita tambah 9 dengan 7 dan jawapannya ialah 16.',true),
('b0000000-0000-0000-0000-000000000047','a0000000-0000-0000-0000-000000000004','Berapakah 9 + 8?','multiple_choice','medium','15','16','17','18','c','9 + 8 = 17. Kita tambah 9 dengan 8 dan jawapannya ialah 17.',true),
('b0000000-0000-0000-0000-000000000048','a0000000-0000-0000-0000-000000000004','Berapakah 9 + 9?','multiple_choice','medium','16','17','19','18','d','9 + 9 = 18. Kita tambah 9 dengan 9 dan jawapannya ialah 18.',true),
('b0000000-0000-0000-0000-000000000049','a0000000-0000-0000-0000-000000000004','Berapakah 8 + 3?','multiple_choice','medium','10','11','12','9','b','8 + 3 = 11. Kita tambah 8 dengan 3 dan jawapannya ialah 11.',true),
('b0000000-0000-0000-0000-000000000050','a0000000-0000-0000-0000-000000000004','Berapakah 8 + 4?','multiple_choice','medium','10','11','12','13','c','8 + 4 = 12. Kita tambah 8 dengan 4 dan jawapannya ialah 12.',true),
('b0000000-0000-0000-0000-000000000051','a0000000-0000-0000-0000-000000000004','Berapakah 8 + 5?','multiple_choice','medium','13','14','12','11','a','8 + 5 = 13. Kita tambah 8 dengan 5 dan jawapannya ialah 13.',true),
('b0000000-0000-0000-0000-000000000052','a0000000-0000-0000-0000-000000000004','Berapakah 8 + 6?','multiple_choice','medium','12','13','15','14','d','8 + 6 = 14. Kita tambah 8 dengan 6 dan jawapannya ialah 14.',true),
('b0000000-0000-0000-0000-000000000053','a0000000-0000-0000-0000-000000000004','Berapakah 8 + 7?','multiple_choice','medium','14','15','13','16','b','8 + 7 = 15. Kita tambah 8 dengan 7 dan jawapannya ialah 15.',true),
('b0000000-0000-0000-0000-000000000054','a0000000-0000-0000-0000-000000000004','Berapakah 8 + 8?','multiple_choice','medium','16','17','15','14','a','8 + 8 = 16. Kita tambah 8 dengan 8 dan jawapannya ialah 16.',true),
('b0000000-0000-0000-0000-000000000055','a0000000-0000-0000-0000-000000000004','Berapakah 7 + 4?','multiple_choice','medium','10','12','11','9','c','7 + 4 = 11. Kita tambah 7 dengan 4 dan jawapannya ialah 11.',true),
('b0000000-0000-0000-0000-000000000056','a0000000-0000-0000-0000-000000000004','Berapakah 7 + 5?','multiple_choice','medium','11','13','10','12','d','7 + 5 = 12. Kita tambah 7 dengan 5 dan jawapannya ialah 12.',true),
('b0000000-0000-0000-0000-000000000057','a0000000-0000-0000-0000-000000000004','Berapakah 7 + 6?','multiple_choice','medium','12','14','11','13','b','7 + 6 = 13. Kita tambah 7 dengan 6 dan jawapannya ialah 13.',true),
('b0000000-0000-0000-0000-000000000058','a0000000-0000-0000-0000-000000000004','Berapakah 7 + 7?','multiple_choice','medium','14','15','13','12','a','7 + 7 = 14. Kita tambah 7 dengan 7 dan jawapannya ialah 14.',true),
('b0000000-0000-0000-0000-000000000059','a0000000-0000-0000-0000-000000000004','Berapakah 6 + 5?','multiple_choice','medium','10','12','11','9','c','6 + 5 = 11. Kita tambah 6 dengan 5 dan jawapannya ialah 11.',true),
('b0000000-0000-0000-0000-000000000060','a0000000-0000-0000-0000-000000000004','Berapakah 6 + 6?','multiple_choice','medium','11','13','14','12','d','6 + 6 = 12. Kita tambah 6 dengan 6 dan jawapannya ialah 12.',true),
-- Q61-Q80: Soalan cerita sederhana
('b0000000-0000-0000-0000-000000000061','a0000000-0000-0000-0000-000000000004','Perpustakaan mempunyai 8 buku Bahasa Melayu dan 5 buku Matematik. Berapa jumlah buku?','multiple_choice','medium','12','13','14','11','b','8 + 5 = 13. Jumlah buku ialah 13 buah.',true),
('b0000000-0000-0000-0000-000000000062','a0000000-0000-0000-0000-000000000004','Puan Nora ada 9 murid lelaki dan 6 murid perempuan dalam kelas. Berapa jumlah murid?','multiple_choice','medium','15','14','16','13','a','9 + 6 = 15. Jumlah murid dalam kelas ialah 15 orang.',true),
('b0000000-0000-0000-0000-000000000063','a0000000-0000-0000-0000-000000000004','Amin kumpul 7 setem pada hari Isnin dan 8 setem pada hari Selasa. Berapa jumlah setem?','multiple_choice','medium','14','13','15','16','c','7 + 8 = 15. Jumlah setem yang dikumpul ialah 15 keping.',true),
('b0000000-0000-0000-0000-000000000064','a0000000-0000-0000-0000-000000000004','Dalam beg ada 6 biji oren dan 7 biji limau. Berapa jumlah buah-buahan?','multiple_choice','medium','12','11','14','13','d','6 + 7 = 13. Jumlah buah-buahan ialah 13 biji.',true),
('b0000000-0000-0000-0000-000000000065','a0000000-0000-0000-0000-000000000004','Kelas 1 Bestari ada 8 orang murid hadir pagi. 8 orang lagi hadir petang. Berapa jumlah murid?','multiple_choice','medium','15','16','17','14','b','8 + 8 = 16. Jumlah murid yang hadir ialah 16 orang.',true),
('b0000000-0000-0000-0000-000000000066','a0000000-0000-0000-0000-000000000004','Pokok A ada 9 buah. Pokok B ada 8 buah. Berapa jumlah buah?','multiple_choice','medium','17','16','18','15','a','9 + 8 = 17. Jumlah buah ialah 17 biji.',true),
('b0000000-0000-0000-0000-000000000067','a0000000-0000-0000-0000-000000000004','Tasya ada 5 helai baju dan Zara ada 7 helai baju. Berapa jumlah baju mereka?','multiple_choice','medium','10','11','12','13','c','5 + 7 = 12. Jumlah baju Tasya dan Zara ialah 12 helai.',true),
('b0000000-0000-0000-0000-000000000068','a0000000-0000-0000-0000-000000000004','Pak Long ada 6 ekor lembu dan 6 ekor kambing. Berapa jumlah ternakan Pak Long?','multiple_choice','medium','10','11','13','12','d','6 + 6 = 12. Jumlah ternakan Pak Long ialah 12 ekor.',true),
('b0000000-0000-0000-0000-000000000069','a0000000-0000-0000-0000-000000000004','Encik Kamal simpan 7 biji telur pagi dan 5 biji telur petang. Berapa jumlah telur?','multiple_choice','medium','11','12','13','10','b','7 + 5 = 12. Jumlah telur yang disimpan ialah 12 biji.',true),
('b0000000-0000-0000-0000-000000000070','a0000000-0000-0000-0000-000000000004','Kumpulan A menang 9 mata dan Kumpulan B menang 9 mata. Berapa jumlah mata?','multiple_choice','medium','18','17','19','16','a','9 + 9 = 18. Jumlah mata kedua-dua kumpulan ialah 18 mata.',true),
('b0000000-0000-0000-0000-000000000071','a0000000-0000-0000-0000-000000000004','Berapakah 10 + 5?','multiple_choice','medium','14','16','15','13','c','10 + 5 = 15. Kita tambah 10 dengan 5 untuk mendapat 15.',true),
('b0000000-0000-0000-0000-000000000072','a0000000-0000-0000-0000-000000000004','Berapakah 10 + 8?','multiple_choice','medium','16','17','19','18','d','10 + 8 = 18. Kita tambah 10 dengan 8 untuk mendapat 18.',true),
('b0000000-0000-0000-0000-000000000073','a0000000-0000-0000-0000-000000000004','Berapakah 10 + 9?','multiple_choice','medium','18','19','20','17','b','10 + 9 = 19. Kita tambah 10 dengan 9 untuk mendapat 19.',true),
('b0000000-0000-0000-0000-000000000074','a0000000-0000-0000-0000-000000000004','Berapakah 10 + 10?','multiple_choice','medium','20','19','21','18','a','10 + 10 = 20. Kita tambah 10 dengan 10 untuk mendapat 20.',true),
('b0000000-0000-0000-0000-000000000075','a0000000-0000-0000-0000-000000000004','Berapakah 11 + 4?','multiple_choice','medium','14','16','15','13','c','11 + 4 = 15. Kita tambah 11 dengan 4 untuk mendapat 15.',true),
('b0000000-0000-0000-0000-000000000076','a0000000-0000-0000-0000-000000000004','Berapakah 12 + 5?','multiple_choice','medium','16','15','18','17','d','12 + 5 = 17. Kita tambah 12 dengan 5 untuk mendapat 17.',true),
('b0000000-0000-0000-0000-000000000077','a0000000-0000-0000-0000-000000000004','Berapakah 13 + 4?','multiple_choice','medium','16','17','18','15','b','13 + 4 = 17. Kita tambah 13 dengan 4 untuk mendapat 17.',true),
('b0000000-0000-0000-0000-000000000078','a0000000-0000-0000-0000-000000000004','Berapakah 14 + 5?','multiple_choice','medium','19','18','20','17','a','14 + 5 = 19. Kita tambah 14 dengan 5 untuk mendapat 19.',true),
('b0000000-0000-0000-0000-000000000079','a0000000-0000-0000-0000-000000000004','Berapakah 11 + 7?','multiple_choice','medium','17','16','18','19','c','11 + 7 = 18. Kita tambah 11 dengan 7 untuk mendapat 18.',true),
('b0000000-0000-0000-0000-000000000080','a0000000-0000-0000-0000-000000000004','Berapakah 13 + 6?','multiple_choice','medium','18','17','20','19','d','13 + 6 = 19. Kita tambah 13 dengan 6 untuk mendapat 19.',true)
ON CONFLICT (id) DO NOTHING;

-- ── Questions: SUKAR (20 soalan) ─────────────────────────────
INSERT INTO public.questions
  (id, topic_id, question_text, question_type, difficulty,
   option_a, option_b, option_c, option_d, correct_answer, explanation, is_active)
VALUES
('b0000000-0000-0000-0000-000000000081','a0000000-0000-0000-0000-000000000004','Berapakah 25 + 13?','multiple_choice','hard','37','38','39','36','b','25 + 13 = 38. Tambah puluh: 20+10=30, tambah sa: 5+3=8, jadi 38.',true),
('b0000000-0000-0000-0000-000000000082','a0000000-0000-0000-0000-000000000004','Berapakah 34 + 21?','multiple_choice','hard','55','54','56','53','a','34 + 21 = 55. Tambah puluh: 30+20=50, tambah sa: 4+1=5, jadi 55.',true),
('b0000000-0000-0000-0000-000000000083','a0000000-0000-0000-0000-000000000004','Berapakah 42 + 35?','multiple_choice','hard','76','78','77','75','c','42 + 35 = 77. Tambah puluh: 40+30=70, tambah sa: 2+5=7, jadi 77.',true),
('b0000000-0000-0000-0000-000000000084','a0000000-0000-0000-0000-000000000004','Berapakah 51 + 26?','multiple_choice','hard','76','75','78','77','d','51 + 26 = 77. Tambah puluh: 50+20=70, tambah sa: 1+6=7, jadi 77.',true),
('b0000000-0000-0000-0000-000000000085','a0000000-0000-0000-0000-000000000004','Berapakah 63 + 14?','multiple_choice','hard','76','77','78','75','b','63 + 14 = 77. Tambah puluh: 60+10=70, tambah sa: 3+4=7, jadi 77.',true),
('b0000000-0000-0000-0000-000000000086','a0000000-0000-0000-0000-000000000004','Kedai ada 45 biji oren dan 32 biji epal. Berapa jumlah buah-buahan?','multiple_choice','hard','77','76','78','75','a','45 + 32 = 77. Jumlah buah-buahan ialah 77 biji.',true),
('b0000000-0000-0000-0000-000000000087','a0000000-0000-0000-0000-000000000004','Berapakah 28 + 19?','multiple_choice','hard','46','48','47','45','c','28 + 19 = 47. Tambah: 28 + 19 = 47.',true),
('b0000000-0000-0000-0000-000000000088','a0000000-0000-0000-0000-000000000004','Berapakah 36 + 27?','multiple_choice','hard','62','64','61','63','d','36 + 27 = 63. Tambah: 36 + 27 = 63.',true),
('b0000000-0000-0000-0000-000000000089','a0000000-0000-0000-0000-000000000004','Sekolah A ada 48 murid lelaki dan 39 murid perempuan. Berapa jumlah murid?','multiple_choice','hard','86','87','88','85','b','48 + 39 = 87. Jumlah murid sekolah ialah 87 orang.',true),
('b0000000-0000-0000-0000-000000000090','a0000000-0000-0000-0000-000000000004','Berapakah 53 + 28?','multiple_choice','hard','81','80','82','79','a','53 + 28 = 81. Tambah sa: 3+8=11, tulis 1 simpan 1. Tambah puluh: 5+2+1=8. Jawapan: 81.',true),
('b0000000-0000-0000-0000-000000000091','a0000000-0000-0000-0000-000000000004','Berapakah 47 + 36?','multiple_choice','hard','82','84','83','81','c','47 + 36 = 83. Tambah sa: 7+6=13, tulis 3 simpan 1. Tambah puluh: 4+3+1=8. Jawapan: 83.',true),
('b0000000-0000-0000-0000-000000000092','a0000000-0000-0000-0000-000000000004','Berapakah 65 + 28?','multiple_choice','hard','92','94','91','93','d','65 + 28 = 93. Tambah sa: 5+8=13, tulis 3 simpan 1. Tambah puluh: 6+2+1=9. Jawapan: 93.',true),
('b0000000-0000-0000-0000-000000000093','a0000000-0000-0000-0000-000000000004','Ladang pak cik ada 56 pokok pisang dan 34 pokok kelapa. Berapa jumlah pokok?','multiple_choice','hard','89','90','91','88','b','56 + 34 = 90. Jumlah pokok dalam ladang ialah 90 batang.',true),
('b0000000-0000-0000-0000-000000000094','a0000000-0000-0000-0000-000000000004','Berapakah 29 + 29?','multiple_choice','hard','58','57','59','56','a','29 + 29 = 58. Tambah sa: 9+9=18, tulis 8 simpan 1. Tambah puluh: 2+2+1=5. Jawapan: 58.',true),
('b0000000-0000-0000-0000-000000000095','a0000000-0000-0000-0000-000000000004','Berapakah 38 + 48?','multiple_choice','hard','85','87','86','84','c','38 + 48 = 86. Tambah sa: 8+8=16, tulis 6 simpan 1. Tambah puluh: 3+4+1=8. Jawapan: 86.',true),
('b0000000-0000-0000-0000-000000000096','a0000000-0000-0000-0000-000000000004','Berapakah 17 + 68?','multiple_choice','hard','84','86','83','85','d','17 + 68 = 85. Tambah sa: 7+8=15, tulis 5 simpan 1. Tambah puluh: 1+6+1=8. Jawapan: 85.',true),
('b0000000-0000-0000-0000-000000000097','a0000000-0000-0000-0000-000000000004','Berapakah 46 + 46?','multiple_choice','hard','91','92','93','90','b','46 + 46 = 92. Tambah sa: 6+6=12, tulis 2 simpan 1. Tambah puluh: 4+4+1=9. Jawapan: 92.',true),
('b0000000-0000-0000-0000-000000000098','a0000000-0000-0000-0000-000000000004','Berapakah 57 + 37?','multiple_choice','hard','94','93','95','92','a','57 + 37 = 94. Tambah sa: 7+7=14, tulis 4 simpan 1. Tambah puluh: 5+3+1=9. Jawapan: 94.',true),
('b0000000-0000-0000-0000-000000000099','a0000000-0000-0000-0000-000000000004','Kampung A ada 68 orang penduduk dan kampung B ada 27 orang penduduk. Berapa jumlah penduduk?','multiple_choice','hard','94','96','95','93','c','68 + 27 = 95. Jumlah penduduk kedua-dua kampung ialah 95 orang.',true),
('b0000000-0000-0000-0000-000000000100','a0000000-0000-0000-0000-000000000004','Berapakah 49 + 49?','multiple_choice','hard','97','99','96','98','d','49 + 49 = 98. Tambah sa: 9+9=18, tulis 8 simpan 1. Tambah puluh: 4+4+1=9. Jawapan: 98.',true)
ON CONFLICT (id) DO NOTHING;
