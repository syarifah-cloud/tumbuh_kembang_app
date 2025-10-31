// lib/main.dart (Final dengan Provider dan Routing Lanjutan)

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

// Import Provider Anda
import 'providers/location_provider.dart'; // Sesuaikan path

// Import Model yang akan dilewatkan sebagai argumen
import 'models/clinic_model.dart'; // Sesuaikan path

// Import Screens Anda
import 'screens/welcome_screens.dart';
import 'screens/login_screens.dart';
import 'screens/register_screens.dart';
import 'screens/main_screen.dart';   
import 'screens/set_location_screen.dart'; // Import screen baru
import 'screens/map_route_screen.dart';      // Import screen baru

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env"); 
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: const PantauNusaApp(),
    ),
  );
}

class PantauNusaApp extends StatelessWidget {
  const PantauNusaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PantauNusa',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'),
      ],
      locale: const Locale('id', 'ID'),
      
      // --- ROUTING DIMODIFIKASI DI SINI ---
      initialRoute: '/',
      routes: {
        // Rute statis (tidak butuh argumen)
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainScreen(), 
        '/set-location': (context) => const SetLocationScreen(),
      },
      // onGenerateRoute untuk menangani rute dinamis (yang butuh argumen)
      onGenerateRoute: (settings) {
        // Cek apakah nama rute yang dipanggil adalah '/map-route'
        if (settings.name == '/map-route') {
          // Pastikan argumen yang dikirim adalah objek Clinic
          if (settings.arguments is Clinic) {
            final clinic = settings.arguments as Clinic;
            return MaterialPageRoute(
              builder: (context) {
                // Buat MapRouteScreen dengan data clinic yang diterima
                return MapRouteScreen(clinic: clinic);
              },
            );
          }
        }
        // Jika nama rute tidak cocok, kembalikan null agar Flutter tahu
        // bahwa rute ini tidak ditangani di sini.
        return null; 
      },
      // ------------------------------------
    );
  }
}