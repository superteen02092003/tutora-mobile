package vn.tutora.tutora_mb

import android.app.Application
import com.zing.zalo.zalosdk.oauth.ZaloSDKApplication

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // Bắt buộc với Zalo SDK: khởi tạo trước khi gọi đăng nhập.
        ZaloSDKApplication.wrap(this)
    }
}
