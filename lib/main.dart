import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './constants.dart';

import './screens/chat_screen.dart';
import './screens/profile_screen.dart';
import './screens/update_details_screen.dart';
import './screens/verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:stream_chat_flutter_core/stream_chat_flutter_core.dart'
    as stream_chat;
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Use the local Firebase Functions emulator
  FirebaseFunctions functions = FirebaseFunctions.instance;
  final client =
      stream_chat.StreamChatClient(streamApi, logLevel: stream_chat.Level.INFO);

  // Replace `10.0.2.2` with `localhost` if you're using an iOS simulator
  functions.useFunctionsEmulator('localhost', 5001);

  runApp(Chateo(
    client: client,
  ));
}

class Chateo extends StatelessWidget {
  Chateo({super.key, required this.client});
  final stream_chat.StreamChatClient client;
  final _auth = FirebaseAuth.instance;
  initState() {
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        logger.i('User is currently signed out!');
      } else {
        logger.i('User is signed in!');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.system,
      theme: AppTheme.light(ThemeData.light()),
      darkTheme: AppTheme.dark(ThemeData.dark()),
      builder: (context, child) {
        return stream_chat.StreamChatCore(
          client: client,
          child: child!,
        );
      },
      initialRoute: '/',
      routes: {
        '/': (context) => WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => RegistrationScreen(),
        '/home': (context) => const HomeScreen(),
        '/chat': (context) => const ChatScreen(),
        '/verify': (context) => const VerificationScreen(),
        '/update_details': (context) => const UpdateDetailsScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
