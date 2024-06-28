import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

const gemini_api_key = "AIzaSyAkTu1APiM_33fZaVeNSXPkPU5v8nUKs2I";
final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: gemini_api_key);

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
  const DisplayPictureScreen({Key? key, required this.imageData}): super(key: key);
  @override
  _DisplayPictureScreenState createState() => _DisplayPictureScreenState(imageData: imageData);
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  String? description;
  final Uint8List imageData;
  _DisplayPictureScreenState({required this.imageData});
  @override
  void initState() {
    super.initState();
    _describeImage();
  }

  Future<void> _describeImage() async {
    final prompt = TextPart('''Fill in the following details about this plant. Give those details as a json. Give me only numbers, percentages or 1 word answers. If you are not sure on any value, just write NA
    Name:
    Scientific Name:
    Optimal Sunlight:
    Optimal Temperature:
    Optimal Water Content:
    ''');
    final imagePart = DataPart('image/jpeg', imageData);
     try {
      final response = await model.generateContent([Content.multi([prompt, imagePart])]);
      setState(() {
        description = response.text;
      });
    } catch (e) {
      setState(() {
        description = "Error: Unable to get description.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final imageHeight = screenSize.height / 2;
    
    return Scaffold(
      appBar: AppBar(title: Text("Display Picture")),
      body: Column(children: [Container(height: imageHeight, width: double.infinity, 
        child: imageData == null ? Center( child: Text('No image Captured')) : Image.memory(imageData!,fit: BoxFit.contain),
      ),
      Expanded(child: Container(color: Colors.white, ),
      ),
      Container(child: description == null ? Text("asdsf") : Text(description!)),
      ],
      ),
    );
  }
}



