const { supabaseAdmin } = require('../services/supabase.service');
const ordersService = require('../services/orders.service');

async function listOrders(req, res, next) {
  try {
    const { data: profile } = await supabaseAdmin
      .from('profiles')
      .select('role')
      .eq('id', req.user.id)
      .single();

    const orders = await ordersService.listOrdersForUser(
      req.user.id,
      profile?.role || req.user.role || 'customer',
      req.query,
    );

    res.json({ success: true, data: orders });
  } catch (error) {
    next(error);
  }
}

async function createOrder(req, res, next) {
  try {
    const order = await ordersService.createOrder(req.user.id, req.body);
    res.status(201).json({ success: true, data: order });
  } catch (error) {
    next(error);
  }
}

async function getOrder(req, res, next) {
  try {
    const order = await ordersService.getOrderById(req.params.id);
    res.json({ success: true, data: order });
  } catch (error) {
    next(error);
  }
}

async function respondToOrder(req, res, next) {
  try {
    const { response, decline_reason } = req.body;
    if (!['accepted', 'declined'].includes(response)) {
      return res.status(400).json({ success: false, message: 'response phải là accepted hoặc declined' });
    }

    const result = await ordersService.providerRespond(
      req.params.id,
      req.user.id,
      response,
      decline_reason,
    );

    res.json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
}

module.exports = { listOrders, createOrder, getOrder, respondToOrder };
