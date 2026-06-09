const { supabaseAdmin } = require('./supabase.service');

/**
 * Đảm bảo bucket public tồn tại trước khi upload (thay thế chạy migration thủ công).
 */
async function ensurePublicImageBucket(
  bucketId,
  { fileSizeLimit = 5 * 1024 * 1024, allowedMimeTypes = ['image/jpeg', 'image/png'] } = {},
) {
  const { data: buckets, error: listError } = await supabaseAdmin.storage.listBuckets();
  if (listError) {
    throw listError;
  }

  const exists = (buckets ?? []).some((b) => b.id === bucketId || b.name === bucketId);
  if (exists) return;

  const { error } = await supabaseAdmin.storage.createBucket(bucketId, {
    public: true,
    fileSizeLimit,
    allowedMimeTypes,
  });

  if (error && !/already exists/i.test(error.message)) {
    throw error;
  }
}

module.exports = { ensurePublicImageBucket };
