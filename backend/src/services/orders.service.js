const { supabaseAdmin } = require('./supabase.service');

function splitAddress(raw) {
  const address = String(raw || '').trim() || 'Chưa nhập địa chỉ';
  return { address, city: 'TP.HCM', district: 'Quận 1' };
}

function defaultVehicleSize(serviceType) {
  if (serviceType === 'premium') return 'large_truck';
  if (serviceType === 'express') return 'medium_truck';
  return 'small_truck';
}

function defaultPricing(serviceType, floorNumber) {
  const baseByType = { standard: 500000, express: 800000, premium: 1200000 };
  const basePrice = baseByType[serviceType] || 500000;
  const floorPrice = Math.max(0, Number(floorNumber) || 0) * 50000;
  return {
    base_price: basePrice,
    distance_price: 0,
    floor_price: floorPrice,
    service_fee: 0,
    total_price: basePrice + floorPrice,
  };
}

async function listOrdersForUser(userId, role, queryParams = {}) {
  let query = supabaseAdmin.from('orders').select('*').order('created_at', { ascending: false });

  if (role === 'customer') {
    query = query.eq('customer_id', userId);
  } else if (role === 'provider') {
    query = query.or(`provider_id.eq.${userId},status.eq.pending,status.eq.matched`);
  }

  const { status } = queryParams;
  if (status) {
    const statuses = String(status).split(',').map((s) => s.trim()).filter(Boolean);
    if (statuses.length === 1) {
      query = query.eq('status', statuses[0]);
    } else if (statuses.length > 1) {
      query = query.in('status', statuses);
    }
  }

  const { data, error } = await query;
  if (error) throw Object.assign(new Error(error.message), { status: 400 });
  return data;
}

async function createOrder(customerId, payload) {
  const body = payload || {};

  const { data: profile } = await supabaseAdmin
    .from('profiles')
    .select('full_name, phone')
    .eq('id', customerId)
    .single();

  const contactName = body.pickup_contact_name || profile?.full_name || 'Khách hàng';
  const contactPhone = body.pickup_contact_phone || profile?.phone || '+84900000000';
  const serviceType = body.service_type || 'standard';
  const pickup = splitAddress(body.pickup_address);
  const delivery = splitAddress(body.delivery_address || body.dropoff_address);
  const floor = body.pickup_floor ?? body.floor_number ?? 1;

  const pricing = body.base_price != null && body.total_price != null
    ? {
        base_price: body.base_price,
        distance_price: body.distance_price || 0,
        floor_price: body.floor_price || 0,
        service_fee: body.service_fee || 0,
        total_price: body.total_price,
      }
    : defaultPricing(serviceType, floor);

  const notes = [body.description, body.special_notes, body.pickup_notes]
    .filter(Boolean)
    .map(String)
    .join('\n');

  const { data, error } = await supabaseAdmin
    .from('orders')
    .insert({
      customer_id: customerId,
      vehicle_size: body.vehicle_size || defaultVehicleSize(serviceType),
      service_type: serviceType,
      pickup_address: pickup.address,
      pickup_city: body.pickup_city || pickup.city,
      pickup_district: body.pickup_district || pickup.district,
      pickup_floor: floor,
      pickup_contact_name: contactName,
      pickup_contact_phone: contactPhone,
      pickup_notes: notes || null,
      delivery_address: delivery.address,
      delivery_city: body.delivery_city || delivery.city,
      delivery_district: body.delivery_district || delivery.district,
      delivery_contact_name: body.delivery_contact_name || contactName,
      delivery_contact_phone: body.delivery_contact_phone || contactPhone,
      delivery_notes: body.delivery_notes || null,
      base_price: pricing.base_price,
      distance_price: pricing.distance_price,
      floor_price: pricing.floor_price,
      service_fee: pricing.service_fee,
      total_price: pricing.total_price,
      scheduled_pickup_time: body.scheduled_pickup_time,
      number_of_rooms: body.number_of_rooms || 1,
      number_of_helpers: body.number_of_helpers ?? body.num_helpers ?? 0,
      status: 'pending',
    })
    .select('*')
    .single();

  if (error) throw Object.assign(new Error(error.message), { status: 400 });
  return data;
}

async function providerRespond(orderId, providerId, response, declineReason) {
  const { error: responseError } = await supabaseAdmin.from('order_provider_responses').insert({
    order_id: orderId,
    provider_id: providerId,
    response,
    decline_reason: declineReason || null,
  });

  if (responseError) throw Object.assign(new Error(responseError.message), { status: 400 });

  if (response === 'accepted') {
    const { data, error } = await supabaseAdmin
      .from('orders')
      .update({
        provider_id: providerId,
        status: 'accepted',
        provider_accepted_at: new Date().toISOString(),
      })
      .eq('id', orderId)
      .select('*')
      .single();

    if (error) throw Object.assign(new Error(error.message), { status: 400 });
    return data;
  }

  return { order_id: orderId, response };
}

async function getOrderById(orderId) {
  const { data, error } = await supabaseAdmin.from('orders').select('*').eq('id', orderId).single();
  if (error) throw Object.assign(new Error(error.message), { status: 404 });
  return data;
}

module.exports = {
  listOrdersForUser,
  createOrder,
  providerRespond,
  getOrderById,
};
