module log;

int LOGI(const(char)* fmt, float x, float y, float z) { return __android_log_print(android_LogPriority.ANDROID_LOG_INFO, "native-activity", fmt, x, y, z); }
int LOGW(const(char)* warning) { return __android_log_print(android_LogPriority.ANDROID_LOG_WARN, "native-activity", warning); }
import android.log;
