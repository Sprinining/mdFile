---
title: framework
date: 2022-06-22 07:14:09 +0800
categories: [android, framework]
tags: [Android, Framework]
description: 
---
## SettingsApp管控

### 一级菜单管控

- OPTION_1("OPTION_1"), ---电池
  OPTION_2("OPTION_2"), ---连接的设备
  OPTION_3("OPTION_3"), ---网络
  OPTION_4("OPTION_4"), ---搜索栏
  OPTION_5("OPTION_5"), ---显示
  OPTION_6("OPTION_6"), ---声音
  OPTION_7("OPTION_7"), ---应用和通知
  OPTION_8("OPTION_8"), ---账户
  OPTION_13("OPTION_9"),  ---系统
  OPTION_10("OPTION_10"), --存储
  OPTION_11("OPTION_11"), ---无障碍
  OPTION_12("OPTION_12"), ---安全
- int类型，0隐藏，1显示

```java
diff --git a/vendor/mediatek/proprietary/packages/apps/MtkSettings/src/com/android/settings/SettingsActivity.java b/vendor/mediatek/proprietary/packages/apps/MtkSettings/src/com/android/settings/SettingsActivity.java
old mode 100755
new mode 100644
index 2aecb3a0a6..ba4e9d8daa
--- a/vendor/mediatek/proprietary/packages/apps/MtkSettings/src/com/android/settings/SettingsActivity.java
+++ b/vendor/mediatek/proprietary/packages/apps/MtkSettings/src/com/android/settings/SettingsActivity.java
@@ -527,6 +527,10 @@ public class SettingsActivity extends SettingsDrawerActivity
 
         updateTilesList();
         updateDeviceIndex();
+
+        boolean isSearchBarVisible = android.provider.Settings.Secure.getInt(getContentResolver(), android.provider.Settings.Secure.OPTION_4, 1) == 1;
+        View searchBar = findViewById(R.id.search_bar_container);
+        if(searchBar != null) searchBar.setVisibility(isSearchBarVisible ? View.VISIBLE : View.GONE);
     }
 
     @Override
diff --git a/vendor/mediatek/proprietary/packages/apps/MtkSettings/src/com/android/settings/dashboard/DashboardSummary.java b/vendor/mediatek/proprietary/packages/apps/MtkSettings/src/com/android/settings/dashboard/DashboardSummary.java
old mode 100755
new mode 100644
index 78e90512bd..653d9f1994
--- a/vendor/mediatek/proprietary/packages/apps/MtkSettings/src/com/android/settings/dashboard/DashboardSummary.java
+++ b/vendor/mediatek/proprietary/packages/apps/MtkSettings/src/com/android/settings/dashboard/DashboardSummary.java
@@ -62,6 +66,7 @@ public class DashboardSummary extends InstrumentedFragment
 
     private static final String STATE_SCROLL_POSITION = "scroll_position";
     private static final String STATE_CATEGORIES_CHANGE_CALLED = "categories_change_called";
+    private ContentResolver contentResolver;
 
     private final Handler mHandler = new Handler();
 
@@ -131,6 +136,8 @@ public class DashboardSummary extends InstrumentedFragment
+
+        contentResolver = getContext().getContentResolver();
     }
 
     @Override
@@ -285,10 +292,53 @@ public class DashboardSummary extends InstrumentedFragment
         }
     }
 
+    private boolean isTileEnable(String className){
+        if(className == null || "".equals(className))
+            return true;
+        switch(className){
+            case "com.android.settings.Settings$NetworkDashboardActivity":
+                return Settings.Secure.getInt(contentResolver, Settings.Secure.OPTION_3, 1) == 1;
+            case "com.android.settings.Settings$ConnectedDeviceDashboardActivity":
+                return Settings.Secure.getInt(contentResolver, Settings.Secure.OPTION_2, 1) == 1;
+            case "com.android.settings.Settings$AppAndNotificationDashboardActivity":
+                return Settings.Secure.getInt(contentResolver, Settings.Secure.OPTION_7, 1) == 1;
+            case "com.android.settings.Settings$PowerUsageSummaryActivity":
+                return Settings.Secure.getInt(contentResolver, Settings.Secure.OPTION_1, 1) == 1;
+            case "com.android.settings.Settings$DisplaySettingsActivity":
+                return Settings.Secure.getInt(contentResolver, Settings.Secure.OPTION_5, 1) == 1;
+            case "com.android.settings.Settings$SoundSettingsActivity":
+                return Settings.Secure.getInt(contentResolver, Settings.Secure.OPTION_6, 1) == 1;
+            case "com.android.settings.Settings$StorageDashboardActivity":
+                return Settings.Secure.getInt(contentResolver, Settings.Secure.OPTION_10, 1) == 1;
+            case "com.android.settings.Settings$SecurityDashboardActivity":
+                return Settings.Secure.getInt(contentResolver, Settings.Secure.OPTION_12, 1) == 1;
+            case "com.android.settings.Settings$AccountDashboardActivity":
+                return Settings.Secure.getInt(contentResolver, Settings.Secure.OPTION_8, 1) == 1;
+            case "com.android.settings.Settings$AccessibilitySettingsActivity":
+                return Settings.Secure.getInt(contentResolver, Settings.Secure.OPTION_11, 1) == 1;
+            case "com.android.settings.Settings$SystemDashboardActivity":
+                return Settings.Secure.getInt(contentResolver, Settings.Secure.OPTION_9, 1) == 1;
+        }
+        return true;
+    }
+
+    private void filterDashboardCategory(DashboardCategory category){
+        if(category == null || category.getTiles() == null)
+            return;
+        List<Tile> tiles = category.getTiles();
+        for (Tile tile : tiles) {
+            Intent intent = tile.intent;
+            if(!isTileEnable(intent.getComponent().getClassName())){
+                category.removeTile(tile);
+            }
+        }
+    }
+
     @WorkerThread
     void updateCategory() {
         final DashboardCategory category = mDashboardFeatureProvider.getTilesForCategory(
                 CategoryKey.CATEGORY_HOMEPAGE);
+        filterDashboardCategory(category);
         mSummaryLoader.updateSummaryToCache(category);
         mStagingCategory = category;
         if (mSuggestionControllerMixin == null) {
```

