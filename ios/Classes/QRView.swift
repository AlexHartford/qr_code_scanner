//
//  QRView.swift
//  flutter_qr
//
//  Created by Julius Canute on 21/12/18.
//

import Foundation
import MTBBarcodeScanner

public class QRView: NSObject, FlutterPlatformView {
    @IBOutlet var previewView: UIView!
    var scanner: MTBBarcodeScanner?
    var registrar: FlutterPluginRegistrar
    var channel: FlutterMethodChannel
    var permissionChannel: FlutterMethodChannel
    
    public init(withFrame frame: CGRect, withRegistrar registrar: FlutterPluginRegistrar, withId id: Int64){
        self.registrar = registrar
        previewView = UIView(frame: frame)
        channel = FlutterMethodChannel(name: "net.touchcapture.qr.flutterqr/qrview_\(id)", binaryMessenger: registrar.messenger())
        permissionChannel = FlutterMethodChannel(name: "net.touchcapture.qr.flutterqr/permission", binaryMessenger: registrar.messenger())
    }
    
    func isCameraAvailable(success: Bool) -> Void {
        if success {
            do {
                try scanner?.startScanning(resultBlock: { codes in
                    if let codes = codes {
                        for code in codes {
                            guard let stringValue = code.stringValue else { continue }
                            self.channel.invokeMethod("onRecognizeQR", arguments: stringValue)
                        }
                    }
                })
            } catch {
                NSLog("Unable to start scanning")
            }
        } else {
            self.permissionChannel.invokeMethod("cameraPermission", arguments: false)
            // Responsibility delegated to app_settings on the Flutter side.
            // openSettingsDialog()
        }
    }
    
    public func view() -> UIView {
        channel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
            switch(call.method){
                case "setDimensions":
                    let arguments = call.arguments as! Dictionary<String, Double>
                    self?.setDimensions(width: arguments["width"] ?? 0, height: arguments["height"] ?? 0)
                case "flipCamera":
                    self?.flipCamera()
                case "toggleFlash":
                    self?.toggleFlash()
                case "pauseCamera":
                    self?.pauseCamera()
                case "resumeCamera":
                    self?.resumeCamera()
                case "stopCamera":
                    self?.stopCamera()
                case "openPermissionSettings":
                    self?.openSettingsDialog()
                default:
                    result(FlutterMethodNotImplemented)
                    return
            }
        })
        return previewView
    }
    
    func setDimensions(width: Double, height: Double) -> Void {
       previewView.frame = CGRect(x: 0, y: 0, width: width, height: height)
       scanner = MTBBarcodeScanner(previewView: previewView)
       scanner?.allowTapToFocus = true
       MTBBarcodeScanner.requestCameraPermission(success: isCameraAvailable)
    }
    
    func flipCamera(){
        if let sc: MTBBarcodeScanner = scanner {
            if sc.hasOppositeCamera() {
                sc.flipCamera()
            }
        }
    }
    
    func toggleFlash(){
        if let sc: MTBBarcodeScanner = scanner {
            if sc.hasTorch() {
                sc.toggleTorch()
            }
        }
    }
    
    func pauseCamera() {
        if let sc: MTBBarcodeScanner = scanner {
            if sc.isScanning() {
                sc.freezeCapture()
            }
        }
    }
    
    func resumeCamera() {
        if let sc: MTBBarcodeScanner = scanner {
            if !sc.isScanning() {
                sc.unfreezeCapture()
            }
        }
    }

    func stopCamera() {
        if let sc: MTBBarcodeScanner = scanner {
            sc.stopScanning()
        }
    }

    func openSettingsDialog() {
        let alert = UIAlertController(title: "Unable to access camera",
                                      message: "To enable access, go to Settings > Privacy > Camera and turn on camera access for this app.",
                                      preferredStyle: UIAlertController.Style.alert)

        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(okAction)

        let settingsAction = UIAlertAction(title: "Settings", style: .default, handler: { _ in
            // Take the user to Settings app to possibly change permission.
            guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else { return }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                        // Successfully opened settings
                    })
                } else {
                    // Fallback on earlier versions
                    UIApplication.shared.openURL(settingsUrl)
                }
            }
        })
        alert.addAction(settingsAction)

        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: { () in
            // Unfortunately, this doesn't do much because IOS kills your app if the user changes settings.
            // Leaving this in with the hope that one day Apple changes their mind.
            let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
            self.permissionChannel.invokeMethod("cameraPermission", arguments: status == .authorized)
        })
    }
}
