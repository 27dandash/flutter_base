// Script to sync missing translation keys from ar.json/en.json to lang.json
// Usage: dart find_missing_keys.dart
//
// هذا السكريبت يبحث عن المفاتيح الموجودة في ar.json و en.json
// ولكن غير موجودة في lang.json ويضيفها تلقائياً

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

void main() async {
  // قراءة الملفات
  final langFile = File('assets/translations/lang.json');
  final arFile = File('assets/translations/ar.json');
  final enFile = File('assets/translations/en.json');

  final langData =
      json.decode(await langFile.readAsString()) as Map<String, dynamic>;
  final arData =
      json.decode(await arFile.readAsString()) as Map<String, dynamic>;
  final enData =
      json.decode(await enFile.readAsString()) as Map<String, dynamic>;

  // استخراج المفاتيح الموجودة في lang.json
  final langKeys = <String>{};
  for (var key in langData.keys) {
    // المفتاح في lang.json له صيغة: 'key #$ English Translation'
    String realKey;
    if (key.contains('#\$')) {
      realKey = key.split('#\$')[0].trim();
    } else {
      realKey = key;
    }

    // تحويل إلى snake_case
    final snakeKey = realKey.replaceAll(' ', '_').toLowerCase();
    langKeys.add(snakeKey);
  }

  // إيجاد المفاتيح المفقودة
  final missingKeys = <Map<String, String>>[];
  for (var key in arData.keys) {
    if (!langKeys.contains(key)) {
      missingKeys.add({
        'key': key,
        'ar': arData[key] as String,
        'en': (enData[key] ?? '') as String,
      });
    }
  }

  log('عدد المفاتيح المفقودة: ${missingKeys.length}\n');

  if (missingKeys.isEmpty) {
    log('لا توجد مفاتيح مفقودة! 🎉');
    return;
  }

  // طباعة المفاتيح المفقودة
  log('المفاتيح المفقودة من lang.json:');
  log('=' * 80);
  for (var item in missingKeys) {
    log('\nKey: ${item['key']}');
    log('AR: ${item['ar']}');
    log('EN: ${item['en']}');
    log('-' * 80);
  }

  // إضافة المفاتيح المفقودة إلى lang.json
  log('\n\nجاري إضافة المفاتيح المفقودة إلى lang.json...');

  final newLangData = Map<String, dynamic>.from(langData);

  for (var item in missingKeys) {
    // تحويل المفتاح من snake_case إلى الصيغة الأصلية
    final originalKey = item['key']!.replaceAll('_', ' ');
    final newKey = '$originalKey #\$ ${item['en']}';
    newLangData[newKey] = item['ar'];
  }

  // حفظ الملف المحدث
  final encoder = const JsonEncoder.withIndent('    ');
  await langFile.writeAsString(encoder.convert(newLangData));

  log('\n✅ تم إضافة ${missingKeys.length} مفتاح إلى lang.json بنجاح!');
  log('الآن يمكنك تشغيل: make tr');
}