### 二级菜单管控

- OPTION_13("OPTION_13")  -- WIFI外的其他菜单
  OPTION_14("OPTION_14")  --除关于/开发者选项/重置选项外的其他菜单项
  OPTION_15("OPTION_15")  -- 开发者选项
  OPTION_16("OPTION_16")  -- 重置选项
- 0隐藏，1显示

```java
diff --git a/vendor/mediatek/proprietary/packages/apps/MtkSettings/src/com/android/settings/dashboard/DashboardFragment.java b/vendor/mediatek/proprietary/packages/apps/MtkSettings/src/com/android/settings/dashboard/DashboardFragment.java
old mode 100755
new mode 100644
index 0adf5d1433..dd5925aea3
--- a/vendor/mediatek/proprietary/packages/apps/MtkSettings/src/com/android/settings/dashboard/DashboardFragment.java
+++ b/vendor/mediatek/proprietary/packages/apps/MtkSettings/src/com/android/settings/dashboard/DashboardFragment.java
@@ -427,6 +428,10 @@ public abstract class DashboardFragment extends SettingsPreferenceFragment
                 screen.addPreference(pref);
                 mDashboardTilePrefKeys.add(key);
             }
+            final Preference preference = screen.findPreference(key);
+            if (preference != null) {
+                preference.setVisible(isOtherOptionsEnable(key));
+            }
             remove.remove(key);
         }
         // Finally remove tiles that are gone.
@@ -439,4 +444,20 @@ public abstract class DashboardFragment extends SettingsPreferenceFragment
         }
         mSummaryLoader.setListening(true);
     }
+
+    private boolean isOtherOptionsEnable(String key){
+        switch(key){
+            case "dashboard_tile_pref_com.android.settings.Settings$DataUsageSummaryActivity":
+            case "dashboard_tile_pref_com.android.settings.Settings$SimSettingsActivity":
+                return Settings.Secure.getInt(getContext().getContentResolver(), Settings.Secure.OPTION_13, 1) == 1;
+            case "dashboard_tile_pref_com.android.settings.Settings$LanguageAndInputSettingsActivity":
+            case "dashboard_tile_pref_com.android.settings.Settings$DateTimeSettingsActivity":
+            case "dashboard_tile_pref_com.android.settings.Settings$UserSettingsActivity":
+                return Settings.Secure.getInt(getContext().getContentResolver(), Settings.Secure.OPTION_14, 1) == 1;
+            case "dashboard_tile_pref_com.android.settings.Settings$DevelopmentSettingsDashboardActivity":
+                return Settings.Secure.getInt(getContext().getContentResolver(), Settings.Secure.OPTION_15, 1) == 1;
+            default:
+        }
+        return true;
+    }
 }
diff --git a/vendor/mediatek/proprietary/packages/apps/MtkSettings/src/com/android/settings/network/NetworkDashboardFragment.java b/vendor/mediatek/proprietary/packages/apps/MtkSettings/src/com/android/settings/network/NetworkDashboardFragment.java
old mode 100755
new mode 100644
index 80320e422e..53d87c02d6
--- a/vendor/mediatek/proprietary/packages/apps/MtkSettings/src/com/android/settings/network/NetworkDashboardFragment.java
+++ b/vendor/mediatek/proprietary/packages/apps/MtkSettings/src/com/android/settings/network/NetworkDashboardFragment.java
@@ -91,6 +94,53 @@ public class NetworkDashboardFragment extends DashboardFragment implements
     }
     /// @}
 
+    @Override
+    public void onResume() {
+        super.onResume();
+        showOtherOptionsEnable();
+    }
+
+    private void showOtherOptionsEnable(){
+        boolean enable = Settings.Secure.getInt(getContext().getContentResolver(), Settings.Secure.OPTION_13, 1) == 1;
+        PreferenceScreen preferenceScreen = getPreferenceScreen();
+        Preference pref = preferenceScreen.findPreference("mobile_network_settings");
+        if (pref != null) pref.setVisible(enable);
+        pref = preferenceScreen.findPreference("ethernet_settings");
+        if (pref != null) pref.setVisible(enable);
+        pref = preferenceScreen.findPreference("tether_settings");
+        if (pref != null) pref.setVisible(enable);
+        pref = preferenceScreen.findPreference("manage_mobile_plan");
+        if (pref != null) pref.setVisible(enable);
+        pref = preferenceScreen.findPreference("airplane_mode");
+        if (pref != null) pref.setVisible(enable);
+        pref = preferenceScreen.findPreference("proxy_settings");
+        if (pref != null) pref.setVisible(enable);
+        pref = preferenceScreen.findPreference("vpn_settings");
+        if (pref != null) pref.setVisible(enable);
+        pref = preferenceScreen.findPreference("rcse_settings");
+        if (pref != null) pref.setVisible(enable);
+        pref = preferenceScreen.findPreference("private_dns_settings");
+        if (pref != null) pref.setVisible(enable);
+    }
+
     @Override
     public int getHelpResource() {
         return R.string.help_url_network_dashboard;
diff --git a/vendor/mediatek/proprietary/packages/apps/MtkSettings/src/com/android/settings/system/SystemDashboardFragment.java b/vendor/mediatek/proprietary/packages/apps/MtkSettings/src/com/android/settings/system/SystemDashboardFragment.java
old mode 100755
new mode 100644
index 8334143739..704f52fc62
--- a/vendor/mediatek/proprietary/packages/apps/MtkSettings/src/com/android/settings/system/SystemDashboardFragment.java
+++ b/vendor/mediatek/proprietary/packages/apps/MtkSettings/src/com/android/settings/system/SystemDashboardFragment.java
@@ -61,6 +62,39 @@ public class SystemDashboardFragment extends DashboardFragment {
 
+     @Override
+    public void onResume() {
+        super.onResume();
+        showOtherOptionsEnable();
+    }
+
+    private void showOtherOptionsEnable(){
+        boolean enable = Settings.Secure.getInt(getContext().getContentResolver(), Settings.Secure.OPTION_14, 1) == 1;
+        PreferenceScreen preferenceScreen = getPreferenceScreen();
+        Preference pref = preferenceScreen.findPreference("gesture_settings");
+        if (pref != null) pref.setVisible(enable);
+        pref = preferenceScreen.findPreference("backup_settings");
+        if (pref != null) pref.setVisible(enable);
+        pref = preferenceScreen.findPreference("system_update_settings");
+        if (pref != null) pref.setVisible(enable);
+        pref = preferenceScreen.findPreference("additional_system_update_settings");
+        if (pref != null) pref.setVisible(enable);
+        
+        enable = Settings.Secure.getInt(getContext().getContentResolver(), Settings.Secure.OPTION_16, 1) == 1;
+        pref = preferenceScreen.findPreference("reset_dashboard");
+        if (pref != null) pref.setVisible(enable);
+    }
+
     @Override
     public int getMetricsCategory() {
         return MetricsProto.MetricsEvent.SETTINGS_SYSTEM_CATEGORY;
```

