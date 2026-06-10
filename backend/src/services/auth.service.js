/**
 * Auth — Node JWT (register/login/me/change-password) + quên MK qua SMTP OTP.
 * Bổ sung: đăng nhập Google (BE-008) — verify id_token rồi phát JWT Node.
 * DB: docs/supabase/20240113000000_node_auth.sql
 */
const crypto = require('crypto');
const {
  httpError,
  normalizeEmail,
  normalizePhone,
  buildAuthResponse,
  publicProfile,
} = require('./auth.helpers');
const { hashPassword, verifyPassword, hashResetToken, generateResetToken } = require('../utils/password');
const { supabaseAdmin } = require('./supabase.service');
const { sendPasswordResetOtp } = require('./mail.service');
const { OAuth2Client } = require('google-auth-library');
const env = require('../config/env');

/** Danh sách client id hợp lệ (audience) khi verify Google id_token. */
const GOOGLE_CLIENT_IDS = String(env.GOOGLE_CLIENT_ID || '')
  .split(',')
  .map((id) => id.trim())
  .filter(Boolean);
const googleClient = new OAuth2Client();

/** Verify Google id_token thuần Node (không qua Supabase Auth). */
async function verifyGoogleIdToken(idToken) {
  if (GOOGLE_CLIENT_IDS.length === 0) {
    throw httpError(500, 'GOOGLE_CLIENT_ID chưa được cấu hình trên server', 'config_error');
  }
  try {
    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: GOOGLE_CLIENT_IDS,
    });
    return ticket.getPayload();
  } catch (err) {
    throw httpError(401, `Google token không hợp lệ: ${err.message}`, 'auth_failed');
  }
}

async function findProfileByEmail(email) {
  const { data, error } = await supabaseAdmin
    .from('profiles')
    .select('id, email')
    .eq('email', email)
    .maybeSingle();

  if (error) {
    throw httpError(500, error.message, 'db_error');
  }
  return data;
}

/**
 * BE-001 — POST /api/auth/register
 */
async function register(body) {
  const { email, password, full_name, phone, role: roleInput, business_name, ward, address } = body || {};
  const role = roleInput === 'provider' ? 'provider' : 'customer';

  if (!email || !password || !full_name) {
    throw httpError(400, 'email, password, and full_name are required', 'validation_error');
  }

  const normalizedEmail = normalizeEmail(email);
  if (!normalizedEmail.includes('@') || !normalizedEmail.includes('.')) {
    throw httpError(400, 'Invalid email format', 'validation_error');
  }

  if (String(password).length < 8) {
    throw httpError(400, 'Password must be at least 8 characters', 'validation_error');
  }

  const trimmedName = String(full_name).trim();
  if (!trimmedName) {
    throw httpError(400, 'full_name is required', 'validation_error');
  }

  let normalizedPhone = null;
  if (role === 'customer') {
    if (!phone) {
      throw httpError(400, 'phone is required for customer registration', 'validation_error');
    }
    normalizedPhone = normalizePhone(phone);
  } else {
    if (!business_name || !String(business_name).trim()) {
      throw httpError(400, 'business_name is required for provider registration', 'validation_error');
    }
    if (phone) {
      normalizedPhone = normalizePhone(phone);
    }
  }

  const { data: existing } = await supabaseAdmin
    .from('profiles')
    .select('id')
    .eq('email', normalizedEmail)
    .limit(1);

  if (existing && existing.length > 0) {
    throw httpError(409, 'Email already registered', 'email_exists');
  }

  const userId = crypto.randomUUID();
  const passwordHash = await hashPassword(password);

  try {
    const { data: profile, error: profileError } = await supabaseAdmin
      .from('profiles')
      .insert([
        {
          id: userId,
          email: normalizedEmail,
          full_name: trimmedName,
          phone: normalizedPhone,
          role,
          status: role === 'provider' ? 'pending_verification' : 'active',
          ...(ward ? { ward: String(ward).trim() } : {}),
          ...(address ? { address: String(address).trim() } : {}),
          ...(ward ? { city: 'Đà Nẵng' } : {}),
        },
      ])
      .select();

    if (profileError) {
      throw httpError(500, `Profile creation failed: ${profileError.message}`, 'db_error');
    }

    const { error: credError } = await supabaseAdmin.from('user_credentials').insert([
      { user_id: userId, password_hash: passwordHash },
    ]);

    if (credError) {
      throw httpError(500, `Credential creation failed: ${credError.message}`, 'db_error');
    }

    if (role === 'customer') {
      const { error: cpError } = await supabaseAdmin.from('customer_profiles').insert([
        { id: userId },
      ]);
      if (cpError) {
        throw httpError(500, `Customer profile creation failed: ${cpError.message}`, 'db_error');
      }
    } else if (role === 'provider') {
      const { error: ppError } = await supabaseAdmin.from('provider_profiles').insert([
        {
          id: userId,
          business_name: String(business_name).trim(),
          vehicle_type: 'small_truck',
          base_price: 100000,
          price_per_km: 10000,
          price_per_floor: 15000,
          is_verified: false,
        },
      ]);
      if (ppError) {
        throw httpError(500, `Provider profile creation failed: ${ppError.message}`, 'db_error');
      }
    }

    return buildAuthResponse(profile[0]);
  } catch (error) {
    if (error.status) throw error;
    throw httpError(500, error.message, 'internal_error');
  }
}

