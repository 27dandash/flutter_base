part of '../imports/products_imports.dart';

/// Public entry point — wire navigators to `const ProductsScreen()`.
///
/// Responsibilities of a *screen* file:
///   - Provide the cubit(s).
///   - Own the `ViewController` lifecycle (init / dispose).
///   - Compose scaffold + body. **Never** layout content directly here —
///     that's the body widget's job. No methods beyond the lifecycle ones.
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late final ProductsCubit _cubit;
  late final ProductsViewController _vc;

  /// rxdart subject we feed each keystroke into; emits after 350 ms of
  /// silence so search calls are debounced on the *bloc* side.
  final PublishSubject<String> _searchSubject = PublishSubject<String>();
  StreamSubscription<String>? _searchSub;

  @override
  void initState() {
    super.initState();
    _cubit = injector<ProductsCubit>()..fetchProducts();

    _vc = ProductsViewController(onSearch: _searchSubject.add);

    _searchSub = _searchSubject
        .debounceTime(const Duration(milliseconds: 350))
        .distinct()
        .listen((q) => _cubit.fetchProducts(search: q));
  }

  @override
  void dispose() {
    _searchSub?.cancel();
    _searchSubject.close();
    _vc.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProductsCubit>.value(
      value: _cubit,
      child: AppPageShell(
        title: Text(LocaleKeys.products),
        actions: [
          TextButton(
            onPressed: () => _vc.openFilterSheet(context),
            child: Text(
              LocaleKeys.productsFilter,
              style: const TextStyle().setPrimaryColor.s13.medium,
            ),
          ),
        ],
        body: _ProductsBody(controller: _vc),
      ),
    );
  }
}
