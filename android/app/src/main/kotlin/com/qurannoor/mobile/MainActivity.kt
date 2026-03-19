package com.qurannoor.mobile

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
                        null,
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

    private fun emitFromRotationVector(rotationVector: FloatArray) {
        val rotationMatrix = FloatArray(9)
        SensorManager.getRotationMatrixFromVector(rotationMatrix, rotationVector)
        val adjustedMatrix = adjustForDisplayRotation(rotationMatrix)
        emitHeadingFromMatrix(adjustedMatrix)
    }

    private fun emitFromFallbackSensors() {
        if (!hasGravity || !hasMagnetic) {
            return
        }

        val rotationMatrix = FloatArray(9)
        val inclinationMatrix = FloatArray(9)
        val success =
            SensorManager.getRotationMatrix(
                rotationMatrix,
                inclinationMatrix,
                gravityValues,
                magneticValues,
            )
        if (!success) {
            return
        }

        val adjustedMatrix = adjustForDisplayRotation(rotationMatrix)
        emitHeadingFromMatrix(adjustedMatrix)
    }

    private fun adjustForDisplayRotation(rotationMatrix: FloatArray): FloatArray {
        val remappedMatrix = FloatArray(9)
        val rotation =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                display?.rotation ?: Surface.ROTATION_0
            } else {
                @Suppress("DEPRECATION")
                windowManager.defaultDisplay.rotation
            }

        val (worldAxisX, worldAxisY) =
            when (rotation) {
                Surface.ROTATION_90 -> SensorManager.AXIS_Y to SensorManager.AXIS_MINUS_X
                Surface.ROTATION_180 ->
                    SensorManager.AXIS_MINUS_X to SensorManager.AXIS_MINUS_Y

                Surface.ROTATION_270 -> SensorManager.AXIS_MINUS_Y to SensorManager.AXIS_X
                else -> SensorManager.AXIS_X to SensorManager.AXIS_Y
            }

        SensorManager.remapCoordinateSystem(
            rotationMatrix,
            worldAxisX,
            worldAxisY,
            remappedMatrix,
        )
        return remappedMatrix
    }

    private fun emitHeadingFromMatrix(rotationMatrix: FloatArray) {
        val orientationValues = FloatArray(3)
        SensorManager.getOrientation(rotationMatrix, orientationValues)
        val azimuthRadians = orientationValues[0]
        val azimuthDegrees =
            ((Math.toDegrees(azimuthRadians.toDouble()) + 360.0) % 360.0).toFloat()
        if (lastHeading.isNaN() || abs(lastHeading - azimuthDegrees) >= 1f) {
            lastHeading = azimuthDegrees
            eventSink?.success(azimuthDegrees.toDouble())
        }
    }
}
