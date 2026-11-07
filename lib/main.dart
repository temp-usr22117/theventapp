import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/post_screen.dart';
import 'screens/post_details_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/about_screen.dart';
import 'screens/report_bug_screen.dart';
import 'widgets/floating_nav_bar.dart';
import 'widgets/desktop_sidebar.dart';
import 'widgets/app_drawer.dart';
import 'services/session_service.dart';
import 'services/auth_service.dart';
import 'utils/responsive.dart';
import 'models/post_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TheVent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        primaryColor: const Color(0xFF7C4DFF),
      ),
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainScreen(),
        '/post': (context) => const PostScreen(),
        '/about': (context) => const AboutScreen(),
        '/report-bug': (context) => const ReportBugScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/post-details') {
          final post = settings.arguments as PostModel;
          return MaterialPageRoute(
            builder: (context) => PostDetailsScreen(post: post),
          );
        }
        return null;
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  bool _isChecking = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAuthSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAuthSession();
    }
  }

  Future<void> _checkAuthSession() async {
    final isValid = await SessionService().isSessionValid();
    if (!isValid) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _isAuthenticated = false;
        });
      }
      return;
    }

    // Session is marked valid locally; verify/await Firebase user restore
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      try {
        user = await FirebaseAuth.instance
            .authStateChanges()
            .firstWhere((u) => u != null)
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        user = FirebaseAuth.instance.currentUser;
      }
    }

    if (!mounted) return;

    if (user != null) {
      await SessionService().recordActivity();
      setState(() {
        _isChecking = false;
        _isAuthenticated = true;
      });
    } else {
      await SessionService().onLogout();
      setState(() {
        _isChecking = false;
        _isAuthenticated = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const SplashScreen();
    }

    if (_isAuthenticated) {
      return const MainScreen();
    }

    return const LoginScreen();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isSidebarCollapsed = false;
  late final PageController _pageController;
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSessionOnResume();
    }
  }

  Future<void> _checkSessionOnResume() async {
    final isValid = await SessionService().isSessionValid();
    if (!isValid && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  void _onTabSelected(int index) {
    SessionService().recordActivity();
    final isWide = Responsive.isWide(context);

    if (isWide) {
      if (_currentIndex == index) return;
      setState(() => _currentIndex = index);
      if (index == 0) {
        _homeKey.currentState?.loadPosts();
      }
      return;
    }

    // On Mobile:
    if (index == 0 || index == 1) {
      if (_currentIndex == index) return;
      setState(() => _currentIndex = index);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      if (index == 0) {
        _homeKey.currentState?.loadPosts();
      }
    } else if (index == 2) {
      Navigator.pushNamed(context, '/about');
    } else if (index == 3) {
      Navigator.pushNamed(context, '/report-bug');
    }
  }

  Future<void> _onPostTap() async {
    SessionService().recordActivity();
    await Navigator.pushNamed(context, '/post');
    if (!mounted) return;
    // If user was on Profile tab when posting, transition back to Home to see the post
    if (_currentIndex != 0) {
      if (!Responsive.isWide(context)) {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
      setState(() => _currentIndex = 0);
    }
    _homeKey.currentState?.loadPosts();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Color(0xFF9E9E9E)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF9E9E9E)),
            ),
          ),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              Navigator.pop(dialogContext);
              await AuthService().logout();
              if (mounted) {
                nav.pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(
                color: Color(0xFFFF4D6D),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = Responsive.isWide(context);

    if (isWide) {
      // Desktop / Wide layout (Reddit / Twitter style)
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFF0D0D0D),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Navigation Sidebar (collapsible via hamburger)
            DesktopSidebar(
              currentIndex: _currentIndex,
              onTabSelected: _onTabSelected,
              onPostTap: _onPostTap,
              isCollapsed: _isSidebarCollapsed,
              onToggleCollapse: () {
                setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
              },
              onLogout: _showLogoutDialog,
            ),

            // Center-Right Content Area (Constrained max-width for reading)
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  HomeScreen(key: _homeKey, onPostTap: _onPostTap),
                  const ProfileScreen(),
                  const AboutScreen(),
                  const ReportBugScreen(),
                ],
              ),
            ),
          ],
        ),
        // No floating navigation bar on desktop/web!
        bottomNavigationBar: null,
      );
    }

    // Mobile layout
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        currentIndex: _currentIndex,
        onTabSelected: _onTabSelected,
        onPostTap: _onPostTap,
        onLogout: _showLogoutDialog,
      ),
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: [
          HomeScreen(key: _homeKey, onPostTap: _onPostTap),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: ModernFloatingNavBar(
            currentIndex: _currentIndex > 1 ? 0 : _currentIndex,
            onTabSelected: _onTabSelected,
            onPostTap: _onPostTap,
          ),
        ),
      ),
    );
  }
}
