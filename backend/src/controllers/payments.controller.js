const { supabaseAdmin } = require('../services/supabase.service');
const paymentsService = require('../services/payments.service');
const payosService = require('../services/payos.service');
const env = require('../config/env');
const { httpError } = require('../services/auth.helpers');

/** BE-034: GET /api/customers/me/wallet */
async function getWallet(req, res, next) {
  try {
    const data = await paymentsService.getWalletBalance(req.user.id);
    res.json({ success: true, data });
  } catch (error) {
    next(error);
  }
}

/** BE-036: GET /api/customers/me/payment-methods */
async function getPaymentMethods(req, res, next) {
  try {
    const data = await paymentsService.getPaymentMethods(req.user.id);
    res.json({ success: true, data });
  } catch (error) {
    next(error);
  }
}

/** BE-036: POST /api/customers/me/payment-methods */
async function addPaymentMethod(req, res, next) {
  try {
    const data = await paymentsService.addPaymentMethod(req.user.id, req.body || {});
    res.status(201).json({ success: true, data });
  } catch (error) {
    next(error);
  }
}

/** BE-036: PATCH /api/customers/me/payment-methods/:id */
async function updatePaymentMethod(req, res, next) {
  try {
    const { id } = req.params;
    if (!id) {
      return next(httpError(400, 'Thiếu payment method ID', 'missing_id'));
    }
    const data = await paymentsService.updatePaymentMethod(req.user.id, id, req.body || {});
    res.json({ success: true, data });
  } catch (error) {
    next(error);
  }
}

/** BE-036: DELETE /api/customers/me/payment-methods/:id */
async function deletePaymentMethod(req, res, next) {
  try {
    const { id } = req.params;
    if (!id) {
      return next(httpError(400, 'Thiếu payment method ID', 'missing_id'));
    }
    const result = await paymentsService.deletePaymentMethod(req.user.id, id);
    res.json({ success: true, message: 'Đã xóa phương thức thanh toán' });
  } catch (error) {
    next(error);
  }
}

/** GET /api/customers/me/payments — Lấy danh sách payments của customer */
async function getPayments(req, res, next) {
  try {
    const { data, error } = await supabaseAdmin
      .from('payments')
      .select('id, payment_code, order_id, amount, currency, status, escrow_status, payos_qr_code, created_at, paid_at')
      .eq('customer_id', req.user.id)
      .order('created_at', { ascending: false })
      .limit(50);

    if (error) throw httpError(500, error.message, 'db_error');

    res.json({ success: true, data: data || [] });
  } catch (error) {
    next(error);
  }
}

/** GET /api/customers/me/payments/:id — Lấy chi tiết một payment */
async function getPayment(req, res, next) {
  try {
    const { id } = req.params;

    if (!id) {
      return next(httpError(400, 'Thiếu payment ID', 'missing_id'));
    }

    const { data: payment, error } = await supabaseAdmin
      .from('payments')
      .select('*')
      .eq('id', id)
      .eq('customer_id', req.user.id)
      .single();

    if (error || !payment) {
      return next(httpError(404, 'Không tìm thấy payment', 'payment_not_found'));
    }

    res.json({ success: true, data: payment });
  } catch (error) {
    next(error);
  }
}

