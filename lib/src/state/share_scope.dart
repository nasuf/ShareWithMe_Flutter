part of '../../main.dart';

class ShareScope extends InheritedNotifier<ShareController> {
  const ShareScope({
    super.key,
    required ShareController controller,
    required super.child,
  }) : super(notifier: controller);

  static ShareController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ShareScope>();
    assert(scope != null, 'ShareScope not found');
    return scope!.notifier!;
  }
}
