const { supabaseAdmin } = require('./supabase.service');
const { uploadBuffer } = require('./cloudinary.service');
const { httpError } = require('./auth.helpers');

const VALID_DOC_TYPES = ['cccd_front', 'cccd_back', 'license_front', 'license_back', 'vehicle_registration', 'vehicle_photo'];

const PROVIDER_SELECT = `
  id,
  business_name,
  vehicle_type,
  vehicle_plate,
  base_price,
  price_per_km,
  price_per_floor,
  rating,
  total_reviews,
  is_verified,
  is_available,
  service_area,
  profiles!provider_profiles_id_fkey(full_name, avatar_url, phone)
`;

// ── Browse (customer-facing) ──────────────────────────────────────────────────

async function browseProviders({ city, minRating, limit = 20 }) {
  let query = supabaseAdmin
    .from('provider_profiles')
    .select(PROVIDER_SELECT)
    .eq('is_verified', true)
    .eq('is_available', true)
    .order('rating', { ascending: false })
    .limit(limit);

  if (minRating) query = query.gte('rating', minRating);

  const { data, error } = await query;
  if (error) throw Object.assign(new Error(error.message), { status: 400 });

  return data;
}

function mapProviderRow(row) {
  const profile = Array.isArray(row.profiles) ? row.profiles[0] : row.profiles;
  const fullName = profile?.full_name ?? null;
  const businessName = row.business_name ?? fullName ?? 'Nhà xe';
  return {
    id: row.id,
    name: businessName,
    business_name: row.business_name ?? businessName,
    full_name: fullName,
    avatar_url: profile?.avatar_url ?? null,
    phone: profile?.phone ?? null,
    vehicle_type: row.vehicle_type,
    vehicle_plate: row.vehicle_plate ?? null,
    base_price: row.base_price != null ? Number(row.base_price) : null,
    price_per_km: row.price_per_km != null ? Number(row.price_per_km) : null,
    price_per_floor: row.price_per_floor != null ? Number(row.price_per_floor) : null,
    rating: row.rating != null ? Number(row.rating) : 0,
    total_reviews: row.total_reviews ?? 0,
    is_verified: Boolean(row.is_verified),
    is_available: Boolean(row.is_available),
    service_area: row.service_area ?? [],
  };
}

function mapServicePackage(row) {
  return {
    id: row.id,
    name: row.name,
    description: row.description ?? null,
    service_type: row.service_type,
    vehicle_size: row.vehicle_size,
    base_price: Number(row.base_price),
    price_per_km: Number(row.price_per_km ?? 0),
    price_per_floor: Number(row.price_per_floor ?? 0),
    helper_count: row.helper_count ?? 0,
    includes_packing: Boolean(row.includes_packing),
    includes_insurance: Boolean(row.includes_insurance),
    max_weight_kg: row.max_weight_kg != null ? Number(row.max_weight_kg) : null,
    estimated_duration_hours:
      row.estimated_duration_hours != null ? Number(row.estimated_duration_hours) : null,
  };
}

function mapReview(row) {
  const customer = Array.isArray(row.customer) ? row.customer[0] : row.customer;
  return {
    id: row.id,
    order_id: row.order_id,
    rating: row.rating,
    title: row.title ?? null,
    comment: row.comment ?? null,
    tags: row.tags ?? [],
    created_at: row.created_at,
    customer_name: customer?.full_name ?? 'Khách hàng',
  };
}

async function loadProviderRow(providerId) {
  const { data, error } = await supabaseAdmin
    .from('provider_profiles')
    .select(PROVIDER_SELECT)
    .eq('id', providerId)
    .maybeSingle();

  if (error) {
    if (error.code === '42P01') {
      return loadProviderFromProfilesOnly(providerId);
    }
    throw httpError(500, error.message, 'db_error');
  }
  if (data) return data;

  return loadProviderFromProfilesOnly(providerId);
}

