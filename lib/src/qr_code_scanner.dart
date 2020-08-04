import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef QRViewCreatedCallback = void Function(QRViewController controller);

const libraryId = 'net.touchcapture.qr.flutterqr';
const cameraPermission = 'cameraPermission';
const permissionGranted = 'granted';

class QRView extends StatefulWidget {
  const QRView({
    @required Key key,
    @required this.onQRViewCreated,
    @required this.permissionStreamSink,
    this.overlay,
  })  : assert(key != null),
        assert(onQRViewCreated != null),
        assert(permissionStreamSink != null),
        super(key: key);

  final QRViewCreatedCallback onQRViewCreated;
  final ShapeBorder overlay;
  final StreamSink<bool> permissionStreamSink;

  @override
  State<StatefulWidget> createState() => _QRViewState();
}

class _QRViewState extends State<QRView> {
  MethodChannel permissionChannel;

  Widget _getPlatformQrView() {
    Widget _platformQrView;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        _platformQrView = AndroidView(
          viewType: '$libraryId/qrview',
          onPlatformViewCreated: _onPlatformViewCreated,
        );
        break;
      case TargetPlatform.iOS:
        _platformQrView = UiKitView(
          viewType: '$libraryId/qrview',
          onPlatformViewCreated: _onPlatformViewCreated,
          creationParams: _CreationParams.fromWidget(0, 0).toMap(),
          creationParamsCodec: StandardMessageCodec(),
        );
        break;
      default:
        throw UnsupportedError(
            'No default webview implementation for $defaultTargetPlatform.');
    }
    return _platformQrView;
  }

  void _onPlatformViewCreated(int id) {
    if (widget.onQRViewCreated == null) {
      return;
    }
    widget.onQRViewCreated(QRViewController._(id, widget.key));
    permissionChannel = MethodChannel('$libraryId/permission')
      ..setMethodCallHandler(
        (call) async {
          if (call.method == cameraPermission) {
            if (call.arguments != null) {
              final isPermissionGranted = call.arguments == permissionGranted;
              widget.permissionStreamSink.add(isPermissionGranted);
            }
          }
        },
      );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _getPlatformQrView(),
        if (widget.overlay != null)
          Container(
            decoration: ShapeDecoration(
              shape: widget.overlay,
            ),
          )
      ],
    );
  }
}

class _CreationParams {
  _CreationParams({this.width, this.height});

  final double height;
  final double width;

  static _CreationParams fromWidget(double width, double height) {
    return _CreationParams(
      width: width,
      height: height,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'width': width, 'height': height};
  }
}

class QRViewController {
  QRViewController._(int id, GlobalKey qrKey)
      : _channel = MethodChannel('$libraryId/qrview_$id') {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final RenderBox renderBox = qrKey.currentContext.findRenderObject();
      _channel.invokeMethod('setDimensions',
          {'width': renderBox.size.width, 'height': renderBox.size.height});
    }
    _channel.setMethodCallHandler(
      (call) async {
        switch (call.method) {
          case scanMethodCall:
            {
              if (call.arguments != null) {
                _scanUpdateController.sink.add(call.arguments.toString());
              }
              break;
            }
        }
      },
    );
  }

  static const scanMethodCall = 'onRecognizeQR';

  final MethodChannel _channel;
  final StreamController<String> _scanUpdateController =
      StreamController<String>();

  Stream<String> get scannedDataStream => _scanUpdateController.stream;

  void flipCamera() {
    _channel.invokeMethod('flipCamera');
  }

  void toggleFlash() {
    _channel.invokeMethod('toggleFlash');
  }

  void pauseCamera() {
    _channel.invokeMethod('pauseCamera');
  }

  void resumeCamera() {
    _channel.invokeMethod('resumeCamera');
  }

  void openPermissionSettings() {
    _channel.invokeMethod('openPermissionSettings');
  }

  void stopCamera() {
    _channel.invokeMethod('stopCamera');
  }

  void dispose() {
    stopCamera();
    _scanUpdateController.close();
  }
}
