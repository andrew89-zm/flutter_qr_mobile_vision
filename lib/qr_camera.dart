import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:qr_mobile_vision/qr_mobile_vision.dart';

class QrCamera extends StatefulWidget {
  QrCamera({this.fit = BoxFit.cover, this.qrCodeCallback, this.notStartedBuilder}) : assert(fit != null);

  final BoxFit fit;
  final ValueChanged<String> qrCodeCallback;
  final WidgetBuilder notStartedBuilder;

  void qrCodeHandler(String string) {
    qrCodeCallback(string);
  }

  @override
  QrCameraState createState() => new QrCameraState();
}

class QrCameraState extends State<QrCamera> {
  QrCameraState();

  bool inited = false;
  PreviewDetails details;

  void initOnce(num width, num height) async {
    if (!inited) {
      inited = true;
      var _details = await QrMobileVision.start(
        width: width.toInt(),
        height: height.toInt(),
        qrCodeHandler: widget.qrCodeHandler,
      );
      setState(() {
        details = _details;
      });
    }
  }

  @override
  deactivate() {
    super.deactivate();
    QrMobileVision.stop();
  }

  @override
  Widget build(BuildContext context) {
    return new LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        initOnce(constraints.maxWidth, constraints.maxHeight);
        var content;
        if (details != null) {
          content = Preview(previewDetails: details, targetWidth: constraints.maxWidth, targetHeight: constraints.maxHeight, fit: widget.fit);
        } else {
          var notStartedBuilder = widget.notStartedBuilder;
          content = notStartedBuilder == null ? new Text("Camera Loading ...") : notStartedBuilder(context);
        }
        return new SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: content,
        );
      },
    );
  }
}

class Preview extends StatelessWidget {
  final double width, height;
  final double targetWidth, targetHeight;
  final int textureId;
  final int orientation;
  final BoxFit fit;

  Preview({
    @required PreviewDetails previewDetails,
    @required this.targetWidth,
    @required this.targetHeight,
    @required this.fit,
  })  : assert(previewDetails != null),
        textureId = previewDetails.textureId,
        width = previewDetails.width.toDouble(),
        height = previewDetails.height.toDouble(),
        orientation = previewDetails.orientation;

  @override
  Widget build(BuildContext context) {
    double frameHeight, frameWidth;

    return new NativeDeviceOrientationReader(
      builder: (context) {
        var nativeOrientation = NativeDeviceOrientationReader.orientation(context);

        int baseOrientation = 0;
        if (orientation != 0 && (width > height)) {
          baseOrientation = orientation ~/ 90;
          frameWidth = width;
          frameHeight = height;
        } else {
          frameHeight = width;
          frameWidth = height;
        }

        int nativeOrientationInt;
        switch (nativeOrientation) {
          case NativeDeviceOrientation.landscapeLeft:
            nativeOrientationInt = Platform.isAndroid ? 3 : 1;
            break;
          case NativeDeviceOrientation.landscapeRight:
            nativeOrientationInt = Platform.isAndroid ? 1 : 3;
            break;
          case NativeDeviceOrientation.portraitDown:
            nativeOrientationInt = 2;
            break;
          case NativeDeviceOrientation.portraitUp:
          case NativeDeviceOrientation.unknown:
            nativeOrientationInt = 0;
        }

        return new FittedBox(
          fit: fit,
          child: new RotatedBox(
            quarterTurns: baseOrientation + nativeOrientationInt,
            child: new SizedBox(
              width: frameWidth,
              height: frameHeight,
              child: new Texture(textureId: textureId),
            ),
          ),
        );
      },
    );
  }
}
