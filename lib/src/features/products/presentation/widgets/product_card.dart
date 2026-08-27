part of '../imports/products_imports.dart';

/// Single product row. Tapping opens the details screen; long-press fires
/// the delete dialog so the example covers both navigation and a
/// destructive UI flow with optimistic state.
class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final ProductEntity product;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProductsCubit>();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: EdgeInsetsDirectional.symmetric(
          horizontal: AppPadding.pW12,
          vertical: AppPadding.pH8,
        ),
        leading: CachedImage(
          url: product.imageUrl ?? '',
          width: AppSize.sH50,
          height: AppSize.sH50,
          borderRadius: BorderRadius.circular(AppCircular.r8),
        ),
        title: Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle().setMainTextColor.s14.semiBold,
        ),
        subtitle: Text(
          '${product.price.toCurrency()} ${LocaleKeys.productsCurrency}'
          ' • ${_productStatusLabel(product.status)}',
          style: const TextStyle().setSecondryColor.s12.regular,
        ),
        onTap: () => Go.to(ProductDetailsScreen(productId: product.id)),
        onLongPress: () => _confirmDelete(context, cubit),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ProductsCubit cubit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _ProductDeleteDialog(),
    );
    if (confirmed != true) return;
    // Optimistic delete: cubit removes locally, fires DELETE, rolls back on
    // failure. Surface any failure via the shared snackbar utility.
    final result = await cubit.delete(product.id);
    result.fold(
      (failure) => MessageUtils.showSnackBar(
        context: context,
        baseStatus: BaseStatus.error,
        message: failure.userMessage,
      ),
      (_) {},
    );
  }
}

/// Maps the domain [ProductStatus] to a localized label. Lives in the
/// presentation layer so the domain enum stays free of `LocaleKeys`.
String _productStatusLabel(ProductStatus status) => switch (status) {
  ProductStatus.available => LocaleKeys.productStatusAvailable,
  ProductStatus.outOfStock => LocaleKeys.productStatusOutOfStock,
  ProductStatus.draft => LocaleKeys.productStatusDraft,
  ProductStatus.archived => LocaleKeys.productStatusArchived,
  ProductStatus.unknown => LocaleKeys.failureUnknown,
};
