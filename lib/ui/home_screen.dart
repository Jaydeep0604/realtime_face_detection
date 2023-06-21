import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:realtime_face_detection/ML/Recognition.dart';
import 'package:realtime_face_detection/ML/Recognizer.dart';
import 'package:realtime_face_detection/main.dart';
import 'package:realtime_face_detection/ui/face_detector_painter_screen.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  dynamic controller;

  bool isBusy = false;

  late Size size;

  late CameraDescription description = cameras[1];

  CameraLensDirection camDirec = CameraLensDirection.front;

  late List<Recognition> recognitions = [];

  TextEditingController textEditingController = TextEditingController();

  //TODO declare face detector
  late FaceDetector faceDetector;

  //TODO declare face recognizer
  late Recognizer _recognizer;

  @override
  void initState() {
    super.initState();

    // TODO initialize face detector
    faceDetector = FaceDetector(
      options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
          enableClassification: true,
          enableLandmarks: true,
          enableTracking: true),
    );

    //TODO initialize face recognizer
    _recognizer = Recognizer();

    //TODO initialize camera footage
    initializeCamera();
  }

  //TODO code to initialize the camera feed

  initializeCamera() async {
    controller = CameraController(
      description,
      ResolutionPreset.max,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      controller.startImageStream((image) => {
            if (!isBusy)
              {
                isBusy = true,
                frame = image,
                doFaceDetectionOnFrame(),
              }
          });
    });
  }

  //TODO close all resources
  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  //TODO face detection on a frame
  dynamic _scanResults;
  CameraImage? frame;

  doFaceDetectionOnFrame() async {
    //TODO convert frame into InputImage format
    InputImage inputImage = getInputImage();

    //TODO pass InputImage to face detection model and detect faces
    List<Face> faces = await faceDetector.processImage(inputImage);
    // String facesJson = json.encode(faces);
    print("count =${faces.length}");

    //TODO perform face recognition on detected faces
    if (faces.length <= 1) {
      performFaceRecognition(faces);
    } else {
      setState(() {
      // _scanResults = faces;
      isBusy = false;
    });
    }

    
  }

  img.Image? image;
  bool register = false;

  //TODO perform Face Recognition
  performFaceRecognition(List<Face> faces) async {
    recognitions.clear();

    //TODO convert CameraImage to Image and rotate it so that our frame will be in a portrait
    image = _convertYUV420(frame!);
    image = img.copyRotate(
        image!, camDirec == CameraLensDirection.front ? 270 : 90);

    for (Face face in faces) {
      Rect faceRect = face.boundingBox;
      //TODO crop face
      img.Image croppedFace = img.copyCrop(
          image!,
          faceRect.left.toInt(),
          faceRect.top.toInt(),
          faceRect.width.toInt(),
          faceRect.height.toInt());

      //TODO pass cropped face to face recognition model
      Recognition recognition = _recognizer.recognize(croppedFace, faceRect);
      if (recognition.distance > 1) {
        recognition.name = "Unknown";
      }
      recognitions.add(recognition);
      //TODO show face registration dialogue
      if (register) {
        showFaceRegistrationDialogue(image!, recognition);
        register = false;
      }
    }

    setState(() {
      isBusy = false;
      _scanResults = recognitions;
    });
  }
  // For black and white image in register popup box
  // img.Image _convertYUV420(CameraImage image) {
  //   var imag = img.Image(image.width, image.height); // Create Image buffer
  //   Plane plane = image.planes[0];
  //   const int shift = (0xFF << 24);
  //   // Fill image buffer with plane[0] from YUV420_888
  //   for (int x = 0; x < image.width; x++) {
  //     for (int planeOffset = 0;
  //         planeOffset < image.height * image.width;
  //         planeOffset += image.width) {
  //       final pixelColor = plane.bytes[planeOffset + x];
  //       // color: 0x FF  FF  FF  FF
  //       //           A   B   G   R
  //       // Calculate pixel color
  //       var newVal =
  //           shift | (pixelColor << 16) | (pixelColor << 8) | pixelColor;
  //       imag.data[planeOffset + x] = newVal;
  //     }
  //   }
  //   return imag;
  // }

  // For black and white image in register popup box
  img.Image _convertYUV420(CameraImage image) {
    int width = image.width;
    int height = image.height;

    img.Image convertedImage = img.Image(width, height); // Create Image buffer

    Plane planeY = image.planes[0];
    Plane planeU = image.planes[1];
    Plane planeV = image.planes[2];

    int uvRowStride = planeU.bytesPerRow;
    int? uvPixelStride = planeU.bytesPerPixel;

    // Fill image buffer with plane data
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        int uvIndex = uvPixelStride! * (x ~/ 2) + uvRowStride * (y ~/ 2);
        int index = y * width + x;

        int yValue = planeY.bytes[index];
        int uValue = planeU.bytes[uvIndex];
        int vValue = planeV.bytes[uvIndex];

        // Calculate pixel color
        int r = (yValue + vValue * 1436 ~/ 1024 - 179).clamp(0, 255);
        int g = (yValue -
                uValue * 46549 ~/ 131072 +
                44 -
                vValue * 93604 ~/ 131072 +
                91)
            .clamp(0, 255);
        int b = (yValue + uValue * 1814 ~/ 1024 - 227).clamp(0, 255);

        // color: 0x FF  FF  FF  FF
        //           A   B   G   R
        int newVal = 0xFF000000 | (b << 16) | (g << 8) | r;
        convertedImage.data[index] = newVal;
      }
    }
    return convertedImage;
  }

  //TODO convert CameraImage to InputImage
  InputImage getInputImage() {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in frame!.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();
    final Size imageSize =
        Size(frame!.width.toDouble(), frame!.height.toDouble());
    final camera = description;
    final imageRotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    // if (imageRotation == null) return;
    final inputImageFormat =
        InputImageFormatValue.fromRawValue(frame!.format.raw);
    // if (inputImageFormat == null) return null;

    final planeData = frame!.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation!,
      inputImageFormat: inputImageFormat!,
      planeData: planeData,
    );
    final inputImage =
        InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);
    return inputImage;
  }

  // TODO Show rectangles around detected faces
  Widget buildResult() {
    if (_scanResults == null ||
        controller == null ||
        !controller.value.isInitialized) {
      return const Center(child: Text('Camera is not initialized'));
    }
    final Size imageSize = Size(
      controller.value.previewSize!.height,
      controller.value.previewSize!.width,
    );
    CustomPainter painter =
        FaceDetectorPainter(imageSize, _scanResults, camDirec);
    return CustomPaint(
      painter: painter,
    );
  }

  //TODO toggle camera direction
  void _toggleCameraDirection() async {
    if (camDirec == CameraLensDirection.back) {
      camDirec = CameraLensDirection.front;
      description = cameras[1];
      // description = cameras[0];
    } else {
      camDirec = CameraLensDirection.back;
      description = cameras[0];
    }
    await controller.stopImageStream();
    setState(() {
      controller;
    });
    initializeCamera();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> stackChildren = [];
    size = MediaQuery.of(context).size;
    if (controller != null) {
      //TODO View for displaying the live camera footage
      stackChildren.add(
        Positioned(
          top: 0.0,
          left: 0.0,
          width: size.width,
          height: size.height,
          child: Container(
            child: (controller.value.isInitialized)
                ? AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: CameraPreview(controller),
                  )
                : Container(),
          ),
        ),
      );

      // //TODO View for displaying rectangles around detected aces
      stackChildren.add(
        Positioned(
            top: 0.0,
            left: 0.0,
            width: size.width,
            height: size.height,
            child: buildResult()),
      );
    }
    return Scaffold(
      // backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      extendBody: true,
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(left: 15, right: 15),
        color: Colors.black.withOpacity(0.3),
        height: 45,
        child: Stack(
          // mainAxisAlignment: MainAxisAlignment.center,
          // crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.center,
              child: IconButton(
                icon: const Icon(
                  Icons.person_add_outlined,
                  color: Colors.blue,
                ),
                iconSize: 30,
                // color: Colors.black,
                onPressed: () {
                  register = true;
                },
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(
                  Icons.flip_camera_ios_outlined,
                  color: Colors.lightBlue,
                ),
                iconSize: 30,
                // color: Colors.black,
                onPressed: () {
                  _toggleCameraDirection();
                },
              ),
            ),
          ],
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Stack(
          children: [
            Positioned(
              top: 0.0,
              left: 0.0,
              width: size.width,
              height: size.height,
              child: Container(
                child: (controller.value.isInitialized)
                    ? AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: CameraPreview(controller),
                      )
                    : Container(),
              ),
            ),

            //TODO View for displaying rectangles around detected aces

            Positioned(
                top: 0.0,
                left: 0.0,
                width: size.width,
                height: size.height,
                child: buildResult()),
          ],
        ),
      ),
    );
  }

  //TODO Face Registration Dialogue
  showFaceRegistrationDialogue(img.Image croppedFace, Recognition recognition) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Face Registration", textAlign: TextAlign.center),
        alignment: Alignment.center,
        content: SizedBox(
          height: 340,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 20,
              ),
              Image.memory(
                Uint8List.fromList(img.encodeJpg(croppedFace)),
                width: 200,
                height: 200,
              ),
              SizedBox(
                width: 200,
                child: TextField(
                    controller: textEditingController,
                    decoration: const InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        hintText: "Enter Name")),
              ),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                  onPressed: () {
                    Recognizer.registered.putIfAbsent(
                        textEditingController.text, () => recognition);
                    textEditingController.text = "";
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Face Registered"),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                      primary: Colors.blue, minimumSize: const Size(200, 40)),
                  child: const Text("Register"))
            ],
          ),
        ),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}





















// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:flutter/services.dart';
// import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
// import 'package:image/image.dart' as img;
// import 'package:realtime_face_detection/ML/Recognition.dart';
// import 'package:realtime_face_detection/ML/Recognizer.dart';
// import 'package:realtime_face_detection/main.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class HomeScreen extends StatefulWidget {
//   HomeScreen({Key? key}) : super(key: key);
//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   dynamic controller;

//   bool isBusy = false;

//   late Size size;

//   late CameraDescription description = cameras[1];

//   CameraLensDirection camDirec = CameraLensDirection.front;

//   late List<Recognition> recognitions = [];

//   TextEditingController textEditingController = TextEditingController();

//   //TODO declare face detector
//   late FaceDetector faceDetector;

//   //TODO declare face recognizer
//   late Recognizer _recognizer;

//   SharedPreferences? sharedPreferences;

//   @override
//   void initState() {
//     super.initState();

//     // TODO initialize face detector
//     faceDetector = FaceDetector(
//       options: FaceDetectorOptions(
//           performanceMode: FaceDetectorMode.accurate,
//           enableClassification: true,
//           enableLandmarks: true,
//           enableTracking: true),
//     );

//     //TODO initialize face recognizer
//     _recognizer = Recognizer();

//     //TODO initialize shared preferences
//     SharedPreferences.getInstance().then((prefs) {
//       sharedPreferences = prefs;
//     });

