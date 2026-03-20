import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_theme.dart';
import '../../../di/providers.dart';

/// 대회 연결 화면 - QR 스캔 또는 토큰 직접 입력
class TournamentConnectScreen extends ConsumerStatefulWidget {
  const TournamentConnectScreen({super.key});

  @override
  ConsumerState<TournamentConnectScreen> createState() =>
      _TournamentConnectScreenState();
}

class _TournamentConnectScreenState
    extends ConsumerState<TournamentConnectScreen> {
  final _tokenController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _showScanner = false;
  String? _errorMessage;

  MobileScannerController? _scannerController;

  @override
  void dispose() {
    _tokenController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _verifyToken(String token) async {
    if (token.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      apiClient.setApiToken(token);

      final result = await apiClient.verifyTournament(token);

      if (!mounted) return;

      if (result.isSuccess && result.data != null) {
        // 대회 확인 화면으로 이동
        context.push(
          '/confirm/${result.data!.id}',
          extra: token,
        );
      } else {
        setState(() {
          _errorMessage = result.error ?? '대회 정보를 확인할 수 없습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '연결 중 오류가 발생했습니다: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onQRDetected(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue != null) {
      _scannerController?.stop();
      setState(() {
        _showScanner = false;
      });

      // QR 코드에서 토큰 추출
      final token = _extractTokenFromQR(barcode!.rawValue!);
      if (token != null) {
        _verifyToken(token);
      } else {
        setState(() {
          _errorMessage = '유효하지 않은 QR 코드입니다.';
        });
      }
    }
  }

  String? _extractTokenFromQR(String qrData) {
    // QR 코드 형식: URL 또는 직접 토큰
    // 예: https://bdr.kr/t/ABC123 또는 ABC123
    if (qrData.contains('/t/')) {
      final parts = qrData.split('/t/');
      return parts.length > 1 ? parts.last : null;
    }
    // 직접 토큰인 경우
    if (qrData.length >= 6 && qrData.length <= 50) {
      return qrData;
    }
    return null;
  }

  void _toggleScanner() {
    setState(() {
      _showScanner = !_showScanner;
      if (_showScanner) {
        _scannerController = MobileScannerController(
          detectionSpeed: DetectionSpeed.normal,
          facing: CameraFacing.back,
        );
      } else {
        _scannerController?.dispose();
        _scannerController = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/tournaments');
            }
          },
          tooltip: '뒤로가기',
        ),
        title: const Text('대회 연결'),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/tournaments'),
            icon: const Icon(Icons.list),
            label: const Text('내 대회'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Row(
          children: [
            // 왼쪽: QR 스캐너 또는 안내
            Expanded(
              flex: 1,
              child: _buildLeftPanel(),
            ),

            // 오른쪽: 토큰 입력
            Expanded(
              flex: 1,
              child: _buildRightPanel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPanel() {
    if (_showScanner && _scannerController != null) {
      return Container(
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryColor, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              MobileScanner(
                controller: _scannerController!,
                onDetect: _onQRDetected,
              ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  onPressed: _toggleScanner,
                  icon: const Icon(Icons.close, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                ),
              ),
              // 스캔 가이드
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.7),
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 120,
            color: AppTheme.primaryColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'QR 코드로 빠르게 연결',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            '대회 관리 페이지의 QR 코드를\n스캔하여 연결하세요',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _toggleScanner,
            icon: const Icon(Icons.camera_alt),
            label: const Text('카메라로 스캔'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '대회 연결',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '대회 토큰을 입력하여 연결하세요',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 32),

            // 토큰 입력 필드
            TextFormField(
              controller: _tokenController,
              decoration: InputDecoration(
                labelText: '대회 토큰',
                hintText: 'ABC123',
                prefixIcon: const Icon(Icons.vpn_key),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppTheme.backgroundColor,
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '토큰을 입력해주세요';
                }
                if (value.length < 6) {
                  return '토큰은 6자 이상이어야 합니다';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 에러 메시지
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.errorColor),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.errorColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppTheme.errorColor),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // 연결 버튼
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        if (_formKey.currentState?.validate() ?? false) {
                          _verifyToken(_tokenController.text.trim());
                        }
                      },
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        '연결하기',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 32),

            // 최근 연결 대회
            _buildRecentTournaments(),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildRecentTournaments() {
    final recentAsync = ref.watch(_recentTournamentsProvider);

    return recentAsync.when(
      data: (tournaments) {
        if (tournaments.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 16),
            Text(
              '최근 연결',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            ...tournaments.take(3).map((t) => _buildRecentItem(t)),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildRecentItem(RecentTournamentInfo tournament) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.sports_basketball,
          color: AppTheme.primaryColor,
        ),
      ),
      title: Text(tournament.name),
      subtitle: Text(
        '마지막 연결: ${_formatDate(tournament.lastConnected)}',
        style: TextStyle(color: AppTheme.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _verifyToken(tournament.token),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return '오늘';
    if (diff.inDays == 1) return '어제';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${date.month}/${date.day}';
  }
}

/// 최근 연결 대회 정보
class RecentTournamentInfo {
  final String id;
  final String name;
  final String token;
  final DateTime lastConnected;

  RecentTournamentInfo({
    required this.id,
    required this.name,
    required this.token,
    required this.lastConnected,
  });
}

/// 최근 연결 대회 Provider
final _recentTournamentsProvider =
    FutureProvider<List<RecentTournamentInfo>>((ref) async {
  final db = ref.watch(databaseProvider);
  final recents = await db.tournamentDao.getRecentTournaments();

  return recents.map((r) => RecentTournamentInfo(
    id: r.tournamentId,
    name: r.tournamentName,
    token: r.apiToken,
    lastConnected: r.connectedAt,
  )).toList();
});
