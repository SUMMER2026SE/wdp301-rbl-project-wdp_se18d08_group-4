const { supabaseAdmin } = require('./supabase.service');
const { httpError } = require('./auth.helpers');

const VALID_CATEGORIES = ['furniture', 'electronics', 'appliances', 'clothes', 'books', 'other'];
const VALID_CONDITIONS = ['new', 'like_new', 'good', 'fair', 'poor'];
const VALID_STATUSES   = ['active', 'reserved', 'hidden', 'closed'];

/** API-062 — POST /api/marketplace/listings */
async function createListing(userId, body) {
  const { title, description, category, condition, area, price, images } = body || {};

  if (!title || !category || !condition || price === undefined) {
    throw httpError(400, 'Thiếu field bắt buộc: title, category, condition, price', 'validation_error');
  }
  if (!VALID_CATEGORIES.includes(category)) {
    throw httpError(400, `category không hợp lệ. Chọn: ${VALID_CATEGORIES.join(', ')}`, 'validation_error');
  }
  if (!VALID_CONDITIONS.includes(condition)) {
    throw httpError(400, `condition không hợp lệ. Chọn: ${VALID_CONDITIONS.join(', ')}`, 'validation_error');
  }
  if (isNaN(Number(price)) || Number(price) < 0) {
    throw httpError(400, 'price phải là số không âm', 'validation_error');
  }

  const payload = {
    owner_id:    userId,
    title:       String(title).trim(),
    description: description ? String(description).trim() : null,
    category,
    condition,
    area:        area ? String(area).trim() : null,
    price:       Number(price),
    images:      Array.isArray(images) ? images : [],
    status:      'active',
    fee_paid:    false,
  };

  const { data, error } = await supabaseAdmin
    .from('marketplace_listings')
    .insert([payload])
    .select(`
      id, title, description, category, condition, area,
      price, images, status, fee_paid, created_at, updated_at,
      profiles:owner_id ( id, full_name, avatar_url, phone )
    `)
    .single();

  if (error) throw httpError(500, error.message, 'db_error');
  return data;
}

/** API-059 — GET /api/marketplace/listings */
async function browseListings(query) {
  const {
    keyword,
    category,
    condition,
    area,
    min_price,
    max_price,
    page    = 1,
    limit   = 20,
  } = query || {};

  const pageNum  = Math.max(1, parseInt(page, 10)  || 1);
  const limitNum = Math.min(50, Math.max(1, parseInt(limit, 10) || 20));
  const from     = (pageNum - 1) * limitNum;
  const to       = from + limitNum - 1;

  let q = supabaseAdmin
    .from('marketplace_listings')
    .select(
      `id, title, description, category, condition, area,
       price, images, status, created_at,
       profiles:owner_id ( id, full_name, avatar_url )`,
      { count: 'exact' }
    )
    .eq('status', 'active')
    .order('created_at', { ascending: false })
    .range(from, to);

  if (keyword) {
    q = q.or(`title.ilike.%${keyword}%,description.ilike.%${keyword}%`);
  }
  if (category && VALID_CATEGORIES.includes(category)) {
    q = q.eq('category', category);
  }
  if (condition && VALID_CONDITIONS.includes(condition)) {
    q = q.eq('condition', condition);
  }
  if (area) {
    q = q.ilike('area', `%${area}%`);
  }
  if (min_price !== undefined && !isNaN(Number(min_price))) {
    q = q.gte('price', Number(min_price));
  }
  if (max_price !== undefined && !isNaN(Number(max_price))) {
    q = q.lte('price', Number(max_price));
  }

  const { data, error, count } = await q;
  if (error) throw httpError(500, error.message, 'db_error');

  return {
    listings: data || [],
    pagination: {
      total: count || 0,
      page:  pageNum,
      limit: limitNum,
      pages: Math.ceil((count || 0) / limitNum),
    },
  };
}

/** API-060 — GET /api/marketplace/my-listings */
async function getMyListings(userId, query) {
  const { status, page = 1, limit = 20 } = query || {};

  const pageNum  = Math.max(1, parseInt(page, 10)  || 1);
  const limitNum = Math.min(50, Math.max(1, parseInt(limit, 10) || 20));
  const from     = (pageNum - 1) * limitNum;
  const to       = from + limitNum - 1;

  let q = supabaseAdmin
    .from('marketplace_listings')
    .select(
      'id, title, description, category, condition, area, price, images, status, fee_paid, created_at, updated_at',
      { count: 'exact' }
    )
    .eq('owner_id', userId)
    .order('created_at', { ascending: false })
    .range(from, to);

  if (status && VALID_STATUSES.includes(status)) {
    q = q.eq('status', status);
  }

  const { data, error, count } = await q;
  if (error) throw httpError(500, error.message, 'db_error');

  return {
    listings: data || [],
    pagination: {
      total: count || 0,
      page:  pageNum,
      limit: limitNum,
      pages: Math.ceil((count || 0) / limitNum),
    },
  };
}

module.exports = { createListing, browseListings, getMyListings };
