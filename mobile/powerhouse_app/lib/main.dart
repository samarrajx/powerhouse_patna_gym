import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/app_theme.dart';
import 'core/api_service.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/user_shell.dart';
import 'features/dashboard/admin_shell.dart';
import 'features/notifications/notifications_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'core/notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize Notification Service
    await NotificationService.initialize();

  } catch (e) {
    print("Firebase initialization skipped or failed: $e");
  }
  runApp(const ProviderScope(child: PowerHouseApp()));
}

class PowerHouseApp extends ConsumerWidget {
  const PowerHouseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);

    // Setup FCM when authenticated
    if (authState.isAuthenticated) {
      _setupFCM(ref);
    }

    return MaterialApp(
      title: 'PH Gym',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: _getHome(authState),
      builder: (context, child) {
        return _NotificationHandler(child: child!);
      },
    );
  }

  Future<void> _setupFCM(WidgetRef ref) async {
    try {
      final messaging = FirebaseMessaging.instance;
      
      // Request permission
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      print('🔔 FCM Permission status: ${settings.authorizationStatus}');

      // Get token
      final token = await messaging.getToken();
      if (token != null) {
        print('🔔 FCM Device Token: $token');
        await ApiService.post('/auth/device-token', {
          'token': token,
          'platform': Platform.isAndroid ? 'android' : 'ios',
        });
      }

      // Subscribe to global topic
      await messaging.subscribeToTopic('all_users');
      print('🔔 FCM Subscribed to global topic: all_users');
    } catch (e) {
      print("❌ FCM Setup Error: $e");
    }
  }

  Widget _getHome(AuthState authState) {
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!authState.isAuthenticated) return const LoginScreen();
    if (authState.role == 'admin') return const AdminShell();
    return const UserShell();
  }
}

class _NotificationHandler extends ConsumerStatefulWidget {
  final Widget child;
  const _NotificationHandler({required this.child});

  @override
  ConsumerState<_NotificationHandler> createState() => _NotificationHandlerState();
}

class _NotificationHandlerState extends ConsumerState<_NotificationHandler> {
  @override
  void initState() {
    super.initState();
    
    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 main: Received FCM message in foreground: ${message.notification?.title}");
      if (message.notification != null && mounted) {
        // Show system-level local notification even in foreground
        NotificationService.showNotification(message);

        // Also show a snackbar for immediate feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.notification!.title ?? 'New Notification', 
                     style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                Text(message.notification!.body ?? '', style: const TextStyle(color: Colors.white70)),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () {
                ref.read(notificationsProvider.notifier).fetchNotifications();
              },
            ),
          ),
        );
      }
    });

    // Handle interaction when app is in background but opened via notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      ref.read(notificationsProvider.notifier).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
