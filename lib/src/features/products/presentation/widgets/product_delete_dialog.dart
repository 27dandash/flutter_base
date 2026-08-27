part of '../imports/products_imports.dart';

/// Simple confirm dialog. Returns `true` on confirm, `false`/`null`
/// otherwise — let the caller decide what to do.
class _ProductDeleteDialog extends StatelessWidget {
  const _ProductDeleteDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        LocaleKeys.productsDeleteTitle,
        style: const TextStyle().setMainTextColor.s16.semiBold,
      ),
      content: Text(
        LocaleKeys.productsDeleteConfirm,
        style: const TextStyle().setMainTextColor.s13.regular,
      ),
      actions: [
        TextButton(
          onPressed: () => Go.back(false),
          child: Text(
            LocaleKeys.cancel,
            style: const TextStyle().setHintColor.s13.medium,
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.secondary),
          onPressed: () => Go.back(true),
          child: Text(
            LocaleKeys.productsDelete,
            style: const TextStyle().setWhiteColor.s13.semiBold,
          ),
        ),
      ],
    );
  }
}
