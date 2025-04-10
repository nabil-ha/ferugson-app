import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'api/services.dart';
import 'models/models.dart';
import 'pages/auth/login_page.dart';
import 'pages/coach/coach_dashboard.dart';
import 'pages/player/player_dashboard.dart';
import 'pages/coach/create_session_page.dart';
import 'pages/coach/ai_insights_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Provider<FirebaseService>(
      create: (_) => FirebaseService(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Ferguson',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginPage(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);

    return StreamBuilder<User?>(
      stream: Stream.fromFuture(Future<User?>.microtask(() async {
        // Using a delayed future to simulate a stream since we need to get the user from Firestore
        if (firebaseService.currentUser == null) return null;

        final userService = UserService(firebaseService);
        return await userService.getCurrentUser();
      })),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          // Redirect based on user role
          if (user is Coach) {
            return CoachMainScreen();
          } else if (user is Player) {
            return const PlayerDashboard();
          } else {
            // Other roles can be handled here
            return const Scaffold(
              body: Center(
                child: Text('Unsupported user role'),
              ),
            );
          }
        }

        // No user is signed in
        return const LoginPage();
      },
    );
  }
}

// Navigation container for managing Coach navigation
class CoachMainScreen extends StatefulWidget {
  const CoachMainScreen({super.key});

  @override
  State<CoachMainScreen> createState() => _CoachMainScreenState();
}

class _CoachMainScreenState extends State<CoachMainScreen> {
  int _currentIndex = 1; // Default to Home tab

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      CreateSessionPage(
        onSessionCreated: () {
          setState(() {
            _currentIndex = 1; // Reset to Home tab
          });
        },
      ), // Training tab
      CoachDashboard(
        onSwitchToAI: () {
          setState(() {
            _currentIndex = 2; // Switch to AI tab
          });
        },
      ), // Home tab
      const AIInsightsPage(), // AI tab
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer),
            label: 'Sessions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart_outlined),
            label: 'AI',
          ),
        ],
      ),
    );
  }
}

class PlayerMainScreen extends StatefulWidget {
  const PlayerMainScreen({super.key});

  @override
  State<PlayerMainScreen> createState() => _PlayerMainScreenState();
}

class _PlayerMainScreenState extends State<PlayerMainScreen> {
  int _currentIndex = 0; // Default to Home tab

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const PlayerDashboard(), // Home tab
      const AIInsightsPage(), // AI tab
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart_outlined),
            label: 'AI',
          ),
        ],
      ),
    );
  }
}
