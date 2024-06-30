import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'camera_screen/camera_screen.dart'; // Updated import

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Green Health',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(1, 217, 237, 191)),
        useMaterial3: true,
        fontFamily: "Jost",
      ),
      home: const MyHomePage(title: 'Green Health'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text("Welcome", style: TextStyle(fontFamily: "Jost",fontSize: 36.0, fontWeight:FontWeight.bold)),
            const Padding( padding: EdgeInsets.only(top:81.0),child: Text(
              'Snap a pic of your plant to get started!',textAlign: TextAlign.center,
             style: TextStyle(fontFamily: "Jost",fontSize: 20.0))),
            Padding(
              padding: const EdgeInsets.only(top: 140.0),
              child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CameraScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(222, 144, 210, 109),
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(24.0)
              ),
              child: const Icon(
                Icons.forest,
                size: 32.0,
                
              ),
            ), 
            ),
          ],
        ),
      ),
    );
  }
}
