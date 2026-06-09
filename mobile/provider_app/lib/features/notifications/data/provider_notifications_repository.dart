import '../../../core/mock/mock_provider_notifications.dart';
import '../domain/provider_notification_models.dart';

class ProviderNotificationsRepository {
  Future<List<ProviderNotification>> fetchInbox() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return MockProviderNotifications.inboxWithReadState();
  }

  Future<ProviderNotification?> byId(String id) async {
    return MockProviderNotifications.byId(id);
  }

  Future<void> markRead(String id) async {
    MockProviderNotifications.readIds.add(id);
  }

  Future<void> markAllRead() async {
    for (final n in MockProviderNotifications.inbox) {
      MockProviderNotifications.readIds.add(n.id);
    }
  }

  Future<int> unreadCount() async => MockProviderNotifications.unreadCount();
}
