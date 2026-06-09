import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/mock/mock_provider_reviews.dart';
import '../../../../core/theme/uni_move_colors.dart';
import '../../../../core/widgets/shad_screen_scope.dart';
import '../../domain/provider_review.dart';

class ProviderReviewsPage extends StatelessWidget {
  const ProviderReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = UniMoveColors.of(context);
    final summary = MockProviderReviews.summary;
    final reviews = MockProviderReviews.reviews;

    return ShadScreenScope(
      builder: (_, theme) {
        return Scaffold(
          backgroundColor: c.background,
          appBar: AppBar(
            backgroundColor: c.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: Text('Đánh giá của khách', style: TextStyle(color: c.onSurface, fontWeight: FontWeight.w800)),
            iconTheme: IconThemeData(color: c.onSurface),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              _summaryHero(theme, c, summary),
              const SizedBox(height: 20),
              _detailScores(theme, c, summary),
              const SizedBox(height: 24),
              Text(
                'Nhận xét gần đây',
                style: theme.textTheme.large.copyWith(fontWeight: FontWeight.w800, color: c.onSurface),
              ),
              const SizedBox(height: 12),
              ...reviews.map((r) => _ReviewCard(review: r, theme: theme, c: c)),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryHero(ShadThemeData theme, UniMoveColors c, ProviderReviewSummary s) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [c.primary, c.primaryLight]),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.averageRating.toStringAsFixed(1),
                style: theme.textTheme.h1.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < s.averageRating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber.shade200,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${s.totalReviews} đánh giá',
                style: theme.textTheme.small.copyWith(color: Colors.white70),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Tỷ lệ phản hồi', style: theme.textTheme.small.copyWith(color: Colors.white70)),
              Text(
                '${s.responseRate.toStringAsFixed(0)}%',
                style: theme.textTheme.h3.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailScores(ShadThemeData theme, UniMoveColors c, ProviderReviewSummary s) {
    final rows = [
      ('Chất lượng dịch vụ', s.avgServiceQuality),
      ('Đúng giờ', s.avgPunctuality),
      ('Chuyên nghiệp', s.avgProfessionalism),
      ('Giá trị tiền', s.avgValueForMoney),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (var star = 5; star >= 1; star--) ...[
            Row(
              children: [
                Text('$star', style: TextStyle(fontWeight: FontWeight.w700, color: c.onSurface)),
                const SizedBox(width: 4),
                Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: s.fractionForStar(star),
                      minHeight: 6,
                      backgroundColor: c.chipBg,
                      color: c.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${s.countForStar(star)}', style: theme.textTheme.small.copyWith(color: c.onSurfaceMuted)),
              ],
            ),
            if (star > 1) const SizedBox(height: 8),
          ],
          const Divider(height: 24),
          ...rows.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(r.$1, style: theme.textTheme.small.copyWith(color: c.onSurfaceMuted)),
                  Text(
                    r.$2.toStringAsFixed(1),
                    style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w800, color: c.onSurface),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, required this.theme, required this.c});

  final ProviderReview review;
  final ShadThemeData theme;
  final UniMoveColors c;

  @override
  Widget build(BuildContext context) {
    final d = review.createdAt;
    final dateStr = '${d.day}/${d.month}/${d.year}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: c.iconBgSecondary,
                  child: Text(
                    review.customerName.isNotEmpty ? review.customerName[0] : 'K',
                    style: TextStyle(color: c.primary, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.customerName, style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w700, color: c.onSurface)),
                      Text('#${review.orderNumber} · $dateStr', style: theme.textTheme.small.copyWith(color: c.onSurfaceMuted)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text('${review.rating}', style: TextStyle(fontWeight: FontWeight.w800, color: c.onSurface)),
                    Icon(Icons.star_rounded, size: 18, color: Colors.amber.shade700),
                  ],
                ),
              ],
            ),
            if ((review.title ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(review.title!, style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w700, color: c.onSurface)),
            ],
            const SizedBox(height: 8),
            Text(review.comment, style: theme.textTheme.small.copyWith(color: c.onSurface, height: 1.45)),
            if (review.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: review.tags
                    .map(
                      (t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: c.chipBg, borderRadius: BorderRadius.circular(8)),
                        child: Text(t, style: theme.textTheme.small.copyWith(color: c.primaryLight, fontSize: 11)),
                      ),
                    )
                    .toList(),
              ),
            ],
            if ((review.providerResponse ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.iconBgTertiary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Phản hồi nhà xe', style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w700, color: c.primary)),
                    const SizedBox(height: 4),
                    Text(
                      review.providerResponse!,
                      style: theme.textTheme.small.copyWith(color: c.onSurface, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
