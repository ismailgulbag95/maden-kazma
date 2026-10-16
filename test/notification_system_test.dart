import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/localized_test_app.dart';

import 'package:tasin_alti/app/game_controller.dart';
import 'package:tasin_alti/data/save_store.dart';
import 'package:tasin_alti/services/notification_service.dart';
import 'package:tasin_alti/ui/widgets/notification_permission_dialog.dart';

class _MemorySaveStore implements SaveStore {
  String? savePayload;

  @override
  bool recoveredBackup = false;

  @override
  Future<String?> load() async => savePayload;

  @override
  Future<void> save(String rawSave) async {
    savePayload = rawSave;
  }

  @override
  Future<void> clear() async {
    savePayload = null;
  }
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('xyz.luan/audioplayers.global'),
          (call) async => null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('xyz.luan/audioplayers'),
          (call) async => null,
        );
  });

  group('Bildirim Sistemi & İzin Yönetimi Testleri', () {
    test(
      'NotificationService singleton başlatılabilir ve güvenli çalışır',
      () async {
        final service = NotificationService.instance;
        expect(service, isNotNull);

        await service.initialize();
        expect(service.isInitialized, isTrue);

        await service.cancelAll();
        await service.scheduleCargoFullNotification(
          const Duration(minutes: 15),
        );
        await service.scheduleDailyDutyNotification();
        await service.scheduleInactivityNotification();
      },
    );

    test(
      'GameController bildirim ayarlarını ve yaşam döngüsünü yönetir',
      () async {
        final controller = GameController(saveStore: _MemorySaveStore());
        await controller.initialize();

        expect(controller.state.notificationsEnabled, isFalse);
        expect(controller.state.notificationPromptShown, isFalse);

        await controller.setNotificationsEnabled(true);
        expect(controller.state.notificationsEnabled, isTrue);
        expect(controller.state.notificationPromptShown, isTrue);

        await controller.onAppPaused();
        await controller.onAppResumed();

        await controller.setNotificationsEnabled(false);
        expect(controller.state.notificationsEnabled, isFalse);

        await controller.dismissNotificationPrompt();
        expect(controller.state.notificationPromptShown, isTrue);
        expect(controller.state.notificationsEnabled, isFalse);

        controller.dispose();
      },
    );

    testWidgets(
      'NotificationPermissionDialog doğru butonları ve metinleri sunar',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);

        var enabledCalled = false;
        var dismissedCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('tr'),
            supportedLocales: testSupportedLocales,
            localizationsDelegates: testLocalizationDelegates,
            home: Scaffold(
              body: NotificationPermissionDialog(
                onEnable: () async {
                  enabledCalled = true;
                },
                onDismiss: () {
                  dismissedCalled = true;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('MADEN TELSİZİ FREKANSI'), findsOneWidget);
        expect(find.text('Ambar Dolum Alarmı'), findsOneWidget);
        expect(find.text('Günlük Vardiya Görevleri'), findsOneWidget);
        expect(find.text('Sismik Damar Keşifleri'), findsOneWidget);

        final enableButton = find.text('TELSİZİ AÇ (BİLDİRİMLERİ ETKİNLEŞTİR)');
        expect(enableButton, findsOneWidget);

        await tester.tap(enableButton);
        await tester.pumpAndSettle();
        expect(enabledCalled, isTrue);
        expect(dismissedCalled, isFalse);
      },
    );
  });
}
