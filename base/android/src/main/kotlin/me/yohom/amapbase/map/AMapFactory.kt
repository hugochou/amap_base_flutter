package me.yohom.amapbase.map

import android.annotation.SuppressLint
import android.app.Activity
import android.app.Application
import android.content.Context
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.widget.ImageView
import android.widget.TextView
import com.amap.api.maps.AMap
import com.amap.api.maps.AMapOptions
import com.amap.api.maps.TextureMapView
import com.amap.api.maps.model.CameraPosition
import com.amap.api.maps.model.Marker
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import me.yohom.amapbase.*
import me.yohom.amapbase.AMapBasePlugin.Companion.registrar
import me.yohom.amapbase.common.parseFieldJson
import me.yohom.amapbase.common.toFieldJson
import java.util.concurrent.atomic.AtomicInteger

const val mapChannelName = "me.yohom/map"
const val markerClickedChannelName = "me.yohom/marker_clicked"
const val markerDeselectChannelName = "me.yohom/marker_deselect"
const val cameraChangeChannelName = "me.yohom/camera_change"
const val cameraChangeFinishedChannelName = "me.yohom/camera_change_finished"
const val success = "调用成功"

class AMapFactory(private val activityState: AtomicInteger)
    : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, id: Int, params: Any?): PlatformView {
        val view = AMapView(
                context,
                id,
                activityState,
                (params as String).parseFieldJson<UnifiedAMapOptions>().toAMapOption()
        )
        view.setup()
        return view
    }
}

