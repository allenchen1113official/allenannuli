-- =============================================
-- 陳艾倫個人大事紀 資料庫結構
-- 請至 Supabase SQL Editor 執行此檔案
-- =============================================

-- 分類表
CREATE TABLE IF NOT EXISTS categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  color TEXT NOT NULL DEFAULT '#4A90E2',
  icon TEXT DEFAULT '📌',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 大事紀表
CREATE TABLE IF NOT EXISTS events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  year INTEGER NOT NULL,
  month INTEGER,
  title TEXT NOT NULL,
  summary TEXT NOT NULL,
  detail TEXT,
  image_url TEXT,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 大事紀分類關聯表
CREATE TABLE IF NOT EXISTS event_categories (
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
  PRIMARY KEY (event_id, category_id)
);

-- 預設分類資料
INSERT INTO categories (name, color, icon) VALUES
  ('職涯', '#2563EB', '💼'),
  ('學習', '#7C3AED', '📚'),
  ('親情', '#DC2626', '❤️'),
  ('友情', '#D97706', '🤝'),
  ('愛情', '#DB2777', '💕'),
  ('運動', '#16A34A', '🏃'),
  ('音樂', '#0891B2', '🎵'),
  ('旅遊', '#EA580C', '✈️'),
  ('健康', '#65A30D', '🏥'),
  ('其他', '#6B7280', '📌')
ON CONFLICT (name) DO NOTHING;

-- 更新時間觸發器
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_events_updated_at ON events;
CREATE TRIGGER update_events_updated_at
  BEFORE UPDATE ON events
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- RLS 政策（允許匿名讀取，授權後才能寫入）
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_categories ENABLE ROW LEVEL SECURITY;

-- 允許所有人讀取
CREATE POLICY "Allow public read categories" ON categories FOR SELECT USING (true);
CREATE POLICY "Allow public read events" ON events FOR SELECT USING (true);
CREATE POLICY "Allow public read event_categories" ON event_categories FOR SELECT USING (true);

-- 允許所有人寫入（後台管理用，若需要驗證可改為 auth.role() = 'authenticated'）
CREATE POLICY "Allow all write categories" ON categories FOR ALL USING (true);
CREATE POLICY "Allow all write events" ON events FOR ALL USING (true);
CREATE POLICY "Allow all write event_categories" ON event_categories FOR ALL USING (true);
