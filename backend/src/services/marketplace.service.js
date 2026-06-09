const { supabaseAdmin } = require('./supabase.service');
const { httpError } = require('./auth.helpers');
const { createNotification } = require('./notification.service');
const { ensurePublicImageBucket } = require('./storage.helpers');

const VALID_CATEGORIES = ['furniture', 'electronics', 'appliances', 'clothes', 'books', 'other'];
const VALID_CONDITIONS = ['new', 'like_new', 'good', 'fair', 'poor'];
const VALID_STATUSES   = ['active', 'reserved', 'hidden', 'closed'];

const MARKETPLACE_IMAGES_BUCKET = 'marketplace-images';
const EXT_BY_MIME = { 'image/jpeg': 'jpg', 'image/png': 'png' };

// ── Batch 1 ──────────────────────────────────────────────────────────────────

/** API-062 — POST /api/marketplace/listings */
async function createListing(userId, body) {
  const { title, description, category, condition, area, price, images, usage_duration } = body || {};

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

  const { data, error } = await supabaseAdmin
    .from('marketplace_listings')
    .insert([{
      owner_id:    userId,
      title:       String(title).trim(),
      description: description ? String(description).trim() : null,
      category,
      condition,
      area:           area ? String(area).trim() : null,
      price:          Number(price),
      images:         Array.isArray(images) ? images : [],
      usage_duration: usage_duration ? String(usage_duration).trim() : null,
      status:      'active',
      fee_paid:    false,
    }])
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
async function browseListings(query, userId) {
  const { keyword, category, condition, area, min_price, max_price, seller_id, page = 1, limit = 20 } = query || {};

  const pageNum  = Math.max(1, parseInt(page, 10) || 1);
  const limitNum = Math.min(50, Math.max(1, parseInt(limit, 10) || 20));
  const from = (pageNum - 1) * limitNum;
  const to   = from + limitNum - 1;

  const uid = String(userId || '').trim();

  let q = supabaseAdmin
    .from('marketplace_listings')
    .select(
      `id, title, description, category, condition, area,
       price, images, status, created_at,
       profiles:owner_id ( id, full_name, avatar_url )`,
      { count: 'exact' }
    )
    .order('created_at', { ascending: false })
    .range(from, to);

  // active: mọi user; reserved: chỉ người đăng hoặc người mua đã được chốt
  if (uid) {
    q = q.or(
      `status.eq.active,and(status.eq.reserved,or(owner_id.eq.${uid},confirmed_buyer_id.eq.${uid}))`,
    );
  } else {
    q = q.eq('status', 'active');
  }

  if (keyword) q = q.or(`title.ilike.%${keyword}%,description.ilike.%${keyword}%`);
  if (category && VALID_CATEGORIES.includes(category)) q = q.eq('category', category);
  if (condition && VALID_CONDITIONS.includes(condition)) q = q.eq('condition', condition);
  if (area) q = q.ilike('area', `%${area}%`);
  if (min_price !== undefined && !isNaN(Number(min_price))) q = q.gte('price', Number(min_price));
  if (max_price !== undefined && !isNaN(Number(max_price))) q = q.lte('price', Number(max_price));
  if (seller_id) q = q.eq('owner_id', seller_id);

  const { data, error, count } = await q;
  if (error) throw httpError(500, error.message, 'db_error');

  return {
    listings: data || [],
    pagination: { total: count || 0, page: pageNum, limit: limitNum, pages: Math.ceil((count || 0) / limitNum) },
  };
}

/** API-060 — GET /api/marketplace/my-listings */
async function getMyListings(userId, query) {
  const { status, page = 1, limit = 20 } = query || {};

  const pageNum  = Math.max(1, parseInt(page, 10) || 1);
  const limitNum = Math.min(50, Math.max(1, parseInt(limit, 10) || 20));
  const from = (pageNum - 1) * limitNum;
  const to   = from + limitNum - 1;

  let q = supabaseAdmin
    .from('marketplace_listings')
    .select('id, title, description, category, condition, area, price, images, status, fee_paid, created_at, updated_at', { count: 'exact' })
    .eq('owner_id', userId)
    .order('created_at', { ascending: false })
    .range(from, to);

  if (status && VALID_STATUSES.includes(status)) q = q.eq('status', status);

  const { data, error, count } = await q;
  if (error) throw httpError(500, error.message, 'db_error');

  const listings = data || [];

  // Đếm số khách quan tâm cho từng tin
  const withCounts = await Promise.all(listings.map(async (l) => {
    const { count: interestCount } = await supabaseAdmin
      .from('marketplace_interests')
      .select('id', { count: 'exact', head: true })
      .eq('listing_id', l.id);
    return { ...l, interest_count: interestCount || 0 };
  }));

  return {
    listings: withCounts,
    pagination: { total: count || 0, page: pageNum, limit: limitNum, pages: Math.ceil((count || 0) / limitNum) },
  };
}

// ── Batch 2 ──────────────────────────────────────────────────────────────────

/** API-061 — GET /api/marketplace/listings/:id */
async function getListing(listingId, userId) {
  const { data, error } = await supabaseAdmin
    .from('marketplace_listings')
    .select(`
      id, title, description, category, condition, area,
      price, images, status, fee_paid, usage_duration, created_at, updated_at,
      deal_confirmed, confirmed_price, confirmed_buyer_id, transport_booked,
      profiles:owner_id ( id, full_name, avatar_url, phone )
    `)
    .eq('id', listingId)
    .single();

  if (error || !data) throw httpError(404, 'Không tìm thấy tin', 'not_found');

  const { count: interestCount } = await supabaseAdmin
    .from('marketplace_interests')
    .select('id', { count: 'exact', head: true })
    .eq('listing_id', listingId);

  let isInterested = false;
  let isRated = false;
  if (userId) {
    const [{ data: mine }, { data: rating }] = await Promise.all([
      supabaseAdmin.from('marketplace_interests').select('id').eq('listing_id', listingId).eq('buyer_id', userId).single(),
      supabaseAdmin.from('marketplace_ratings').select('id').eq('listing_id', listingId).eq('buyer_id', userId).single(),
    ]);
    isInterested = !!mine;
    isRated      = !!rating;
  }

  return {
    ...data,
    interest_count: interestCount || 0,
    is_interested:  isInterested,
    is_rated:       isRated,
    is_mine:        data.profiles?.id === userId,
  };
}

/** API-064 — PATCH /api/marketplace/listings/:id/status */
async function updateListingStatus(listingId, userId, status) {
  if (!VALID_STATUSES.includes(status)) {
    throw httpError(400, `status không hợp lệ. Chọn: ${VALID_STATUSES.join(', ')}`, 'validation_error');
  }

  const { data: listing } = await supabaseAdmin
    .from('marketplace_listings')
    .select('id, owner_id')
    .eq('id', listingId)
    .single();

  if (!listing) throw httpError(404, 'Không tìm thấy tin', 'not_found');
  if (listing.owner_id !== userId) throw httpError(403, 'Không có quyền chỉnh sửa tin này', 'forbidden');

  const { data, error } = await supabaseAdmin
    .from('marketplace_listings')
    .update({ status })
    .eq('id', listingId)
    .select('id, title, status, updated_at')
    .single();

  if (error) throw httpError(500, error.message, 'db_error');
  return data;
}

/** API-065 — POST /api/marketplace/listings/:id/interest */
async function expressInterest(listingId, userId, body) {
  const { data: listing } = await supabaseAdmin
    .from('marketplace_listings')
    .select('id, owner_id, status')
    .eq('id', listingId)
    .single();

  if (!listing) throw httpError(404, 'Không tìm thấy tin', 'not_found');
  if (listing.status !== 'active') throw httpError(400, 'Tin không còn nhận quan tâm', 'listing_unavailable');
  if (listing.owner_id === userId) throw httpError(400, 'Không thể quan tâm tin của chính mình', 'validation_error');

  const { error } = await supabaseAdmin
    .from('marketplace_interests')
    .upsert(
      { listing_id: listingId, buyer_id: userId, note: body?.note || null },
      { onConflict: 'listing_id,buyer_id', ignoreDuplicates: true }
    );

  if (error) throw httpError(500, error.message, 'db_error');

  const { count } = await supabaseAdmin
    .from('marketplace_interests')
    .select('id', { count: 'exact', head: true })
    .eq('listing_id', listingId);

  // Lấy tên buyer để gửi thông báo cho seller
  const { data: buyer } = await supabaseAdmin
    .from('profiles')
    .select('full_name')
    .eq('id', userId)
    .single();

  const buyerName = buyer?.full_name || 'Ai đó';

  createNotification(
    listing.owner_id,
    'marketplace_interest',
    `❤️ ${buyerName} quan tâm tin của bạn`,
    `${buyerName} vừa bấm "Tôi muốn nhận". Hãy nhắn tin để thỏa thuận!`,
    { listingId, actionData: { listing_id: listingId, buyer_id: userId }, priority: 'normal' },
  );

  return { listing_id: listingId, interest_count: count || 0 };
}

// ── Batch 3 ──────────────────────────────────────────────────────────────────

/** API-066 — GET /api/marketplace/listings/:id/interests */
async function getInterestedBuyers(listingId, userId) {
  const { data: listing } = await supabaseAdmin
    .from('marketplace_listings')
    .select('id, owner_id')
    .eq('id', listingId)
    .single();

  if (!listing) throw httpError(404, 'Không tìm thấy tin', 'not_found');
  if (listing.owner_id !== userId) throw httpError(403, 'Chỉ người đăng mới xem được', 'forbidden');

  const { data, error } = await supabaseAdmin
    .from('marketplace_interests')
    .select(`
      id, created_at, note,
      profiles:buyer_id ( id, full_name, avatar_url, phone )
    `)
    .eq('listing_id', listingId)
    .order('created_at', { ascending: false });

  if (error) throw httpError(500, error.message, 'db_error');

  const buyers = await Promise.all((data || []).map(async (row) => {
    const buyerId = row.profiles?.id;
    if (!buyerId) return null;

    const { data: conv } = await supabaseAdmin
      .from('marketplace_conversations')
      .select('id, last_message_text, last_message_at, seller_unread')
      .eq('listing_id', listingId)
      .eq('buyer_id', buyerId)
      .single();

    return {
      id:            buyerId,
      name:          row.profiles?.full_name || '',
      avatar_url:    row.profiles?.avatar_url || null,
      contact:       row.profiles?.phone || '',
      interested_at: row.created_at,
      note:          row.note || '',
      last_message:  conv?.last_message_text || null,
      unread_count:  conv?.seller_unread || 0,
      conversation_id: conv?.id || null,
    };
  }));

  return buyers.filter(Boolean);
}

/** Tạo hoặc lấy conversation giữa seller và buyer cho 1 listing */
async function getOrCreateConversation(listingId, buyerId, sellerId) {
  const { data: existing } = await supabaseAdmin
    .from('marketplace_conversations')
    .select('id, seller_id, buyer_id')
    .eq('listing_id', listingId)
    .eq('buyer_id', buyerId)
    .single();

  if (existing) return existing;

  const { data, error } = await supabaseAdmin
    .from('marketplace_conversations')
    .insert([{ listing_id: listingId, seller_id: sellerId, buyer_id: buyerId }])
    .select('id, seller_id, buyer_id')
    .single();

  if (error) throw httpError(500, error.message, 'db_error');
  return data;
}

/** API-067 — GET /api/marketplace/listings/:listingId/conversations/:buyerId/messages */
async function getMessages(listingId, buyerId, userId) {
  const { data: listing } = await supabaseAdmin
    .from('marketplace_listings')
    .select('id, owner_id')
    .eq('id', listingId)
    .single();

  if (!listing) throw httpError(404, 'Không tìm thấy tin', 'not_found');

  const isSeller = listing.owner_id === userId;
  const isBuyer  = userId === buyerId;
  if (!isSeller && !isBuyer) throw httpError(403, 'Không có quyền xem chat này', 'forbidden');

  const conv = await getOrCreateConversation(listingId, buyerId, listing.owner_id);

  const unreadField = isSeller ? { seller_unread: 0 } : { buyer_unread: 0 };
  await supabaseAdmin
    .from('marketplace_conversations')
    .update(unreadField)
    .eq('id', conv.id);

  const { data: messages, error } = await supabaseAdmin
    .from('marketplace_messages')
    .select(`
      id, text, is_offer, offer_amount,
      is_deal_confirm, is_deal_cancel, created_at,
      profiles:sender_id ( id, full_name )
    `)
    .eq('conversation_id', conv.id)
    .order('created_at', { ascending: true });

  if (error) throw httpError(500, error.message, 'db_error');

  return {
    conversation_id: conv.id,
    messages: (messages || []).map((m) => ({
      id:              m.id,
      text:            m.text,
      from_buyer:      m.profiles?.id === buyerId,
      is_offer:        m.is_offer,
      offer_amount:    m.offer_amount,
      is_deal_confirm: m.is_deal_confirm,
      is_deal_cancel:  m.is_deal_cancel,
      created_at:      m.created_at,
    })),
  };
}

/** API-068 — POST /api/marketplace/listings/:listingId/conversations/:buyerId/messages */
async function sendMessage(listingId, buyerId, userId, body) {
  const { text, is_offer = false, offer_amount } = body || {};

  if (!text || !String(text).trim()) {
    throw httpError(400, 'text không được để trống', 'validation_error');
  }

  const { data: listing } = await supabaseAdmin
    .from('marketplace_listings')
    .select('id, owner_id')
    .eq('id', listingId)
    .single();

  if (!listing) throw httpError(404, 'Không tìm thấy tin', 'not_found');

  const isSeller = listing.owner_id === userId;
  const isBuyer  = userId === buyerId;
  if (!isSeller && !isBuyer) throw httpError(403, 'Không có quyền chat này', 'forbidden');

  const conv = await getOrCreateConversation(listingId, buyerId, listing.owner_id);

  const { data: msg, error } = await supabaseAdmin
    .from('marketplace_messages')
    .insert([{
      conversation_id: conv.id,
      sender_id:       userId,
      text:            String(text).trim(),
      is_offer:        is_offer && !!offer_amount,
      offer_amount:    is_offer && offer_amount ? Number(offer_amount) : null,
    }])
    .select('id, text, is_offer, offer_amount, created_at')
    .single();

  if (error) throw httpError(500, error.message, 'db_error');

  await supabaseAdmin
    .from('marketplace_conversations')
    .update({
      last_message_text: msg.text,
      last_message_at:   msg.created_at,
      ...(isSeller ? { buyer_unread: 1 } : { seller_unread: 1 }),
    })
    .eq('id', conv.id);

  const recipientId = isSeller ? buyerId : listing.owner_id;
  const preview = msg.text.length > 60 ? msg.text.substring(0, 60) + '…' : msg.text;
  createNotification(recipientId, 'marketplace_message', 'Tin nhắn mới trong Chợ sinh viên', preview, {
    listingId,
    actionData: { listing_id: listingId, buyer_id: buyerId },
    icon: 'chat',
  });

  return { ...msg, from_buyer: isBuyer };
}

// ── Batch 4 ──────────────────────────────────────────────────────────────────

/** API-069 — POST /api/marketplace/listings/:listingId/conversations/:buyerId/deal */
async function confirmDeal(listingId, sellerId, buyerId, body) {
  const { agreed_price } = body || {};

  const { data: listing } = await supabaseAdmin
    .from('marketplace_listings')
    .select('id, owner_id, status, deal_confirmed, transport_booked, price')
    .eq('id', listingId)
    .single();

  if (!listing) throw httpError(404, 'Không tìm thấy tin', 'not_found');
  if (listing.owner_id !== sellerId) throw httpError(403, 'Chỉ người đăng mới chốt được', 'forbidden');
  if (listing.deal_confirmed) throw httpError(400, 'Tin đã được chốt đơn rồi', 'already_confirmed');
  if (listing.status === 'closed') throw httpError(400, 'Tin đã đóng', 'listing_closed');

  const { data: interest } = await supabaseAdmin
    .from('marketplace_interests')
    .select('id')
    .eq('listing_id', listingId)
    .eq('buyer_id', buyerId)
    .single();
  if (!interest) throw httpError(400, 'Người mua chưa quan tâm tin này', 'buyer_not_interested');

  const confirmedPrice = agreed_price != null && !isNaN(Number(agreed_price)) && Number(agreed_price) > 0
    ? Number(agreed_price)
    : null;

  const { data: updated, error } = await supabaseAdmin
    .from('marketplace_listings')
    .update({
      deal_confirmed:      true,
      confirmed_buyer_id:  buyerId,
      confirmed_price:     confirmedPrice,
      status:              'reserved',
    })
    .eq('id', listingId)
    .select('id, title, status, deal_confirmed, confirmed_price, confirmed_buyer_id, transport_booked')
    .single();

  if (error) throw httpError(500, error.message, 'db_error');

  const conv = await getOrCreateConversation(listingId, buyerId, sellerId);
  const priceNote = confirmedPrice
    ? ` — Giá chốt: ${Number(confirmedPrice).toLocaleString('vi-VN')}đ`
    : '';
  await supabaseAdmin
    .from('marketplace_messages')
    .insert([{
      conversation_id: conv.id,
      sender_id:       sellerId,
      text:            `Người bán đã chốt đơn — bạn có thể đặt xe lấy đồ${priceNote}.`,
      is_deal_confirm: true,
    }]);

  createNotification(buyerId, 'marketplace_deal_confirmed',
    '🎉 Đơn hàng đã được chốt!',
    `Người bán đã chốt đơn${priceNote}. Bạn có thể đặt xe lấy đồ ngay.`,
    { listingId, actionData: { listing_id: listingId, buyer_id: buyerId }, priority: 'high' },
  );

  return updated;
}

/** API-070 — DELETE /api/marketplace/listings/:listingId/deal */
async function cancelDeal(listingId, sellerId) {
  const { data: listing } = await supabaseAdmin
    .from('marketplace_listings')
    .select('id, owner_id, deal_confirmed, confirmed_buyer_id, transport_booked')
    .eq('id', listingId)
    .single();

  if (!listing) throw httpError(404, 'Không tìm thấy tin', 'not_found');
  if (listing.owner_id !== sellerId) throw httpError(403, 'Chỉ người đăng mới huỷ được', 'forbidden');
  if (!listing.deal_confirmed) throw httpError(400, 'Tin chưa được chốt đơn', 'not_confirmed');
  if (listing.transport_booked) throw httpError(400, 'Khách đã đặt xe — không thể huỷ chốt', 'transport_already_booked');

  const buyerId = listing.confirmed_buyer_id;

  const { data: updated, error } = await supabaseAdmin
    .from('marketplace_listings')
    .update({
      deal_confirmed:     false,
      confirmed_buyer_id: null,
      confirmed_price:    null,
      status:             'active',
    })
    .eq('id', listingId)
    .select('id, title, status, deal_confirmed, confirmed_price, confirmed_buyer_id, transport_booked')
    .single();

  if (error) throw httpError(500, error.message, 'db_error');

  if (buyerId) {
    const conv = await getOrCreateConversation(listingId, buyerId, sellerId);
    await supabaseAdmin
      .from('marketplace_messages')
      .insert([{
        conversation_id: conv.id,
        sender_id:       sellerId,
        text:            'Người bán đã huỷ chốt đơn.',
        is_deal_cancel:  true,
      }]);

    createNotification(buyerId, 'marketplace_deal_cancelled',
      'Đơn hàng bị huỷ chốt',
      'Người bán đã huỷ chốt đơn. Bạn vẫn có thể tiếp tục thương lượng.',
      { listingId, actionData: { listing_id: listingId, buyer_id: buyerId } },
    );
  }

  return updated;
}

/** API-071 — POST /api/marketplace/listings/:listingId/transport-booked */
async function markTransportBooked(listingId, buyerId) {
  const { data: listing } = await supabaseAdmin
    .from('marketplace_listings')
    .select('id, owner_id, deal_confirmed, confirmed_buyer_id, transport_booked')
    .eq('id', listingId)
    .single();

  if (!listing) throw httpError(404, 'Không tìm thấy tin', 'not_found');
  if (!listing.deal_confirmed) throw httpError(400, 'Tin chưa được chốt đơn', 'not_confirmed');
  if (listing.confirmed_buyer_id !== buyerId) throw httpError(403, 'Chỉ người được chốt mới đặt xe được', 'forbidden');
  if (listing.transport_booked) return { listing_id: listingId, transport_booked: true };

  const { data: updated, error } = await supabaseAdmin
    .from('marketplace_listings')
    .update({ transport_booked: true })
    .eq('id', listingId)
    .select('id, transport_booked')
    .single();

  if (error) throw httpError(500, error.message, 'db_error');

  createNotification(listing.owner_id, 'marketplace_transport_booked',
    '🚚 Người mua đã đặt xe!',
    'Người mua đã đặt xe lấy đồ. Chuẩn bị đồ để bàn giao nhé.',
    { listingId, actionData: { listing_id: listingId, buyer_id: buyerId }, priority: 'high' },
  );

  return updated;
}

// ── Batch 5 — Yêu thích ──────────────────────────────────────────────────────

/** GET /api/marketplace/my-interests */
async function getMyInterests(userId) {
  const { data, error } = await supabaseAdmin
    .from('marketplace_interests')
    .select(`
      id, created_at,
      listing:listing_id (
        id, title, description, category, condition, area,
        price, images, status, created_at,
        profiles:owner_id ( id, full_name, avatar_url )
      )
    `)
    .eq('buyer_id', userId)
    .order('created_at', { ascending: false });

  if (error) throw httpError(500, error.message, 'db_error');

  const listings = (data || [])
    .filter(row => row.listing)
    .map(row => ({ ...row.listing, interest_count: 0, interested_at: row.created_at }));

  return { listings };
}

/** DELETE /api/marketplace/listings/:id/interest */
async function removeInterest(listingId, userId) {
  const { error } = await supabaseAdmin
    .from('marketplace_interests')
    .delete()
    .eq('listing_id', listingId)
    .eq('buyer_id', userId);

  if (error) throw httpError(500, error.message, 'db_error');
  return { listing_id: listingId };
}

// ── Bump listing ──────────────────────────────────────────────────────────────

/** Xem tin của 1 seller cụ thể (seller profile page) */
async function browseByOwner(sellerId) {
  const { data, error } = await supabaseAdmin
    .from('marketplace_listings')
    .select(`
      id, title, description, category, condition, area,
      price, images, status, created_at,
      profiles:owner_id ( id, full_name, avatar_url )
    `)
    .eq('owner_id', sellerId)
    .in('status', ['active', 'reserved'])
    .order('created_at', { ascending: false });

  if (error) throw httpError(500, error.message, 'db_error');
  return data || [];
}

/** Đẩy tin lên đầu (1 lần / 24h) */
async function bumpListing(listingId, userId) {
  const { data: listing } = await supabaseAdmin
    .from('marketplace_listings')
    .select('id, owner_id, status, bumped_at')
    .eq('id', listingId)
    .single();

  if (!listing) throw httpError(404, 'Không tìm thấy tin', 'not_found');
  if (listing.owner_id !== userId) throw httpError(403, 'Chỉ người đăng mới đẩy được tin', 'forbidden');
  if (!['active', 'reserved'].includes(listing.status)) throw httpError(400, 'Chỉ đẩy được tin đang mở hoặc đang giữ', 'invalid_status');

  // Giới hạn 1 lần bump / 24h
  if (listing.bumped_at) {
    const hoursSince = (Date.now() - new Date(listing.bumped_at).getTime()) / 3_600_000;
    if (hoursSince < 24) {
      const hoursLeft = Math.ceil(24 - hoursSince);
      throw httpError(429, `Bạn chỉ được đẩy tin 1 lần / 24h. Còn ${hoursLeft} giờ nữa.`, 'too_many_requests');
    }
  }

  const now = new Date().toISOString();
  const { error } = await supabaseAdmin
    .from('marketplace_listings')
    .update({ created_at: now, bumped_at: now })
    .eq('id', listingId);

  if (error) throw httpError(500, error.message, 'db_error');
  return { listing_id: listingId, bumped_at: now };
}

// ── UX Improvements ──────────────────────────────────────────────────────────

/** POST /api/marketplace/listings/:id/confirm-received */
async function confirmReceived(listingId, buyerId) {
  const { data: listing } = await supabaseAdmin
    .from('marketplace_listings')
    .select('id, owner_id, confirmed_buyer_id, transport_booked, status')
    .eq('id', listingId)
    .single();

  if (!listing) throw httpError(404, 'Không tìm thấy tin', 'not_found');
  if (listing.confirmed_buyer_id !== buyerId) throw httpError(403, 'Chỉ người được chốt mới xác nhận được', 'forbidden');
  if (!listing.transport_booked) throw httpError(400, 'Chưa đặt xe', 'transport_not_booked');
  if (listing.status === 'closed') throw httpError(400, 'Tin đã đóng', 'already_closed');

  const { data: updated, error } = await supabaseAdmin
    .from('marketplace_listings')
    .update({ status: 'closed' })
    .eq('id', listingId)
    .select('id, status')
    .single();

  if (error) throw httpError(500, error.message, 'db_error');

  createNotification(listing.owner_id, 'marketplace_item_received',
    '✅ Người mua đã xác nhận nhận đồ!',
    'Giao dịch hoàn tất. Hãy để người mua đánh giá bạn.',
    { listingId, actionData: { listing_id: listingId, buyer_id: buyerId }, priority: 'high' },
  );

  return updated;
}

/** POST /api/marketplace/listings/:id/rating */
async function createRating(listingId, buyerId, body) {
  const { rating, comment } = body || {};

  if (!rating || isNaN(Number(rating)) || Number(rating) < 1 || Number(rating) > 5) {
    throw httpError(400, 'rating phải là số từ 1 đến 5', 'validation_error');
  }

  const { data: listing } = await supabaseAdmin
    .from('marketplace_listings')
    .select('id, owner_id, confirmed_buyer_id, status')
    .eq('id', listingId)
    .single();

  if (!listing) throw httpError(404, 'Không tìm thấy tin', 'not_found');
  if (listing.confirmed_buyer_id !== buyerId) throw httpError(403, 'Chỉ người mua mới đánh giá được', 'forbidden');
  if (listing.status !== 'closed') throw httpError(400, 'Tin chưa hoàn tất giao dịch', 'not_closed');

  const { data, error } = await supabaseAdmin
    .from('marketplace_ratings')
    .insert([{
      listing_id: listingId,
      buyer_id:   buyerId,
      seller_id:  listing.owner_id,
      rating:     Number(rating),
      comment:    comment ? String(comment).trim() : null,
    }])
    .select('id, rating, comment, created_at')
    .single();

  if (error) {
    if (error.code === '23505') throw httpError(400, 'Bạn đã đánh giá giao dịch này rồi', 'already_rated');
    throw httpError(500, error.message, 'db_error');
  }

  return data;
}

/** GET /api/marketplace/seller/:sellerId/stats */
async function getSellerStats(sellerId) {
  const { data, error } = await supabaseAdmin
    .from('marketplace_ratings')
    .select('rating')
    .eq('seller_id', sellerId);

  if (error) throw httpError(500, error.message, 'db_error');

  const ratings = (data || []).map(r => r.rating);
  const review_count = ratings.length;
  const avg_rating = review_count > 0
    ? Math.round((ratings.reduce((a, b) => a + b, 0) / review_count) * 10) / 10
    : null;

  return { seller_id: sellerId, avg_rating, review_count };
}

/** API-072 — POST /api/marketplace/listings/images (Supabase Storage) */
async function uploadListingImage(userId, file) {
  if (!file?.buffer?.length) {
    throw httpError(400, 'Thiếu file ảnh (field: image)', 'validation_error');
  }

  const ext = EXT_BY_MIME[file.mimetype];
  if (!ext) {
    throw httpError(400, 'Chỉ chấp nhận ảnh JPG hoặc PNG', 'invalid_file_type');
  }

  const objectPath = `${userId}/${Date.now()}-${Math.random().toString(36).slice(2, 10)}.${ext}`;

  try {
    await ensurePublicImageBucket(MARKETPLACE_IMAGES_BUCKET, {
      fileSizeLimit: 5242880,
      allowedMimeTypes: ['image/jpeg', 'image/png'],
    });
  } catch (bucketError) {
    throw httpError(
      500,
      `Không tạo được bucket ${MARKETPLACE_IMAGES_BUCKET}: ${bucketError.message}`,
      'storage_bucket_missing',
    );
  }

  const { error: uploadError } = await supabaseAdmin.storage
    .from(MARKETPLACE_IMAGES_BUCKET)
    .upload(objectPath, file.buffer, {
      contentType: file.mimetype,
      upsert: false,
      cacheControl: '3600',
    });

  if (uploadError) {
    throw httpError(500, uploadError.message, 'storage_error');
  }

  const { data: urlData } = supabaseAdmin.storage
    .from(MARKETPLACE_IMAGES_BUCKET)
    .getPublicUrl(objectPath);
  const url = urlData?.publicUrl;
  if (!url) throw httpError(500, 'Không tạo được URL ảnh', 'storage_error');

  return { url };
}

module.exports = {
  createListing, browseListings, getMyListings,
  getListing, updateListingStatus, expressInterest, removeInterest,
  getInterestedBuyers, getMessages, sendMessage,
  confirmDeal, cancelDeal, markTransportBooked,
  getMyInterests, browseByOwner, bumpListing,
  confirmReceived, createRating, getSellerStats,
  uploadListingImage,
};