/** BE-032: POST /api/customers/me/payments/deposit — Tạo deposit payment với PayOS QR code */
async function createDeposit(req, res, next) {
  try {
    const { order_id, amount, payment_method = 'payos', customer_name, customer_email } = req.body;

    // Validation
    if (!order_id || !amount) {
      return next(httpError(400, 'Thiếu order_id hoặc amount', 'validation_error'));
    }

    if (amount <= 0) {
      return next(httpError(400, 'Số tiền phải lớn hơn 0', 'invalid_amount'));
    }

    if (payment_method !== 'payos') {
      return next(httpError(400, 'Hiện chỉ hỗ trợ thanh toán PayOS', 'unsupported_payment_method'));
    }

    // Get order details to verify it exists and belongs to user
    const { data: order, error: orderError } = await supabaseAdmin
      .from('orders')
      .select('id, customer_id, service_type')
      .eq('id', order_id)
      .single();

    if (orderError || !order) {
      return next(httpError(404, 'Không tìm thấy đơn hàng', 'order_not_found'));
    }

    if (order.customer_id !== req.user.id) {
      return next(httpError(403, 'Không có quyền truy cập đơn hàng này', 'access_denied'));
    }

    // Generate payment code and order code
    const paymentCode = payosService.generatePaymentCode();
    const orderCode = payosService.generateOrderCode();

    // Create payment record in DB (status: pending)
    const { data: paymentRecord, error: insertError } = await supabaseAdmin
      .from('payments')
      .insert({
        payment_code: paymentCode,
        order_id,
        customer_id: req.user.id,
        amount,
        currency: 'VND',
        payment_method,
        status: 'pending',
        escrow_status: 'pending',
        payment_purpose: 'deposit',
        description: `Deposit cho đơn chuyển trọ #${order_id.substring(0, 8)}`,
      })
      .select('*')
      .single();

    if (insertError) {
      console.error('Payment insert error:', insertError);
      return next(httpError(500, 'Lỗi tạo payment record', 'db_error'));
    }

    // Call PayOS API to create payment link
    const payosPayload = {
      paymentCode,
      amount: Math.round(amount),
      orderCode: parseInt(orderCode, 10),
      // PayOS: description ngắn, không dấu (giới hạn ký tự trên VietQR)
      description: paymentCode,
      returnUrl: `${env.APP_URL}/payment-success?payment_code=${paymentCode}`,
      cancelUrl: `${env.APP_URL}/payment-cancel?payment_code=${paymentCode}`,
      customerName: customer_name || req.user.name || 'Customer',
      customerEmail: customer_email || req.user.email || 'noreply@unimove.com',
    };

    const payosResponse = await payosService.createPaymentLink(payosPayload);

    // Update payment record with PayOS details
    const { error: updateError } = await supabaseAdmin
      .from('payments')
      .update({
        payos_order_id: payosResponse.orderCode.toString(),
        payos_payment_url: payosResponse.checkoutUrl,
        payos_qr_code: payosResponse.qrCode,
        expires_at: payosResponse.expiresAt.toISOString(),
      })
      .eq('id', paymentRecord.id);

    if (updateError) {
      console.error('Payment update error:', updateError);
      return next(httpError(500, 'Lỗi cập nhật payment details', 'db_error'));
    }

    // Return payment link and QR code to client
    res.status(201).json({
      success: true,
      data: {
        payment_id: paymentRecord.id,
        payment_code: paymentCode,
        order_id,
        amount,
        currency: 'VND',
        status: 'pending',
        // Payment links
        checkout_url: payosResponse.checkoutUrl,
        qr_code: payosResponse.qrCode,
        qr_code_data_url: payosResponse.qrCode, // For displaying QR
        // Bank transfer details (for manual payment)
        bank_account_number: payosResponse.accountNumber,
        bank_account_name: payosResponse.accountName,
        // Timing
        expires_at: payosResponse.expiresAt,
        created_at: new Date().toISOString(),
      },
      message: 'Tạo link thanh toán thành công. Quét mã QR để thanh toán.',
    });
  } catch (error) {
    next(error);
  }
}

