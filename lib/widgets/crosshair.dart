import 'package:flutter/material.dart';

class Crosshair extends StatefulWidget {

  const Crosshair({Key key}) : super(key: key);

  @override
  _CrosshairState createState() => _CrosshairState();
}

class _CrosshairState extends State<Crosshair> {

  double width = 200;
  double height = 200;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 1000),
      curve: Curves.easeInOutCubic,
      onEnd: () {
        if (width == 200) {
          setState(() {
            width = 300;
            height = 300;
          });
        }
        else {
          setState(() {
            width = 200;
            height = 200;
          });
        }
      },
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border:
          Border.all(width: 2.0, color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2)
          )
        ]
      ),
      child: Center(
        child: Container(
          height: 10,
          width: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}