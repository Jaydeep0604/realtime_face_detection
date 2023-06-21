// //TODO Face Registration Dialogue
//   import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:realtime_face_detection/ML/Recognition.dart';
// import 'package:realtime_face_detection/ML/Recognizer.dart';

// showFaceRegistrationDialogue(img.Image croppedFace, Recognition recognition) {
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
//               ElevatedButton(
//                   onPressed: () {
//                     Recognizer.registered.putIfAbsent(
//                         textEditingController.text, () => recognition);
//                     textEditingController.text = "";
//                     Navigator.pop(context);
//                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//                       content: Text("Face Registered"),
//                     ));
//                   },
//                   style: ElevatedButton.styleFrom(
//                       primary: Colors.blue, minimumSize: const Size(200, 40)),
//                   child: const Text("Register"))
//             ],
//           ),
//         ),
//         contentPadding: EdgeInsets.zero,
//       ),
//     );
//   }