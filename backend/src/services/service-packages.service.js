const { httpError } = require('./auth.helpers');
const { supabaseAdmin } = require('./supabase.service');

/** Fallback khớp booking_mock_repository.fetchPackages() khi chưa có bảng/seed DB. */
const DEFAULT_COMBO_PACKAGES = [
  {
    id: 'default-economy',
    tier: 'economy',
    label: 'Combo nhẹ',
    subtitle: 'Ít đồ · 1 người khuân vác',
    badge: 'TIẾT KIỆM',
    price: 199000,
    popular: false,
    labor_included: 1,
    included_km: 5,
    extra_km_price: 8000,
    extra_labor_combo_price: 65000,
    extra_labor_retail_price: 120000,
    features: [
      { text: 'Vali, bàn, vài thùng — chuyến ngắn', included: true },
      { text: 'Xe tải ~500kg (nhà xe đối tác báo giá)', included: true },
      { text: '1 người khuân vác trong combo', included: true },
      { text: 'Bảo hiểm hàng hóa', included: false },
    ],
  },
  {
    id: 'default-standard',
    tier: 'standard',
    label: 'Combo phòng trọ',
    subtitle: 'Đồ vừa · 2 người khuân vác',
    badge: 'PHỔ BIẾN',
    price: 450000,
    popular: true,
    labor_included: 2,
    included_km: 10,
    extra_km_price: 7000,
    extra_labor_combo_price: 75000,
    extra_labor_retail_price: 120000,
    features: [
      { text: 'Giường, tủ, bếp — đa số sinh viên', included: true },
      { text: 'Xe tải ~1 tấn (nhà xe đối tác báo giá)', included: true },
      { text: '2 người khuân vác trong combo', included: true },
      { text: 'Bảo hiểm cơ bản', included: true },
    ],
  },
  {
    id: 'default-premium',
    tier: 'premium',
    label: 'Combo trọn gói',
    subtitle: 'Nhiều đồ · 3 người + bọc đồ',
    badge: 'TRỌN CHUYẾN',
    price: 890000,
    popular: false,
    labor_included: 3,
    included_km: 15,
    extra_km_price: 6000,
    extra_labor_combo_price: 70000,
    extra_labor_retail_price: 120000,
    features: [
      { text: 'Nhiều đồ lớn, cần đóng gói', included: true },
      { text: 'Xe tải ~1.5 tấn (nhà xe đối tác báo giá)', included: true },
      { text: '3 người khuân vác + hỗ trợ bọc đồ', included: true },
      { text: 'Bảo hiểm toàn diện', included: true },
    ],
  },
];

function mapPackageRow(row) {
  const features = Array.isArray(row.features) ? row.features : [];
  return {
    id: row.id,
    tier: row.tier,
    label: row.label,
    subtitle: row.subtitle ?? '',
    badge: row.badge,
    price: Number(row.price),
    popular: Boolean(row.popular),
    labor_included: Number(row.labor_included ?? 0),
    included_km: Number(row.included_km ?? 0),
    extra_km_price: Number(row.extra_km_price ?? 0),
    extra_labor_combo_price: Number(row.extra_labor_combo_price ?? 0),
    extra_labor_retail_price: Number(row.extra_labor_retail_price ?? 0),
    features: features.map((f) => ({
      text: f.text ?? '',
      included: Boolean(f.included),
    })),
  };
}

/** BE-021 — GET /api/service-packages */
async function listComboPackages(activeOnly = true) {
  let query = supabaseAdmin
    .from('combo_service_packages')
    .select('*')
    .order('sort_order', { ascending: true });

  if (activeOnly) {
    query = query.eq('is_active', true);
  }

  const { data, error } = await query;

  if (error) {
    if (error.code === '42P01') {
      return DEFAULT_COMBO_PACKAGES;
    }
    throw httpError(500, error.message, 'db_error');
  }

  if (!data?.length) {
    return DEFAULT_COMBO_PACKAGES;
  }

  return data.map(mapPackageRow);
}

module.exports = { listComboPackages, DEFAULT_COMBO_PACKAGES };
