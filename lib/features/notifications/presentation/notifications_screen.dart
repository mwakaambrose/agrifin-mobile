import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../viewmodels/notifications_viewmodel.dart';
import '../../../core/context/current_context.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = NotificationsViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appCtx = context.watch<CurrentContext>();
    final groupId = appCtx.group_id ?? 1;
    // initial load
    if (!_viewModel.busy && _viewModel.notifications.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _viewModel.load(groupId);
      });
    }
    // error toast
    if (_viewModel.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(_viewModel.error!),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          'Notifications',
          style: GoogleFonts.redHatDisplay(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            tooltip: 'Refresh',
            onPressed: _viewModel.busy ? null : () => _viewModel.load(groupId),
          ),
          if (!_viewModel.isEmpty)
            IconButton(
              icon: Icon(
                Icons.mark_email_read,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              tooltip: 'Mark all as read',
              onPressed: () => _viewModel.markAllAsRead(),
            ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, child) {
            if (_viewModel.busy) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_viewModel.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => _viewModel.load(groupId),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 120),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Notifications',
                            style: GoogleFonts.redHatDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You have no new notifications at this time.',
                            style: GoogleFonts.redHatDisplay(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () => _viewModel.load(groupId),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
                itemCount: _viewModel.notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final notification = _viewModel.notifications[i];
                  final isRead = _viewModel.isNotificationRead(notification.id);
                  return Dismissible(
                    key: ValueKey(notification.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    onDismissed: (_) {
                      _viewModel.dismissNotification(notification.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Notification dismissed'),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: GestureDetector(
                      onTap: () => _viewModel.markAsRead(notification.id),
                      child: Card(
                        elevation: isRead ? 1 : 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        color:
                            isRead
                                ? Theme.of(
                                  context,
                                ).colorScheme.surface.withOpacity(0.7)
                                : Theme.of(context).colorScheme.surface,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Icon(
                            isRead
                                ? Icons.mark_email_read
                                : Icons.mark_email_unread,
                            color:
                                isRead
                                    ? Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.5)
                                    : Theme.of(context).colorScheme.primary,
                            size: 32,
                          ),
                          title: Text(
                            notification.title,
                            style: GoogleFonts.redHatDisplay(
                              fontWeight: FontWeight.bold,
                              color:
                                  isRead
                                      ? Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.7)
                                      : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                notification.message,
                                style: GoogleFonts.redHatDisplay(
                                  color:
                                      isRead
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.6)
                                          : Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _viewModel.formatDate(notification.dateTime),
                                style: GoogleFonts.redHatDisplay(
                                  fontSize: 13,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                          trailing:
                              isRead
                                  ? Icon(
                                    Icons.check_circle,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 22,
                                  )
                                  : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