async function loadProviderFromProfilesOnly(providerId) {
  const { data: profile, error: profileError } = await supabaseAdmin
    .from('profiles')
    .select('id, full_name, avatar_url, phone, role')
    .eq('id', providerId)
    .eq('role', 'provider')
    .maybeSingle();

  if (profileError) throw httpError(500, profileError.message, 'db_error');
  if (!profile) return null;

  const { data: pp, error: ppError } = await supabaseAdmin
    .from('provider_profiles')
    .select(
      'id, business_name, vehicle_type, vehicle_plate, base_price, price_per_km, price_per_floor, rating, total_reviews, is_verified, is_available, service_area',
    )
    .eq('id', providerId)
    .maybeSingle();

  if (ppError && ppError.code !== '42P01') throw httpError(500, ppError.message, 'db_error');

  if (!pp) {
    return {
      id: profile.id,
      business_name: profile.full_name,
      vehicle_type: null,
      vehicle_plate: null,
      base_price: null,
      price_per_km: null,
      price_per_floor: null,
      rating: 0,
      total_reviews: 0,
      is_verified: false,
      is_available: false,
      service_area: [],
      profiles: { full_name: profile.full_name, avatar_url: profile.avatar_url, phone: profile.phone },
    };
  }

  return { ...pp, profiles: { full_name: profile.full_name, avatar_url: profile.avatar_url, phone: profile.phone } };
}

/** BE-020 — GET /api/providers/:id */
async function getProviderById(providerId, { reviewsLimit = 5 } = {}) {
  const id = String(providerId || '').trim();
  if (!id) throw httpError(400, 'Thiếu id nhà xe', 'validation_error');

  const providerRow = await loadProviderRow(id);
  if (!providerRow) throw httpError(404, 'Không tìm thấy nhà xe', 'not_found');

  const limit = Math.min(Math.max(parseInt(String(reviewsLimit), 10) || 5, 1), 20);

  const [packagesResult, reviewsResult, summaryResult] = await Promise.all([
    supabaseAdmin
      .from('service_packages')
      .select(
        'id, name, description, service_type, vehicle_size, base_price, price_per_km, price_per_floor, helper_count, includes_packing, includes_insurance, max_weight_kg, estimated_duration_hours, sort_order',
      )
      .eq('provider_id', id)
      .eq('is_active', true)
      .order('sort_order', { ascending: true }),
    supabaseAdmin
      .from('reviews')
      .select('id, order_id, rating, title, comment, tags, created_at, customer:profiles!customer_id(full_name)')
      .eq('provider_id', id)
      .eq('is_published', true)
      .eq('is_hidden', false)
      .order('created_at', { ascending: false })
      .limit(limit),
    supabaseAdmin.from('provider_reviews_summary').select('*').eq('provider_id', id).maybeSingle(),
  ]);

  if (packagesResult.error) throw httpError(500, packagesResult.error.message, 'db_error');
  if (reviewsResult.error) throw httpError(500, reviewsResult.error.message, 'db_error');
  if (summaryResult.error) throw httpError(500, summaryResult.error.message, 'db_error');

  const base = mapProviderRow(providerRow);

  return {
    ...base,
    packages: (packagesResult.data || []).map(mapServicePackage),
    reviews_summary: summaryResult.data
      ? {
          total_reviews: summaryResult.data.total_reviews ?? 0,
          average_rating: Number(summaryResult.data.average_rating ?? 0),
          rating_5_count: summaryResult.data.rating_5_count ?? 0,
          rating_4_count: summaryResult.data.rating_4_count ?? 0,
          rating_3_count: summaryResult.data.rating_3_count ?? 0,
          rating_2_count: summaryResult.data.rating_2_count ?? 0,
          rating_1_count: summaryResult.data.rating_1_count ?? 0,
          avg_service_quality: Number(summaryResult.data.avg_service_quality ?? 0),
          avg_punctuality: Number(summaryResult.data.avg_punctuality ?? 0),
          avg_professionalism: Number(summaryResult.data.avg_professionalism ?? 0),
          avg_value_for_money: Number(summaryResult.data.avg_value_for_money ?? 0),
          response_rate: Number(summaryResult.data.response_rate ?? 0),
        }
      : null,
    reviews: (reviewsResult.data || []).map(mapReview),
  };
}

// ── Provider self-service ─────────────────────────────────────────────────────

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