@SuppressLint("CheckResult")
class AMapView(context: Context,
               private val id: Int,
               private val activityState: AtomicInteger,
               amapOptions: AMapOptions) : PlatformView, Application.ActivityLifecycleCallbacks, AMap.InfoWindowAdapter, AMap.OnCameraChangeListener {

    private val context = context
    private val mapView = TextureMapView(context, amapOptions)
    private var disposed = false
    private val registrarActivityHashCode: Int = AMapBasePlugin.registrar.activity().hashCode()

    // add by Chris
    private var selectedMarker: Marker? = null
    private var centerMarker: Marker? = null
    private var cameraChangeSink: EventChannel.EventSink? = null
    private var cameraChangeFinishedSink: EventChannel.EventSink? = null

    override fun getView(): View = mapView

    override fun dispose() {
        if (disposed) {
            return
        }
        disposed = true
        if (selectedMarker != null) selectedMarker!!.destroy()
        mapView.onDestroy()

        registrar.activity().application.unregisterActivityLifecycleCallbacks(this)
    }

    fun setup() {
        when (activityState.get()) {
            STOPPED -> {
                mapView.onCreate(null)
                mapView.onResume()
                mapView.onPause()
            }
            RESUMED -> {
                mapView.onCreate(null)
                mapView.onResume()
            }
            CREATED -> mapView.onCreate(null)
            DESTROYED -> {
            }
            else -> throw IllegalArgumentException("Cannot interpret " + activityState.get() + " as an activity activityState")
        }

        // 地图相关method channel
        val mapChannel = MethodChannel(registrar.messenger(), "$mapChannelName$id")
        mapChannel.setMethodCallHandler { call, result ->
            if (call.method == "map#setCenterMarkerId") {
                val markerId = call.argument<String>("markerId") ?: ""
                centerMarker = mapView.map.mapScreenMarkers.filter { it.id == markerId }.first()
            } else if (call.method == "map#hideInfoWindow") {
                if (selectedMarker != null) {
                    selectedMarker!!.hideInfoWindow()
                    selectedMarker = null
                }
            } else {
                MAP_METHOD_HANDLER[call.method]
                        ?.with(mapView.map)
                        ?.onMethodCall(call, result) ?: result.notImplemented()
            }
        }

        // marker click event channel
        var eventSink: EventChannel.EventSink? = null
        val markerClickedEventChannel = EventChannel(registrar.messenger(), "$markerClickedChannelName$id")
        markerClickedEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(p0: Any?, sink: EventChannel.EventSink?) {
                eventSink = sink
            }

            override fun onCancel(p0: Any?) {}
        })
        mapView.map.setOnMarkerClickListener {
            if (selectedMarker != null) {
                val icon = selectedMarker?.options?.icon
                if (icon != null) {
                    selectedMarker?.setIcon(icon)
                }
            }
            selectedMarker = it
            val obj = it.`object`
            if (obj != null && obj is Map<*, *> && obj["selectedIcon"] != null) {
                var selectedIcon = obj["selectedIcon"] as String
                it.setIcon(UnifiedAssets.getBitmapDescriptor(selectedIcon))
            }
            it.showInfoWindow()
            eventSink?.success(UnifiedMarkerOptions(it).toFieldJson())
            true
        }


        // marker deselect event channel (add by Chris)
        var deselectSink: EventChannel.EventSink? = null
        val markerDeselectEventChannel = EventChannel(registrar.messenger(), "$markerDeselectChannelName$id")
        markerDeselectEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(p0: Any?, sink: EventChannel.EventSink?) {
                deselectSink = sink
            }

            override fun onCancel(p0: Any?) {}
        })
        mapView.map.setOnMapClickListener {
            if (selectedMarker != null) {
                val icon = selectedMarker?.options?.icon
                if (icon != null) {
                    selectedMarker?.setIcon(icon)
                }
                deselectSink?.success(UnifiedMarkerOptions(selectedMarker!!).toFieldJson())
            }
            true
        }


        // marker camera change event channel (add by Chris)
        val cameraChangeEventChannel = EventChannel(registrar.messenger(), "$cameraChangeChannelName$id")
        cameraChangeEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(p0: Any?, sink: EventChannel.EventSink?) {
                cameraChangeSink = sink
            }

            override fun onCancel(p0: Any?) {}
        })

        // marker camera change finished event channel (add by Chris)
        val cameraChangeFinishedEventChannel = EventChannel(registrar.messenger(), "$cameraChangeFinishedChannelName$id")
        cameraChangeFinishedEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(p0: Any?, sink: EventChannel.EventSink?) {
                cameraChangeFinishedSink = sink
            }

            override fun onCancel(p0: Any?) {}
        })

        mapView.map.setOnCameraChangeListener(this)

        // info window adapter (add by Chris)
        mapView.map.setInfoWindowAdapter(this)

        // 注册生命周期
        registrar.activity().application.registerActivityLifecycleCallbacks(this)
    }

    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return
        }
        mapView.onCreate(savedInstanceState)
    }

    override fun onActivityStarted(activity: Activity) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return
        }
    }

    override fun onActivityResumed(activity: Activity) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return
        }
        mapView.onResume()
    }

    override fun onActivityPaused(activity: Activity) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return
        }
        mapView.onPause()
    }

    override fun onActivityStopped(activity: Activity) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return
        }
    }

    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle?) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return
        }
        mapView.onSaveInstanceState(outState)
    }

    override fun onActivityDestroyed(activity: Activity) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return
        }
        mapView.onDestroy()
    }

    override fun onCameraChangeFinish(p0: CameraPosition?) {
        cameraChangeFinishedSink?.success(p0?.target?.toFieldJson())
        if (centerMarker != null && p0 != null) {
            centerMarker!!.position = p0!!.target
        }
    }

    override fun onCameraChange(p0: CameraPosition?) {
        cameraChangeSink?.success(p0?.target?.toFieldJson())
        if (centerMarker != null && p0 != null) {
            centerMarker!!.position = p0!!.target
        }
    }

    // implemented InfoWindowAdapter (add by Chris)
    override fun getInfoContents(p0: Marker?): View? {
        return null
    }

    override fun getInfoWindow(p0: Marker?): View? {
        var infoWindow = LayoutInflater.from(context).inflate(R.layout.custom_info_view, null)
        render(p0, infoWindow);
        return infoWindow;
    }

    /**
     * 自定义infowinfow窗口，将自定义的infoWindow和Marker关联起来
     */
    fun render(marker: Marker?, view: View) {
        val title = marker?.title ?: ""
        val textView = view.findViewById<TextView>(R.id.textView)
        textView.setText(title)

        var type: Int = 0
        var map: Map<*, *>
        if (marker != null && marker!!.`object` is Map<*, *>) {
            map = marker!!.`object` as Map<*, *>
            type = (map["type"] as Number).toInt()
        }
        val image = UnifiedAssets.getBitmap("images/mam_pin_in_$type.png")
        val imageView = view.findViewById<ImageView>(R.id.imageView)
        imageView.setImageBitmap(image)
    }
}