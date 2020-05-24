import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rxdart/rxdart.dart';
import '../utils/image_utils.dart';

class ColorViewer extends StatelessWidget {

  ColorViewer({this.colorController, this.colorKey});

  final GlobalKey colorKey;
  final BehaviorSubject<Color> colorController;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      initialData: Colors.green[500],
      stream: colorController.stream,
      builder: (buildContext, snapColor) {
        Color selectedColor = snapColor.data ?? Colors.green;
        return IgnorePointer(
          ignoring: true,
          child: Container(
            width: 110,
            height: 40,
            margin: EdgeInsets.only(top: 160),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                width: 1.0, color: Colors.white
              ),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2)
                )
              ]
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                AnimatedContainer(
                  key: colorKey,
                  duration: Duration(milliseconds: 500),
                  width: 20,
                  height: 20,
                  margin: EdgeInsets.only(left: 5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selectedColor,
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: 5),
                    child: Text(
                      "${selectedColor.toHex().toUpperCase()}",
                      style: GoogleFonts.montserrat(
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      }
    );
  }
}