## 安装管控

- string类型：Settings.Secure.OPTION_LEVEL ="xxxx"
- S0不管控，S1管控。
- 管控后，只有用户指定包名的AppStore才能安装带有指定flag的应用，并且不能adb安装，也不能静默安装

```java
diff --git a/frameworks/base/services/core/java/com/android/server/pm/PackageManagerService.java b/frameworks/base/services/core/java/com/android/server/pm/PackageManagerService.java
old mode 100755
new mode 100644
index 09dbd35c67..51cc48154b
--- a/frameworks/base/services/core/java/com/android/server/pm/PackageManagerService.java
+++ b/frameworks/base/services/core/java/com/android/server/pm/PackageManagerService.java
@@ -21629,6 +21630,16 @@ Slog.v(TAG, ":: stepped forward, applying functor at tag " + parser.getName());
     public void onShellCommand(FileDescriptor in, FileDescriptor out,
             FileDescriptor err, String[] args, ShellCallback callback,
             ResultReceiver resultReceiver) {
+
+        if(args != null && args.length > 0 && "install".equals(args[0])){
+            String level = Secure.getString(mContext.getContentResolver(), Secure.OPTION_LEVEL);
+            if (level != null && ("S1".equals(level))) {
+                if(resultReceiver != null)
+                    resultReceiver.send(1, null);
+                return;
+            }
+        }
+
         (new PackageManagerShellCommand(this)).exec(
                 this, in, out, err, args, callback, resultReceiver);
     }
diff --git a/vendor/mediatek/proprietary/packages/apps/PackageInstaller/src/com/android/packageinstaller/PackageInstallerActivity.java b/vendor/mediatek/proprietary/packages/apps/PackageInstaller/src/com/android/packageinstaller/PackageInstallerActivity.java
old mode 100755
new mode 100644
index ba608dbfe5..aaa35ec07e
--- a/vendor/mediatek/proprietary/packages/apps/PackageInstaller/src/com/android/packageinstaller/PackageInstallerActivity.java
+++ b/vendor/mediatek/proprietary/packages/apps/PackageInstaller/src/com/android/packageinstaller/PackageInstallerActivity.java
@@ -554,6 +554,23 @@ public class PackageInstallerActivity extends OverlayTouchActivity implements On
      * show the appropriate dialog.
      */
     private void checkIfAllowedAndInitiateInstall() {
+        String level = Settings.Secure.getString(getContentResolver(), Settings.Secure.OPTION_LEVEL);
+        if (level != null) {
+            if("S1".equals(level)){
+                boolean allow = getIntent().getBooleanExtra("allow", false);
+                String packageNameOfInstaller = getIntent().getComponent().getPackageName();
+                if(packageNameOfInstaller == null || !"appstore".equals(packageNameOfInstaller) || !allow){
+                    setResult(RESULT_CANCELED);
+                    if (mSessionId != -1) {
+                        mInstaller.setPermissionsResult(mSessionId, false);
+                    }
+                    finish();
+                    return;
+                }
+            }
+        }
+
          boolean ignoreUnknownSourcesSettings = false;
         // Check for install apps user restriction first.
```