/** BE-003 — POST /api/auth/login */
async function login(body) {
  const { email, password } = body || {};

  if (!email || !password) {
    throw httpError(400, 'Email and password are required', 'validation_error');
  }

  const normalizedEmail = normalizeEmail(email);

  const { data: profiles, error: profileError } = await supabaseAdmin
    .from('profiles')
    .select('*')
    .eq('email', normalizedEmail)
    .limit(1);

  if (profileError) {
    throw httpError(500, `Profile lookup failed: ${profileError.message}`, 'db_error');
  }

  if (!profiles || profiles.length === 0) {
    throw httpError(401, 'Invalid email or password', 'auth_failed');
  }

  const profile = profiles[0];

  const { data: credentials, error: credError } = await supabaseAdmin
    .from('user_credentials')
    .select('password_hash')
    .eq('user_id', profile.id)
    .limit(1);

  if (credError) {
    throw httpError(500, `Credential lookup failed: ${credError.message}`, 'db_error');
  }

  if (!credentials || credentials.length === 0) {
    throw httpError(401, 'Invalid email or password', 'auth_failed');
  }

  const passwordMatch = await verifyPassword(password, credentials[0].password_hash);
  if (!passwordMatch) {
    throw httpError(401, 'Invalid email or password', 'auth_failed');
  }

  return buildAuthResponse(profile);
}

/** BE-003 — GET /api/auth/me */
async function getMe(userId) {
  if (!userId) {
    throw httpError(400, 'User ID is required', 'validation_error');
  }

  const { data: profiles, error } = await supabaseAdmin
    .from('profiles')
    .select('*')
    .eq('id', userId)
    .limit(1);

  if (error) {
    throw httpError(500, `Profile lookup failed: ${error.message}`, 'db_error');
  }

  if (!profiles || profiles.length === 0) {
    throw httpError(404, 'User not found', 'user_not_found');
  }

  const row = profiles[0];
  if (row.role === 'provider') {
    const { data: pp } = await supabaseAdmin
      .from('provider_profiles')
      .select('business_name, is_verified, rating')
      .eq('id', userId)
      .maybeSingle();
    return publicProfile(row, pp || undefined);
  }

  return publicProfile(row);
}

/** PATCH /api/auth/me — cập nhật hồ sơ (customer + provider) */
async function updateProfile(userId, body) {
  if (!userId) {
    throw httpError(400, 'User ID is required', 'validation_error');
  }

  const { data: profiles, error: lookupError } = await supabaseAdmin
    .from('profiles')
    .select('role')
    .eq('id', userId)
    .limit(1);

  if (lookupError) throw httpError(500, lookupError.message, 'db_error');
  if (!profiles?.length) throw httpError(404, 'User not found', 'user_not_found');

  const role = profiles[0].role;
  const { full_name, phone, business_name, vehicle_type, student_id, university, address } = body || {};

  const profileUpdates = {};
  if (full_name !== undefined) profileUpdates.full_name = String(full_name).trim();
  if (phone !== undefined) profileUpdates.phone = normalizePhone(phone);

  if (Object.keys(profileUpdates).length > 0) {
    const { error } = await supabaseAdmin.from('profiles').update(profileUpdates).eq('id', userId);
    if (error) throw httpError(500, error.message, 'db_error');
  }

  if (role === 'provider') {
    const ppUpdates = {};
    if (business_name !== undefined) ppUpdates.business_name = String(business_name).trim();
    if (vehicle_type !== undefined) ppUpdates.vehicle_type = String(vehicle_type).trim();
    if (Object.keys(ppUpdates).length > 0) {
      const { error } = await supabaseAdmin.from('provider_profiles').update(ppUpdates).eq('id', userId);
      if (error) throw httpError(500, error.message, 'db_error');
    }
  } else if (role === 'customer') {
    const customerUpdates = {};
    if (student_id !== undefined) customerUpdates.student_id = student_id;
    if (university !== undefined) customerUpdates.university = university;
    if (address !== undefined) customerUpdates.address = address;
    if (Object.keys(customerUpdates).length > 0) {
      const { error } = await supabaseAdmin
        .from('customer_profiles')
        .upsert({ id: userId, ...customerUpdates }, { onConflict: 'id' });
      if (error) throw httpError(500, error.message, 'db_error');
    }
  }

  if (
    Object.keys(profileUpdates).length === 0 &&
    !(role === 'provider' && (business_name !== undefined || vehicle_type !== undefined)) &&
    !(role === 'customer' && (student_id !== undefined || university !== undefined || address !== undefined))
  ) {
    throw httpError(400, 'Không có trường hợp lệ để cập nhật', 'validation_error');
  }

  return getMe(userId);
}

