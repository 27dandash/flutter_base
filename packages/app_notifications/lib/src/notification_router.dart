sealed class NotificationAction {
  const NotificationAction();
}

final class NavigateToChat extends NotificationAction {
  final String chatId;
  const NavigateToChat(this.chatId);
}

final class NavigateToScreen extends NotificationAction {
  final String route;
  const NavigateToScreen(this.route);
}

final class OpenUrl extends NotificationAction {
  final Uri url;
  const OpenUrl(this.url);
}

final class DismissAction extends NotificationAction {
  const DismissAction();
}

abstract interface class NotificationRouter {
  Future<void> route(NotificationAction action);
}
