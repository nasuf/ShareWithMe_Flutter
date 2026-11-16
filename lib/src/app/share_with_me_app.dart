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
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'ShareWithMe',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(Brightness.light),
          darkTheme: buildAppTheme(Brightness.dark),
          themeMode: _toMaterialThemeMode(controller.themeMode),
          home: ShareScope(controller: controller, child: const HomeShell()),
        );
      },
    );
  }
}