/** BE-006 — POST /api/auth/change-password (Node JWT — user_credentials) */
async function changePassword(userId, body) {
  const old_password = body?.old_password ?? body?.current_password ?? body?.password;
  const new_password = body?.new_password ?? body?.newPassword;

  if (!userId) {
    throw httpError(400, 'User ID is required', 'validation_error');
  }

  if (!old_password || !new_password) {
    throw httpError(400, 'Old password and new password are required', 'validation_error');
  }

  if (String(new_password).length < 8) {
    throw httpError(400, 'New password must be at least 8 characters', 'validation_error');
  }

  const { data: credentials, error: credError } = await supabaseAdmin
    .from('user_credentials')
    .select('password_hash')
    .eq('user_id', userId)
    .limit(1);

  if (credError) {
    throw httpError(500, `Credential lookup failed: ${credError.message}`, 'db_error');
  }

  if (!credentials || credentials.length === 0) {
    throw httpError(404, 'User credentials not found', 'not_found');
  }

  const passwordMatch = await verifyPassword(old_password, credentials[0].password_hash);
  if (!passwordMatch) {
    throw httpError(401, 'Old password is incorrect', 'invalid_password');
  }

  const newPasswordHash = await hashPassword(new_password);

  const { error: updateError } = await supabaseAdmin
    .from('user_credentials')
    .update({ password_hash: newPasswordHash })
    .eq('user_id', userId);

  if (updateError) {
    throw httpError(500, `Password update failed: ${updateError.message}`, 'db_error');
  }

  return { success: true, message: 'Password changed successfully' };
}

/** BE-007 — POST /api/auth/forgot-password (OTP qua SMTP) */
async function forgotPassword(email) {
  const normalized = normalizeEmail(email);
  if (!normalized || !normalized.includes('@')) {
    throw httpError(400, 'Email không hợp lệ', 'validation_error');
  }

  const profile = await findProfileByEmail(normalized);
  if (!profile) {
    return {
      email: normalized,
      message: 'Nếu email đã đăng ký, mã xác nhận đã được gửi.',
    };
  }

  const otp = generateResetToken();
  const tokenHash = hashResetToken(otp);
  const expiresMinutes = parseInt(String(env.PASSWORD_RESET_OTP_EXPIRES_MINUTES || 10), 10);
  const expiresAt = new Date(Date.now() + expiresMinutes * 60 * 1000).toISOString();

  const { error: insertError } = await supabaseAdmin.from('password_reset_tokens').insert({
    user_id: profile.id,
    token_hash: tokenHash,
    expires_at: expiresAt,
  });

  if (insertError) {
    if (insertError.code === '42P01') {
      throw httpError(
        500,
        'Bảng password_reset_tokens chưa có. Chạy migration 20240113000000_node_auth.sql trên Supabase.',
        'db_schema_missing',
      );
    }
    throw httpError(500, insertError.message, 'db_error');
  }

  try {
    await sendPasswordResetOtp({
      to: normalized,
      otp,
      expiresMinutes,
    });
  } catch (mailErr) {
    throw httpError(mailErr.status || 502, mailErr.message, mailErr.code || 'smtp_error');
  }

  return {
    email: normalized,
    message: 'Nếu email đã đăng ký, mã xác nhận đã được gửi.',
  };
}