/** BE-029: Webhook PayOS — xác nhận thanh toán */
async function payosWebhook(req, res, next) {
  try {
    const { code, desc, data } = req.body;

    /**
     * PayOS webhook response format:
     * {
     *   code: "00",  // "00" = success, other = error
     *   desc: "success description",
     *   data: {
     *     orderCode: 123456,
     *     amount: 1000000,
     *     amountPaid: 1000000,
     *     amountRemaining: 0,
     *     status: "PAID",  // "PAID", "CANCELLED", "EXPIRED"
     *     transactions: [{
     *       paymentLinkId: "...",
     *       amount: 1000000,
     *       accountNumber: "...",
     *       reference: "...",
     *       transactionDateTime: "2026-06-06T10:30:00Z",
     *       paymentMethodType: "BANK_TRANSFER"
     *     }],
     *     cancellationReason: null,
     *     reference: "PAY-20260606-0001"  // Our payment code
     *   }
     * }
     */

    // Validate webhook structure
    if (!data || !data.reference) {
      console.warn('PayOS webhook: missing required fields', req.body);
      return res.status(400).json({
        success: false,
        message: 'Invalid webhook payload',
        code: 'invalid_payload',
      });
    }

    const paymentCode = data.reference; // Our payment_code: PAY-YYYYMMDD-XXXX
    const payosStatus = data.status; // PAID, CANCELLED, EXPIRED
    const payosOrderCode = data.orderCode;
    const amountPaid = data.amountPaid || 0;

    // Find payment by payment_code
    const { data: payment, error: findError } = await supabaseAdmin
      .from('payments')
      .select('id, customer_id, order_id, amount, status')
      .eq('payment_code', paymentCode)
      .single();

    if (findError || !payment) {
      console.warn('PayOS webhook: payment not found', { paymentCode });
      // Still return 200 to acknowledge webhook (PayOS requirement)
      return res.json({
        success: true,
        message: 'Webhook acknowledged (payment not found - may be already processed)',
      });
    }

    // Check if payment already completed
    if (payment.status === 'completed' || payment.status === 'refunded') {
      console.log('PayOS webhook: payment already processed', { paymentCode, status: payment.status });
      return res.json({
        success: true,
        message: 'Webhook acknowledged (payment already processed)',
      });
    }

    // Determine new payment status based on PayOS status
    let newStatus = 'failed';
    let failureReason = null;

    switch (payosStatus) {
      case 'PAID':
        newStatus = 'completed';
        break;
      case 'CANCELLED':
        newStatus = 'cancelled';
        failureReason = 'Customer cancelled payment';
        break;
      case 'EXPIRED':
        newStatus = 'failed';
        failureReason = 'Payment link expired';
        break;
      default:
        newStatus = 'failed';
        failureReason = `Unknown PayOS status: ${payosStatus}`;
    }

    // Amount validation
    if (newStatus === 'completed' && amountPaid < payment.amount) {
      console.warn('PayOS webhook: insufficient amount paid', {
        expected: payment.amount,
        paid: amountPaid,
      });
      newStatus = 'failed';
      failureReason = `Insufficient amount. Expected: ${payment.amount}, Paid: ${amountPaid}`;
    }

    // Update payment record
    const updatePayload = {
      status: newStatus,
      payos_order_id: payosOrderCode,
      payos_transaction_id: data.transactions?.[0]?.transactionDateTime,
    };

    if (failureReason) {
      updatePayload.failure_reason = failureReason;
    }

    if (newStatus === 'completed') {
      updatePayload.paid_at = new Date().toISOString();
      // Set escrow_status to 'held' for deposit
      // (will be 'released' when customer confirms completion)
      updatePayload.escrow_status = 'held';
    }

    const { error: updateError } = await supabaseAdmin
      .from('payments')
      .update(updatePayload)
      .eq('id', payment.id);

    if (updateError) {
      console.error('PayOS webhook: failed to update payment', updateError);
      // Still return 200 to acknowledge webhook
      return res.json({
        success: true,
        message: 'Webhook acknowledged (but failed to update DB)',
      });
    }

    // Log webhook receipt
    console.log('PayOS webhook: processed successfully', {
      paymentCode,
      status: newStatus,
      amount: payment.amount,
      customerId: payment.customer_id,
    });

    // DB triggers will automatically:
    // 1. update_wallet_on_payment_completed() → update wallet balance
    // 2. create_provider_earnings_trigger() → create provider_earnings record

    // Acknowledge webhook (PayOS requires 200 OK within timeout)
    res.json({
      success: true,
      message: 'Webhook processed successfully',
      data: {
        paymentCode,
        newStatus,
      },
    });
  } catch (error) {
    console.error('PayOS webhook error:', error);
    // Return 200 anyway to prevent webhook retry storms
    res.json({
      success: false,
      message: 'Webhook processing error',
      error: error.message,
    });
  }
}

module.exports = {
  getWallet,
  getPaymentMethods,
  addPaymentMethod,
  updatePaymentMethod,
  deletePaymentMethod,
  getPayments,
  getPayment,
  createDeposit,
  payosWebhook,
};
