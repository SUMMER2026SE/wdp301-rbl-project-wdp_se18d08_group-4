const servicePackagesService = require('../services/service-packages.service');

/** BE-021 — GET /api/service-packages */
async function list(req, res, next) {
  try {
    const activeParam = req.query.active;
    const activeOnly = activeParam === undefined || activeParam === 'true' || activeParam === '1';
    const data = await servicePackagesService.listComboPackages(activeOnly);
    res.json({ success: true, data });
  } catch (error) {
    next(error);
  }
}

module.exports = { list };