async function updateMyProfile(providerId, payload) {
  const profileFields = {};
  if (payload.full_name !== undefined) profileFields.full_name = payload.full_name;
  if (payload.phone !== undefined) profileFields.phone = payload.phone;

  if (Object.keys(profileFields).length > 0) {
    const { error } = await supabaseAdmin.from('profiles').update(profileFields).eq('id', providerId);
    if (error) throw Object.assign(new Error(error.message), { status: 400 });
  }

  const ppFields = { id: providerId };
  if (payload.business_name !== undefined) ppFields.business_name = payload.business_name;
  if (payload.vehicle_type !== undefined) ppFields.vehicle_type = payload.vehicle_type;
  if (payload.base_price !== undefined) ppFields.base_price = payload.base_price;
  if (payload.price_per_km !== undefined) ppFields.price_per_km = payload.price_per_km;
  if (payload.service_area !== undefined) ppFields.service_area = payload.service_area;

  if (Object.keys(ppFields).length > 1) {
    let dbError;
    if (ppFields.business_name !== undefined) {
      // business_name có trong payload → upsert an toàn (tạo mới nếu chưa có)
      ({ error: dbError } = await supabaseAdmin
        .from('provider_profiles')
        .upsert(ppFields, { onConflict: 'id' }));
    } else {
      // Không có business_name → chỉ update row đã tồn tại, tránh vi phạm NOT NULL khi INSERT
      const { id, ...updateFields } = ppFields;
      ({ error: dbError } = await supabaseAdmin
        .from('provider_profiles')
        .update(updateFields)
        .eq('id', providerId));
    }
    if (dbError) throw Object.assign(new Error(dbError.message), { status: 400 });
  }

  return getMyProfile(providerId);
}

async function setOnlineStatus(providerId, isAvailable) {
  const { error } = await supabaseAdmin
    .from('provider_profiles')
    .upsert({ id: providerId, is_available: isAvailable }, { onConflict: 'id' });

  if (error) throw Object.assign(new Error(error.message), { status: 400 });
  return { is_available: isAvailable };
}

// ── Documents ─────────────────────────────────────────────────────────────────

async function uploadDocument(providerId, docType, fileBuffer) {
  if (!VALID_DOC_TYPES.includes(docType)) {
    throw Object.assign(new Error('doc_type không hợp lệ'), { status: 400 });
  }

  console.log(`[uploadDocument] provider=${providerId} docType=${docType} bufferSize=${fileBuffer?.length}`);

  let url, publicId;
  try {
    ({ url, publicId } = await uploadBuffer(fileBuffer, {
      folder: `unimove/provider_documents/${providerId}`,
      public_id: docType,
      overwrite: true,
    }));
    console.log(`[uploadDocument] Cloudinary OK → ${url}`);
  } catch (cloudErr) {
    console.error(`[uploadDocument] Cloudinary FAILED:`, cloudErr.message);
    throw Object.assign(new Error(`Cloudinary upload failed: ${cloudErr.message}`), { status: 502 });
  }

  const { error } = await supabaseAdmin
    .from('provider_documents')
    .upsert(
      {
        provider_id: providerId,
        document_type: docType,
        document_url: url,
        cloudinary_public_id: publicId,
        status: 'pending',
      },
      { onConflict: 'provider_id,document_type' },
    );

  if (error) {
    console.error(`[uploadDocument] DB upsert FAILED:`, error.message);
    throw Object.assign(new Error(error.message), { status: 400 });
  }

  console.log(`[uploadDocument] DB saved OK → ${docType}`);
  return { doc_type: docType, url, status: 'pending' };
}

async function getDocuments(providerId) {
  const { data, error } = await supabaseAdmin
    .from('provider_documents')
    .select('document_type, document_url, cloudinary_public_id, status, created_at')
    .eq('provider_id', providerId)
    .order('created_at', { ascending: true });

  if (error) throw Object.assign(new Error(error.message), { status: 400 });
  return data ?? [];
}

module.exports = {
  browseProviders,
  getProviderById,
  getMyProfile,
  updateMyProfile,
  setOnlineStatus,
  uploadDocument,
  getDocuments,
};
