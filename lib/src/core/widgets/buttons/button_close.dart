import 'package:flutter/material.dart';

@Deprecated('Use CloseButton or IconButton with a contextual Navigator.')
class ButtonClose extends StatelessWidget {
  final VoidCallback? onTap;

  const ButtonClose({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
      onPressed: onTap ?? () => Navigator.of(context).maybePop(),
      icon: const Icon(Icons.close),
    );
  }
}
