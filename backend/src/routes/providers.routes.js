const express = require('express');
const providersController = require('../controllers/providers.controller');
const { requireAuth, requireRole } = require('../middleware/auth.middleware');
const { upload } = require('../middleware/upload.middleware');

const router = express.Router();

// Customer-facing
router.get('/browse', providersController.browse);

// Provider self-service
router.get('/me', requireAuth, requireRole('provider'), providersController.getMe);
router.patch('/me', requireAuth, requireRole('provider'), providersController.updateMe);
router.patch('/me/status', requireAuth, requireRole('provider'), providersController.setStatus);

// Documents (multipart)
router.get('/me/documents', requireAuth, requireRole('provider'), providersController.getDocuments);
router.post('/me/documents', requireAuth, requireRole('provider'), upload.single('file'), providersController.uploadDocument);

module.exports = router;
