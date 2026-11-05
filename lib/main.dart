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
import 'widgets/floating_nav_bar.dart';
import 'services/session_service.dart';
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
      // Re-validate session when app is resumed from background
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
  late final PageController _pageController;
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();

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
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _onPostTap() async {
    SessionService().recordActivity();
    await Navigator.pushNamed(context, '/post');
    // If user was on Profile tab when posting, transition back to Home to see the post
    if (_currentIndex != 0) {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      setState(() => _currentIndex = 0);
    }
    _homeKey.currentState?.loadPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: [
          HomeScreen(key: _homeKey),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: ModernFloatingNavBar(
            currentIndex: _currentIndex,
            onTabSelected: _onTabSelected,
            onPostTap: _onPostTap,
          ),
        ),
      ),
    );
  }
}