## app详情管控

- string类型：Settings.Secure.OPTION_LEVEL ="xxxx"
- S0,S1。S0不管控，S1管控禁止进入app详情（包括长按图标的方式和从设置-应用和通知进入的方式）

```java
diff --git a/vendor/mediatek/proprietary/packages/apps/MtkSettings/src/com/android/settings/applications/appinfo/AppInfoDashboardFragment.java b/vendor/mediatek/proprietary/packages/apps/MtkSettings/src/com/android/settings/applications/appinfo/AppInfoDashboardFragment.java
old mode 100755
new mode 100644
index ce3c07629c..93b5b261eb
--- a/vendor/mediatek/proprietary/packages/apps/MtkSettings/src/com/android/settings/applications/appinfo/AppInfoDashboardFragment.java
+++ b/vendor/mediatek/proprietary/packages/apps/MtkSettings/src/com/android/settings/applications/appinfo/AppInfoDashboardFragment.java
@@ -204,6 +205,12 @@ public class AppInfoDashboardFragment extends DashboardFragment
     @Override
     public void onCreate(Bundle icicle) {
         super.onCreate(icicle);
+        String level = Settings.Secure.getString(getActivity().getApplicationContext().getContentResolver(), Settings.Secure.OPTION_LEVEL);
+        if (level != null) {
+            if("S1".equals(level)){
+                getActivity().finish();
+            }
+        }
         mFinishing = false;
         final Activity activity = getActivity();
```



