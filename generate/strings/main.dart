// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
// ignore: depend_on_referenced_packages
import 'package:watcher/watcher.dart';
import '../utils/exceptions.dart';
import '../utils/generate_constants.dart';
import 'models/names.dart';

/// TO run this file, write this command in terminal:
/// "dart generate/strings/main.dart"
void main() async {
  const String filePath = GenerateConstants.langJsonAssetFilePath;
  final File file = File(filePath);

  final FileWatcher watcher = FileWatcher(filePath);
  final String previousContent = file.readAsStringSync();
  watcher.events.listen((WatchEvent event) {
    if (event.type == ChangeType.MODIFY) {
      print('File changed: ${watcher.path}');
      handleFileChange(file, previousContent);
    }
  });
  final Map<String, dynamic> jsonMap = json.decode(previousContent);
  final Map<String, dynamic> jsonEnMap = await generateJsonTranslate(
    lang: 'en',
    jsonMap: jsonMap,
  );
  await generateJsonTranslate(lang: 'ar', jsonMap: jsonMap);
  await generateAppStrings(jsonEnMap);
  print('Watching for changes in: ${watcher.path}');
}

void handleFileChange(File file, String previousContent) async {
  try {
    final String currentContent = file.readAsStringSync();
    final List<String> currentLines = currentContent.split('\n');
    final List<String> previousLines = previousContent.split('\n');

    for (int i = 0; i < currentLines.length; i++) {
      if (i >= previousLines.length || currentLines[i] != previousLines[i]) {
        print('Line ${i + 1} changed');
        print(
          'Previous: ${(i) >= previousLines.length ? 'null' : previousLines[i]}',
        );
        print('Current: ${currentLines[i]}');
        print('------------------------------------------------------');
      }
    }
    previousContent = currentContent;
    final Map<String, dynamic> jsonMap = json.decode(currentContent);
    final Map<String, dynamic> jsonEnMap = await generateJsonTranslate(
      lang: 'en',
      jsonMap: jsonMap,
    );
    await generateJsonTranslate(lang: 'ar', jsonMap: jsonMap);
    await generateAppStrings(jsonEnMap);
  } catch (e) {
    print('Uknown Key');
  }
}

Future<Map<String, dynamic>> generateJsonTranslate({
  required String lang,
  required Map<String, dynamic> jsonMap,
}) async {
  final StringBuffer buffer = StringBuffer();
  final String filePath = lang == 'en'
      ? GenerateConstants.langEnJsonAssetFilePath
      : lang == 'ar'
      ? GenerateConstants.langArJsonAssetFilePath
      : '';
  final File file = File(filePath);
  buffer.writeln('{');
  // String content = file.readAsStringSync().trim();
  // final Map<String, dynamic> fileMap = json.decode(content);
  // List<String> lines = content.split('\n');
  // List<String> linesWithoutLastCurlBrace = lines.sublist(0, lines.length - 1);
  // buffer.writeAll(linesWithoutLastCurlBrace, '\n');
  // String bufferStringTrim = buffer.toString().trim();
  // bufferStringTrim = '$bufferStringTrim,';
  // buffer.clear();
  // buffer.writeln(bufferStringTrim);
  int counter = 0;
  //print('fileMap ${fileMap.toString()}');
  jsonMap.forEach((String key, dynamic value) {
    //print('$lang($counter)  "$key": "$value"');
    try {
      final Names keyNames = Names.fromString(key);
      final String valueStr = value.toString();
      // Check if value contains variables like {name}
      final bool hasVariables = RegExp(r'\{\w+\}').hasMatch(valueStr);

      // if (!fileMap.containsKey(keyNames.snakeCase)) {
      //print('$lang($counter)  !containsKey "${keyNames.snakeCase}" ');
      if (lang == 'en') {
        if (hasVariables) {
          // For English with variables: generate English text from key and preserve variables
          final String englishWithVars = generateEnglishWithVariables(
            keyNames.original,
            extractVariables(valueStr),
          );
          buffer.write('  "${keyNames.snakeCase}": "$englishWithVars"');
        } else {
          buffer.write('  "${keyNames.snakeCase}": "${keyNames.original}"');
        }
      } else {
        buffer.write('  "${keyNames.snakeCase}": "$valueStr"');
      }
      if (counter < jsonMap.length - 1) {
        buffer.write(',');
        // }
        buffer.writeln();
      }
    } on NamesException {
      final String keyStr = '[$key]';
      const String errorMessage = 'is not valid!';
      print(
        '${GenerateConstants.blueColorCode} $keyStr ${GenerateConstants.redColorCode}$errorMessage',
      );
    }
    counter++;
  });
  final List<String> linesAfterWrite = buffer.toString().trim().split('\n');
  String lastLineOfLinesAfterWrite = linesAfterWrite.last.trimRight();
  //print('lastLineOfLinesAfterWrite $lastLineOfLinesAfterWrite');
  if (lastLineOfLinesAfterWrite[lastLineOfLinesAfterWrite.length - 1] == ',') {
    lastLineOfLinesAfterWrite = lastLineOfLinesAfterWrite.substring(
      0,
      lastLineOfLinesAfterWrite.length - 1,
    );
    linesAfterWrite[linesAfterWrite.length - 1] = lastLineOfLinesAfterWrite;
    buffer.clear();
    buffer.writeAll(linesAfterWrite, '\n');
  }
  buffer.writeln('');
  buffer.writeln('}');
  await file.writeAsString(buffer.toString());
  print(
    '${GenerateConstants.greenColorCode} Lang Json File Updated successfully at $filePath ${GenerateConstants.resetColorCode}',
  );
  return json.decode(buffer.toString());
}

