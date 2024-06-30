import 'dart:ffi';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

const String geminiApiKey = String.fromEnvironment('API_KEY'); 
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
    _controller!.setFlashMode(FlashMode.off);
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
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              
              if (snapshot.connectionState == ConnectionState.done) {
                return SizedBox.expand(child: CameraPreview(_controller!));
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
          Positioned(
            bottom: 50.0,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton.large(
                child: Icon(Icons.camera),
                onPressed: () async {
                  try {
                    await _initializeControllerFuture;
                    _controller!.setFlashMode(FlashMode.off);
                    final image = await _controller!.takePicture();
                    _controller!.initialize();
                    
                    imageData = await image.readAsBytes();

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
            ),
          ),
        ],
      ),
    );
  }
}






//Next Page
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
 
    name: Give me the plant's commonly known name here. If you are not sure of the value just write NA.
    scientific_name: Give me the plant's scientific name here. If you are not sure of the value just write NA.
    sunlight: A percentage value with unit for the optimal amount of sunlight the plant needs. If you are not sure of the value just give me an average optimal percentage of sunlight; plants of this family need. You may use ranges if not sure. The unit should be in hours/day
    temp: A Celsius value with unit for the optimal environmental temperature for the plant. If you are not sure of the value just give me an average optimal environmental temperature plants of this family need. You may use ranges if not sure. The unit should be in °C.
    water: A litres value with unit for the optimal amount of water the plant needs. If you are not sure of the value just give me an average optimal litres value of water; plants of this family need. You may use ranges if not sure. The unit should be in l/day.
    about: A short 25 word description of the plant. If you are not sure of the value just write No Description.
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

  GestureDetector imageDisplayCreation(Image image, final croppedHeight) {
    return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        body: SizedBox.expand(
                          child: Image.memory(imageData),
                        ),
                      ),
                    ),
                  );
                },
                                child: Container(
                  height: croppedHeight,
                  width: double.infinity, // Full width
                  margin: EdgeInsets.symmetric(horizontal: 11.0), // 11.0 space on left and right
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.memory(
                      widget.imageData,
                      fit: BoxFit.cover,
                    ),
                  ),
              ));
  }

  @override
  Widget build(BuildContext context) {


    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = MediaQuery.of(context).size;
        final croppedHeight = screenSize.height / 2;
        return Scaffold(
          appBar: AppBar(title: Text("Plant Details"), backgroundColor: Color.fromARGB(117, 44, 120, 101),),
          body: 
        
        plantDetails == null ? Container(decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.fromARGB(117, 44, 120, 101), Color.fromARGB(223, 217, 237, 191)],
                ),
              ),child: Center(child: CircularProgressIndicator())) : 
        
        plantDetails!['name'] == "NA" ? Center(child: Container(decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.fromARGB(117, 44, 120, 101), Color.fromARGB(223, 217, 237, 191)],
                ),
              ),
          child: Column(
            children: <Widget>[
              imageDisplayCreation(Image.memory(imageData),croppedHeight),
              const Padding(
                padding: EdgeInsets.all(40.0),
                child: Text("Unable to identify the plant. Please retake the picture.", style: TextStyle(fontSize: 20) ,textAlign: TextAlign.center,),
              ),
            ],
          ),
        )) : 
        
        Container(
          height: screenSize.height,
        decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.fromARGB(117, 44, 120, 101), Color.fromARGB(223, 217, 237, 191)],
                ),
              ),
          child: Column(
                  
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     
                        
                          Padding(
                            padding: const EdgeInsets.only(bottom: 13.0),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                    
                                children: [
                                  Text(
                                    "Name: ${plantDetails!['name']}",
                                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),textAlign: TextAlign.left,
                                  ),
                                  Text(
                                    "Scientific Name: ${plantDetails!['scientific_name']}",
                                    style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                      
                    
                    imageDisplayCreation(Image.memory(imageData),croppedHeight),
                    Padding(padding: EdgeInsets.only(top: 16.0, bottom: 16.0),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _infoBox("Sunlight", plantDetails!['sunlight'], Colors.deepOrange, Color.fromARGB(255, 255, 153, 0)),
                            _infoBox("Temperature", plantDetails!['temp'], Colors.green, Color.fromARGB(255, 144, 210, 109)),
                            _infoBox("Water", plantDetails!['water'], Colors.blue, Colors.blueAccent),
                          ],
                        ),
                      ),
                    ),
                    Padding(padding: EdgeInsets.only(left:16.0,right:16.0), child : Container(
                      decoration: BoxDecoration(                  color: const Color.fromARGB(255,44, 120, 101),
        borderRadius: BorderRadius.circular(8)),
                      child: 
                        Padding(
                          
                          padding: const EdgeInsets.all(16.0),
                          child: Text(plantDetails!['about'], style: TextStyle(color: Color.fromARGB(202, 255, 255, 255)),),
                        ),
                      
                    )),
                   
                  ],
                ),
        )
          );
      }
    );

  }

  Widget _infoBox(String title, dynamic value, Color bordercolor, Color backgroundColor) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: bordercolor),
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