## SystemUI管控

### 截屏管控

- int类型：Settings.Secure.OPTION_17= "OPTION_17"
- 0不管控，1管控。管控后，禁止截屏操作

```java
diff --git a/vendor/mediatek/proprietary/packages/apps/SystemUI/src/com/android/systemui/screenshot/TakeScreenshotService.java b/vendor/mediatek/proprietary/packages/apps/SystemUI/src/com/android/systemui/screenshot/TakeScreenshotService.java
index 34b8bfe59e..b5a7df003c 100644
--- a/vendor/mediatek/proprietary/packages/apps/SystemUI/src/com/android/systemui/screenshot/TakeScreenshotService.java
+++ b/vendor/mediatek/proprietary/packages/apps/SystemUI/src/com/android/systemui/screenshot/TakeScreenshotService.java
@@ -46,6 +47,11 @@ public class TakeScreenshotService extends Service {
                     }
                 }
             };
+            
+            if(Settings.Secure.getInt(getContentResolver(), Settings.Secure.OPTION_17, 1) == 1){
+                post(finisher);
+                return;
+            }
 
             // If the storage for this user is locked, we have no place to store
             // the screenshot, so skip taking it instead of showing a misleading

```

### 快捷设置管控

- string类型：Settings.Secure.OPTION_LEVEL ="xxxx"
- S0,S1。S0不管控，S1管控，隐藏部分快捷设置入口并隐藏快捷设置编辑入口

