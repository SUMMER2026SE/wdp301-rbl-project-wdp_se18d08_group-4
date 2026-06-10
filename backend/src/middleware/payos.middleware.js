const crypto = require('crypto');
const env = require('../config/env');

/**
 * Middleware to verify PayOS webhook signature
 * PayOS sử dụng HMAC-SHA256 để sign webhook payload
 * 
 * Headers:
 * - x-payos-signature: HMAC-SHA256(body, secret)
 */
function verifyPayOSSignature(req, res, next) {
  try {
    // Get signature from header
    const signature = req.headers['x-payos-signature'];
    if (!signature) {
      return res.status(401).json({
        success: false,
        message: 'Missing PayOS signature header',
        code: 'missing_signature',
      });
    }

    // Get raw body (must be string/Buffer for HMAC)
    const rawBody = req.rawBody || JSON.stringify(req.body);

    // Get PayOS secret from env
    const payosSecret = env.PAYOS_CHECKSUM_KEY || env.PAYOS_SECRET;
    if (!payosSecret) {
      console.error('PAYOS_CHECKSUM_KEY or PAYOS_SECRET not configured');
      return res.status(500).json({
        success: false,
        message: 'PayOS configuration error',
        code: 'config_error',
      });
    }

    // Compute HMAC-SHA256
    const computedSignature = crypto
      .createHmac('sha256', payosSecret)
      .update(rawBody)
      .digest('hex');

    // Compare signatures (timing-safe comparison)
    const isValid = crypto.timingSafeEqual(
      Buffer.from(signature),
      Buffer.from(computedSignature)
    ).valueOf();

    if (!isValid) {
      console.warn('PayOS signature verification failed', {
        expected: computedSignature,
        received: signature,
      });
      return res.status(401).json({
        success: false,
        message: 'Invalid PayOS signature',
        code: 'invalid_signature',
      });
    }

    // Signature verified
    req.payosVerified = true;
    next();
  } catch (error) {
    console.error('PayOS signature verification error:', error);
    res.status(500).json({
      success: false,
      message: 'Signature verification error',
      code: 'verification_error',
    });
  }
}

module.exports = { verifyPayOSSignature };
