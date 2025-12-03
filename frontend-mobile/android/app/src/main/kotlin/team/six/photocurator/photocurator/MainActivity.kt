package team.six.photocurator.photocurator

import android.os.Bundle
import androidx.core.splashscreen.SplashScreen
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen() // ← 여기서 스플래시 강제 종료를 준비함
            .setKeepOnScreenCondition { false } // ← 즉시 사라지게 함

        super.onCreate(savedInstanceState)
    }
}

