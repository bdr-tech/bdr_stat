// ─── Network Status Banners ───────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/theme/bdr_design_system.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.pendingCount, this.onDismiss});
  final int pendingCount;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
      child: GlassBox(
        borderRadius: DS.radiusSm,
        blur: DS.blurRadiusSm,
        fillColor: DS.warning.withValues(alpha: 0.08),
        borderColor: DS.warning.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, size: 14, color: DS.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '오프라인 · 대기 $pendingCount건',
                style: DSText.jakartaBody(color: DS.warning, size: 11),
              ),
            ),
            if (onDismiss != null)
              TapScaleButton(
                onTap: onDismiss,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: DS.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(DS.radiusXs),
                    border: Border.all(color: DS.warning.withValues(alpha: 0.4)),
                  ),
                  child: Text('확인', style: DSText.jakartaButton(color: DS.warning, size: 11)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SyncingBanner extends StatelessWidget {
  const SyncingBanner({super.key, required this.pendingCount});
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
      child: GlassBox(
        borderRadius: DS.radiusSm,
        blur: DS.blurRadiusSm,
        fillColor: DS.success.withValues(alpha: 0.08),
        borderColor: DS.success.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          children: [
            const SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: DS.success),
            ),
            const SizedBox(width: 8),
            Text(
              '동기화 중... ($pendingCount건)',
              style: DSText.jakartaBody(color: DS.success, size: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class FlushBanner extends StatelessWidget {
  const FlushBanner({super.key, required this.pendingCount, required this.onFlush});
  final int pendingCount;
  final VoidCallback onFlush;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
      child: GlassBox(
        borderRadius: DS.radiusSm,
        blur: DS.blurRadiusSm,
        fillColor: DS.awayBlue.withValues(alpha: 0.07),
        borderColor: DS.awayBlue.withValues(alpha: 0.25),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.cloud_upload_rounded, size: 14, color: DS.awayBlue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '대기 이벤트 $pendingCount건',
                style: DSText.jakartaBody(color: DS.awayBlue, size: 11),
              ),
            ),
            TapScaleButton(
              onTap: onFlush,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: DS.awayBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DS.radiusXs),
                  border: Border.all(color: DS.awayBlue.withValues(alpha: 0.4)),
                ),
                child: Text('전송', style: DSText.jakartaButton(color: DS.awayBlue, size: 11)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
