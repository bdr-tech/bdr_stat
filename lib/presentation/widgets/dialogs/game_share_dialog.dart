import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/services/game_share_service.dart';
import '../../../core/theme/app_theme.dart';

/// 경기 공유 QR 코드 다이얼로그
class GameShareDialog extends StatelessWidget {
  const GameShareDialog({
    super.key,
    required this.shareData,
  });

  final GameShareData shareData;

  @override
  Widget build(BuildContext context) {
    final shareService = GameShareService.instance;
    final qrUrl = shareService.generateQrUrl(shareData);
    final shareUrl = shareService.generateShareUrl(shareData);
    final isSynced = shareData.isSynced;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Row(
              children: [
                const Icon(Icons.qr_code_2, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '실시간 스코어 공유',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'QR 코드를 스캔하여 경기를 확인하세요',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 경기 정보 카드
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // 팀 vs 팀
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          shareData.homeTeamName,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          shareData.scoreDisplay,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          shareData.awayTeamName,
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 상태 표시
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (shareData.status == 'live') ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        '${shareData.quarterDisplay} ${shareData.clockDisplay}',
                        style: TextStyle(
                          color: shareData.status == 'live'
                              ? Colors.red
                              : Theme.of(context).hintColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // QR 코드 or 미동기화 안내
            if (isSynced && qrUrl != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrUrl,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  errorStateBuilder: (context, error) => Container(
                    width: 200,
                    height: 200,
                    color: Colors.white,
                    child: Center(
                      child: Text(
                        'QR 생성 오류',
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 200,
                height: 160,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sync_disabled, size: 40, color: Theme.of(context).hintColor),
                    const SizedBox(height: 8),
                    Text(
                      '서버 동기화 후\nQR이 생성됩니다',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // URL 복사 영역
            if (isSynced && shareUrl != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        shareUrl,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: shareUrl));
                        HapticFeedback.mediumImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('URL이 복사되었습니다'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 20),
                      tooltip: 'URL 복사',
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // 공유 버튼들
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final text = shareService.generateShareText(shareData);
                      Clipboard.setData(ClipboardData(text: text));
                      HapticFeedback.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('공유 텍스트가 복사되었습니다'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.content_copy),
                    label: const Text('텍스트 복사'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Share API 연동
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('공유하기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 안내 텍스트
            Text(
              '💡 체육관 스크린에 QR 코드를 표시하면 관중들이 실시간 점수를 확인할 수 있습니다',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// 경기 공유 다이얼로그 표시 헬퍼 함수
Future<void> showGameShareDialog({
  required BuildContext context,
  required GameShareData shareData,
}) {
  return showDialog(
    context: context,
    builder: (context) => GameShareDialog(shareData: shareData),
  );
}
