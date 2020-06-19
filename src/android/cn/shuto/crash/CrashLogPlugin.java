package cn.shuto.crash;


import android.Manifest;

import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PermissionHelper;

/**
 * 应用崩溃日志文件插件
 */
public class CrashLogPlugin extends CordovaPlugin {

    protected final static String[] permissions = {Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE};
    private static final int CODE = 1;

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        CrashHandler crashHandler = CrashHandler.getInstance();
//    crashHandler.init(cordova.getContext()); // 老版本里没有这个方法
        crashHandler.init(cordova.getActivity().getApplicationContext());

        boolean readPermission = PermissionHelper.hasPermission(this, Manifest.permission.READ_EXTERNAL_STORAGE);
        boolean writePermission = PermissionHelper.hasPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE);
        if (!readPermission || !writePermission) {
            PermissionHelper.requestPermissions(this, CODE, permissions);
        }
    }

}
