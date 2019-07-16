package me.yohom.amapbase.map

import android.graphics.BitmapFactory
import android.content.Context
import com.amap.api.maps.model.BitmapDescriptor
import com.amap.api.maps.model.BitmapDescriptorFactory
import me.yohom.amapbase.AMapBasePlugin.Companion.registrar
import android.util.DisplayMetrics
import android.view.WindowManager
import android.graphics.*

object UnifiedAssets {
    private val assetManager = registrar.context().assets

    /**
     * 获取宿主app的图片
     */
    fun getBitmapDescriptor(asset: String): BitmapDescriptor {
        val assetFileDescriptor = assetManager.openFd(registrar.lookupKeyForAsset(asset))
        return BitmapDescriptorFactory.fromBitmap(BitmapFactory.decodeStream(assetFileDescriptor.createInputStream()))
    }

    /**
     * 获取plugin自带的图片
     */
    fun getDefaultBitmapDescriptor(asset: String): BitmapDescriptor {
        return BitmapDescriptorFactory.fromAsset(registrar.lookupKeyForAsset(asset, "amap_base"))
    }


    fun getMamBitmapDescriptor(type: Int): BitmapDescriptor {

        val wm = registrar.context().getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val dm = DisplayMetrics()
        wm.defaultDisplay.getMetrics(dm)

        val options = BitmapFactory.Options()
        options.inTargetDensity = dm.densityDpi
        options.inDensity = 320
        val bgBitmap = getBitmap("images/mam_pin_bg.png", null, options)
        val iconBitmap = getBitmap("images/mam_pin_in_$type.png", null, options)

        val space = 2
        val bitmap = Bitmap.createBitmap(bgBitmap.width + space, bgBitmap.height + space, bgBitmap.config)
        val canvas = Canvas(bitmap)
        canvas.drawBitmap(bgBitmap, 1f, 1f, null)
        val left = (bitmap.width - iconBitmap.width) / 2f
        canvas.drawBitmap(iconBitmap, left, left, null)

        return BitmapDescriptorFactory.fromBitmap(bitmap)
    }

    fun getBitmap(asset: String, rect: Rect? = null, options: BitmapFactory.Options? = null): Bitmap {
        val assetFileDescriptor = assetManager.openFd(registrar.lookupKeyForAsset(asset, "amap_base"))
        return BitmapFactory.decodeStream(assetFileDescriptor.createInputStream(), rect, options)
    }
}