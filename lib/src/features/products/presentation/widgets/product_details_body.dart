part of '../imports/products_imports.dart';

class _ProductDetailsBody extends StatelessWidget {
  const _ProductDetailsBody();

  @override
  Widget build(BuildContext context) {
    return AsyncBlocBuilder<ProductDetailsCubit, ProductEntity>(
      builder: (context, product) {
        return CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: Text(
                product.name,
                style: const TextStyle().setMainTextColor.s16.semiBold,
              ),
              pinned: true,
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedImage(
                        url: product.imageUrl!,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(AppCircular.r12),
                      ),
                    ),
                  16.szH,
                  Row(
                    children: [
                      Text(
                        '${product.price.toCurrency()} '
                        '${LocaleKeys.productsCurrency}',
                        style: const TextStyle().setMainTextColor.s20.bold,
                      ),
                      const Spacer(),
                      Chip(
                        label: Text(
                          _productStatusLabel(product.status),
                          style: const TextStyle().setMainTextColor.s12.medium,
                        ),
                      ),
                    ],
                  ),
                  16.szH,
                  Text(
                    LocaleKeys.productsDescription,
                    style: const TextStyle().setMainTextColor.s14.semiBold,
                  ),
                  8.szH,
                  Text(
                    product.description.isEmpty
                        ? LocaleKeys.productsNoDescription
                        : product.description,
                    style: const TextStyle().setSecondryColor.s13.regular,
                  ),
                ],
              ).paddingAll(AppPadding.pH16),
            ),
          ],
        );
      },
    );
  }
}
