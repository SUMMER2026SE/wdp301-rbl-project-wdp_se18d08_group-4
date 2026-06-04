/**
 * BE-021 — Gói combo chuyển trọ (marketplace).
 */
const express = require('express');
const servicePackagesController = require('../controllers/service-packages.controller');
const { requireAuth, requireRole } = require('../middleware/auth.middleware');

const router = express.Router();

router.get(
  '/',
  requireAuth,
  requireRole('customer'),
  servicePackagesController.list,
);

module.exports = router;
