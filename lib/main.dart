import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_dart/firebase_dart.dart';
import 'pages/signin.dart';
import 'widgets/headerAnfooter.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseDart.setup(storagePath: null);
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: 'AIzaSyBujy5VtHYtgd_mVxaJ_Kav_Myg0mNrjI8',
      appId: '1:928662382569:web:31443ebd4e33c303a04d78',
      messagingSenderId: '928662382569',
      projectId: 'part3-29031',
      storageBucket: 'part3-29031.firebasestorage.app',
      authDomain: 'part3-29031.firebaseapp.com',
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CourtSync',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A2A4A),
        ),
      ),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = DatabaseService.instance.authStateChanges.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (DatabaseService.instance.isSignedIn) {
      return const HeaderAndFooter();
    }
    return const SignInPage();
  }
}
