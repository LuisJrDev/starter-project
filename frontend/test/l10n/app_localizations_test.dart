import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/l10n/l10n.dart';

Set<String> textKeysOf(String arbFile) {
  final texts = jsonDecode(File('lib/l10n/$arbFile').readAsStringSync()) as Map<String, dynamic>;
  return texts.keys.where((key) => !key.startsWith('@')).toSet();
}

void main() {
  test('every text of the app is translated to Spanish', () {
    expect(textKeysOf('app_es.arb'), textKeysOf('app_en.arb'));
  });

  test('supports English and Spanish', () {
    expect(AppLocalizations.supportedLocales, containsAll(const [Locale('en'), Locale('es')]));
  });

  test('writes large numbers as each language does', () {
    expect(lookupAppLocalizations(const Locale('en')).contentTooLong(10000), contains('10,000'));
    expect(lookupAppLocalizations(const Locale('es')).contentTooLong(10000), contains('10.000'));
  });
}
