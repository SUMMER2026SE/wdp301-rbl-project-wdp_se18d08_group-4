import '../../../core/mock/mock_provider_data.dart';
import '../../../core/mock/mock_provider_messages.dart';
import '../../orders/domain/provider_order.dart';
import '../domain/chat_models.dart';

class ProviderChatRepository {
  List<ProviderChatThread> buildThreads(List<ProviderOrder> orders) {
    MockProviderMessages.ensureSeeded(orders);

    final threads = <ProviderChatThread>[];
    for (final o in orders) {
      if (o.customerId == null || o.customerId!.isEmpty) continue;
      final tid = ProviderChatThread.threadIdFor(o.id);
      final meta = MockProviderMessages.metaFor(tid);
      if (meta == null) continue;

      threads.add(
        ProviderChatThread.fromOrder(
          o,
          customerName: _customerName(o.customerId),
          lastPreview: meta.preview,
          lastAt: meta.lastAt,
          unreadCount: meta.unread,
        ),
      );
    }

    threads.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return threads;
  }

  Future<List<ProviderChatMessage>> fetchMessages(String threadId) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return MockProviderMessages.messagesFor(threadId);
  }

  Future<ProviderChatMessage> sendMessage({
    required String threadId,
    required String content,
    required bool canSend,
  }) async {
    if (!canSend) {
      throw StateError('Đơn đã kết thúc — chỉ được xem lại tin nhắn.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final msg = ProviderChatMessage(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      threadId: threadId,
      senderRole: MessageSenderRole.provider,
      content: content,
      createdAt: DateTime.now(),
    );
    MockProviderMessages.appendMessage(msg);
    return msg;
  }

  String _customerName(String? id) => MockProviderData.customerNameOf(id);
}
