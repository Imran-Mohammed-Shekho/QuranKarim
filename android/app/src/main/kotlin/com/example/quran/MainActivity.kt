package com.example.quran1

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.view.Surface
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import kotlin.math.abs

class MainActivity : FlutterActivity(), EventChannel.StreamHandler, SensorEventListener {
    private val compassChannelName = "quran/device_compass"
    private var sensorManager: SensorManager? = null
    private var rotationVectorSensor: Sensor? = null
    private var accelerometerSensor: Sensor? = null
    private var magnetometerSensor: Sensor? = null
    private var eventSink: EventChannel.EventSink? = null
    private var isListening = false
    private var gravityValues = FloatArray(3)
    private var magneticValues = FloatArray(3)
    private var hasGravity = false
    private var hasMagnetic = false
    private var lastHeading = Float.NaN

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        rotationVectorSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
        accelerometerSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        magnetometerSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, compassChannelName)
                .setStreamHandler(this)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
        startCompass()
    }

    override fun onCancel(arguments: Any?) {
        stopCompass()
        eventSink = null
    }

    override fun onResume() {
        super.onResume()
        if (eventSink != null) {
            startCompass()
        }
    }

    override fun onPause() {
        stopCompass()
        super.onPause()
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

    override fun onSensorChanged(event: SensorEvent) {
        when (event.sensor.type) {
            Sensor.TYPE_ROTATION_VECTOR -> emitFromRotationVector(event.values.clone())
            Sensor.TYPE_ACCELEROMETER -> {
                gravityValues = event.values.clone()
                hasGravity = true
                emitFromFallbackSensors()
            }
            Sensor.TYPE_MAGNETIC_FIELD -> {
                magneticValues = event.values.clone()
                hasMagnetic = true
                emitFromFallbackSensors()
            }
        }
    }

    private fun startCompass() {
        if (isListening) {
            return
        }

        val manager =
                sensorManager
                        ?: run {
                            eventSink?.error(
                                    "NO_SENSOR_MANAGER",
                                    "Sensor manager is unavailable.",
                                    null
                            )
                            return
                        }

        if (rotationVectorSensor != null) {
            manager.registerListener(this, rotationVectorSensor, SensorManager.SENSOR_DELAY_UI)
            isListening = true
            return
        }

        if (accelerometerSensor != null && magnetometerSensor != null) {
            manager.registerListener(this, accelerometerSensor, SensorManager.SENSOR_DELAY_UI)
            manager.registerListener(this, magnetometerSensor, SensorManager.SENSOR_DELAY_UI)
            isListening = true
            return
        }

        eventSink?.error("NO_COMPASS_SENSOR", "Compass sensor is unavailable.", null)
    }

    private fun stopCompass() {
        if (!isListening) {
            return
        }
        sensorManager?.unregisterListener(this)
        isListening = false
        hasGravity = false
        hasMagnetic = false
    }

    private fun emitFromRotationVector(values: FloatArray) {
        val rotationMatrix = FloatArray(9)
        SensorManager.getRotationMatrixFromVector(rotationMatrix, values)
        emitHeading(rotationMatrix)
    }

    private fun emitFromFallbackSensors() {
        if (!hasGravity || !hasMagnetic) {
            return
        }

        val rotationMatrix = FloatArray(9)
        if (!SensorManager.getRotationMatrix(rotationMatrix, null, gravityValues, magneticValues)) {
            return
        }
        emitHeading(rotationMatrix)
    }

    private fun emitHeading(rotationMatrix: FloatArray) {
        val adjustedMatrix = FloatArray(9)
        when (currentDisplayRotation()) {
            Surface.ROTATION_90 ->
                    SensorManager.remapCoordinateSystem(
                            rotationMatrix,
                            SensorManager.AXIS_Y,
                            SensorManager.AXIS_MINUS_X,
                            adjustedMatrix
                    )
            Surface.ROTATION_180 ->
                    SensorManager.remapCoordinateSystem(
                            rotationMatrix,
                            SensorManager.AXIS_MINUS_X,
                            SensorManager.AXIS_MINUS_Y,
                            adjustedMatrix
                    )
            Surface.ROTATION_270 ->
                    SensorManager.remapCoordinateSystem(
                            rotationMatrix,
                            SensorManager.AXIS_MINUS_Y,
                            SensorManager.AXIS_X,
                            adjustedMatrix
                    )
            else -> System.arraycopy(rotationMatrix, 0, adjustedMatrix, 0, rotationMatrix.size)
        }

        val orientation = FloatArray(3)
        SensorManager.getOrientation(adjustedMatrix, orientation)
        val azimuth = Math.toDegrees(orientation[0].toDouble()).toFloat()
        val normalizedHeading = normalizeHeading(azimuth)
        val smoothedHeading = smoothHeading(normalizedHeading)

        if (lastHeading.isNaN() || abs(angleDelta(lastHeading, smoothedHeading)) >= 0.5f) {
            lastHeading = smoothedHeading
            eventSink?.success(smoothedHeading.toDouble())
        }
    }

    private fun currentDisplayRotation(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            display?.rotation ?: Surface.ROTATION_0
        } else {
            @Suppress("DEPRECATION") windowManager.defaultDisplay.rotation
        }
    }

    private fun smoothHeading(rawHeading: Float): Float {
        if (lastHeading.isNaN()) {
            return rawHeading
        }
        val delta = angleDelta(lastHeading, rawHeading)
        return normalizeHeading(lastHeading + (delta * 0.18f))
    }

    private fun angleDelta(from: Float, to: Float): Float {
        return (((to - from) + 540f) % 360f) - 180f
    }

    private fun normalizeHeading(value: Float): Float {
        return ((value % 360f) + 360f) % 360f
    }
}
