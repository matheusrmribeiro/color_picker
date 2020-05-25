import 'dart:async';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:color_picker/widgets/panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as imglib;
import 'package:rxdart/rxdart.dart';

import 'utils/image_utils.dart';
import 'widgets/color_viewer.dart';
import 'widgets/crosshair.dart';

class ColorPicker extends StatefulWidget {
  ColorPicker(this.cameras);

  final List<CameraDescription> cameras;

  @override
  _ColorPickerState createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  final BehaviorSubject<Color> _colorController = BehaviorSubject<Color>();
  final BehaviorSubject<CameraImage> _cameraStream = BehaviorSubject<CameraImage>();
  final BehaviorSubject<bool> _shouldReadCamera = BehaviorSubject<bool>.seeded(true);
  final BehaviorSubject<imglib.Image> _screenshotStream = BehaviorSubject<imglib.Image>();
  final ImageUtils _imageUtils = ImageUtils();
  final GlobalKey _colorKey = GlobalKey();
  final GlobalKey _colorListKey = GlobalKey();

  CameraController _camera;
  Offset _cameraSize;
  Offset _colorPosition = Offset(0, 0);
  bool _colorSelected = false;
  Color selectedColor;

  @override
  void initState() {
    super.initState();
  
    _camera = CameraController(widget.cameras[0], ResolutionPreset.veryHigh, enableAudio: false);
    _camera.initialize().then((_) {
      if (!mounted) 
        return;

      // _colorController.add(Colors.purple);
      _camera.startImageStream((image) {
        if (_shouldReadCamera.value){
          _cameraStream.add(image);
          _shouldReadCamera.add(false);
          Future.delayed(Duration(milliseconds: 1000)).then((value) => _shouldReadCamera.add(true));
        }
      });

      setState(() {});
    });
    

    _cameraStream.listen((CameraImage value) => _imageUtils.captureImage(value, (img) => _screenshotStream.add(img)));
    
    _screenshotStream.listen((imglib.Image value) async => loadSnapshotBytes());
  }

  @override
  void dispose() {
    _camera.stopImageStream();
    _camera?.dispose();
    _cameraStream.close();
    _colorController.close();
    _screenshotStream.close();
    _shouldReadCamera.close();
    super.dispose();
  }

  Future<void> loadSnapshotBytes() async {
    int abgrToArgb(int argbColor) {
      int r = (argbColor >> 16) & 0xFF;
      int b = argbColor & 0xFF;
      return (argbColor & 0xFF00FF00) | (b << 16) | r;
    }

    double px = _screenshotStream.value.width / 2;
    double py = _screenshotStream.value.height / 2;

    int pixel32 = _screenshotStream.value.getPixelSafe(px.toInt(), py.toInt());
    int hex = abgrToArgb(pixel32);

    _colorController.add(Color(hex));
  }


  void onSelectedColor(Function addColor) async {
                  
    selectedColor = _colorController.value;

    RenderBox boxBegin = _colorKey.currentContext.findRenderObject();
    Offset positionBegin = boxBegin.localToGlobal(Offset.zero);
    
    setState(() {
      _colorPosition = positionBegin;
    });

    RenderBox boxEnd = _colorListKey.currentContext.findRenderObject();
    Offset positionEnd = boxEnd.localToGlobal(Offset.zero);

    await Future.delayed(Duration(milliseconds: 375));

    setState(() {
      _colorSelected = true;
      _colorPosition = Offset(positionEnd.dx + 10, positionEnd.dy + 20);
    });

    await Future.delayed(Duration(milliseconds: 500));

    setState(() {
      _colorSelected = false;
    });

    addColor(selectedColor);

  }
  
  @override
  Widget build(BuildContext context) {
    _cameraSize = Offset(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height * 0.7);

    return Scaffold(
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: <Widget>[
                    Container(
                      height: _cameraSize.dy,
                      width: _cameraSize.dx,
                      child: CameraPreview(_camera)
                    ),
                    Center(
                      child: Crosshair()
                    ),
                    Center(
                      child: Container(
                        margin: EdgeInsets.only(bottom: 15),
                        child: ColorViewer(colorController: _colorController, colorKey: _colorKey,)
                      )
                    ),
                  ],
                ),
              ),
              Panel(
                colorListKey: _colorListKey,
                colorController: _colorController,
                onTap: onSelectedColor
              )
            ],
          ),
          AnimatedPositioned(
            duration: Duration(milliseconds: 375),
            left: _colorPosition.dx,
            top: _colorPosition.dy,
            child: IgnorePointer(
              ignoring: true,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (_colorSelected) ? selectedColor : Colors.transparent,
                ),
              ),
            ),
          ),
        ],
      )
    );
  }
  
}
