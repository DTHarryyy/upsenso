import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/notifications/fcm_notification_service.dart';

void main() {
  group('FcmNotificationService.lowStockTopic', () {
    test('creates a business-scoped, FCM-safe topic', () {
      expect(
        FcmNotificationService.lowStockTopic(
          'b6ca661d-a1b8-457b-a942-fb1f3b5bc01e',
        ),
        'low-stock-b6ca661d-a1b8-457b-a942-fb1f3b5bc01e',
      );
    });

    test('rejects blank topics', () {
      expect(
        () => FcmNotificationService.lowStockTopic('***'),
        throwsArgumentError,
      );
    });

    test(
      'is a no-op on unsupported platforms without resolving Firebase',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);

        final service = FcmNotificationService();

        await service.configureTopics(
          businessId: 'b6ca661d-a1b8-457b-a942-fb1f3b5bc01e',
          mayViewStockLevels: true,
          mayManageBilling: true,
        );
        await service.clear();
        await service.dispose();
      },
    );
  });

  group('FcmNotificationService.planAlertsTopic', () {
    test('creates a business-scoped, FCM-safe topic', () {
      expect(
        FcmNotificationService.planAlertsTopic(
          'b6ca661d-a1b8-457b-a942-fb1f3b5bc01e',
        ),
        'plan-alerts-b6ca661d-a1b8-457b-a942-fb1f3b5bc01e',
      );
    });

    test('rejects blank topics', () {
      expect(
        () => FcmNotificationService.planAlertsTopic('***'),
        throwsArgumentError,
      );
    });
  });
}
