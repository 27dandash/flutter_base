import 'bootstrap/app_environment.dart';
import 'bootstrap/bootstrap.dart';

/// Default local entry point. Release automation must target the explicit
/// environment entry points instead.
void main() => bootstrap(AppEnvironment.development);
