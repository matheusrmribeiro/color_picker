import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraViewer extends StatefulWidget {
  CameraViewer({Key key, this.camera, this.controller, this.child}) : super(key: key);
  
  final CameraDescription camera;
  final StreamController<CameraImage> controller;
  final Widget child;

  @override
  _CameraViewerState createState() => _CameraViewerState();
}

class _CameraViewerState extends State<CameraViewer> {

  CameraController controller;

  @override
  void initState() {
    super.initState();
    controller = CameraController(widget.camera, ResolutionPreset.medium, enableAudio: false);
    
    controller.addListener(() {
      controller.startImageStream((image) => 
        widget.controller.add(image)
      );
    });

    controller.initialize().then((_) {
      if (!mounted)
        return;
      setState(() {});
    });
  }

    @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }
    return Stack(
      children: <Widget>[
        (controller.value.isInitialized)
        ? AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller)
          )
        : Container(),
        widget.child,
      ],
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   if (!controller.value.isInitialized) {
  //     return Container();
  //   }
  //   return AspectRatio(
  //     aspectRatio: controller.value.aspectRatio,
  //     child: CameraPreview(controller)
  //   );
  // }
}
