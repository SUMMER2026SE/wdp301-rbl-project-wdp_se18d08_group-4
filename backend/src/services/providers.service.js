const { supabaseAdmin } = require('./supabase.service');
const { uploadBuffer } = require('./cloudinary.service');

const VALID_DOC_TYPES = ['cccd_front', 'license_front', 'license_back', 'vehicle_registration', 'vehicle_photo'];

// ── Browse (customer-facing) ──────────────────────────────────────────────────

async function browseProviders({ city, minRating, limit = 20 }) {
  let query = supabaseAdmin
    .from('provider_profiles')
    .select(`
      id,
      business_name,
      vehicle_type,
      base_price,
      rating,
      total_reviews,
      is_verified,
      is_available,
      profiles!provider_profiles_id_fkey(full_name, avatar_url)
    `)
    .eq('is_verified', true)
    .eq('is_available', true)
    .order('rating', { ascending: false })
    .limit(limit);

  if (minRating) query = query.gte('rating', minRating);

  const { data, error } = await query;
  if (error) throw Object.assign(new Error(error.message), { status: 400 });

  return data;
}

// ── Provider self-service ─────────────────────────────────────────────────────

/**
 * GET /api/providers/me
 * Trả về profile đầy đủ: join profiles + provider_profiles.
 */
async function getMyProfile(providerId) {
  const { data: profile, error: pErr } = await supabaseAdmin
    .from('profiles')
    .select('id, email, full_name, phone, avatar_url, role, created_at')
    .eq('id', providerId)
    .single();

  if (pErr) throw Object.assign(new Error(pErr.message), { status: 404 });

  const { data: pp } = await supabaseAdmin
    .from('provider_profiles')
    .select('business_name, vehicle_type, base_price, price_per_km, service_area, rating, total_reviews, is_verified, is_available, total_orders, completed_orders')
    .eq('id', providerId)
    .maybeSingle();

  return {
    id: profile.id,
    email: profile.email,
    full_name: profile.full_name,
    phone: profile.phone,
    avatar_url: profile.avatar_url,
    role: profile.role,
    business_name: pp?.business_name ?? null,
    vehicle_type: pp?.vehicle_type ?? null,
    base_price: pp?.base_price ?? null,
    price_per_km: pp?.price_per_km ?? null,
    service_area: pp?.service_area ?? [],
    rating: pp?.rating ?? 0,
    total_reviews: pp?.total_reviews ?? 0,
    is_verified: pp?.is_verified ?? false,
    is_available: pp?.is_available ?? false,
    total_orders: pp?.total_orders ?? 0,
    completed_orders: pp?.completed_orders ?? 0,
  };
}

/**
 * PATCH /api/providers/me
 * Cập nhật profile + provider_profiles (upsert).
 */
async function updateMyProfile(providerId, payload) {
  // Cập nhật profiles
  const profileFields = {};
  if (payload.full_name !== undefined) profileFields.full_name = payload.full_name;
  if (payload.phone !== undefined) profileFields.phone = payload.phone;

  if (Object.keys(profileFields).length > 0) {
    const { error } = await supabaseAdmin
      .from('profiles')
      .update(profileFields)
      .eq('id', providerId);
    if (error) throw Object.assign(new Error(error.message), { status: 400 });
  }

  // Upsert provider_profiles
  const ppFields = { id: providerId };
  if (payload.business_name !== undefined) ppFields.business_name = payload.business_name;
  if (payload.vehicle_type !== undefined) ppFields.vehicle_type = payload.vehicle_type;
  if (payload.base_price !== undefined) ppFields.base_price = payload.base_price;
  if (payload.price_per_km !== undefined) ppFields.price_per_km = payload.price_per_km;
  if (payload.service_area !== undefined) ppFields.service_area = payload.service_area;

  if (Object.keys(ppFields).length > 1) {
    const { error } = await supabaseAdmin
      .from('provider_profiles')
      .upsert(ppFields, { onConflict: 'id' });
    if (error) throw Object.assign(new Error(error.message), { status: 400 });
  }

  return getMyProfile(providerId);
}

/**
 * PATCH /api/providers/me/status
 * Bật/tắt nhận đơn: is_available.
 */
async function setOnlineStatus(providerId, isAvailable) {
  const { error } = await supabaseAdmin
    .from('provider_profiles')
    .upsert({ id: providerId, is_available: isAvailable }, { onConflict: 'id' });

  if (error) throw Object.assign(new Error(error.message), { status: 400 });
  return { is_available: isAvailable };
}

// ── Documents ─────────────────────────────────────────────────────────────────

/**
 * POST /api/providers/me/documents
 * Upload một tài liệu lên Cloudinary rồi upsert vào provider_documents.
 */
async function uploadDocument(providerId, docType, fileBuffer) {
  if (!VALID_DOC_TYPES.includes(docType)) {
    throw Object.assign(new Error('doc_type không hợp lệ'), { status: 400 });
  }

  const { url, publicId } = await uploadBuffer(fileBuffer, {
    folder: `unimove/provider_documents/${providerId}`,
    public_id: docType,
    overwrite: true,
  });

  const { error } = await supabaseAdmin
    .from('provider_documents')
    .upsert(
      { provider_id: providerId, doc_type: docType, cloudinary_url: url, cloudinary_public_id: publicId, status: 'pending' },
      { onConflict: 'provider_id,doc_type' },
    );

  if (error) throw Object.assign(new Error(error.message), { status: 400 });

  return { doc_type: docType, url, status: 'pending' };
}

/**
 * GET /api/providers/me/documents
 */
async function getDocuments(providerId) {
  const { data, error } = await supabaseAdmin
    .from('provider_documents')
    .select('doc_type, cloudinary_url, status, created_at')
    .eq('provider_id', providerId)
    .order('created_at', { ascending: true });

  if (error) throw Object.assign(new Error(error.message), { status: 400 });
  return data ?? [];
}

module.exports = {
  browseProviders,
  getMyProfile,
  updateMyProfile,
  setOnlineStatus,
  uploadDocument,
  getDocuments,
};
