import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

import 'package:camera/camera.dart';
import 'package:color_picker/camera_viewer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as imglib;

typedef convert_func = Pointer<Uint32> Function(Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>, Int32, Int32, Int32, Int32);
typedef Convert = Pointer<Uint32> Function(Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>, int, int, int, int); 

class ColorPickerWidget extends StatefulWidget {
  ColorPickerWidget(this.cameras);

  final List<CameraDescription> cameras;

  @override
  _ColorPickerWidgetState createState() => _ColorPickerWidgetState();
}

class _ColorPickerWidgetState extends State<ColorPickerWidget> {
  GlobalKey imageKey = GlobalKey();

  final StreamController<Color> _stateController = StreamController<Color>();

  imglib.Image photo;

  CameraController controller;
  Uint8List screenShot;
  imglib.Image img;

  final DynamicLibrary convertImageLib = Platform.isAndroid
    ? DynamicLibrary.open("libconvertImage.so")
    : DynamicLibrary.process();
  Convert conv;

  @override
  void initState() {
    super.initState();
    controller = CameraController(widget.cameras[0], ResolutionPreset.max, enableAudio: false);
    
    controller.initialize().then((_) {
      if (!mounted)
        return;

      setState(() {});
    });  

    conv = convertImageLib.lookup<NativeFunction<convert_func>>('convertImage').asFunction<Convert>();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      ),
      body: Stack(
        children: <Widget>[


          GestureDetector(
            onPanDown: (details) {
              searchPixel(details.globalPosition);
            },
            onPanUpdate: (details) {
              searchPixel(details.globalPosition);
            },
            child: CameraPreview(controller),
          ),


          IgnorePointer(
            ignoring: true,
            child: RepaintBoundary(
              key: imageKey,
              child: (img == null)
              ? Container()
              : Image.memory(
                  imglib.encodePng(img),
                )
            ),
          ),


          StreamBuilder(
            initialData: Colors.green[500],
            stream: _stateController.stream,
            builder: (buildContext, snapColor) {
              Color selectedColor = snapColor.data ?? Colors.green;
              return Stack(
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.all(30),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selectedColor,
                        border: Border.all(width: 2.0, color: Colors.white),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2))
                        ]),
                  ),
                ],
              );
            }
          )
        ],
      )
    );
  }

  void searchPixel(Offset globalPosition) async {

    controller.startImageStream((image) async {
      controller.stopImageStream();
      captureImage(image);  
      setState(() {});

      await loadSnapshotBytes();
     _calculatePixel(globalPosition);
    });  


  }

  Future<void> loadSnapshotBytes() async {
    RenderRepaintBoundary boxPaint = imageKey.currentContext.findRenderObject();
    ui.Image capture = await boxPaint.toImage();
    ByteData imageBytes = await capture.toByteData(format: ui.ImageByteFormat.png);
    
    List<int> values = imageBytes.buffer.asUint8List();
    photo = null;
    photo = imglib.decodeImage(values);
    capture.dispose();
  }

  void _calculatePixel(Offset globalPosition) {
    RenderBox box = imageKey.currentContext.findRenderObject();
    Offset localPosition = box.globalToLocal(globalPosition);

    double px = localPosition.dx;
    double py = localPosition.dy;

    if (true) {
      double widgetScale = box.size.width / photo.width;
      print(py);
      px = (px / widgetScale);
      py = (py / widgetScale);
    }

    int pixel32 = photo.getPixelSafe(px.toInt(), py.toInt());
    int hex = abgrToArgb(pixel32);

    _stateController.add(Color(hex));
  }

  void captureImage(CameraImage image){

    if(Platform.isAndroid){
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
      Pointer<Uint32> imgP = conv(p, p1, p2, image.planes[1].bytesPerRow,
        image.planes[1].bytesPerPixel, image.planes[0].bytesPerRow, image.height);
        
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
    }else if(Platform.isIOS){
      img = imglib.Image.fromBytes(
        image.planes[0].bytesPerRow,
        image.height,
        image.planes[0].bytes,
        format: imglib.Format.bgra,
      );
    }
  }
}

// image lib uses uses KML color format, convert #AABBGGRR to regular #AARRGGBB
int abgrToArgb(int argbColor) {
  int r = (argbColor >> 16) & 0xFF;
  int b = argbColor & 0xFF;
  return (argbColor & 0xFF00FF00) | (b << 16) | r;
}