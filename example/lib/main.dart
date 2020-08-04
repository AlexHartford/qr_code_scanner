import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

void main() => runApp(MaterialApp(home: QRViewExample()));

class QRViewExample extends HookWidget {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  QRViewController controller;

  @override
  Widget build(BuildContext context) {
    final permissionController = useStreamController<bool>();
    final qrText = useState('');
    final flash = useState(false);
    final backCamera = useState(true);
    final isPermissionGranted = useState(true);

    useEffect(() {
      permissionController.stream
          .listen((bool event) => isPermissionGranted.value = event);
      return permissionController.close;
    }, [permissionController]);

    useEffect(() {
      return controller?.dispose;
    }, const []);

    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: isPermissionGranted.value
                ? qrViewWidget(qrText, permissionController)
                : permissionDialogWidget(),
            flex: 4,
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text("barcode value: ${qrText.value}"),
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
                              flash.value = !flash.value;
                            }
                          },
                          child: Text(
                            'flash ${flash.value ? 'on' : 'off'}',
                            style: TextStyle(
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.all(8.0),
                        child: RaisedButton(
                          onPressed: () {
                            if (controller != null) {
                              controller.flipCamera();
                              backCamera.value = !backCamera.value;
                            }
                          },
                          child: Text(
                              'using ${backCamera.value ? 'back' : 'front'} camera',
                              style: TextStyle(fontSize: 20)),
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
                  RaisedButton(
                    onPressed: () {
                      controller?.stopCamera();
                    },
                    child: Text('stop', style: TextStyle(fontSize: 20)),
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

  Widget qrViewWidget(ValueNotifier<String> qrText, StreamController stream) =>
      QRView(
        key: qrKey,
        onQRViewCreated: (QRViewController controller) {
          this.controller = controller;
          controller.scannedDataStream
              .listen((scanData) => qrText.value = scanData);
        },
        permissionStreamSink: stream.sink,
        overlay: QrScannerOverlayShape(
          borderColor: Colors.cyan,
          borderRadius: 10,
          borderLength: 75,
          borderWidth: 5,
          cutOutSize: 300,
        ),
      );

  Widget permissionDialogWidget() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Enable camera permissions to scan QR codes!',
                style: TextStyle(color: Colors.black, fontSize: 24.0),
              ),
              FlatButton(
                color: Colors.blue,
                onPressed: () {
                  controller.openPermissionSettings();
                },
                child: Text('Open Settings'),
              )
            ],
          ),
        ),
      );
}
