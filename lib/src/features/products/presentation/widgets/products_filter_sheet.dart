part of '../imports/products_imports.dart';

/// Modal bottom sheet for picking a status filter. Returns the picked
/// status; `null` means "clear filter".
class _ProductsFilterSheet extends StatelessWidget {
  const _ProductsFilterSheet({required this.current});

  final ProductStatus? current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                LocaleKeys.productsFilterByStatus,
                style: const TextStyle().setMainTextColor.s14.semiBold,
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Go.back<ProductStatus?>(null),
                child: Text(
                  LocaleKeys.productsClear,
                  style: const TextStyle().setPrimaryColor.s13.medium,
                ),
              ),
            ],
          ).paddingSymmetric(horizontal: AppPadding.pW16),
          const Divider(),
          // Material 3: a single `RadioGroup` owns the selection; child
          // `RadioListTile`s just declare their `value`.
          RadioGroup<ProductStatus>(
            groupValue: current,
            onChanged: (s) => Go.back<ProductStatus?>(s),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final status in ProductStatus.values)
                  if (status != ProductStatus.unknown)
                    RadioListTile<ProductStatus>(
                      value: status,
                      title: Text(
                        _productStatusLabel(status),
                        style: const TextStyle().setMainTextColor.s13.regular,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ).paddingSymmetric(vertical: AppPadding.pH12),
    );
  }
}
