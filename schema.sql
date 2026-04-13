-- =============================================
-- 陳艾倫個人大事紀 資料庫結構
-- 請至 Supabase SQL Editor 執行此檔案
-- =============================================

-- 分類表（加入 user_id 支援多用戶）
CREATE TABLE IF NOT EXISTS categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  color TEXT NOT NULL DEFAULT '#1d7fe5',
  icon TEXT DEFAULT '📌',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 大事紀表（加入 user_id 支援多用戶）
CREATE TABLE IF NOT EXISTS events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  year INTEGER NOT NULL,
  month INTEGER,
  day INTEGER CHECK (day >= 1 AND day <= 31),
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

-- 數字統計表（首頁圓形數字）
CREATE TABLE IF NOT EXISTS stats (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  number INTEGER NOT NULL DEFAULT 0,
  unit TEXT,
  color TEXT DEFAULT '#f97316',
  visible BOOLEAN DEFAULT TRUE,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

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

-- RLS 政策（每個使用者只能存取自己的資料）
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE stats ENABLE ROW LEVEL SECURITY;

-- 先移除舊政策（若存在）
DROP POLICY IF EXISTS "Allow public read categories" ON categories;
DROP POLICY IF EXISTS "Allow public read events" ON events;
DROP POLICY IF EXISTS "Allow public read event_categories" ON event_categories;
DROP POLICY IF EXISTS "Allow all write categories" ON categories;
DROP POLICY IF EXISTS "Allow all write events" ON events;
DROP POLICY IF EXISTS "Allow all write event_categories" ON event_categories;

-- categories：已登入者只能存取自己的分類
CREATE POLICY "Users manage own categories" ON categories
  FOR ALL USING (auth.uid() = user_id);

-- events：已登入者只能存取自己的大事紀
CREATE POLICY "Users manage own events" ON events
  FOR ALL USING (auth.uid() = user_id);

-- event_categories：透過 event 的 user_id 控制
CREATE POLICY "Users manage own event_categories" ON event_categories
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM events
      WHERE events.id = event_categories.event_id
        AND events.user_id = auth.uid()
    )
  );

-- stats：已登入者只能存取自己的統計
CREATE POLICY "Users manage own stats" ON stats
  FOR ALL USING (auth.uid() = user_id);

-- =============================================
-- 若需要將舊資料（無 user_id）遷移，請手動執行：
-- UPDATE events SET user_id = '<your-user-uuid>' WHERE user_id IS NULL;
-- UPDATE categories SET user_id = '<your-user-uuid>' WHERE user_id IS NULL;
-- =============================================
