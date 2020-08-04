import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

void main() => runApp(MaterialApp(home: QRViewExample()));

// ignore: must_be_immutable
class QRViewExample extends HookWidget {
  QRViewExample({Key key})
      : this.qrKey = GlobalKey(debugLabel: 'QR'),
        super(key: key);

  final GlobalKey qrKey;

  QRViewController controller;

  @override
  Widget build(BuildContext context) {
    final permissionController = useStreamController<bool>();
    final isPermissionGranted = useState(true);

    final qrText = useState('');
    final flash = useState(false);

    useEffect(() {
      permissionController.stream
          .listen((bool event) => isPermissionGranted.value = event);
      return permissionController.close;
    }, [permissionController]);

    useEffect(() {
      return controller?.dispose;
    }, const []);

    useEffect(() {
      qrText.addListener(() => print(qrText.value));
      return qrText.dispose;
    }, [qrText.value]);

    return Scaffold(
      body: Stack(
        children: <Widget>[
          isPermissionGranted.value
              ? qrViewWidget(qrText, permissionController)
              : permissionDialogWidget(),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 64),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  controlButton(
                    icon: Icons.play_arrow,
                    onPressed: () => controller.resumeCamera(),
                  ),
                  controlButton(
                    icon: Icons.pause,
                    onPressed: () => controller.pauseCamera(),
                  ),
                  controlButton(
                    icon: Icons.stop,
                    onPressed: () => controller.stopCamera(),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 64),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  RaisedButton(
                    child: Icon(
                      flash.value ? Icons.flash_on : Icons.flash_off,
                      color: flash.value ? Colors.yellow : Colors.white,
                    ),
                    color: Colors.black,
                    shape: CircleBorder(),
                    padding: const EdgeInsets.all(16),
                    elevation: 8,
                    onPressed: () {
                      controller.toggleFlash();
                      flash.value = !flash.value;
                    },
                  ),
                  controlButton(
                    icon: Icons.autorenew,
                    onPressed: () => controller.flipCamera(),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  RaisedButton controlButton({IconData icon, Function onPressed}) =>
      RaisedButton(
        child: Icon(
          icon,
          color: Colors.white,
        ),
        color: Colors.black,
        shape: CircleBorder(),
        padding: const EdgeInsets.all(16),
        elevation: 8,
        onPressed: onPressed,
      );

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
          borderColor: Colors.cyanAccent,
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
