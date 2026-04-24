import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const ProviderScope(child: AquaSentinelApp()));
}

class AquaSentinelApp extends ConsumerWidget {
  const AquaSentinelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'AquaSentinel',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routerConfig: router.config(),
    );
  }

  ThemeData _buildTheme() {
    const primary = Color(0xFF00D4FF);
    const secondary = Color(0xFF64748B);
    const background = Color(0xFF050505);
    const surface = Color(0xFF0D1B2A);
    const cardSurface = Color(0xFF0F2133);

    final textTheme = TextTheme(
      displayLarge: GoogleFonts.spaceGrotesk(color: Colors.white),
      displayMedium: GoogleFonts.spaceGrotesk(color: Colors.white),
      displaySmall: GoogleFonts.spaceGrotesk(color: Colors.white),
      headlineLarge: GoogleFonts.spaceGrotesk(color: Colors.white),
      headlineMedium: GoogleFonts.spaceGrotesk(color: Colors.white),
      headlineSmall: GoogleFonts.spaceGrotesk(color: Colors.white),
      titleLarge: GoogleFonts.spaceGrotesk(color: Colors.white),
      titleMedium: GoogleFonts.spaceGrotesk(color: Colors.white),
      titleSmall: GoogleFonts.spaceGrotesk(color: Colors.white),
      bodyLarge: GoogleFonts.inter(color: Colors.white70),
      bodyMedium: GoogleFonts.inter(color: Colors.white70),
      bodySmall: GoogleFonts.inter(color: Colors.white54),
      labelLarge: GoogleFonts.spaceGrotesk(color: Colors.white),
      labelMedium: GoogleFonts.spaceGrotesk(color: Colors.white70),
      labelSmall: GoogleFonts.spaceGrotesk(color: Colors.white54),
    );

    return ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        tertiary: Color(0xFF90CAF9),
        surface: surface,
        error: Color(0xFFFF4757),
        onPrimary: background,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: primary),
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: primary.withValues(alpha: 0.12), width: 1),
        ),
      ),
      dividerColor: Colors.white10,
      iconTheme: const IconThemeData(color: Colors.white70),
    );
  }
}
