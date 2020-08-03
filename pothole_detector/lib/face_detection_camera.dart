import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite/tflite.dart';
import 'dart:math' as math;
import './boundary_box.dart';
import 'temp.dart';

class FaceDetectionFromLiveCamera extends StatefulWidget {
  @override
  _FaceDetectionFromLiveCameraState createState() =>
      _FaceDetectionFromLiveCameraState();
}

class _FaceDetectionFromLiveCameraState
    extends State<FaceDetectionFromLiveCamera> {
  List<CameraDescription> _availableCameras;
  CameraController cameraController;
  bool isDetecting = false;
  List<dynamic> _recognitions;
  int _imageHeight = 0;
  int _imageWidth = 0;
  bool front = true;

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    loadModel();
    _getAvailableCameras();
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }

  Future<void> _getAvailableCameras() async {
    WidgetsFlutterBinding.ensureInitialized();
    _availableCameras = await availableCameras();
    _initializeCamera(_availableCameras[0]);
  }

  void loadModel() async {
    await Tflite.loadModel(
      model: "assets/model_unquant.tflite",
      labels: "assets/labels.txt",
    );
  }

  void _showCameraException(CameraException e) {
    String errorText = 'Error:${e.code}\nError message : ${e.description}';
    print(errorText);
  }

  void _onCapturePressed(context) async {
    try {
      final path =
          join((await getTemporaryDirectory()).path, '${DateTime.now()}.png');
      await cameraController.takePicture(path);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TempClass()),
      );
    } catch (e) {
      _showCameraException(e);
    }
  }

  Future<void> _initializeCamera(CameraDescription description) async {
    cameraController = CameraController(description, ResolutionPreset.high);
    try {
      await cameraController.initialize().then(
        (_) {
          if (!mounted) {
            return;
          }
          cameraController.startImageStream(
            (CameraImage img) {
              if (!isDetecting) {
                isDetecting = true;
                Tflite.runModelOnFrame(
                  bytesList: img.planes.map(
                    (plane) {
                      return plane.bytes;
                    },
                  ).toList(),
                  threshold: 0.5,
                  rotation: 0,
                  imageHeight: img.height,
                  imageWidth: img.width,
                  numResults: 1,
                ).then(
                  (recognitions) {
                    setRecognitions(recognitions, img.height, img.width);
                    isDetecting = false;
                  },
                );
              }
            },
          );
        },
      );
    } catch (e) {
      print(e);
    }
  }

  void setRecognitions(recognitions, imageHeight, imageWidth) {
    setState(() {
      _recognitions = recognitions;
      _imageHeight = imageHeight;
      _imageWidth = imageWidth;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size screen = MediaQuery.of(context).size;
    return Container(
      constraints: const BoxConstraints.expand(),
      child: cameraController == null
          ? Container(
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            )
          : Scaffold(
              floatingActionButton: RotatedBox(
                quarterTurns: 1,
                child: FloatingActionButton(
                  backgroundColor: Colors.amber,
                  onPressed: () {
                    _onCapturePressed(context);
                  },
                  child: Icon(
                    Icons.camera,
                    color: Colors.black,
                  ),
                ),
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerFloat,
              backgroundColor: Colors.black,
              // appBar: AppBar(
              //   title: Text("Mask detector"),
              //   centerTitle: true,
              //   backgroundColor: Colors.redAccent,
              // ),
              body: Stack(
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: cameraController.value.aspectRatio,
                      child: CameraPreview(cameraController),
                    ),
                  ),
                  BoundaryBox(
                      _recognitions == null ? [] : _recognitions,
                      math.max(_imageHeight, _imageWidth),
                      math.min(_imageHeight, _imageWidth),
                      screen.height,
                      screen.width),
                ],
              ),
            ),
    );
  }
}
