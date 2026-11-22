part of 'app_dropdown.dart';

extension _DropdownTrigger<T> on _AppDropdownState<T> {
  String _getDisplayText(
    dynamic value, {
    bool isLoading = false,
    bool isFailer = false,
  }) {
    // While loading the field renders normally (hint / current value); only
    // the arrow turns into a loader and the field is not tappable.
    if (isFailer) return LocaleKeys.exceptionError;

    if (widget.isMultiSelect) {
      final selected = value as List<T>? ?? [];
      if (selected.isEmpty) return widget.hint ?? LocaleKeys.selectAnOption;
      return selected.map(widget.itemAsString).join(', ');
    }

    if (value == null) return widget.hint ?? LocaleKeys.selectAnOption;
    return widget.itemAsString(value);
  }

  /// Trailing icon of the field.
  ///
  /// While the data is loading a spinner is shown (the field is not tappable);
  /// when the data arrives it animates into the down-arrow.
  Widget _buildSuffix(
    BuildContext context, {
    bool isLoading = false,
    bool isFailer = false,
  }) {
    final Widget child;
    if (isLoading) {
      child = SizedBox(
        key: const ValueKey('dropdown-loading'),
        width: DropdownLayout.selectionWidgetSize.w,
        height: DropdownLayout.selectionWidgetSize.h,
        child: const CircularProgressIndicator(
          strokeWidth: DropdownLayout.loadingIndicatorStroke,
          color: AppColors.primary,
        ),
      );
    } else if (isFailer) {
      child = Icon(
        Icons.error_outline,
        key: const ValueKey('dropdown-error'),
        color: AppColors.error,
        size: DropdownLayout.errorIconSize.h,
      );
    } else if (widget.readonly) {
      child = const SizedBox.shrink(key: ValueKey('dropdown-none'));
    } else {
      child = KeyedSubtree(
        key: const ValueKey('dropdown-arrow'),
        child: AppAssets.svg.baseSvg.arrowDown.svg(
          colorFilter: ColorFilter.mode(
            widget.suffixIconColor ??
                Theme.of(context).colorScheme.onSurfaceVariant,
            BlendMode.srcIn,
          ),
        ),
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: child,
    );
  }

  Widget _buildFieldChrome(
    BuildContext context,
    FormFieldState<dynamic> state,
    dynamic value,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          _buildLabel(context),
          SizedBox(height: AppSize.sH6),
        ],
        // When a paginated cubit is attached, react to its loading/error
        // state so the trigger shows a spinner / error icon automatically.
        if (widget.paginatedCubit != null)
          BlocBuilder<PaginatedAsyncCubit<T>, PaginatedState<T>>(
            bloc: widget.paginatedCubit,
            buildWhen: (prev, curr) => prev.status != curr.status,
            builder: (ctx, pState) => _buildTrigger(
              context,
              state,
              value,
              overrideIsLoading: pState.isFirstLoad,
              overrideIsFailer: pState.isInitialError,
            ),
          )
        else
          _buildTrigger(context, state, value),
        if (state.hasError && state.errorText != null)
          Padding(
            padding: EdgeInsetsDirectional.only(
              top: DropdownLayout.errorTopGap.h,
              start: DropdownLayout.errorStartGap.w,
            ),
            child: Text(
              state.errorText!,
              style: context.textStyle.s12.regular.setColor(AppColors.error),
            ),
          ),
      ],
    );
  }

  Widget _buildLabel(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: widget.label,
            style:
                widget.labelTextStyle ??
                context.textStyle.s14.regular.setColor(
                  Theme.of(context).colorScheme.onSurface,
                ),
          ),
          if (widget.isOptional)
            TextSpan(
              text: ' (${LocaleKeys.optional})',
              style: context.textStyle.s12.regular.setColor(
                Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrigger(
    BuildContext context,
    FormFieldState<dynamic> state,
    dynamic value, {
    bool overrideIsLoading = false,
    bool overrideIsFailer = false,
  }) {
    final effectiveIsLoading = overrideIsLoading || widget.isLoading;
    final effectiveIsFailer = overrideIsFailer || widget.isFailer;
    final borderRadius =
        widget.borderRadius ??
        BorderRadius.circular(DropdownLayout.fieldBorderRadius.r);
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: state.hasError
            ? Border.all(
                width: 0.5,
                color: AppColors.error.withValues(alpha: 0.65),
              )
            : null,
      ),
      child: Semantics(
        button: true,
        enabled: !widget.readonly && !effectiveIsLoading,
        label:
            widget.semanticLabel ??
            widget.label ??
            _getDisplayText(
              value,
              isLoading: effectiveIsLoading,
              isFailer: effectiveIsFailer,
            ),
        child: InkWell(
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          borderRadius: borderRadius,
          onTap: widget.readonly || effectiveIsLoading
              ? null
              : effectiveIsFailer && widget.onRetry != null
              ? widget.onRetry
              : () => _openSheet(state),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: widget.contentPadding ?? EdgeInsets.all(AppPadding.pH12),
            decoration: BoxDecoration(
              color: widget.readonly
                  ? Theme.of(context).disabledColor.withValues(alpha: 0.12)
                  : widget.fillColor ??
                        Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: borderRadius,
              border: Border.all(
                color: state.hasError
                    ? AppColors.error
                    : (widget.isBordered
                          ? AppColors.border
                          : Colors.transparent),
                width: state.hasError ? 1.0 : 0.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _getDisplayText(
                      value,
                      isLoading: effectiveIsLoading,
                      isFailer: effectiveIsFailer,
                    ),
                    overflow: TextOverflow.ellipsis,
                    style:
                        widget.style ??
                        (_isValueEmpty(value)
                            ? (widget.hintTextStyle ??
                                  context.textStyle.s12.regular.setColor(
                                    Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ))
                            : context.textStyle.s14.regular.setColor(
                                widget.readonly
                                    ? Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                    : Theme.of(context).colorScheme.onSurface,
                              )),
                  ),
                ),
                _buildSuffix(
                  context,
                  isLoading: effectiveIsLoading,
                  isFailer: effectiveIsFailer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
