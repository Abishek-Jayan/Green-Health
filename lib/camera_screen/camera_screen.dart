import 'dart:ffi';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

const geminiApiKey = "AIzaSyAkTu1APiM_33fZaVeNSXPkPU5v8nUKs2I"; 
final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: geminiApiKey);

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  Uint8List? imageData;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.high,
    );

    _initializeControllerFuture = _controller!.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Camera')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller!);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera),
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final image = await _controller!.takePicture();
            imageData = await image.readAsBytes();
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Picture taken')),
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(imageData: imageData!),
              ),
            );
          } catch (e) {
            print(e);
          }
        },
      ),
    );
  }
}

class DisplayPictureScreen extends StatefulWidget {
  final Uint8List imageData;

  const DisplayPictureScreen({Key? key, required this.imageData}) : super(key: key);

  @override
  _DisplayPictureScreenState createState() => _DisplayPictureScreenState(imageData: imageData);
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  Map<String, dynamic>? plantDetails;
  final Uint8List imageData;

  _DisplayPictureScreenState({required this.imageData});

  @override
  void initState() {
    super.initState();
    _describeImage();
  }

  Future<void> _describeImage() async {
    final prompt = TextPart('''
Fill in the following details about this plant.
Give those details in proper JSON format with no extra characters. This is mandatory.
Give me only numbers, percentages, or 1-word answers.
If you are not sure on any value, just write NA. If your are not sure of the plant's name, just make up a name.
    name:
    scientific_name:
    sunlight:
    temp:
    water:
    ''');
    final imagePart = DataPart('image/jpeg', imageData);

    try {
      final response = await model.generateContent([Content.multi([prompt, imagePart])]);
      setState(() {
        plantDetails = jsonDecode(response.text!);
      });
    } catch (e) {
      print("Error fetching or decoding JSON: $e");
      setState(() {
        plantDetails = {"Error": "Unable to get description."};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final imageHeight = screenSize.height / 2;

    return Scaffold(
  appBar: AppBar(title: Text("Plant Stats")),
  body: Center(

    child: plantDetails == null ? CircularProgressIndicator() : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text(
                      "Name: ${plantDetails!['name']}",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Scientific Name: ${plantDetails!['scientific_name']}",
                      style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        appBar: AppBar(),
                        body: Center(
                          child: Image.memory(imageData),
                        ),
                      ),
                    ),
                  );
                },
                child: Container(
                  height: imageHeight,
                  width: double.infinity,
                  child: Image.memory(imageData, fit: BoxFit.cover),
                ),
              ),
              Expanded(
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _infoBox("Sunlight", plantDetails!['sunlight']),
                      _infoBox("Temperature", plantDetails!['temp']),
                      _infoBox("Water", plantDetails!['water']),
                    ],
                  ),
                ),
              ),
            ],
          )
        // : Center(
        //     child: Text(
        //       "Unclear picture, please take another one!",
        //       style: TextStyle(fontSize: 16),
        //       textAlign: TextAlign.center,
        //     ),
        //   ),
  ),
);

  }

  Widget _infoBox(String title, dynamic value) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            value ?? 'NA',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