/// Extracts unique variable names from a translation string
/// e.g., "Hello {name}, you have {count} messages" -> ['name', 'count']
List<String> extractVariables(String value) {
  final RegExp regex = RegExp(r'\{(\w+)\}');
  // Use Match instead of deprecated RegExpMatch type
  final Iterable<Match> matches = regex.allMatches(value);
  // Use toSet() to remove duplicates, then back to list
  return matches.map((match) => match.group(1)!).toSet().toList();
}

/// Generates English translation text from key name with variable placeholders
/// If keyOriginal already contains the variables, return it as-is
/// Otherwise, append the variables to the end
String generateEnglishWithVariables(
  String keyOriginal,
  List<String> variables,
) {
  // Check if keyOriginal already contains the variables
  final bool alreadyHasVariables = variables.every(
    (v) => keyOriginal.contains('{$v}'),
  );

  if (alreadyHasVariables) {
    // Key already has variables (e.g., "Hello {name}"), use it directly
    return keyOriginal;
  } else {
    // Key doesn't have variables, append them
    final String varsPlaceholders = variables.map((v) => '{$v}').join(', ');
    return '$keyOriginal: $varsPlaceholders';
  }
}

Future<void> generateAppStrings(Map<String, dynamic> jsonMap) async {
  final StringBuffer buffer = StringBuffer();
  buffer.writeln(
    'import \'package:easy_localization/easy_localization.dart\';',
  );
  buffer.writeln();
  buffer.writeln('abstract class LocaleKeys {');
  jsonMap.forEach((String key, dynamic value) {
    try {
      final Names keyNames = Names.fromString(key);
      final List<String> variables = extractVariables(value.toString());

      buffer.writeln(
        "  static const String _${keyNames.camelCase} = '${keyNames.snakeCase}';",
      );

      if (variables.isEmpty) {
        // No variables - generate a simple getter
        buffer.writeln(
          '  static String get ${keyNames.camelCase} => _${keyNames.camelCase}.tr();',
        );
      } else {
        // Has variables - generate a function with named parameters
        final String params = variables
            .map((v) => 'required String $v')
            .join(', ');
        final String namedArgs = variables.map((v) => "'$v': $v").join(', ');
        buffer.writeln(
          '  static String ${keyNames.camelCase}({$params}) => _${keyNames.camelCase}.tr(namedArgs: {$namedArgs});',
        );
      }
      buffer.writeln();
    } on NamesException {
      final String keyStr = '[$key]';
      const String errorMessage = 'is not valid!';
      print(
        '${GenerateConstants.blueColorCode} $keyStr ${GenerateConstants.redColorCode}$errorMessage',
      );
    }
  });
  buffer.writeln('}');
  final File file = File(GenerateConstants.outputStringsFilePath);
  await file.writeAsString(buffer.toString());
  print(
    '${GenerateConstants.greenColorCode} class AppStrings Generated successfully at ${GenerateConstants.outputStringsFilePath} ${GenerateConstants.resetColorCode}',
  );
}
