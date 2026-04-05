# 📦 คู่มือ Build & อัปโหลด Google Play Console

**แอป**: Skill Wallet Kool  
**Package**: `com.swk.skillwalletkool`  
**Keystore**: `flutter_app/android/app/key/upload-keystore.jks`

---

## ⚡ สรุปสั้น (ทำทุกครั้งที่ release)

```
1. เพิ่ม versionCode ใน pubspec.yaml
2. flutter build appbundle --release
3. อัปโหลด .aab ขึ้น Play Console
```

---

## 📋 ขั้นตอนละเอียด

### ขั้นตอนที่ 1 — อัปเดต Version

เปิดไฟล์ `flutter_app/pubspec.yaml` แก้บรรทัด `version`:

```yaml
version: 1.0.1+5
#        ↑       ↑
#  versionName  versionCode (ต้องเพิ่มทุก upload ไม่ซ้ำกัน)
```

> **กฎ**: `versionCode` (ตัวเลขหลัง +) ต้องมากกว่าครั้งก่อนเสมอ  
> ปัจจุบัน version ล่าสุด = `1.0.0+4` → ครั้งต่อไปใช้ `+5`

---

### ขั้นตอนที่ 2 — Build AAB (App Bundle)

เปิด Terminal แล้วไปที่โฟลเดอร์ flutter_app:

```bash
cd d:/SWK/Skill-Wallet-Kool/flutter_app
```

Build release:

```bash
flutter build appbundle --release
```

> ไฟล์ output อยู่ที่:  
> `flutter_app/build/app/outputs/bundle/release/app-release.aab`

---

### ขั้นตอนที่ 3 — อัปโหลดขึ้น Google Play Console

1. เปิด [Google Play Console](https://play.google.com/console)
2. เลือกแอป **Skill Wallet Kool**
3. ไปที่ **Release > Testing > Internal testing** (หรือ Production)
4. กด **Create new release**
5. อัปโหลดไฟล์ `app-release.aab`
6. กรอก Release notes (ภาษาไทย/อังกฤษ)
7. กด **Save** → **Review release** → **Start rollout**

---

## 🔑 ข้อมูล Keystore (อย่าแชร์สาธารณะ)

| ค่า | ข้อมูล |
|-----|--------|
| Keystore file | `android/app/key/upload-keystore.jks` |
| Key alias | `upload` |
| storePassword | ดูใน `android/key.properties` |
| keyPassword | ดูใน `android/key.properties` |

> ไฟล์ `key.properties` และ `upload-keystore.jks` ห้าม commit ขึ้น Git สาธารณะ  
> ตรวจสอบว่าอยู่ใน `.gitignore` แล้ว

---

## 🛠 Build APK (สำหรับทดสอบเครื่องโดยตรง)

```bash
flutter build apk --release
```

ไฟล์ output: `flutter_app/build/app/outputs/flutter-apk/app-release.apk`

ติดตั้งผ่าน ADB:

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## ❗ ปัญหาที่พบบ่อย

| ปัญหา | วิธีแก้ |
|-------|--------|
| `versionCode` ซ้ำ | เพิ่มตัวเลขหลัง `+` ใน pubspec.yaml |
| Keystore ไม่เจอ | ตรวจสอบ path ใน `key.properties` ให้ตรงกับไฟล์จริง |
| Build failed | ลอง `flutter clean` แล้ว build ใหม่ |
| Storage เต็มใน emulator | `adb shell pm trim-caches 1000000000` |

---

## 🔄 flutter clean (ถ้า build มีปัญหา)

```bash
cd d:/SWK/Skill-Wallet-Kool/flutter_app
flutter clean
flutter pub get
flutter build appbundle --release
```

---

*อัปเดตล่าสุด: เมษายน 2026*
