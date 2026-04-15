-- =============================================
-- 遷移腳本：請在 Supabase SQL Editor 執行
-- 安全：全部使用 IF NOT EXISTS / IF EXISTS
-- =============================================

-- 1. 為既有資料表加入 user_id 欄位（若尚未有）
ALTER TABLE categories   ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE events       ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- 2. 建立 stats 統計表（若尚未建立）
CREATE TABLE IF NOT EXISTS stats (
  id         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id    UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  label      TEXT NOT NULL,
  number     INTEGER NOT NULL DEFAULT 0,
  unit       TEXT,
  color      TEXT DEFAULT '#f97316',
  visible    BOOLEAN DEFAULT TRUE,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. 啟用 RLS
ALTER TABLE categories   ENABLE ROW LEVEL SECURITY;
ALTER TABLE events       ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE stats        ENABLE ROW LEVEL SECURITY;

-- 4. 移除所有舊政策（冪等：不存在也不會報錯）
DROP POLICY IF EXISTS "Allow public read categories"       ON categories;
DROP POLICY IF EXISTS "Allow public read events"           ON events;
DROP POLICY IF EXISTS "Allow public read event_categories" ON event_categories;
DROP POLICY IF EXISTS "Allow all write categories"         ON categories;
DROP POLICY IF EXISTS "Allow all write events"             ON events;
DROP POLICY IF EXISTS "Allow all write event_categories"   ON event_categories;
DROP POLICY IF EXISTS "Users manage own categories"        ON categories;
DROP POLICY IF EXISTS "Users manage own events"            ON events;
DROP POLICY IF EXISTS "Users manage own event_categories"  ON event_categories;
DROP POLICY IF EXISTS "Users manage own stats"             ON stats;
DROP POLICY IF EXISTS "Public read events"                 ON events;
DROP POLICY IF EXISTS "Public read categories"             ON categories;
DROP POLICY IF EXISTS "Public read event_categories"       ON event_categories;
DROP POLICY IF EXISTS "Public read stats"                  ON stats;
DROP POLICY IF EXISTS "Users insert own events"            ON events;
DROP POLICY IF EXISTS "Users update own events"            ON events;
DROP POLICY IF EXISTS "Users delete own events"            ON events;
DROP POLICY IF EXISTS "Users insert own categories"        ON categories;
DROP POLICY IF EXISTS "Users update own categories"        ON categories;
DROP POLICY IF EXISTS "Users delete own categories"        ON categories;
DROP POLICY IF EXISTS "Users write own event_categories"   ON event_categories;
DROP POLICY IF EXISTS "Users insert own stats"             ON stats;
DROP POLICY IF EXISTS "Users update own stats"             ON stats;
DROP POLICY IF EXISTS "Users delete own stats"             ON stats;

-- 5. 公開讀取（首頁不需登入即可瀏覽）
CREATE POLICY "Public read events"           ON events           FOR SELECT USING (true);
CREATE POLICY "Public read categories"       ON categories       FOR SELECT USING (true);
CREATE POLICY "Public read event_categories" ON event_categories FOR SELECT USING (true);
CREATE POLICY "Public read stats"            ON stats            FOR SELECT USING (true);

-- 6. 需登入才能寫入（只能操作自己的資料）
CREATE POLICY "Users insert own events"    ON events FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users update own events"    ON events FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users delete own events"    ON events FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users insert own categories" ON categories FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users update own categories" ON categories FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users delete own categories" ON categories FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users write own event_categories" ON event_categories
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM events
      WHERE events.id = event_categories.event_id
        AND events.user_id = auth.uid()
    )
  );

CREATE POLICY "Users insert own stats" ON stats FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users update own stats" ON stats FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users delete own stats" ON stats FOR DELETE USING (auth.uid() = user_id);

-- =============================================
-- 完成！若有舊資料需指定擁有者，請執行：
-- UPDATE events      SET user_id = auth.uid() WHERE user_id IS NULL;
-- UPDATE categories  SET user_id = auth.uid() WHERE user_id IS NULL;
-- （需在登入後的 RLS 環境下執行，或直接填入你的 UUID）
-- =============================================

-- Add visibility control columns to events
ALTER TABLE events ADD COLUMN IF NOT EXISTS show_on_homepage BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE events ADD COLUMN IF NOT EXISTS show_on_rings BOOLEAN NOT NULL DEFAULT true;
