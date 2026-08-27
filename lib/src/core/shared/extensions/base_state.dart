import 'package:flutter/material.dart';

enum BaseStatus { initial, loading, loadingMore, success, error }

extension BasseStatusExt on BaseStatus {
  bool get isInitial => this == BaseStatus.initial;

  bool get isLoading => this == BaseStatus.loading;

  bool get isLoadingMore => this == BaseStatus.loadingMore;

  bool get isSuccess => this == BaseStatus.success;

  bool get isError => this == BaseStatus.error;

  T when<T>({
    T Function()? onInitial,
    required T Function() onSuccess,
    required T Function() onLoading,
    required T Function() onError,
    required Widget Function() onLoadingMore,
  }) {
    switch (this) {
      case BaseStatus.initial:
        return onInitial?.call() ?? onLoading();
      case BaseStatus.loading:
        return onLoading();
      case BaseStatus.success:
      case BaseStatus.loadingMore:
        return onSuccess();
      case BaseStatus.error:
        return onError();
    }
  }
}
