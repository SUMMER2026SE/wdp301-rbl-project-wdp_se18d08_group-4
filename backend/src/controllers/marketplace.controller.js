const marketplaceService = require('../services/marketplace.service');
const { httpError } = require('../services/auth.helpers');

// ── Batch 1 ──────────────────────────────────────────────────────────────────

/** API-062 — POST /api/marketplace/listings */
async function createListing(req, res, next) {
  try {
    const data = await marketplaceService.createListing(req.user.id, req.body);
    res.status(201).json({ success: true, data });
  } catch (error) { next(error); }
}

/** API-059 — GET /api/marketplace/listings */
async function browseListings(req, res, next) {
  try {
    const data = await marketplaceService.browseListings(req.query, req.user.id);
    res.json({ success: true, ...data });
  } catch (error) { next(error); }
}

/** API-060 — GET /api/marketplace/my-listings */
async function getMyListings(req, res, next) {
  try {
    const data = await marketplaceService.getMyListings(req.user.id, req.query);
    res.json({ success: true, ...data });
  } catch (error) { next(error); }
}

// ── Batch 2 ──────────────────────────────────────────────────────────────────

/** API-061 — GET /api/marketplace/listings/:id */
async function getListing(req, res, next) {
  try {
    const data = await marketplaceService.getListing(req.params.id, req.user.id);
    res.json({ success: true, data });
  } catch (error) { next(error); }
}

/** API-064 — PATCH /api/marketplace/listings/:id/status */
async function updateListingStatus(req, res, next) {
  try {
    const data = await marketplaceService.updateListingStatus(req.params.id, req.user.id, req.body.status);
    res.json({ success: true, data });
  } catch (error) { next(error); }
}

/** API-065 — POST /api/marketplace/listings/:id/interest */
async function expressInterest(req, res, next) {
  try {
    const data = await marketplaceService.expressInterest(req.params.id, req.user.id, req.body);
    res.json({ success: true, data });
  } catch (error) { next(error); }
}

/** API-065b — DELETE /api/marketplace/listings/:id/interest */
async function removeInterest(req, res, next) {
  try {
    const data = await marketplaceService.removeInterest(req.params.id, req.user.id);
    res.json({ success: true, data });
  } catch (error) { next(error); }
}

// ── Batch 3 ──────────────────────────────────────────────────────────────────

/** API-066 — GET /api/marketplace/listings/:id/interests */
async function getInterestedBuyers(req, res, next) {
  try {
    const data = await marketplaceService.getInterestedBuyers(req.params.id, req.user.id);
    res.json({ success: true, data });
  } catch (error) { next(error); }
}

/** API-067 — GET /api/marketplace/listings/:listingId/conversations/:buyerId/messages */
async function getMessages(req, res, next) {
  try {
    const data = await marketplaceService.getMessages(req.params.listingId, req.params.buyerId, req.user.id);
    res.json({ success: true, data });
  } catch (error) { next(error); }
}

/** API-068 — POST /api/marketplace/listings/:listingId/conversations/:buyerId/messages */
async function sendMessage(req, res, next) {
  try {
    const data = await marketplaceService.sendMessage(req.params.listingId, req.params.buyerId, req.user.id, req.body);
    res.status(201).json({ success: true, data });
  } catch (error) { next(error); }
}

// ── Batch 4 ──────────────────────────────────────────────────────────────────

/** API-069 — POST /api/marketplace/listings/:listingId/conversations/:buyerId/deal */
async function confirmDeal(req, res, next) {
  try {
    const data = await marketplaceService.confirmDeal(req.params.listingId, req.user.id, req.params.buyerId, req.body);
    res.json({ success: true, data });
  } catch (error) { next(error); }
}

/** API-070 — DELETE /api/marketplace/listings/:listingId/deal */
async function cancelDeal(req, res, next) {
  try {
    const data = await marketplaceService.cancelDeal(req.params.listingId, req.user.id);
    res.json({ success: true, data });
  } catch (error) { next(error); }
}

/** API-071 — POST /api/marketplace/listings/:listingId/transport-booked */
async function markTransportBooked(req, res, next) {
  try {
    const data = await marketplaceService.markTransportBooked(req.params.listingId, req.user.id);
    res.json({ success: true, data });
  } catch (error) { next(error); }
}

// ── Batch 5 ──────────────────────────────────────────────────────────────────

/** GET /api/marketplace/my-interests */
async function getMyInterests(req, res, next) {
  try {
    const data = await marketplaceService.getMyInterests(req.user.id);
    res.json({ success: true, ...data });
  } catch (error) { next(error); }
}

/** POST /api/marketplace/listings/:id/bump */
async function bumpListing(req, res, next) {
  try {
    const data = await marketplaceService.bumpListing(req.params.id, req.user.id);
    res.json({ success: true, data });
  } catch (error) { next(error); }
}

/** POST /api/marketplace/listings/:id/rating */
async function createRating(req, res, next) {
  try {
    const data = await marketplaceService.createRating(req.params.id, req.user.id, req.body);
    res.json({ success: true, data });
  } catch (error) { next(error); }
}

/** GET /api/marketplace/seller/:sellerId/stats */
async function getSellerStats(req, res, next) {
  try {
    const data = await marketplaceService.getSellerStats(req.params.sellerId);
    res.json({ success: true, data });
  } catch (error) { next(error); }
}

// ── UX Improvements ──────────────────────────────────────────────────────────

/** POST /api/marketplace/listings/:id/confirm-received */
async function confirmReceived(req, res, next) {
  try {
    const data = await marketplaceService.confirmReceived(req.params.id, req.user.id);
    res.json({ success: true, data });
  } catch (error) { next(error); }
}

/** API-072 — POST /api/marketplace/listings/images */
async function uploadListingImage(req, res, next) {
  try {
    if (!req.file) {
      return next(httpError(400, 'Không có file được upload (field: image)', 'missing_file'));
    }
    const data = await marketplaceService.uploadListingImage(req.user.id, req.file);
    res.json({ success: true, data });
  } catch (error) { next(error); }
}

module.exports = {
  createListing, browseListings, getMyListings,
  getListing, updateListingStatus, expressInterest, removeInterest,
  getInterestedBuyers, getMessages, sendMessage,
  confirmDeal, cancelDeal, markTransportBooked,
  getMyInterests, bumpListing, createRating, getSellerStats,
  confirmReceived, uploadListingImage,
};
