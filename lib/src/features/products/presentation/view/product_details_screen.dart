part of '../imports/products_imports.dart';

/// Open from a list tile:
///   `Go.to(ProductDetailsScreen(productId: id))`
class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({super.key, required this.productId});

  final int productId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProductDetailsCubit>(
      // `..fetchDetails(productId)` triggers the call as soon as the cubit
      // is built. The cascade keeps `create` a single expression.
      create: (_) => injector<ProductDetailsCubit>()..fetchDetails(productId),
      child: const Scaffold(body: _ProductDetailsBody()),
    );
  }
}
