import 'package:flutter_test/flutter_test.dart';
import 'package:digi_lib_app/src/services/notification_service.dart';
import 'package:digi_lib_app/src/models/entities/share.dart';

void main() {
  group('NotificationService', () {
    late NotificationService service;

    setUp(() {
      service = NotificationService.instance;
    });

    tearDown(() async {
      service.clearAll();
    });

    test('should be a singleton', () {
      final service1 = NotificationService.instance;
      final service2 = NotificationService.instance;
      expect(service1, same(service2));
    });

    test('should add notifications', () async {
      final notification = AppNotification(
        id: 'test1',
        type: NotificationType.syncCompleted,
        title: 'Test Notification',
        message: 'This is a test',
        timestamp: DateTime.now(),
      );

      await service.addNotification(notification);
      
      expect(service.notifications.length, equals(1));
      expect(service.notifications.first.id, equals('test1'));
    });

    test('should track unread count', () async {
      final notification1 = AppNotification(
        id: 'test1',
        type: NotificationType.syncCompleted,
        title: 'Test 1',
        message: 'Message 1',
        timestamp: DateTime.now(),
      );

      final notification2 = AppNotification(
        id: 'test2',
        type: NotificationType.syncFailed,
        title: 'Test 2',
        message: 'Message 2',
        timestamp: DateTime.now(),
      );

      await service.addNotification(notification1);
      await service.addNotification(notification2);
      
      expect(service.unreadCount, equals(2));
      
      service.markAsRead('test1');
      expect(service.unreadCount, equals(1));
    });

    test('should mark all as read', () async {
      for (int i = 0; i < 3; i++) {
        await service.addNotification(AppNotification(
          id: 'test$i',
          type: NotificationType.syncCompleted,
          title: 'Test $i',
          message: 'Message $i',
          timestamp: DateTime.now(),
        ));
      }

      expect(service.unreadCount, equals(3));
      
      service.markAllAsRead();
      expect(service.unreadCount, equals(0));
    });

    test('should remove notifications', () async {
      final notification = AppNotification(
        id: 'test1',
        type: NotificationType.syncCompleted,
        title: 'Test',
        message: 'Message',
        timestamp: DateTime.now(),
      );

      await service.addNotification(notification);
      expect(service.notifications.length, equals(1));
      
      service.removeNotification('test1');
      expect(service.notifications.length, equals(0));
    });

    test('should clear all notifications', () async {
      for (int i = 0; i < 3; i++) {
        await service.addNotification(AppNotification(
          id: 'test$i',
          type: NotificationType.syncCompleted,
          title: 'Test $i',
          message: 'Message $i',
          timestamp: DateTime.now(),
        ));
      }

      expect(service.notifications.length, equals(3));
      
      service.clearAll();
      expect(service.notifications.length, equals(0));
    });

    test('should send share invitation notification', () async {
      final share = Share(
        id: 'share123',
        subjectId: 'doc123',
        subjectType: ShareSubjectType.document,
        ownerId: 'owner123',
        granteeEmail: 'user@example.com',
        permission: SharePermission.view,
        createdAt: DateTime.now(),
      );

      await service.sendShareInvitation(share, 'John Doe', 'Test Document');
      
      expect(service.notifications.length, equals(1));
      expect(service.notifications.first.type, equals(NotificationType.shareInvitation));
      expect(service.notifications.first.title, equals('Document Shared'));
    });

    test('should send sync notifications', () async {
      await service.sendSyncCompletedNotification(5);
      expect(service.notifications.length, equals(1));
      expect(service.notifications.first.type, equals(NotificationType.syncCompleted));

      await service.sendSyncFailedNotification('Network error');
      expect(service.notifications.length, equals(2));
      expect(service.notifications.first.type, equals(NotificationType.syncFailed));
    });

    test('should send scan notifications', () async {
      await service.sendScanProgressNotification('My Library', 50, 100);
      expect(service.notifications.length, equals(1));
      expect(service.notifications.first.type, equals(NotificationType.scanProgress));

      await service.sendScanCompletedNotification('My Library', 100);
      expect(service.notifications.length, equals(2));
      expect(service.notifications.first.type, equals(NotificationType.scanCompleted));

      await service.sendScanFailedNotification('My Library', 'Permission denied');
      expect(service.notifications.length, equals(3));
      expect(service.notifications.first.type, equals(NotificationType.scanFailed));
    });

    test('should get notifications by type', () async {
      await service.sendSyncCompletedNotification(5);
      await service.sendSyncFailedNotification('Error');
      await service.sendScanCompletedNotification('Library', 10);

      final syncNotifications = service.getNotificationsByType(NotificationType.syncCompleted);
      expect(syncNotifications.length, equals(1));

      final scanNotifications = service.getNotificationsByType(NotificationType.scanCompleted);
      expect(scanNotifications.length, equals(1));
    });

    test('should get unread notifications', () async {
      await service.sendSyncCompletedNotification(5);
      await service.sendSyncFailedNotification('Error');
      
      service.markAsRead(service.notifications.first.id);
      
      final unreadNotifications = service.getUnreadNotifications();
      expect(unreadNotifications.length, equals(1));
    });

    test('should update preferences', () async {
      const newPreferences = NotificationPreferences(
        syncNotifications: false,
        scanNotifications: true,
        jobNotifications: false,
        shareNotifications: true,
        commentNotifications: false,
      );

      await service.updatePreferences(newPreferences);
      expect(service.preferences.syncNotifications, equals(false));
      expect(service.preferences.scanNotifications, equals(true));
    });

    test('should provide statistics', () async {
      await service.sendSyncCompletedNotification(5);
      await service.sendScanCompletedNotification('Library', 10);
      await service.sendSyncFailedNotification('Error');

      final stats = service.getStatistics();
      expect(stats['total_notifications'], equals(3));
      expect(stats['unread_count'], equals(3));
      expect(stats['type_counts'], isA<Map<String, int>>());
    });

    test('should handle notification streams', () async {
      bool notificationReceived = false;
      bool newNotificationReceived = false;

      service.notificationsStream.listen((notifications) {
        notificationReceived = true;
      });

      service.newNotificationStream.listen((notification) {
        newNotificationReceived = true;
      });

      await service.sendSyncCompletedNotification(5);

      // Give streams time to emit
      await Future.delayed(const Duration(milliseconds: 10));

      expect(notificationReceived, isTrue);
      expect(newNotificationReceived, isTrue);
    });
  });
}