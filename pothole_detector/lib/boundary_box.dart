import 'package:flutter/material.dart';

class BoundaryBox extends StatelessWidget {
  final List<dynamic> results;
  final int previewH;
  final int previewW;
  final double screenH;
  final double screenW;

  BoundaryBox(
      this.results, this.previewH, this.previewW, this.screenH, this.screenW);

  @override
  Widget build(BuildContext context) {
    List<Widget> _renderStrings() {
      return results.map((re) {
        return RotatedBox(
          quarterTurns: 1,
          child: Stack(
            children: <Widget>[
              Positioned(
                left: ((screenW / 2) + 90),
                bottom: -(screenH - 80),
                width: screenW,
                height: screenH,
                child: Text(
                  "${re["label"] == '0 Detected' ? "detected" : "not detected"} ${(re["confidence"] * 100).toStringAsFixed(0)}%",
                  style: TextStyle(
                    backgroundColor: Colors.black,
                    color: re["label"] == '1 Undetected'
                        ? Colors.red
                        : Colors.green,
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                left: (screenW / 2),
                top: 30,
                width: screenW,
                height: screenH,
                child: Text(
                  "Detection only on Horizontal camera feed",
                  style: TextStyle(
                    backgroundColor: Colors.black,
                    color: Colors.amber,
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
        );
      }).toList();
    }

    return Stack(
      children: _renderStrings(),
    );
  }
}
