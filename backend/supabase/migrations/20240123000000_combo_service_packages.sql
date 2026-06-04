-- BE-021: Gói combo marketplace (UniMove — 3 tier cho customer app)
CREATE TABLE IF NOT EXISTS combo_service_packages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tier TEXT NOT NULL CHECK (tier IN ('economy', 'standard', 'premium')),
    label TEXT NOT NULL,
    subtitle TEXT,
    badge TEXT NOT NULL,
    price INTEGER NOT NULL CHECK (price >= 0),
    popular BOOLEAN NOT NULL DEFAULT FALSE,
    labor_included INTEGER NOT NULL DEFAULT 0,
    included_km INTEGER NOT NULL DEFAULT 0,
    extra_km_price INTEGER NOT NULL DEFAULT 0,
    extra_labor_combo_price INTEGER NOT NULL DEFAULT 0,
    extra_labor_retail_price INTEGER NOT NULL DEFAULT 0,
    features JSONB NOT NULL DEFAULT '[]'::jsonb,
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tier)
);

CREATE TRIGGER update_combo_service_packages_updated_at
    BEFORE UPDATE ON combo_service_packages
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

ALTER TABLE combo_service_packages ENABLE ROW LEVEL SECURITY;

CREATE POLICY combo_service_packages_public_read
    ON combo_service_packages FOR SELECT
    USING (is_active = TRUE OR is_admin());

INSERT INTO combo_service_packages (
    tier, label, subtitle, badge, price, popular,
    labor_included, included_km, extra_km_price,
    extra_labor_combo_price, extra_labor_retail_price,
    features, sort_order, is_active
) VALUES
(
    'economy',
    'Combo nhẹ',
    'Ít đồ · 1 người khuân vác',
    'TIẾT KIỆM',
    199000,
    FALSE,
    1, 5, 8000, 65000, 120000,
    '[
      {"text": "Vali, bàn, vài thùng — chuyến ngắn", "included": true},
      {"text": "Xe tải ~500kg (nhà xe đối tác báo giá)", "included": true},
      {"text": "1 người khuân vác trong combo", "included": true},
      {"text": "Bảo hiểm hàng hóa", "included": false}
    ]'::jsonb,
    1,
    TRUE
),
(
    'standard',
    'Combo phòng trọ',
    'Đồ vừa · 2 người khuân vác',
    'PHỔ BIẾN',
    450000,
    TRUE,
    2, 10, 7000, 75000, 120000,
    '[
      {"text": "Giường, tủ, bếp — đa số sinh viên", "included": true},
      {"text": "Xe tải ~1 tấn (nhà xe đối tác báo giá)", "included": true},
      {"text": "2 người khuân vác trong combo", "included": true},
      {"text": "Bảo hiểm cơ bản", "included": true}
    ]'::jsonb,
    2,
    TRUE
),
(
    'premium',
    'Combo trọn gói',
    'Nhiều đồ · 3 người + bọc đồ',
    'TRỌN CHUYẾN',
    890000,
    FALSE,
    3, 15, 6000, 70000, 120000,
    '[
      {"text": "Nhiều đồ lớn, cần đóng gói", "included": true},
      {"text": "Xe tải ~1.5 tấn (nhà xe đối tác báo giá)", "included": true},
      {"text": "3 người khuân vác + hỗ trợ bọc đồ", "included": true},
      {"text": "Bảo hiểm toàn diện", "included": true}
    ]'::jsonb,
    3,
    TRUE
)
ON CONFLICT (tier) DO UPDATE SET
    label = EXCLUDED.label,
    subtitle = EXCLUDED.subtitle,
    badge = EXCLUDED.badge,
    price = EXCLUDED.price,
    popular = EXCLUDED.popular,
    labor_included = EXCLUDED.labor_included,
    included_km = EXCLUDED.included_km,
    extra_km_price = EXCLUDED.extra_km_price,
    extra_labor_combo_price = EXCLUDED.extra_labor_combo_price,
    extra_labor_retail_price = EXCLUDED.extra_labor_retail_price,
    features = EXCLUDED.features,
    sort_order = EXCLUDED.sort_order,
    is_active = EXCLUDED.is_active;

COMMENT ON TABLE combo_service_packages IS 'Gói combo chuyển trọ (marketplace) — BE-021';