/** BE-007 — POST /api/auth/reset-password (email + OTP — Node JWT) */
async function resetPassword(body) {
  const email = body?.email;
  const token = body?.token ?? body?.otp ?? body?.OTP;
  const new_password = body?.new_password ?? body?.newPassword;

  if (!email || !token || !new_password) {
    throw httpError(400, 'Email, token, and new password are required', 'validation_error');
  }

  if (String(new_password).length < 8) {
    throw httpError(400, 'Password must be at least 8 characters', 'validation_error');
  }

  const normalizedEmail = normalizeEmail(email);

  const { data: profiles, error: profileError } = await supabaseAdmin
    .from('profiles')
    .select('id')
    .eq('email', normalizedEmail)
    .limit(1);

  if (profileError) {
    throw httpError(500, `Profile lookup failed: ${profileError.message}`, 'db_error');
  }

  if (!profiles || profiles.length === 0) {
    throw httpError(400, 'Mã xác nhận không hợp lệ hoặc đã hết hạn', 'invalid_token');
  }

  const userId = profiles[0].id;
  const tokenHash = hashResetToken(String(token).trim());

  const { data: tokens, error: tokenError } = await supabaseAdmin
    .from('password_reset_tokens')
    .select('*')
    .eq('user_id', userId)
    .eq('token_hash', tokenHash)
    .is('used_at', null)
    .gt('expires_at', new Date().toISOString())
    .limit(1);

  if (tokenError) {
    throw httpError(500, `Token lookup failed: ${tokenError.message}`, 'db_error');
  }

  if (!tokens || tokens.length === 0) {
    throw httpError(400, 'Mã xác nhận không hợp lệ hoặc đã hết hạn', 'invalid_token');
  }

  const newPasswordHash = await hashPassword(new_password);

  const { error: updateError } = await supabaseAdmin
    .from('user_credentials')
    .update({ password_hash: newPasswordHash })
    .eq('user_id', userId);

  if (updateError) {
    throw httpError(500, `Password update failed: ${updateError.message}`, 'db_error');
  }

  const { error: markError } = await supabaseAdmin
    .from('password_reset_tokens')
    .update({ used_at: new Date().toISOString() })
    .eq('id', tokens[0].id);

  if (markError) {
    throw httpError(500, `Token update failed: ${markError.message}`, 'db_error');
  }

  return { message: 'Đặt lại mật khẩu thành công.' };
}

/**
 * BE-008 — POST /api/auth/google
 * Verify id_token Google thuần Node (google-auth-library), đảm bảo có row
 * trong `profiles`, rồi trả JWT Node (cùng format như login email).
 * Không dùng Supabase Auth.
 */
async function googleAuth(body) {
  const { id_token } = body || {};

  if (!id_token) {
    throw httpError(400, 'id_token is required', 'validation_error');
  }

  const payload = await verifyGoogleIdToken(id_token);

  if (!payload?.email) {
    throw httpError(401, 'Google token thiếu email', 'auth_failed');
  }
  if (payload.email_verified === false) {
    throw httpError(401, 'Email Google chưa được xác minh', 'auth_failed');
  }

  const normalizedEmail = normalizeEmail(payload.email);
  const avatarUrl = payload.picture || null;
  const fullName = payload.name || normalizedEmail.split('@')[0];

  // Tìm profile theo email (nguồn dữ liệu chính của Node API).
  const { data: existingProfiles, error: lookupError } = await supabaseAdmin
    .from('profiles')
    .select('*')
    .eq('email', normalizedEmail)
    .limit(1);

  if (lookupError) {
    throw httpError(500, `Profile lookup failed: ${lookupError.message}`, 'db_error');
  }

  let profile = existingProfiles?.[0] || null;

  if (!profile) {
    const userId = crypto.randomUUID();

    const { data: created, error: createError } = await supabaseAdmin
      .from('profiles')
      .insert([
        {
          id: userId,
          email: normalizedEmail,
          full_name: fullName,
          avatar_url: avatarUrl,
          role: 'customer',
          status: 'active',
        },
      ])
      .select();

    if (createError) {
      throw httpError(500, `Profile creation failed: ${createError.message}`, 'db_error');
    }

    profile = created[0];

    const { error: cpError } = await supabaseAdmin
      .from('customer_profiles')
      .insert([{ id: userId }]);
    if (cpError) {
      throw httpError(500, `Customer profile creation failed: ${cpError.message}`, 'db_error');
    }
  } else if (avatarUrl && !profile.avatar_url) {
    await supabaseAdmin
      .from('profiles')
      .update({ avatar_url: avatarUrl })
      .eq('id', profile.id);
    profile.avatar_url = avatarUrl;
  }

  return buildAuthResponse(profile);
}

module.exports = {
  register,
  login,
  getMe,
  updateProfile,
  changePassword,
  forgotPassword,
  resetPassword,
  googleAuth,
};
