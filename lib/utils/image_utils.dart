import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:ffi/ffi.dart';
import 'package:image/image.dart' as imglib;

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true, bool withAlpha = false}) => '${leadingHashSign ? '#' : ''}'
      '${(withAlpha) ? alpha.toRadixString(16).padLeft(2, '0') : ''}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}

typedef convert_func = Pointer<Uint32> Function(Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>, Int32, Int32, Int32, Int32);
typedef Convert = Pointer<Uint32> Function(Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>, int, int, int, int);

class ImageUtils {
  ImageUtils(){
    conv = convertImageLib.lookup<NativeFunction<convert_func>>('convertImage').asFunction<Convert>();

  }

  Convert conv;

  final DynamicLibrary convertImageLib = Platform.isAndroid
      ? DynamicLibrary.open("libconvertImage.so")
      : DynamicLibrary.process();

  Future<void> captureImage(CameraImage image, Function(imglib.Image img) onCapture) async {
    imglib.Image img;

    if (Platform.isAndroid) {
      // Allocate memory for the 3 planes of the image
      Pointer<Uint8> p = allocate(count: image.planes[0].bytes.length);
      Pointer<Uint8> p1 = allocate(count: image.planes[1].bytes.length);
      Pointer<Uint8> p2 = allocate(count: image.planes[2].bytes.length);

      // Assign the planes data to the pointers of the image
      Uint8List pointerList = p.asTypedList(image.planes[0].bytes.length);
      Uint8List pointerList1 = p1.asTypedList(image.planes[1].bytes.length);
      Uint8List pointerList2 = p2.asTypedList(image.planes[2].bytes.length);
      pointerList.setRange(0, image.planes[0].bytes.length, image.planes[0].bytes);
      pointerList1.setRange(0, image.planes[1].bytes.length, image.planes[1].bytes);
      pointerList2.setRange(0, image.planes[2].bytes.length, image.planes[2].bytes);

      // Call the convertImage function and convert the YUV to RGB
      Pointer<Uint32> imgP = conv(
          p,
          p1,
          p2,
          image.planes[1].bytesPerRow,
          image.planes[1].bytesPerPixel,
          image.planes[0].bytesPerRow,
          image.height);

      // Get the pointer of the data returned from the function to a List
      List imgData = imgP.asTypedList((image.planes[0].bytesPerRow * image.height));
      // Generate image from the converted data
      img = imglib.Image.fromBytes(image.height, image.planes[0].bytesPerRow, imgData);

      // Free the memory space allocated
      // from the planes and the converted data
      free(p);
      free(p1);
      free(p2);
      free(imgP);
    } else if (Platform.isIOS) {
      img = imglib.Image.fromBytes(
        image.planes[0].bytesPerRow,
        image.height,
        image.planes[0].bytes,
        format: imglib.Format.bgra,
      );
    }

    onCapture(img);
  }
}