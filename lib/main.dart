import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/auth_service.dart';
import 'services/api_debug_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'widgets/debug_log_viewer.dart';
import 'widgets/splash_screen.dart';
import 'app_keys.dart';
import 'config/app_route_observer.dart';
import 'services/payment_deep_link_controller.dart';
import 'utils/app_theme.dart';
import 'utils/http_client_helper.dart';
import 'services/app_config_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Global HTTP override to handle self-signed SSL certificates
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Accept all certificates (including self-signed)
        // In production, you should validate certificates properly
        return true;
      };
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure HTTP client to accept self-signed certificates
  // This affects all network requests including images
  HttpOverrides.global = MyHttpOverrides();
  
  // Initialize cookie jar for refresh token support
  await HttpClientHelper.initCookieJar();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final AuthService _authService;
  late final ApiDebugService _apiDebugService;
  late final AppConfigService _appConfigService;
  bool _forceUpdateDialogShown = false;
  bool _isInitialized = false;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authService = AuthService();
    _apiDebugService = ApiDebugService();
    _appConfigService = AppConfigService()..addListener(_onAppConfigLoaded);
    // Use post-frame callback to ensure UI is built first, then initialize
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  @override
  void dispose() {
    PaymentDeepLinkController.instance.dispose();
    _appConfigService.removeListener(_onAppConfigLoaded);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('📱 App Lifecycle State Changed: $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        print('✅ App resumed - checking auth state');
        // Re-verify auth state when app comes back to foreground
        _verifyAuthState();
        // Screen protection removed to prevent dark screen issue
        break;
      case AppLifecycleState.paused:
        print('⏸️ App paused - going to background');
        break;
      case AppLifecycleState.detached:
        print('🔌 App detached');
        break;
      case AppLifecycleState.inactive:
        print('💤 App inactive');
        // Don't change screen protection during inactive state
        // It's a transitional state between active and paused/resumed
        // Screen protection will be handled in paused/resumed states
        break;
      case AppLifecycleState.hidden:
        print('👻 App hidden');
        break;
    }
  }

  Future<void> _verifyAuthState() async {
    print('🔍 Verifying auth state...');
    print('🔍 Current user: ${_authService.currentUser?.userName}');
    print('🔍 Token exists: ${_authService.token != null}');
    print('🔍 Is authenticated: ${_authService.isAuthenticated}');
    
    // If not authenticated but app was initialized, re-initialize to check SharedPreferences
    if (!_authService.isAuthenticated && _isInitialized) {
      print('⚠️ Not authenticated after resume, re-initializing...');
      await Future.wait([_authService.init(), _appConfigService.fetchConfig()]);
    }
  }

  Future<void> _initializeApp() async {
    print('🚀 Starting app initialization...');
    try {
      await Future.wait([_authService.init(), _appConfigService.fetchConfig()]);
      print('✅ AuthService initialization completed');
      print('✅ IsAuthenticated: ${_authService.isAuthenticated}');
      print('✅ User: ${_authService.currentUser?.userName}');
      
      // Check if onboarding has been completed
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      print('✅ Onboarding completed: $onboardingCompleted');
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _showOnboarding = !onboardingCompleted;
        });
        print('✅ App initialization completed, showing UI');
        print('✅ Show onboarding: $_showOnboarding');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          PaymentDeepLinkController.instance.init(authService: _authService);
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error during app initialization: $e');
      print('❌ Stack trace: $stackTrace');
      // Still set initialized to true so the app doesn't hang
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _showOnboarding = true; // Show onboarding on error as fallback
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          PaymentDeepLinkController.instance.init(authService: _authService);
        });
      }
    }
  }


  void _onAppConfigLoaded() {
    if (_forceUpdateDialogShown) return;
    if (!_appConfigService.isLoaded) return;
    if (!_appConfigService.isForceUpdateRequired()) return;

    final ctx = appNavigatorKey.currentContext;
    if (ctx == null) return;
    _forceUpdateDialogShown = true;
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Update Required'),
          content: const Text(
            'A new version of the app is available. Please update to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final url = Uri.parse(
                  defaultTargetPlatform == TargetPlatform.iOS
                      ? 'https://apps.apple.com/us/app/tamergat/id6761669724'
                      : 'https://play.google.com/store/apps/details?id=com.educraft.tamergat',
                );
                if (await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication);
              },
              child: const Text('Update Now'),
            ),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authService),
        ChangeNotifierProvider.value(value: _apiDebugService),
        ChangeNotifierProvider.value(value: _appConfigService),
      ],
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        scaffoldMessengerKey: appScaffoldMessengerKey,
        title: 'GAT Maths - Tamer El-Sawy',
        debugShowCheckedModeBanner: false,
        navigatorObservers: [appRouteObserver],
        theme: AppTheme.lightTheme,
        locale: const Locale('en'),
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: child ?? const SizedBox.shrink(),
          );
        },
        home:!_isInitialized?const SplashScreen():  _showOnboarding ? const OnboardingScreen() : const AppWithDebugButton(),
      ),
    );
  }
}

class AppWithDebugButton extends StatelessWidget {
  const AppWithDebugButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const AuthWrapper(),
        // Debug button - only visible in debug mode
        // Note: This button may be hidden behind other UI elements
        // Use Profile Screen → Developer Tools as alternative access
        if (kDebugMode)
          Positioned(
            top: 50, // Moved down a bit to avoid status bar
            right: 10,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DebugLogViewer(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8), // Changed to red for visibility
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bug_report_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        print('🔄 AuthWrapper rebuilding...');
        print('🔍 IsLoading: ${authService.isLoading}');
        print('🔍 IsAuthenticated: ${authService.isAuthenticated}');
        print('🔍 Current user: ${authService.currentUser?.userName}');
        print('🔍 Token exists: ${authService.token != null}');

        // Show loading indicator while checking authentication
        if (authService.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Return the appropriate screen based on authentication state
        // This will automatically update when authService.notifyListeners() is called
        return authService.isAuthenticated
            ? const HomeScreen()
            : const LoginScreen();
      },
    );
  }
}
