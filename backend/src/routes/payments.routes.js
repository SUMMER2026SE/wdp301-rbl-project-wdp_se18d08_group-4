const express = require('express');
const paymentsController = require('../controllers/payments.controller');
const { requireAuth, requireRole } = require('../middleware/auth.middleware');

const router = express.Router();

// Wallet APIs (BE-034)
router.get('/me/wallet', requireAuth, requireRole('customer'), paymentsController.getWallet);

// Payment Methods APIs (BE-036)
router.get('/me/payment-methods', requireAuth, requireRole('customer'), paymentsController.getPaymentMethods);
router.post('/me/payment-methods', requireAuth, requireRole('customer'), paymentsController.addPaymentMethod);
router.patch('/me/payment-methods/:id', requireAuth, requireRole('customer'), paymentsController.updatePaymentMethod);
router.delete('/me/payment-methods/:id', requireAuth, requireRole('customer'), paymentsController.deletePaymentMethod);

// Payment APIs
router.get('/me', requireAuth, requireRole('customer'), paymentsController.getPayments);
router.get('/me/:id', requireAuth, requireRole('customer'), paymentsController.getPayment);
router.post('/deposit', requireAuth, requireRole('customer'), paymentsController.createDeposit);

module.exports = router;
