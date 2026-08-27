part of '../imports/products_imports.dart';

/// Body of [ProductsScreen]. Three concerns:
///   1. Render the search field (top, sticky).
///   2. Render the list / loading / error / empty states.
///   3. Apply the optional status filter (UI-side; the cubit holds the
///      unfiltered server data so toggling filters doesn't hit the API).
class _ProductsBody extends StatelessWidget {
  const _ProductsBody({required this.controller});

  final ProductsViewController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProductsSearchField(controller: controller),
        Expanded(
          child: AsyncBlocBuilder<ProductsCubit, List<ProductEntity>>(
            onRetry: () => context.read<ProductsCubit>().fetchProducts(
              search: controller.searchController.text,
            ),
            builder: (context, products) {
              return ValueListenableBuilder<ProductStatus?>(
                valueListenable: controller.statusFilter,
                builder: (_, filter, _) {
                  final visible = filter == null
                      ? products
                      : products
                            .where((p) => p.status == filter)
                            .toList(growable: false);

                  if (visible.isEmpty) {
                    // Compatibility view retained until this demo feature is
                    // removed or migrated as a complete product slice.
                    // ignore: deprecated_member_use_from_same_package
                    return EmptyWidget(
                      title: LocaleKeys.productsEmpty,
                      desc: LocaleKeys.errorexceptionNotcontaindesc,
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () =>
                        context.read<ProductsCubit>().fetchProducts(
                          search: controller.searchController.text,
                        ),
                    child: ListView.separated(
                      controller: controller.scrollController,
                      padding: EdgeInsetsDirectional.symmetric(
                        horizontal: AppPadding.pW12,
                        vertical: AppPadding.pH8,
                      ),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => 8.szH,
                      itemBuilder: (_, i) => _ProductCard(product: visible[i]),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
