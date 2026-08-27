import 'package:flutter/material.dart';

import 'named_routes.dart';
import 'page_router/imports_page_router_builder.dart';

class RouterGenerator {
  RouterGenerator._();

  static final PageRouterBuilder _pageRouter = PageRouterBuilder();

  static Route<dynamic> getRoute(RouteSettings settings) {
    final matches = NamedRoutes.values.where(
      (route) => route.routeName == settings.name,
    );
    if (matches.isEmpty) return undefineRoute(settings);

    return switch (matches.single) {
      NamedRoutes.root => _pageRouter.build(
        const _BaseReadyPlaceholder(),
        settings: settings,
      ),
      NamedRoutes.login => _pageRouter.build(
        _SessionPlaceholder(
          key: const ValueKey('login-placeholder'),
          title: 'Authentication required / يلزم تسجيل الدخول',
          message: settings.arguments is String
              ? settings.arguments! as String
              : null,
        ),
        settings: settings,
      ),
      NamedRoutes.activation => _pageRouter.build(
        const _SessionPlaceholder(
          key: ValueKey('activation-placeholder'),
          title: 'Activation required / يلزم تفعيل الحساب',
        ),
        settings: settings,
      ),
    };
  }

  static Route<dynamic> undefineRoute([RouteSettings? settings]) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const Scaffold(
        body: SafeArea(
          child: Center(
            child: Text(
              'Page not found / الصفحة غير موجودة',
              key: ValueKey('unknown-route'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _BaseReadyPlaceholder extends StatelessWidget {
  const _BaseReadyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Text(
            'Base ready / القاعدة جاهزة',
            key: ValueKey('base-ready'),
          ),
        ),
      ),
    );
  }
}

class _SessionPlaceholder extends StatelessWidget {
  const _SessionPlaceholder({super.key, required this.title, this.message});

  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, textAlign: TextAlign.center),
                if (message != null && message!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(message!, textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
