import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_strings.dart';

/// Current UI language (EN / KH).
class LangNotifier extends Notifier<AppLang> {
  @override
  AppLang build() => AppLang.km;

  void set(AppLang lang) => state = lang;
  void toggle() => state = state == AppLang.km ? AppLang.en : AppLang.km;
}

final langProvider = NotifierProvider<LangNotifier, AppLang>(LangNotifier.new);

/// Translate helper: `ref.tr('sos')`.
extension TrRef on WidgetRef {
  String tr(String key) => AppStrings.of(key, watch(langProvider));
}
