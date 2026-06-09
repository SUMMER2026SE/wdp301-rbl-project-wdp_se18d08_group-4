const express = require('express');
const providersController = require('../controllers/providers.controller');
const { requireAuth, requireRole } = require('../middleware/auth.middleware');
const { handleDocumentUpload } = require('../middleware/upload.middleware');

const router = express.Router();

// Shared
router.get('/browse', providersController.browse);

// Provider self-service — /me* must come before /:id
router.get('/me', requireAuth, requireRole('provider'), providersController.getMe);
router.patch('/me', requireAuth, requireRole('provider'), providersController.updateMe);
router.patch('/me/status', requireAuth, requireRole('provider'), providersController.setStatus);
router.get('/me/documents', requireAuth, requireRole('provider'), providersController.getDocuments);
router.post('/me/documents', requireAuth, requireRole('provider'), handleDocumentUpload, providersController.uploadDocument);

// Customer-facing — /:id must be last
router.get('/:id', requireAuth, requireRole('customer'), providersController.getById);

module.exports = router;