//     //TODO initialize camera footage
//     initializeCamera();
//   }

//   //TODO code to initialize the camera feed
//   initializeCamera() async {
//     controller = CameraController(
//       description,
//       ResolutionPreset.max,
//     );
//     await controller.initialize().then((_) {
//       if (!mounted) {
//         return;
//       }
//       controller.startImageStream((CameraImage image) {
//         if (!isBusy) {
//           isBusy = true;
//           frame = image;
//           doFaceDetectionOnFrame();
//         }
//       });
//     });
//   }

//   //TODO close all resources
//   @override
//   void dispose() {
//     controller?.dispose();
//     super.dispose();
//   }

//   //TODO face detection on a frame
//   dynamic _scanResults;
//   CameraImage? frame;

//   doFaceDetectionOnFrame() async {
//     //TODO convert frame into InputImage format
//     InputImage inputImage = getInputImage();

//     //TODO pass InputImage to face detection model and detect faces
//     List<Face> faces = await faceDetector.processImage(inputImage);
//     print("count = ${faces.length}");

//     //TODO perform face recognition on detected faces
//     performFaceRecognition(faces);
//   }

//   img.Image? image;
//   bool register = false;

//   //TODO perform Face Recognition
//   performFaceRecognition(List<Face> faces) async {
//     recognitions.clear();

//     //TODO convert CameraImage to Image and rotate it so that our frame will be in a portrait
//     image = _convertYUV420(frame!);
//     image = img.copyRotate(
//         image!, camDirec == CameraLensDirection.front ? 270 : 90);

//     for (Face face in faces) {
//       Rect faceRect = face.boundingBox;
//       //TODO crop face
//       img.Image croppedFace = img.copyCrop(
//           image!,
//           faceRect.left.toInt(),
//           faceRect.top.toInt(),
//           faceRect.width.toInt(),
//           faceRect.height.toInt());

