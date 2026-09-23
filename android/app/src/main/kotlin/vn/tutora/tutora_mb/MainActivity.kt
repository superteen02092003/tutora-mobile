package vn.tutora.tutora_mb

import android.annotation.SuppressLint
import android.content.Intent
import android.content.pm.PackageManager
import android.util.Base64
import com.zing.zalo.zalosdk.oauth.LoginVia
import com.zing.zalo.zalosdk.oauth.OAuthCompleteListener
import com.zing.zalo.zalosdk.oauth.OauthResponse
import com.zing.zalo.zalosdk.oauth.ZaloOpenAPICallback
import com.zing.zalo.zalosdk.oauth.ZaloSDK
import com.zing.zalo.zalosdk.oauth.model.ErrorResponse
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.security.MessageDigest

/**
 * Cầu nối Zalo SDK v4 cho Flutter (kênh "vn.tutora/zalo_auth").
 *
 * Tự viết thay vì dùng package zalo_flutter: package đó không còn build được với
 * Android Gradle Plugin 8 (thiếu namespace, còn dùng jcenter).
 *
 *  - login(codeChallenge, codeVerifier): mở app Zalo (hoặc trình duyệt nếu chưa cài),
 *    lấy oauth code rồi đổi ra access token ngay trên máy (PKCE, không cần secret).
 *    Trả { isSuccess, data: { access_token, ... } } hoặc { isSuccess: false, error: {...} }.
 *  - getHashKey: key hash của chữ ký app — phải khai báo trên Zalo Developers.
 *  - logout: xoá phiên Zalo SDK đã lưu.
 */
class MainActivity : FlutterActivity() {
    private val zalo get() = ZaloSDK.Instance

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "vn.tutora/zalo_auth")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "login" -> {
                        val challenge = call.argument<String>("codeChallenge")
                        val verifier = call.argument<String>("codeVerifier")
                        if (challenge == null || verifier == null) {
                            result.error("bad_args", "Thiếu codeChallenge/codeVerifier", null)
                        } else {
                            val via = if (call.argument<String>("via") == "web") LoginVia.WEB else LoginVia.APP_OR_WEB
                            login(challenge, verifier, via, result)
                        }
                    }
                    "getHashKey" -> result.success(hashKey())
                    "logout" -> {
                        zalo.unauthenticate()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun login(codeChallenge: String, codeVerifier: String, via: LoginVia, result: MethodChannel.Result) {
        var replied = false
        fun reply(map: Map<String, Any?>) {
            if (replied) return
            replied = true
            runOnUiThread { result.success(map) }
        }

        val listener = object : OAuthCompleteListener() {
            override fun onGetOAuthComplete(response: OauthResponse) {
                zalo.getAccessTokenByOAuthCode(
                    this@MainActivity,
                    response.oauthCode,
                    codeVerifier,
                    ZaloOpenAPICallback { json: JSONObject? -> reply(tokenResult(json)) },
                )
            }

            override fun onAuthenError(errorResponse: ErrorResponse?) {
                reply(
                    mapOf(
                        "isSuccess" to false,
                        "error" to mapOf(
                            "errorCode" to errorResponse?.errorCode,
                            "errorMessage" to errorResponse?.errorMsg,
                            "errorReason" to errorResponse?.errorReason,
                        ),
                    ),
                )
            }
        }

        try {
            zalo.authenticateZaloWithAuthenType(this, via, codeChallenge, JSONObject(), listener)
        } catch (e: Exception) {
            reply(mapOf("isSuccess" to false, "error" to mapOf("errorCode" to -9997, "errorMessage" to e.message)))
        }
    }

    private fun tokenResult(json: JSONObject?): Map<String, Any?> {
        if (json == null) {
            return mapOf("isSuccess" to false, "error" to mapOf("errorCode" to -9999, "errorMessage" to "Zalo không phản hồi"))
        }
        val error = json.optInt("error", 0)
        if (error != 0) {
            return mapOf(
                "isSuccess" to false,
                "error" to mapOf("errorCode" to error, "errorMessage" to json.optString("message")),
            )
        }
        return mapOf(
            "isSuccess" to true,
            "data" to mapOf(
                "access_token" to json.optString("access_token"),
                "refresh_token" to json.optString("refresh_token"),
            ),
        )
    }

    @Suppress("DEPRECATION")
    @SuppressLint("PackageManagerGetSignatures")
    private fun hashKey(): String? = try {
        val info = packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
        info.signatures?.firstOrNull()?.let { sig ->
            val md = MessageDigest.getInstance("SHA")
            md.update(sig.toByteArray())
            Base64.encodeToString(md.digest(), Base64.NO_WRAP)
        }
    } catch (e: Exception) {
        null
    }

    // Zalo SDK trả kết quả đăng nhập (khi mở app Zalo) qua onActivityResult.
    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        ZaloSDK.Instance.onActivityResult(this, requestCode, resultCode, data)
    }
}
