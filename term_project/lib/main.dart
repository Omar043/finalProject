import 'package:flutter/material.dart';
import 'screens/Events_Joined.dart';
import 'screens/Join_an_Event.dart';
import 'screens/Create_and_Manage_Events.dart';
import 'screens/Sign_In.dart';
import 'package:go_router/go_router.dart';
import 'screens/Sign_Up.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

//impliment redirect that redirects user to login if they are no longer logged in
final GoRouter _router = GoRouter(
  initialLocation: '/sign-in',

  routes: [
    //log in
    GoRoute(
      path: '/sign-in',
      builder: (context, state) => const SignInScreen(),
    ),
    //sign up ()
    GoRoute(
      path: '/sign-up',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const MainScaffold()),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: _router);
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 1;

  final EventsJoinedScreen _eventsJoinedScreen = EventsJoinedScreen();
  final JoinAnEventScreen _joinAnEventScreen = const JoinAnEventScreen();
  final CreateAndManageEventsScreen _createAndManageEventsScreen =
      const CreateAndManageEventsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //following is the index for the bottom navigation bar.
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _eventsJoinedScreen,
          _joinAnEventScreen,
          _createAndManageEventsScreen,
        ],
      ),
      //following is bottom navigaiton bar. It is present in every page once
      //the user is logged in
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'View Events Joined',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt),
            label: 'Join an Event',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Create/Manage Events',
          ),
        ],
      ),
    );
  }
}
