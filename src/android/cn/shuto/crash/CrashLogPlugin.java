package cn.shuto.crash;

import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;

/**
 * 应用崩溃日志文件插件
 */
public class CrashLogPlugin extends CordovaPlugin {

  @Override
  public void initialize(CordovaInterface cordova, CordovaWebView webView) {
    super.initialize(cordova, webView);
    CrashHandler crashHandler = CrashHandler.getInstance();
    crashHandler.init(cordova.getContext());
  }

}
