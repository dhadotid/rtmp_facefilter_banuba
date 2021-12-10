package com.yudha.myapplication

import android.Manifest
import android.content.pm.PackageManager
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.view.SurfaceHolder
import android.view.View
import android.view.WindowManager
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.viewbinding.ViewBinding
import com.pedro.rtplibrary.rtmp.RtmpCamera2
import com.yudha.myapplication.databinding.ActivityMainBinding
import net.ossrs.rtmp.ConnectCheckerRtmp

class MainActivity : AppCompatActivity(), SurfaceHolder.Callback,
    ConnectCheckerRtmp {

    private lateinit var _binding: ActivityMainBinding

    private var mWidth = 1080
    private var mHeight = 1920
    private val mBitrate = 1200 * 1024
    private var rtmpUrl: String? = null
    private var camera: RtmpCamera2? = null

    private val REQUIRED_PERMISSIONS = arrayOf(
        Manifest.permission.CAMERA, Manifest.permission.RECORD_AUDIO)

    private fun allPermissionsGranted() = REQUIRED_PERMISSIONS.all {
        ActivityCompat.checkSelfPermission(
            this, it) == PackageManager.PERMISSION_GRANTED
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        _binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(_binding.root)
        prepareCameraPermission()
    }

    private fun setupCamera(){
        _binding.cameraPreview.holder.addCallback(this)
        camera = RtmpCamera2(_binding.cameraPreview, this)
        camera?.setReTries(10)
        camera?.setVideoBitrateOnFly(mBitrate)
        _binding.btSwitchCamera.setOnClickListener {
            camera?.switchCamera()
        }
        _binding.btnStream.setOnClickListener {
            startPublish(_binding.etSreamURL.text.toString())
        }
        _binding.btnStop.setOnClickListener {
            stopStreaming()
        }
    }

    private fun startPublish(rtmpUrl: String){
        camera?.let {
            if (it.prepareAudio() && it.prepareVideo(mWidth, mHeight, mBitrate)){
                this.rtmpUrl = rtmpUrl
                it.startStream(rtmpUrl)
                _binding.btnStream.visibility = View.GONE
                _binding.btnStop.visibility = View.VISIBLE
            }
        }
    }

    private fun stopStreaming() {
        _binding.btnStream.visibility = View.VISIBLE
        _binding.btnStop.visibility = View.GONE
        camera?.stopStream()
    }

    private fun isStreaming(): Boolean {
        camera?.let {
            return it.isStreaming
        }
        return false
    }

    private fun prepareCameraPermission(){
        if(allPermissionsGranted()) {
            setupCamera()
            camera?.startPreview()
        }else{
            ActivityCompat.requestPermissions(
                this,
                REQUIRED_PERMISSIONS,
                12
            )
        }
    }


    override fun onResume() {
        super.onResume()
        camera?.startForwardingFrames()
    }

    override fun onPause() {
        super.onPause()
        camera?.stopForwardingFrames()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (allPermissionsGranted()) {
            setupCamera()
            camera?.startPreview()
        }else{
            Toast.makeText(this, "Permissions not granted by the user.", Toast.LENGTH_LONG).show()
        }
    }

    override fun surfaceCreated(p0: SurfaceHolder) {
        camera?.startPreview()
        rtmpUrl?.let {
            startPublish(it)
        }
    }

    override fun surfaceChanged(p0: SurfaceHolder, p1: Int, p2: Int, p3: Int) {

    }

    override fun surfaceDestroyed(p0: SurfaceHolder) {
        if(isStreaming()){
            stopStreaming()
        }
        camera?.stopPreview()
    }

    override fun onConnectionSuccessRtmp() {

    }

    override fun onConnectionFailedRtmp(reason: String) {
        camera?.let {
            if (it.shouldRetry(reason)){
                Toast.makeText(this, "Retry", Toast.LENGTH_LONG).show()
                camera?.reTry(5000)
            }else{
                stopStreaming()
                Toast.makeText(this, "Failed to connect", Toast.LENGTH_LONG).show()
            }
        }
    }

    override fun onNewBitrateRtmp(bitrate: Long) {

    }

    override fun onDisconnectRtmp() {

    }

    override fun onAuthErrorRtmp() {

    }

    override fun onAuthSuccessRtmp() {

    }
}