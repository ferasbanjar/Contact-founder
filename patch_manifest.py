import re, pathlib

p = pathlib.Path('android/app/src/main/AndroidManifest.xml')
s = p.read_text(encoding='utf-8')

extra = '''    <uses-permission android:name="android.permission.READ_CONTACTS"/>
    <queries>
        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="tel"/></intent>
        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="sms"/></intent>
        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent>
    </queries>
    <application'''

s = s.replace('<application', extra, 1)
s = re.sub(r'android:label="[^"]*"', 'android:label="دليلي"', s, count=1)
p.write_text(s, encoding='utf-8')
print(s)
