-- Add cloudinary_public_id and status to provider_documents,
-- and a unique constraint needed for upsert ON CONFLICT.

ALTER TABLE provider_documents
  ADD COLUMN IF NOT EXISTS cloudinary_public_id TEXT,
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'pending';

ALTER TABLE provider_documents
  DROP CONSTRAINT IF EXISTS provider_documents_provider_doc_unique;

ALTER TABLE provider_documents
  ADD CONSTRAINT provider_documents_provider_doc_unique
  UNIQUE (provider_id, document_type);
