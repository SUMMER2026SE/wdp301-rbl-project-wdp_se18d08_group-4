const providersService = require('../services/providers.service');

// ── Customer-facing ───────────────────────────────────────────────────────────

async function browse(req, res, next) {
  try {
    const providers = await providersService.browseProviders({
      city: req.query.city,
      minRating: req.query.min_rating ? parseFloat(req.query.min_rating) : undefined,
      limit: req.query.limit ? parseInt(req.query.limit, 10) : 20,
    });
    res.json({ success: true, data: providers });
  } catch (error) {
    next(error);
  }
}

// ── Provider self-service ─────────────────────────────────────────────────────

async function getMe(req, res, next) {
  try {
    const profile = await providersService.getMyProfile(req.user.id);
    res.json({ success: true, data: profile });
  } catch (error) {
    next(error);
  }
}

async function updateMe(req, res, next) {
  try {
    const allowed = ['full_name', 'phone', 'business_name', 'vehicle_type', 'base_price', 'price_per_km', 'service_area'];
    const payload = {};
    for (const key of allowed) {
      if (req.body[key] !== undefined) payload[key] = req.body[key];
    }
    const profile = await providersService.updateMyProfile(req.user.id, payload);
    res.json({ success: true, data: profile });
  } catch (error) {
    next(error);
  }
}

async function setStatus(req, res, next) {
  try {
    const { is_available } = req.body;
    if (typeof is_available !== 'boolean') {
      return res.status(400).json({ success: false, message: 'is_available phải là boolean' });
    }
    const result = await providersService.setOnlineStatus(req.user.id, is_available);
    res.json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
}

// ── Documents ─────────────────────────────────────────────────────────────────

async function uploadDocument(req, res, next) {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: 'Vui lòng chọn file ảnh' });
    }
    const { doc_type } = req.body;
    if (!doc_type) {
      return res.status(400).json({ success: false, message: 'Thiếu doc_type' });
    }
    const result = await providersService.uploadDocument(req.user.id, doc_type, req.file.buffer);
    res.json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
}

async function getDocuments(req, res, next) {
  try {
    const docs = await providersService.getDocuments(req.user.id);
    res.json({ success: true, data: docs });
  } catch (error) {
    next(error);
  }
}

module.exports = { browse, getMe, updateMe, setStatus, uploadDocument, getDocuments };
