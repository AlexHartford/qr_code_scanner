import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

void main() => runApp(MaterialApp(home: QRViewExample()));

const flash_on = "FLASH ON";
const flash_off = "FLASH OFF";
const front_camera = "FRONT CAMERA";
const back_camera = "BACK CAMERA";

class QRViewExample extends StatefulWidget {
  const QRViewExample({
    Key key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  var qrText = "";
  var flashState = flash_on;
  var cameraState = front_camera;
  var isPermissionGranted = true;
  QRViewController controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  StreamController<bool> permissionController = StreamController<bool>();

  @override
  void initState() {
    super.initState();
    permissionController.stream.listen((isPermissionGrantedEvent) {
      setState(() {
        isPermissionGranted = isPermissionGrantedEvent;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: isPermissionGranted ? qrViewWidget : permissionDialogWidget,
            flex: 4,
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text("This is the result of scan: $qrText"),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.all(8.0),
                        child: RaisedButton(
                          onPressed: () {
                            if (controller != null) {
                              controller.toggleFlash();
                              if (_isFlashOn(flashState)) {
                                setState(() {
                                  flashState = flash_off;
                                });
                              } else {
                                setState(() {
                                  flashState = flash_on;
                                });
                              }
                            }
                          },
                          child:
                              Text(flashState, style: TextStyle(fontSize: 20)),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.all(8.0),
                        child: RaisedButton(
                          onPressed: () {
                            if (controller != null) {
                              controller.flipCamera();
                              if (_isBackCamera(cameraState)) {
                                setState(() {
                                  cameraState = front_camera;
                                });
                              } else {
                                setState(() {
                                  cameraState = back_camera;
                                });
                              }
                            }
                          },
                          child:
                              Text(cameraState, style: TextStyle(fontSize: 20)),
                        ),
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.all(8.0),
                        child: RaisedButton(
                          onPressed: () {
                            controller?.pauseCamera();
                          },
                          child: Text('pause', style: TextStyle(fontSize: 20)),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.all(8.0),
                        child: RaisedButton(
                          onPressed: () {
                            controller?.resumeCamera();
                          },
                          child: Text('resume', style: TextStyle(fontSize: 20)),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
            flex: 1,
          )
        ],
      ),
    );
  }

  _isFlashOn(String current) {
    return flash_on == current;
  }

  _isBackCamera(String current) {
    return back_camera == current;
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        qrText = scanData;
      });
    });
  }

  @override
  void dispose() {
    controller.dispose();
    permissionController.close();
    super.dispose();
  }

  Widget get qrViewWidget => QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
        permissionStreamSink: permissionController.sink,
        overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: 300,
        ),
      );

  Widget get permissionDialogWidget => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                "Camera Permission is not granted",
                style: TextStyle(color: Colors.black, fontSize: 24.0),
              ),
              FlatButton(
                color: Colors.blue,
                onPressed: () {
                  controller.openPermissionSettings();
                },
                child: Text("Open Settings"),
              )
            ],
          ),
        ),
      );
}