```java
diff --git a/vendor/mediatek/proprietary/packages/apps/SystemUI/src/com/android/systemui/qs/QSFooterImpl.java b/vendor/mediatek/proprietary/packages/apps/SystemUI/src/com/android/systemui/qs/QSFooterImpl.java
index c9ad2f3323..e96c637ad9 100644
--- a/vendor/mediatek/proprietary/packages/apps/SystemUI/src/com/android/systemui/qs/QSFooterImpl.java
+++ b/vendor/mediatek/proprietary/packages/apps/SystemUI/src/com/android/systemui/qs/QSFooterImpl.java
@@ -323,6 +324,15 @@ public class QSFooterImpl extends FrameLayout implements QSFooter,
             mSettingsButton.setVisibility(View.INVISIBLE);
         }
+
+        String level = Settings.Secure.getString(mContext.getContentResolver(), Settings.Secure.OPTION_LEVEL);
+        if (level != null) {
+            if("S1".equals(level)){
+                mEdit.setVisibility(View.GONE);
+            }else{
+                mEdit.setVisibility(View.VISIBLE);
+            }
+        }
     }
 
     private boolean showUserSwitcher(boolean isDemo) {
diff --git a/vendor/mediatek/proprietary/packages/apps/SystemUI/src/com/android/systemui/qs/QSPanel.java b/vendor/mediatek/proprietary/packages/apps/SystemUI/src/com/android/systemui/qs/QSPanel.java
index d2bf219b59..aab3442960 100644
--- a/vendor/mediatek/proprietary/packages/apps/SystemUI/src/com/android/systemui/qs/QSPanel.java
+++ b/vendor/mediatek/proprietary/packages/apps/SystemUI/src/com/android/systemui/qs/QSPanel.java
@@ -90,6 +95,8 @@ public class QSPanel extends LinearLayout implements Tunable, Callback, Brightne
     private BrightnessMirrorController mBrightnessMirrorController;
     private View mDivider;
 
+    private boolean needReset = false;
+
@@ -394,6 +401,42 @@ public class QSPanel extends LinearLayout implements Tunable, Callback, Brightne
             r.tile.refreshState();
         }
         mFooter.refreshState();
+
+        String level = Settings.Secure.getString(mContext.getContentResolver(), Settings.Secure.OPTION_LEVEL);
+        if (level != null) {
+            if("S1".equals(level)){
+                ArrayList<String> preTiles = new ArrayList<String>();
+                ArrayList<String> newTiles = new ArrayList<String>();
+                for(TileRecord tileRecord : mRecords){
+                    preTiles.add(tileRecord.tile.getTileSpec());
+                }
+                for(String s : preTiles){
+                    if("flashlight".equals(s))
+                        newTiles.add(s);
+                }
+
+                ArrayList<String> tempPre = new ArrayList<String>();
+                ArrayList<String> tempNew = new ArrayList<String>();
+                tempPre.addAll(preTiles);
+                tempNew.addAll(newTiles);
+                Collections.sort(tempPre);
+                Collections.sort(tempNew);
+
+                if(!tempPre.equals(tempNew)){
+                    mHost.changeTiles(preTiles, newTiles);
+                    needReset = true;
+                }
+            }else{
+                if(needReset){
+                    needReset = false;
+                    String defaultTileList = mContext.getResources().getString(R.string.quick_settings_tiles_default);
+                    ArrayList<String> defaultTiles = new ArrayList<String>();
+                    defaultTiles.addAll(Arrays.asList(defaultTileList.split(",")));
+                    mHost.changeTiles(defaultTiles, defaultTiles);
+                }
+            }
+        }
     }
 
     public void showDetailAdapter(boolean show, DetailAdapter adapter, int[] locationInWindow) {
```

## Launcher管控

### 桌面弹框管控

- string类型：Settings.Secure.OPTION_LEVEL ="xxxx"
- S0不管控，S1管控。
- 管控后，隐藏掉长按桌面弹出的框

```java
diff --git a/vendor/mediatek/proprietary/packages/apps/Launcher3/src/com/android/launcher3/views/OptionsPopupView.java b/vendor/mediatek/proprietary/packages/apps/Launcher3/src/com/android/launcher3/views/OptionsPopupView.java
index ed4d196c01..3518fcab60 100644
--- a/vendor/mediatek/proprietary/packages/apps/Launcher3/src/com/android/launcher3/views/OptionsPopupView.java
+++ b/vendor/mediatek/proprietary/packages/apps/Launcher3/src/com/android/launcher3/views/OptionsPopupView.java
@@ -143,6 +144,13 @@ public class OptionsPopupView extends ArrowPopup
         }
         RectF target = new RectF(x - halfSize, y - halfSize, x + halfSize, y + halfSize);
 
+        String level = Settings.Secure.getString(launcher.getContentResolver(), Settings.Secure.OPTION_LEVEL);
+        if (level != null) {
+            if("S1".equals(level)){
+                return;
+            }
+        }
+        
         ArrayList<OptionItem> options = new ArrayList<>();
         options.add(new OptionItem(R.string.wallpaper_button_text, R.drawable.ic_wallpaper,
                 ControlType.WALLPAPER_BUTTON, OptionsPopupView::startWallpaperPicker));
```

