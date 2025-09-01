import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_client1/firebase_options.dart';
import 'package:expense_tracker_client1/screens/homepage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  final firestore = FirebaseFirestore.instance;
  final doc = await firestore.collection('spendingTotals').doc('current').get();
  if (!doc.exists) {
    await firestore.collection('spendingTotals').doc('current').set({
      'grocery': 0.0,
      'lunch': 0.0,
      'others': 0.0,
    });
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Homepage(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color.fromARGB(255, 18, 14, 24),
          brightness: Brightness.light,
        ),
      ),
    );
  }
}
