import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:rxdart/rxdart.dart';

class Panel extends StatefulWidget {
  
  const Panel({Key key, this.colorController, this.onTap, this.colorListKey}) : super(key: key);
  
  final BehaviorSubject<Color> colorController;
  final Function(Function(Color)) onTap;
  final GlobalKey colorListKey;

  @override
  _PanelState createState() => _PanelState();
}

class _PanelState extends State<Panel> {

  List<Color> _colors = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      width: double.infinity,
      padding: EdgeInsets.all(8),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: 200,
              height: 58,
              child: ListView.builder(
                key: widget.colorListKey,
                itemCount: _colors.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, int index){
                  return Container(
                    width: 20,
                    height: 20,
                    margin: EdgeInsets.only(left: 10, right: 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _colors[index],
                    ),
                  );
                },
              )
            ),
          ),
          Center(
            child: Container(
              height: 50,
              width: 50,
              child: RaisedButton(
                padding: EdgeInsets.zero,
                child: Icon(Feather.check, color: Colors.white,),
                color: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                onPressed: () {
                  widget.onTap((Color color) {
                    if (_colors.length == 5)
                      _colors.removeLast();
                    setState(() {
                      _colors.insert(0, color);
                    });
                  });
                }),
            ),
          )
        ],
      ),
    );
  }
}