//       //TODO pass cropped face to face recognition model
//       Recognition recognition = _recognizer.recognize(croppedFace, faceRect);
//       if (recognition.distance > 1) {
//         recognition.name = "";
//       }
//       recognitions.add(recognition);
//       //TODO show face registration dialogue
//       if (register) {
//         showFaceRegistrationDialogue(image!, recognition);
//         register = false;
//       }
//     }

//     setState(() {
//       isBusy = false;
//       _scanResults = recognitions;
//     });
//   }

//   // For black and white image in register popup box
//   img.Image _convertYUV420(CameraImage image) {
//     int width = image.width;
//     int height = image.height;

//     img.Image convertedImage = img.Image(width, height); // Create Image buffer

//     Plane planeY = image.planes[0];
//     Plane planeU = image.planes[1];
//     Plane planeV = image.planes[2];

//     int uvRowStride = planeU.bytesPerRow;
//     int? uvPixelStride = planeU.bytesPerPixel;

//     // Fill image buffer with plane data
//     for (int x = 0; x < width; x++) {
//       for (int y = 0; y < height; y++) {
//         int uvIndex = uvPixelStride! * (x ~/ 2) + uvRowStride * (y ~/ 2);
//         int index = y * width + x;

//         int yValue = planeY.bytes[index];
//         int uValue = planeU.bytes[uvIndex];
//         int vValue = planeV.bytes[uvIndex];

//         // Calculate pixel color
//         int r = (yValue + vValue * 1436 ~/ 1024 - 179).clamp(0, 255);
//         int g = (yValue -
//                 uValue * 46549 ~/ 131072 +
//                 44 -
//                 vValue * 93604 ~/ 131072 +
//                 91)
//             .clamp(0, 255);
//         int b = (yValue + uValue * 1814 ~/ 1024 - 227).clamp(0, 255);

//         // color: 0x FF  FF  FF  FF
//         //           A   B   G   R
//         int newVal = 0xFF000000 | (b << 16) | (g << 8) | r;
//         convertedImage.data[index] = newVal;
//       }
//     }
//     return convertedImage;
//   }

//   //TODO convert CameraImage to InputImage
//   InputImage getInputImage() {
//     final WriteBuffer allBytes = WriteBuffer();
//     for (final Plane plane in frame!.planes) {
//       allBytes.putUint8List(plane.bytes);
//     }
//     final bytes = allBytes.done().buffer.asUint8List();
//     final Size imageSize =
//         Size(frame!.width.toDouble(), frame!.height.toDouble());
//     final camera = description;
//     final imageRotation =
//         InputImageRotationValue.fromRawValue(camera.sensorOrientation);
//     final inputImageFormat =
//         InputImageFormatValue.fromRawValue(frame!.format.raw);

//     final planeData = frame!.planes.map(
//       (Plane plane) {
//         return InputImagePlaneMetadata(
//           bytesPerRow: plane.bytesPerRow,
//           height: plane.height,
//           width: plane.width,
//         );
//       },
//     ).toList();

//     final inputImageData = InputImageData(
//       size: imageSize,
//       imageRotation: imageRotation!,
//       inputImageFormat: inputImageFormat!,
//       planeData: planeData,
//     );
//     final inputImage =
//         InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);
//     return inputImage;
//   }

//   // TODO Show rectangles around detected faces
//   Widget buildResult() {
//     if (_scanResults == null ||
//         controller == null ||
//         !controller.value.isInitialized) {
//       return const Center(child: Text('Camera is not initialized'));
//     }
//     final Size imageSize = Size(
//       controller.value.previewSize!.height,
//       controller.value.previewSize!.width,
//     );
//     CustomPainter painter =
//         FaceDetectorPainter(imageSize, _scanResults, camDirec);
//     return CustomPaint(
//       painter: painter,
//     );
//   }

//   //TODO toggle camera direction
//   void _toggleCameraDirection() async {
//     if (camDirec == CameraLensDirection.back) {
//       camDirec = CameraLensDirection.front;
//       description = cameras[1];
//     } else {
//       camDirec = CameraLensDirection.back;
//       description = cameras[0];
//     }
//     await controller.stopImageStream();
//     setState(() {
//       controller;
//     });
//     initializeCamera();
//   }

