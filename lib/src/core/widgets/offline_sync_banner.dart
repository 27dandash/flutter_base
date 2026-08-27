import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../network/cubits/connectivity_cubit.dart';
import '../network/cubits/offline_queue_cubit.dart';

/// Sits at the top of the screen tree and renders a single banner driven by
/// two cubits:
///   - [ConnectivityCubit]  → online / offline
///   - [OfflineQueueCubit]  → pending count + sync status
///
/// Usage: provide both cubits once at the top of the app and drop this
/// widget inside `MaterialApp.builder`.
class OfflineSyncBanner extends StatelessWidget {
  const OfflineSyncBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, bool>(
      builder: (context, online) {
        return BlocBuilder<OfflineQueueCubit, OfflineQueueState>(
          builder: (context, queue) {
            if (online && !queue.isSyncing && queue.pending == 0) {
              return const SizedBox.shrink();
            }

            if (!online) {
              return _Banner(
                color: Colors.red.shade600,
                icon: Icons.wifi_off_rounded,
                text: queue.pending > 0
                    ? 'لا يوجد اتصال — ${queue.pending} عملية في الانتظار'
                    : 'لا يوجد اتصال بالإنترنت',
              );
            }

            if (queue.isSyncing) {
              return _Banner(
                color: Colors.orange.shade700,
                icon: Icons.sync_rounded,
                text: 'جاري المزامنة... (${queue.pending})',
              );
            }

            return _Banner(
              color: Colors.orange.shade700,
              icon: Icons.cloud_upload_outlined,
              text: 'بانتظار المزامنة (${queue.pending})',
            );
          },
        );
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.color, required this.icon, required this.text});

  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
