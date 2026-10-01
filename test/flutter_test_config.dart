import 'dart:async';

import 'package:pusula/core/hareket.dart';

/// Tüm testlerden önce çalışır: süs hareketi (sürekli süzülme) kapatılır, yoksa `pumpAndSettle`
/// hiç bitmez. Hareketin kendisi `test/hareket_test.dart` içinde açıkça açılarak sınanır.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  PusulaHareket.susHareketi = false;
  await testMain();
}
