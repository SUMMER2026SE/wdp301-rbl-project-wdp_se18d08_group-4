const { supabaseAdmin } = require('./supabase.service');

/**
 * Tạo 1 thông báo in-app cho user.
 * @param {string} userId
 * @param {string} type  - notification_type enum value
 * @param {string} title
 * @param {string} body
 * @param {object} opts  - { priority, listingId, actionData, icon }
 */
async function createNotification(userId, type, title, body, opts = {}) {
  const { error } = await supabaseAdmin.from('notifications').insert({
    user_id: userId,
    notification_type: type,
    title,
    body,
    priority: opts.priority || 'normal',
    listing_id: opts.listingId || null,
    action_data: opts.actionData || null,
    icon: opts.icon || null,
    is_read: false,
    is_sent: true,
    sent_at: new Date().toISOString(),
  });
  if (error) console.error('[notification] insert error:', error.message);
}

module.exports = { createNotification };
