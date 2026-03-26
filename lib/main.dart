import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game/ui/screens/wordle_game_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  runApp(const ProviderScope(child: WordleApp()));
}

/// Serves as the root application structure and global theming entrypoint.
class WordleApp extends StatelessWidget {
  const WordleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wördle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        brightness: Brightness.dark,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AdaptiveGameShell(child: WordleGameScreen()),
      },
    );
  }
}

/// Centres the game and constrains it to a mobile-width viewport on wide screens.
/// On a phone this wrapper is invisible — the game fills the screen as normal.
/// On a desktop browser this prevents the layout from stretching awkwardly.
class AdaptiveGameShell extends StatelessWidget {
  final Widget child;
  const AdaptiveGameShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: child,
        ),
      ),
    );
  }
}
