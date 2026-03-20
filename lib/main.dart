import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'core/theme/app_theme.dart';
import 'core/services/crash_reporter.dart';
import 'core/services/performance_monitor.dart';
import 'core/services/supabase_service.dart';
import 'di/providers.dart';
import 'presentation/router/app_router.dart';

void main() async {
  // 크래시 리포팅으로 앱 실행
  await runAppWithCrashReporting(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Google Fonts 런타임 페칭 비활성화 — 오프라인 환경에서 폰트 깨짐 방지
    // 폰트는 google_fonts 패키지 캐시 또는 시스템 폰트로 폴백
    GoogleFonts.config.allowRuntimeFetching = false;

    // Supabase 초기화 (타임아웃 10초, 실패해도 앱 진행)
    try {
      await SupabaseService.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('[Main] Supabase init timeout — continuing without it');
        },
      );
    } catch (e) {
      debugPrint('[Main] Supabase init failed: $e — continuing');
    }

    // 크래시 리포터 초기화
    await LocalCrashReporter.instance.initialize();
    setupCrashReporting();

    // 성능 모니터링 활성화
    PerformanceMonitor.instance.isEnabled = true;

    // 가로 모드 고정
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // 전체 화면 모드 (시스템 바 숨김)
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );

    // 화면 꺼짐 방지
    await WakelockPlus.enable();

    debugPrint('[Main] Starting app...');

    runApp(
      const ProviderScope(
        child: BdrRecorderApp(),
      ),
    );
  });
}

class BdrRecorderApp extends ConsumerWidget {
  const BdrRecorderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'BDR Tournament Recorder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