### 全局搜索管控

- int类型：Settings.Global.OPTION_SEARCH = "xxx"
- 0隐藏全局搜索框，1显示

```java
diff --git a/vendor/mediatek/proprietary/packages/apps/Launcher3/src/com/android/launcher3/allapps/AllAppsContainerView.java b/vendor/mediatek/proprietary/packages/apps/Launcher3/src/com/android/launcher3/allapps/AllAppsContainerView.java
index f0d5f1738a..51452df06f 100644
--- a/vendor/mediatek/proprietary/packages/apps/Launcher3/src/com/android/launcher3/allapps/AllAppsContainerView.java
+++ b/vendor/mediatek/proprietary/packages/apps/Launcher3/src/com/android/launcher3/allapps/AllAppsContainerView.java
@@ -270,7 +271,16 @@ public class AllAppsContainerView extends SpringRelativeLayout implements DragSo
 		mSearchUiManager.initialize(this);
 		android.util.Log.e("===zss=AllAppsContainerView","onFinishInflate() end mSearchContainer="+mSearchContainer.getVisibility());
 		//add by BIRD@hujingcheng 20181103 end
+        checkSearchContainerVisibility();
+    }
 
+    public void checkSearchContainerVisibility(){
+        View searchContainer = findViewById(R.id.search_container_all_apps);
+        if(searchContainer != null){
+            boolean enable = Settings.Global.getInt(this.getContext().getContentResolver(), Settings.Global.OPTION_SEARCH, 1) == 1;
+            int visible = enable ? View.VISIBLE : View.GONE;
+            searchContainer.setVisibility(visible);
+        }
     }
 
     public SearchUiManager getSearchUiManager() {
diff --git a/vendor/mediatek/proprietary/packages/apps/Launcher3/src/com/android/launcher3/allapps/AllAppsTransitionController.java b/vendor/mediatek/proprietary/packages/apps/Launcher3/src/com/android/launcher3/allapps/AllAppsTransitionController.java
index ccd55863c4..adc083e7cf 100644
--- a/vendor/mediatek/proprietary/packages/apps/Launcher3/src/com/android/launcher3/allapps/AllAppsTransitionController.java
+++ b/vendor/mediatek/proprietary/packages/apps/Launcher3/src/com/android/launcher3/allapps/AllAppsTransitionController.java
@@ -93,6 +94,7 @@ public class AllAppsTransitionController implements StateHandler, OnDeviceProfil
     private void onProgressAnimationStart() {
         // Initialize values that should not change until #onDragEnd
         mAppsView.setVisibility(View.VISIBLE);
+        mAppsView.checkSearchContainerVisibility();
     }
 
     @Override
@@ -195,7 +197,8 @@ public class AllAppsTransitionController implements StateHandler, OnDeviceProfil
         boolean hasHeaderExtra = (visibleElements & ALL_APPS_HEADER_EXTRA) != 0;
         boolean hasContent = (visibleElements & ALL_APPS_CONTENT) != 0;
 
-        setter.setViewAlpha(mAppsView.getSearchView(), hasHeader ? 1 : 0, LINEAR);
+        if(Settings.Global.getInt(mAppsView.getContext().getContentResolver(), Settings.Global.OPTION_SEARCH, 1) == 1)
+            setter.setViewAlpha(mAppsView.getSearchView(), hasHeader ? 1 : 0, LINEAR);
         setter.setViewAlpha(mAppsView.getContentView(), hasContent ? 1 : 0, LINEAR);
         setter.setViewAlpha(mAppsView.getScrollBar(), hasContent ? 1 : 0, LINEAR);
         mAppsView.getFloatingHeaderView().setContentVisibility(hasHeaderExtra, hasContent, setter);

```
