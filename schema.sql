-- 1. Create table Rooms
CREATE TABLE rooms (
  id text PRIMARY KEY,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Create table Members (saves the last known position)
CREATE TABLE members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id text REFERENCES rooms(id) ON DELETE CASCADE,
  nickname text NOT NULL,
  avatar_url text NOT NULL,
  lat double precision,
  lng double precision,
  last_updated timestamp with time zone DEFAULT timezone('utc'::text, now())
);

-- 3. Create table Messages (for Live Feed / Chat)
CREATE TABLE messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id text REFERENCES rooms(id) ON DELETE CASCADE,
  member_id uuid REFERENCES members(id) ON DELETE CASCADE,
  content text NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. Enable Realtime for members and messages
ALTER PUBLICATION supabase_realtime ADD TABLE members;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;

-- 5. Enable Row Level Security (RLS) but allow anonymous access (MVP Mode)
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE members ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anon everything on rooms" ON rooms FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon everything on members" ON members FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon everything on messages" ON messages FOR ALL USING (true) WITH CHECK (true);
