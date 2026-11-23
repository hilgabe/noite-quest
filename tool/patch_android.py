"""Ajusta a pasta android/ gerada pelo `flutter create` para os alarmes do app.

- nome do app "Noite Quest"
- permissões de notificação, alarme exato e reinício do celular
- receivers do flutter_local_notifications
- desugaring de Java (exigido pelo flutter_local_notifications)
"""
import pathlib
import re

root = pathlib.Path(__file__).resolve().parent.parent / "android"

manifest = root / "app/src/main/AndroidManifest.xml"
m = manifest.read_text(encoding="utf8")
m = re.sub(r'android:label="[^"]*"', 'android:label="Noite Quest"', m, count=1)
perms = """
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
    <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" android:maxSdkVersion="32"/>
"""
if "POST_NOTIFICATIONS" not in m:
    m = re.sub(r"(<manifest[^>]*>)", r"\1" + perms, m, count=1)
receivers = """
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
"""
if "ScheduledNotificationReceiver" not in m:
    m = m.replace("</application>", receivers + "    </application>", 1)
# a activity precisa aparecer sobre a tela de bloqueio no despertador
if "showWhenLocked" not in m:
    m = m.replace('android:name=".MainActivity"', 'android:name=".MainActivity"\n            android:showWhenLocked="true"\n            android:turnScreenOn="true"', 1)
manifest.write_text(m, encoding="utf8")

kts = root / "app/build.gradle.kts"
groovy = root / "app/build.gradle"
if kts.exists():
    g = kts.read_text(encoding="utf8")
    if "isCoreLibraryDesugaringEnabled" not in g:
        g = g.replace("compileOptions {", "compileOptions {\n        isCoreLibraryDesugaringEnabled = true", 1)
    g = re.sub(r"minSdk = flutter\.minSdkVersion", "minSdk = 23", g)
    if "desugar_jdk_libs" not in g:
        g += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")\n}\n'
    kts.write_text(g, encoding="utf8")
else:
    g = groovy.read_text(encoding="utf8")
    if "coreLibraryDesugaringEnabled" not in g:
        g = g.replace("compileOptions {", "compileOptions {\n        coreLibraryDesugaringEnabled true", 1)
    g = re.sub(r"minSdk\s*=\s*flutter\.minSdkVersion", "minSdk = 23", g)
    g = re.sub(r"minSdkVersion\s+flutter\.minSdkVersion", "minSdkVersion 23", g)
    if "desugar_jdk_libs" not in g:
        g += "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:1.2.2'\n}\n"
    groovy.write_text(g, encoding="utf8")

print("android/ ajustado:", manifest)
