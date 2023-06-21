import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

//TODO method to convert CameraImage to Image
img.Image conver(CameraImage cameraImage) {
  final width = cameraImage.width;
  final height = cameraImage.height;

  final yRowStride = cameraImage.planes[0].bytesPerRow;
  final uvRowStride = cameraImage.planes[1].bytesPerRow;
  final uvPixelStride = cameraImage.planes[1].bytesPerPixel!;

  final image = img.Image(width, height);

  for (var w = 0; w < width; w++) {
    for (var h = 0; h < height; h++) {
      final uvIndex =
          uvPixelStride * (w / 2).floor() + uvRowStride * (h / 2).floor();
      final index = h * width + w;
      final yIndex = h * yRowStride + w;

      final y = cameraImage.planes[0].bytes[yIndex];
      final u = cameraImage.planes[1].bytes[uvIndex];
      final v = cameraImage.planes[2].bytes[uvIndex];

      image.data[index] = yuv2rgb(y, u, v);
    }
  }
  return image;
}


int yuv2rgb(int y, int u, int v) {
  // Convert yuv pixel to rgb
  var r = (y + v * 1436 / 1024 - 179).round();
  var g = (y - u * 46549 / 131072 + 44 - v * 93604 / 131072 + 91).round();
  var b = (y + u * 1814 / 1024 - 227).round();

  // Clipping RGB values to be inside boundaries [ 0 , 255 ]
  r = r.clamp(0, 255);
  g = g.clamp(0, 255);
  b = b.clamp(0, 255);

  return 0xff000000 | ((b << 16) & 0xff0000) | ((g << 8) & 0xff00) | (r & 0xff);
}

// void _toggleCameraDirection() async {
//   if (camDirec == CameraLensDirection.back) {
//     camDirec = CameraLensDirection.front;
//     description = cameras[0];
//   }
//   await controller.stopImageStream();
//   setState(() {
//     controller;
//   });
//   initializeCamera();
// }