//   @override
//   Widget build(BuildContext context) {
//     List<Widget> stackChildren = [];
//     size = MediaQuery.of(context).size;
//     if (controller != null) {
//       //TODO View for displaying the live camera footage
//       stackChildren.add(
//         Positioned(
//           top: 0.0,
//           left: 0.0,
//           width: size.width,
//           height: size.height,
//           child: Container(
//             child: (controller.value.isInitialized)
//                 ? AspectRatio(
//                     aspectRatio: controller.value.aspectRatio,
//                     child: CameraPreview(controller),
//                   )
//                 : Container(),
//           ),
//         ),
//       );

//       // //TODO View for displaying rectangles around detected faces
//       stackChildren.add(
//         Positioned(
//             top: 0.0,
//             left: 0.0,
//             width: size.width,
//             height: size.height,
//             child: buildResult()),
//       );
//     }

    
//     return Scaffold(
//       // backgroundColor: Colors.transparent,
//       extendBodyBehindAppBar: true,
//       extendBody: true,
//       bottomNavigationBar: Container(
//         padding: EdgeInsets.only(left: 15, right: 15),
//         color: Colors.black.withOpacity(0.3),
//         height: 45,
//         child: Stack(
//           children: [
//             Align(
//               alignment: Alignment.center,
//               child: IconButton(
//                 icon: const Icon(
//                   Icons.person_add_outlined,
//                   color: Colors.blue,
//                 ),
//                 iconSize: 30,
//                 onPressed: () {
//                   register = true;
//                 },
//               ),
//             ),
//             Align(
//               alignment: Alignment.centerRight,
//               child: IconButton(
//                 icon: const Icon(
//                   Icons.flip_camera_ios_outlined,
//                   color: Colors.lightBlue,
//                 ),
//                 iconSize: 30,
//                 onPressed: () {
//                   _toggleCameraDirection();
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//       body: Container(
//         margin: const EdgeInsets.only(top: 0),
//         color: Colors.black,
//         child: Stack(
//           children: stackChildren,
//         ),
//       ),
//     );
//   }

//   //TODO Face Registration Dialogue
//   showFaceRegistrationDialogue(img.Image croppedFace, Recognition recognition) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text("Face Registration", textAlign: TextAlign.center),
//         alignment: Alignment.center,
//         content: SizedBox(
//           height: 340,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               const SizedBox(
//                 height: 20,
//               ),
//               Image.memory(
//                 Uint8List.fromList(img.encodeJpg(croppedFace)),
//                 width: 200,
//                 height: 200,
//               ),
//               SizedBox(
//                 width: 200,
//                 child: TextField(
//                     controller: textEditingController,
//                     decoration: const InputDecoration(
//                         fillColor: Colors.white,
//                         filled: true,
//                         hintText: "Enter Name")),
//               ),
//               const SizedBox(
//                 height: 10,
//               ),
//               SizedBox(
//                 width: 200,
//                 child: ElevatedButton(
//                   child: const Text("Register"),
//                   onPressed: () {
//                     recognition.name = textEditingController.text;
//                     _recognizer.registerFace(croppedFace, recognition);
//                     setState(() {});
//                     Navigator.of(ctx).pop();
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


// class FaceDetectorPainter extends CustomPainter {
//   final Size imageSize;
//   final List<Recognition> recognitions;
//   final CameraLensDirection camDirec;

//   FaceDetectorPainter(this.imageSize, this.recognitions, this.camDirec);

//   @override
//   void paint(Canvas canvas, Size size) {
//     final double scaleX = size.width / imageSize.width;
//     final double scaleY = size.height / imageSize.height;

//     final Paint paint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2.0
//       ..color = Colors.red;

//     for (Recognition recognition in recognitions) {
//       final rect = Rect.fromLTRB(
//         recognition.location.left * scaleX,
//         recognition.location.top * scaleY,
//         recognition.location.right * scaleX,
//         recognition.location.bottom * scaleY,
//       );

//       canvas.drawRect(rect, paint);

//       TextSpan span = TextSpan(
//         text: recognition.name,
//         style: TextStyle(
//           color: Colors.red,
//           fontSize: 14.0,
//           backgroundColor: Colors.white,
//         ),
//       );
//       TextPainter tp = TextPainter(
//         text: span,
//         textAlign: TextAlign.left,
//         textDirection: TextDirection.ltr,
//       );
//       tp.layout();
//       tp.paint(canvas, Offset(rect.left, rect.top - tp.height));
//     }
//   }

//   @override
//   bool shouldRepaint(FaceDetectorPainter oldDelegate) {
//     return true;
//   }
// }