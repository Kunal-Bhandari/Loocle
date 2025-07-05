import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/gallery_screen.dart';
import 'providers/image_provider.dart' as custom;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => custom.ImageProvider(),
      child: MaterialApp(
        title: 'Photo Gallery',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 1,
          ),
        ),
        home: const GalleryScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}