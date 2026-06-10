const multer = require('multer');

const AVATAR_MAX_BYTES = 2 * 1024 * 1024;
const MARKETPLACE_IMAGE_MAX_BYTES = 5 * 1024 * 1024;
const DOCUMENT_MAX_BYTES = 10 * 1024 * 1024;
const ALLOWED_MIME = new Set(['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']);

function makeImageUpload(field, maxBytes) {
  return multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: maxBytes, files: 1 },
    fileFilter: (_req, file, cb) => {
      if (!ALLOWED_MIME.has(file.mimetype)) {
        const err = new Error('Chỉ chấp nhận ảnh JPG hoặc PNG.');
        err.status = 400;
        err.code = 'invalid_file_type';
        return cb(err);
      }
      cb(null, true);
    },
  }).single(field);
}

function wrapUpload(upload, sizeMessage) {
  return (req, res, next) => {
    upload(req, res, (err) => {
      if (!err) return next();
      if (err.code === 'LIMIT_FILE_SIZE') {
        err.status = 400;
        err.message = sizeMessage;
        err.code = 'file_too_large';
      }
      next(err);
    });
  };
}

const handleAvatarUpload = wrapUpload(makeImageUpload('avatar', AVATAR_MAX_BYTES), 'Ảnh vượt quá 2MB.');
const handleMarketplaceImageUpload = wrapUpload(makeImageUpload('image', MARKETPLACE_IMAGE_MAX_BYTES), 'Ảnh vượt quá 5MB.');
const handleDocumentUpload = wrapUpload(makeImageUpload('file', DOCUMENT_MAX_BYTES), 'Ảnh vượt quá 10MB.');

module.exports = { handleAvatarUpload, handleMarketplaceImageUpload, handleDocumentUpload };
