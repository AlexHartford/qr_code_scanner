package net.touchcapture.qr.flutterqr

import android.Manifest
import android.app.Activity
import android.app.Application
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.PackageManager.PERMISSION_GRANTED
import android.hardware.Camera.CameraInfo
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import android.view.View
import com.google.zxing.ResultPoint
import com.journeyapps.barcodescanner.BarcodeCallback
import com.journeyapps.barcodescanner.BarcodeResult
import com.journeyapps.barcodescanner.BarcodeView
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.platform.PlatformView


class QRView(private val registrar: PluginRegistry.Registrar, id: Int) :
        PlatformView, MethodChannel.MethodCallHandler {

    companion object {
        const val CAMERA_REQUEST_ID = 513469796
        const val LIBRARY_ID ="net.touchcapture.qr.flutterqr"
        private const val cameraPermission = "cameraPermission"
        private const val openPermissionSettings = "openPermissionSettings"
        private const val permissionGranted = "granted"
        private const val permissionDenied = "denied"
    }

    var barcodeView: BarcodeView? = null
    private val activity = registrar.activity()
    var cameraPermissionContinuation: Runnable? = null
    var requestingPermission = false
    private var isTorchOn: Boolean = false
    val channel: MethodChannel
    private val permissionChannel: MethodChannel
    private var isPermissionEnabled = true

    init {
        registrar.addRequestPermissionsResultListener(CameraRequestPermissionsListener())
        channel = MethodChannel(registrar.messenger(), "$LIBRARY_ID/qrview_$id")
        permissionChannel = MethodChannel(registrar.messenger(), "$LIBRARY_ID/permission")
        channel.setMethodCallHandler(this)
        checkAndRequestPermission(null)
        registrar.activity().application.registerActivityLifecycleCallbacks(object : Application.ActivityLifecycleCallbacks {
            override fun onActivityPaused(p0: Activity?) {
                if (p0 == registrar.activity()) {
                    barcodeView?.pause()
                }
            }

            override fun onActivityResumed(p0: Activity?) {
                if (p0 == registrar.activity()) {
                    if (hasCameraPermission()) {
                        barcodeView?.resume()
                        postPermissionEnabled()
                    }
                }
            }

            override fun onActivityStarted(p0: Activity?) {
            }

            override fun onActivityDestroyed(p0: Activity?) {
            }

            override fun onActivitySaveInstanceState(p0: Activity?, p1: Bundle?) {
            }

            override fun onActivityStopped(p0: Activity?) {
            }

            override fun onActivityCreated(p0: Activity?, p1: Bundle?) {
            }
        })
    }
    private fun postPermissionEnabled() {
        if (!isPermissionEnabled) {
            isPermissionEnabled = true
            permissionChannel.invokeMethod(cameraPermission, permissionGranted)
        }
    }

    fun flipCamera() {
        barcodeView?.pause()
        var settings = barcodeView?.cameraSettings

        if (settings?.requestedCameraId == CameraInfo.CAMERA_FACING_FRONT)
            settings?.requestedCameraId = CameraInfo.CAMERA_FACING_BACK
        else
            settings?.requestedCameraId = CameraInfo.CAMERA_FACING_FRONT

        barcodeView?.cameraSettings = settings
        barcodeView?.resume()
    }

    private fun toggleFlash() {
        if (hasFlash()) {
            barcodeView?.setTorch(!isTorchOn)
            isTorchOn = !isTorchOn
        }

    }

    private fun pauseCamera() {
        if (barcodeView!!.isPreviewActive) {
            barcodeView?.pause()
        }
    }

    private fun resumeCamera() {
        if (!barcodeView!!.isPreviewActive) {
            barcodeView?.resume()
        }
    }

    private fun hasFlash(): Boolean {
        return registrar.activeContext().packageManager
                .hasSystemFeature(PackageManager.FEATURE_CAMERA_FLASH)
    }

    override fun getView(): View {
        return initBarCodeView()?.apply {
            if (hasCameraPermission()) {
                resume()
            }
        }!!
    }

    private fun initBarCodeView(): BarcodeView? {
        if (barcodeView == null) {
            barcodeView = createBarCodeView()
        }
        return barcodeView
    }

    private fun createBarCodeView(): BarcodeView? {
        val barcode = BarcodeView(registrar.activity())
        barcode.decodeContinuous(
                object : BarcodeCallback {
                    override fun barcodeResult(result: BarcodeResult) {
                        channel.invokeMethod("onRecognizeQR", result.text)
                        barcodeView.stopDecoding()
                    }

                    override fun possibleResultPoints(resultPoints: List<ResultPoint>) {}
                }
        )
        return barcode
    }

    override fun dispose() {
        barcodeView?.pause()
        barcodeView = null
    }

    private inner class CameraRequestPermissionsListener : PluginRegistry.RequestPermissionsResultListener {
        override fun onRequestPermissionsResult(id: Int, permissions: Array<String>, grantResults: IntArray): Boolean {
            if (id == CAMERA_REQUEST_ID) {
                if (grantResults[0] == PERMISSION_GRANTED) {
                    isPermissionEnabled = true
                    cameraPermissionContinuation?.run()
                } else {
                    isPermissionEnabled = false
                    permissionChannel.invokeMethod(cameraPermission, permissionDenied)
                }
                return true
            }
            return false
        }
    }

    private fun hasCameraPermission(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
                activity.checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
    }


    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call?.method) {
            "checkAndRequestPermission" -> {
                checkAndRequestPermission(result)
            }
            "flipCamera" -> {
                flipCamera()
            }
            "toggleFlash" -> {
                toggleFlash()
            }
            "pauseCamera" -> {
                pauseCamera()
            }
            "resumeCamera" -> {
                resumeCamera()
            }
            "stopCamera" -> {
                dispose()
            }
            openPermissionSettings -> openSettings()
        }
    }

    private fun openSettings() {
        val uri = Uri.parse("package:" + activity.getPackageName())
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, uri)
        activity.startActivity(intent)
    }

    private fun checkAndRequestPermission(result: MethodChannel.Result?) {
        if (cameraPermissionContinuation != null) {
            result?.error("cameraPermission", "Camera permission request ongoing", null);
        }

        cameraPermissionContinuation = Runnable {
            cameraPermissionContinuation = null
            if (!hasCameraPermission()) {
                result?.error(
                        "cameraPermission", "MediaRecorderCamera permission not granted", null)
                return@Runnable
            }
        }

        requestingPermission = false
        if (hasCameraPermission()) {
            cameraPermissionContinuation?.run()
        } else {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                requestingPermission = true
                registrar
                        .activity()
                        .requestPermissions(
                                arrayOf(Manifest.permission.CAMERA),
                                CAMERA_REQUEST_ID)
            }
        }
    }
}
