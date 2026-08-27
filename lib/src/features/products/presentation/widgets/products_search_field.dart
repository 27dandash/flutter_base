part of '../imports/products_imports.dart';

/// Bound to the [ProductsViewController]'s `searchController`.
///
/// Pumping each keystroke through `onSearch` (a `BehaviorSubject.add`
/// upstream) keeps debounce logic in one place — the screen's `initState`.
class _ProductsSearchField extends StatelessWidget {
  const _ProductsSearchField({required this.controller});

  final ProductsViewController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller.searchController,
      textInputAction: TextInputAction.search,
      onChanged: controller.onSearch,
      style: const TextStyle().setMainTextColor.s13.regular,
      decoration: InputDecoration(
        hintText: LocaleKeys.productsSearchHint,
        hintStyle: const TextStyle().setHintColor.s13.regular,
        prefixIcon: IconWidget(
          icon: AppAssets.svg.baseSvg.search.path,
          height: AppSize.sH20,
        ).paddingAll(AppPadding.pH12),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller.searchController,
          builder: (_, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: IconWidget(
                icon: AppAssets.svg.baseSvg.dropDownClose.path,
                height: AppSize.sH16,
              ),
              onPressed: controller.clearSearch,
            );
          },
        ),
        filled: true,
        fillColor: AppColors.scaffoldBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppCircular.r12),
          borderSide: BorderSide.none,
        ),
      ),
    ).paddingSymmetric(horizontal: AppPadding.pW12, vertical: AppPadding.pH8);
  }
}
