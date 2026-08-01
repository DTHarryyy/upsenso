import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/widgets/app_sub_page_bar.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/notifications/domain/billing_notice_service.dart';
import 'package:pos/features/notifications/domain/repositories/i_notifications_repository.dart';
import 'package:pos/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:pos/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:pos/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:pos/features/notifications/presentation/widgets/notifications_empty_state.dart';
import 'package:pos/features/notifications/presentation/widgets/notifications_error_state.dart';
import 'package:pos/features/notifications/presentation/widgets/notifications_filter_tabs.dart';
import 'package:pos/features/notifications/presentation/widgets/notifications_skeleton.dart';

/// Root entry-point for the Notifications shell branch.
///
/// Provides [NotificationsCubit] (via GetIt) and rebuilds whenever the
/// auth state changes so the cubit always loads with the correct business ID.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final businessId = authState is AuthAuthenticated
            ? authState.user.businessId
            : null;

        return BlocProvider(
          create: (ctx) {
            final cubit = NotificationsCubit(
              sl<INotificationsRepository>(),
              sl<BillingNoticeService>(),
            );
            if (businessId != null) cubit.load(businessId);
            return cubit;
          },
          child: const _NotificationsView(),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppSubPageBar(
        title: 'Notifications',
        actions: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              final hasUnread =
                  state is NotificationsLoaded && state.unreadCount > 0;
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton(
                onPressed: () =>
                    context.read<NotificationsCubit>().markAllAsRead(),
                child: const Text('Mark all read'),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: NotificationsFilterTabs(state: state)),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              _buildBody(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, NotificationsState state) {
    if (state is NotificationsInitial || state is NotificationsLoading) {
      return const NotificationsSkeleton();
    }

    if (state is NotificationsError) {
      return SliverFillRemaining(
        child: NotificationsErrorState(message: state.message),
      );
    }

    if (state is NotificationsLoaded) {
      final items = state.displayed;
      if (items.isEmpty) {
        return SliverFillRemaining(
          child: NotificationsEmptyState(filter: state.activeFilter),
        );
      }
      return SliverList.separated(
        itemCount: items.length,
        separatorBuilder: (_, _) =>
            Container(height: 1, color: AppColors.borderSoft),
        itemBuilder: (ctx, i) => NotificationTile(item: items[i]),
      );
    }

    return const SliverToBoxAdapter();
  }
}
