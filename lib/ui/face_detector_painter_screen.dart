import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:realtime_face_detection/ML/Recognition.dart';

// class FaceDetectorPainter extends CustomPainter {
//   FaceDetectorPainter(this.absoluteImageSize, this.faces, this.camDire2);

//   final Size absoluteImageSize;
//   final List<Recognition> faces;
//   CameraLensDirection camDire2;

//   @override
//   void paint(Canvas canvas, Size size) {
//     final double scaleX = size.width / absoluteImageSize.width;
//     final double scaleY = size.height / absoluteImageSize.height;
//     BorderRadius.circular(50);
//     final Paint paint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.5
//       ..color = Colors.green;

//     for (Recognition face in faces) {
//       canvas.drawRect(
//         Rect.fromLTRB(
//           camDire2 == CameraLensDirection.front
//               ? (absoluteImageSize.width - face.location.right) * scaleX
//               : face.location.left * scaleX,
//           face.location.top * scaleY,
//           camDire2 == CameraLensDirection.front
//               ? (absoluteImageSize.width - face.location.left) * scaleX
//               : face.location.right * scaleX,
//           face.location.bottom * scaleY,
//         ),
//         paint,
//       );

//       TextSpan span = TextSpan(
//           style: const TextStyle(
//               color: Colors.blue, fontSize: 16, fontWeight: FontWeight.w500),
//           text: "${face.name}");
//       TextPainter tp = TextPainter(
//           text: span,
//           textAlign: TextAlign.center,
//           textDirection: TextDirection.ltr);
//       tp.layout();
//       tp.paint(canvas,
//           Offset(face.location.left * scaleX, face.location.bottom * scaleY));
//     }
//   }

//   @override
//   bool shouldRepaint(FaceDetectorPainter oldDelegate) {
//     return true;
//   }
// }

class FaceDetectorPainter extends CustomPainter {
  FaceDetectorPainter(this.absoluteImageSize, this.faces, this.camDire2);

  final Size absoluteImageSize;
  final List<Recognition> faces;
  CameraLensDirection camDire2;

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / absoluteImageSize.width;
    final double scaleY = size.height / absoluteImageSize.height;
    final double borderRadius = 10.0;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..blendMode
      ..strokeWidth = 1.5
      ..color = Colors.green;

    for (Recognition face in faces) {
      Rect squareRect = Rect.fromLTRB(
        camDire2 == CameraLensDirection.front
            ? (absoluteImageSize.width - face.location.right) * scaleX
            : face.location.left * scaleX,
        face.location.top * scaleY,
        camDire2 == CameraLensDirection.front
            ? (absoluteImageSize.width - face.location.left) * scaleX
            : face.location.right * scaleX,
        face.location.bottom * scaleY,
      );
      RRect roundedRect = RRect.fromRectAndRadius(
        squareRect,
        Radius.circular(borderRadius),
      );

      canvas.drawRRect(roundedRect, paint);

      TextSpan span = TextSpan(
        style: const TextStyle(
          color: Colors.green,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        text: face.name,
      );
      TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
      );
      tp.layout();

      double textLeft = squareRect.left + 4; // Add some padding from the left
      double textTop = squareRect.bottom - tp.height - 4; // Add some padding from the bottom
      tp.paint(canvas, Offset(textLeft, textTop));
    }
  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return true;
  }
}
