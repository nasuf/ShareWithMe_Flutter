part of '../../main.dart';

class ShareWithMeApp extends StatefulWidget {
  const ShareWithMeApp({super.key});

  @override
  State<ShareWithMeApp> createState() => _ShareWithMeAppState();
}

class _ShareWithMeAppState extends State<ShareWithMeApp> {
  late final ShareController controller;

  @override
  void initState() {
    super.initState();
    controller = ShareController(
      ApiClient(defaultBackendUrl()),
      settings: AppSettings(),
    );
    unawaited(controller.bootstrap());
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: Brightness.light,
      surface: _surface,
    );
    return MaterialApp(
      title: 'ShareWithMe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
        fontFamilyFallback: const ['PingFang SC', 'Helvetica Neue', 'Arial'],
        scaffoldBackgroundColor: Colors.transparent,
        dividerColor: _line,
        splashFactory: InkRipple.splashFactory,
        visualDensity: VisualDensity.standard,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: _ink,
          titleTextStyle: TextStyle(
            color: _ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        cardTheme: CardThemeData(
          color: Colors.white.withValues(alpha: 0.66),
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.9)),
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.86)),
          ),
          backgroundColor: Colors.white.withValues(alpha: 0.62),
          selectedColor: _accentSoft,
          labelStyle: const TextStyle(color: _ink, fontWeight: FontWeight.w600),
          secondaryLabelStyle: const TextStyle(
            color: _ink,
            fontWeight: FontWeight.w700,
          ),
          checkmarkColor: _accent,
          iconTheme: const IconThemeData(color: _accent, size: 18),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _ink,
            side: const BorderSide(color: _line),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          ),
        ),
        searchBarTheme: SearchBarThemeData(
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStatePropertyAll(
            Colors.white.withValues(alpha: 0.67),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: Colors.white.withValues(alpha: 0.92)),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.68),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: _line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.92)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: _accent, width: 1.4),
          ),
        ),
      ),
      home: ShareScope(controller: controller, child: const HomeShell()),
    );
  }
}
