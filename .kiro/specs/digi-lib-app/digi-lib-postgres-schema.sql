-- digi-lib-postgres-schema.sql
-- PostgreSQL schema for Digital Library App (canonical)
-- Run this in psql or via a migration tool. Requires PostgreSQL 12+.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  name TEXT,
  provider TEXT,
  provider_id TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS libraries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES users(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  type TEXT CHECK(type IN ('local','gdrive','onedrive','s3')) NOT NULL,
  config JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  library_id UUID REFERENCES libraries(id) ON DELETE CASCADE,
  title TEXT,
  author TEXT,
  filename TEXT,
  relative_path TEXT,
  full_path TEXT,
  extension TEXT,
  renamed_name TEXT,
  isbn TEXT,
  year_published Int4,
  status TEXT,
  cloud_id TEXT,
  sha256 TEXT,
  size_bytes BIGINT,
  page_count INTEGER,
  format TEXT,
  status TEXT,
  image_url TEXT,
  amazon_url TEXT,
  review_url TEXT,
  metadata_json jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  tsv tsvector
);

CREATE TABLE IF NOT EXISTS pages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doc_id UUID REFERENCES documents(id) ON DELETE CASCADE,
  page_number INTEGER NOT NULL,
  text_content TEXT,
  thumbnail_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE (doc_id, page_number)
);

CREATE TABLE IF NOT EXISTS tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES users(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(owner_id, name)
);

CREATE TABLE IF NOT EXISTS document_tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doc_id UUID REFERENCES documents(id) ON DELETE CASCADE,
  tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE (doc_id, tag_id)
);

CREATE TABLE IF NOT EXISTS bookmarks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  doc_id UUID REFERENCES documents(id) ON DELETE CASCADE,
  page_number INTEGER,
  note TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doc_id UUID REFERENCES documents(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  page_number INTEGER,
  anchor JSONB,
  content TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS shares (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_id UUID,
  subject_type TEXT CHECK(subject_type IN ('document','folder')),
  owner_id UUID REFERENCES users(id) ON DELETE CASCADE,
  grantee_email TEXT,
  permission TEXT CHECK(permission IN ('view','comment','full')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS reading_progress (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  doc_id UUID REFERENCES documents(id) ON DELETE CASCADE,
  last_page INTEGER,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  PRIMARY KEY (user_id, doc_id)
);

-- Trigger function to update tsvector (abbreviated in SQL)
CREATE OR REPLACE FUNCTION update_documents_tsv(doc_uuid UUID) RETURNS VOID AS $$
BEGIN
  UPDATE documents
  SET tsv = to_tsvector('english',
            coalesce(title,'') || ' ' || coalesce(author,'') || ' ' ||
            coalesce(
              (SELECT string_agg(p.text_content, ' ')
               FROM pages p
               WHERE p.doc_id = doc_uuid), ''
            )
          )
  WHERE id = doc_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Triggers omitted for brevity (include in full migration if needed)
