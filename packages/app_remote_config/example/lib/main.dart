import 'package:app_remote_config/app_remote_config.dart';
import 'package:flutter/material.dart';

const remoteConfigEnabled = bool.fromEnvironment(
  'REMOTE_CONFIG_ENABLED',
  defaultValue: false,
);

void main() => runApp(const RemoteConfigExampleApp());

class RemoteConfigExampleApp extends StatelessWidget {
  const RemoteConfigExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
    darkTheme: ThemeData(
      colorSchemeSeed: Colors.deepPurple,
      brightness: Brightness.dark,
      useMaterial3: true,
    ),
    home: const RemoteConfigExamplePage(),
  );
}

class RemoteConfigExamplePage extends StatefulWidget {
  const RemoteConfigExamplePage({super.key});

  @override
  State<RemoteConfigExamplePage> createState() =>
      _RemoteConfigExamplePageState();
}

class _RemoteConfigExamplePageState extends State<RemoteConfigExamplePage> {
  late final AppRemoteConfig _client;
  var _status = 'Remote Config disabled; local defaults are active.';
  var _message = 'Default value';

  @override
  void initState() {
    super.initState();
    _client = AppRemoteConfig(enabled: remoteConfigEnabled);
    _load();
  }

  Future<void> _load() async {
    await _client.setDefaults(const <String, Object>{
      'welcome_message': 'Default value',
    });
    if (!remoteConfigEnabled) {
      if (mounted) {
        setState(() => _message = _client.getString('welcome_message'));
      }
      return;
    }
    final initialization = await _client.tryInitialize();
    if (!initialization.isSuccess) {
      if (mounted) {
        setState(() {
          _status = 'Firebase configuration is missing or unavailable.';
          _message = _client.getString('welcome_message');
        });
      }
      return;
    }
    final result = await _client.fetchAndActivate(
      policy: RemoteConfigPolicy.forEnvironment(
        RemoteConfigEnvironment.development,
      ),
    );
    if (!mounted) return;
    setState(() {
      _status = result.isSuccess
          ? 'Remote Config completed safely.'
          : 'Remote Config unavailable; local defaults remain active.';
      _message = _client.getString('welcome_message');
    });
  }

  @override
  void dispose() {
    _client.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Optional Remote Config')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_status, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text(_message, key: const Key('remote-config-value')),
          ],
        ),
      ),
    ),
  );
}
