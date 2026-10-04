# SplitSquad — Group Expense & Bill Splitter

> **Mobile Development Course Project (Week 16)**  
> สถาปัตยกรรมแบบ Full-Stack Mobile Application: Flutter (MVVM Architecture) + Django OpenID Connect Provider

---

## 1. Project Name & Description (ชื่อโครงการและรายละเอียด)

**SplitSquad** เป็นระบบบันทึกและหารค่าใช้จ่ายกลุ่ม (Group Expense & Bill Splitter) พร้อมระบบคำนวณยอดหนี้คงค้างสุทธิระหว่างบุคคลแบบเรียลไทม์ และระบบเคลียร์หนี้ (Debt Settlement) ช่วยให้เพื่อนร่วมกลุ่ม ทริปท่องเที่ยว หรือครอบครัวสามารถบันทึกค่าใช้จ่ายและตรวจสอบได้ทันทีว่าใครต้องจ่ายให้ใครเท่าไร

ตัวระบบถูกออกแบบและพัฒนาขึ้นตามหลักสูตรวิชา Mobile Application Development (Week 11–16) โดยประยุกต์ใช้องค์ความรู้ระดับมาตรฐานวิชาชีพ:
- **Week 11 & 15:** สถาปัตยกรรม **Google Compass MVVM** ร่วมกับ Dependency Injection (`MultiProvider`, `ProxyProvider`)
- **Week 12 & 16:** การยืนยันตัวตนความปลอดภัยสูงตามมาตรฐาน **OpenID Connect (OIDC)** ด้วย **Authorization Code Flow + PKCE (Proof Key for Code Exchange)** ร่วมกับ Django และ Protected REST API (Bearer Token)
- **Week 13:** Data Layer Architecture แบบ Stateless (`ApiClient` บน Dio, `Result<T>` pattern สำหรับ Safe Exception Handling, Domain Models, Repository Pattern)
- **Week 14:** ระบบ Flutter Form Management & Input Validation (`Form`, `GlobalKey<FormState>`, `TextFormField`, RegEx validators, `FocusNode`, `TextEditingController`)
- **Week 16:** Persistent Session Management (`SharedPreferences`), Route Guards, Zero-Error Execution, และ Extra Feature (Dark Mode 🌙)

---

## 2. Team Members (ข้อมูลผู้พัฒนา)

| ลำดับ | รหัสนักศึกษา | ชื่อ - นามสกุล | บทบาทหน้าที่ |
| :---: | :---: | :---: | :--- |
| 1 | `65xxxxxxx` | นักศึกษาผู้รับผิดชอบโครงการ | Full-Stack Development (Flutter UI, MVVM, Django Backend, OIDC) |

---

## 3. Features List (รายการคุณสมบัติเด่น)

### 3.1 การยืนยันตัวตนตามมาตรฐานความปลอดภัย (OIDC Authentication - 20 คะแนน)
- [x] **OIDC Authorization Code Flow with PKCE (S256):** รองรับ Web Redirect Flow เชื่อมต่อกับ Django OIDC Provider และแลกเปลี่ยน Access Token อย่างปลอดภัย
- [x] **Persistent Session Storage:** บันทึก Token และ User Profile ลง `SharedPreferences` รีเฟรชหน้าเว็บหรือเปิดแอปใหม่ไม่ต้องล็อกอินซ้ำ
- [x] **Route Guard & Dynamic Routing:** ป้องกันหน้าใช้งานหลักอัตโนมัติ หากยังไม่ผ่านการล็อกอินจะแสดงหน้า LoginScreen ทันที
- [x] **Session Logout:** ปุ่มออกจากระบบ เคลียร์ Token และ User State ออกจาก Storage อย่างสมบูรณ์
- [x] **Quick Preset Logins:** ปุ่มล็อกอินด่วน (Alice, Bob, Admin) สะดวกต่อการตรวจให้คะแนน

### 3.2 การจัดการบิลค่าใช้จ่ายครบทุกมิติ (Main CRUD Functions - 15 คะแนน)
- [x] **Create (สร้างบิล):** เพิ่มรายการค่าใช้จ่าย ระบุชื่อบิล จำนวนเงิน หมวดหมู่ หมายเหตุ และเลือกสมาชิกผู้ร่วมหารได้อิสระ
- [x] **Read (ดูรายการบิลและสรุปยอด):** ดูประวัติค่าใช้จ่ายทั้งหมด พร้อมหน้าสรุปยอดหนี้สุทธิ (Net Balance) และรายละเอียดบิลแยกรายบุคคล
- [x] **Update (แก้ไขบิล):** สามารถกดแก้ไขรายละเอียดบิล ยอดเงิน หรือผู้ร่วมหาร และคำนวณส่วนแบ่งใหม่ทันที
- [x] **Delete (ลบบิล):** สามารถลบบิลที่ไม่ต้องการ พร้อมระบบยืนยันความปลอดภัย (Confirmation Dialog)

### 3.3 ฟีเจอร์เสริมพิเศษ (Extra Features - 10 คะแนน)
- [x] **โหมดกลางคืน (Dark Mode 🌙):** สลับธีมมืด/สว่างได้จาก AppBar หรือหน้า Profile พร้อมจดจำค่าไว้ใน `SharedPreferences`
- [x] **Category Filtering:** กรองดูค่าใช้จ่ายตามหมวดหมู่ (อาหาร, เดินทาง, ที่พัก, บันเทิง, ช้อปปิ้ง, อื่นๆ)
- [x] **Debt Settlement (การบันทึกคืนเงิน):** ระบบคำนวณการเคลียร์หนี้สุทธิระหว่างบุคคล พร้อมอัปเดตสถานะบิลอัตโนมัติ

---

## 4. Tech Stack (เทคโนโลยีที่ใช้)

### Frontend (Mobile & Web)
- **Framework:** Flutter SDK 3.x (Dart 3.x)
- **State Management & DI:** `provider` (MultiProvider, ProxyProvider, ChangeNotifierProxyProvider)
- **Networking:** `dio` (Stateless ApiClient with Bearer Interceptor)
- **Local Storage:** `shared_preferences` (Persistent Session & Theme Mode)
- **Security:** `crypto` (SHA-256 PKCE Code Challenge Generation)
- **Localization & Formatting:** `intl` (Thai Baht Currency & DateTime Format)
- **External Integration:** `url_launcher`

### Backend
- **Framework:** Django 5.x + Django REST Framework
- **Environment & Package Manager:** `uv` (Fast Python Package Manager)
- **OpenID Connect Provider:** `django-oidc-provider` (RSA-256 JWT, PKCE S256)
- **CORS Management:** `django-cors-headers`
- **Database:** SQLite (พร้อม Management Command สำหรับ Seed ข้อมูล)

---

## 5. Prerequisites & Environment Setup (สิ่งที่ต้องเตรียมก่อนรัน)

1. **Python 3.10 ขึ้นไป**
2. **uv** (ติดตั้งง่ายผ่าน `pip install uv` หรือตามคู่มือทางการของ Astral)
3. **Flutter SDK 3.13+** (พร้อมคำสั่ง `flutter` ใน PATH)
4. **Google Chrome** (สำหรับรัน Flutter Web)

---

## 6. Step-by-step Run Instructions (วิธีการรันระบบแบบ Zero-Error)

> [!IMPORTANT]  
> กรุณาตรวจสอบให้แน่ใจว่ารัน Backend ก่อนเปิด Frontend เพื่อให้ OIDC Discovery และ Token Endpoint พร้อมให้บริการ

### ขั้นตอนที่ 1: ติดตั้งและรัน Backend (Terminal ที่ 1)
```powershell
# 1. เข้าสู่โฟลเดอร์ backend
cd backend

# 2. ติดตั้ง Dependencies ทั้งหมดผ่าน uv
uv sync

# 3. รัน Database Migrations
uv run manage.py migrate

# 4. Seed ข้อมูลผู้ใช้เริ่มต้น, OIDC Client (PKCE), และรายการบิลตัวอย่าง
uv run manage.py seed_splitsquad_data

# 5. เริ่มต้นเซิร์ฟเวอร์ Django บนพอร์ต 8000
uv run manage.py runserver 0.0.0.0:8000
```
เซิร์ฟเวอร์ Backend จะทำงานที่: **`http://127.0.0.1:8000`**

---

### ขั้นตอนที่ 2: ติดตั้งและรัน Frontend (Terminal ที่ 2)
```powershell
# 1. เข้าสู่โฟลเดอร์ frontend
cd frontend

# 2. ดึง Flutter Dependencies
flutter pub get

# 3. ตรวจสอบโค้ด (Zero Warnings / Zero Errors)
flutter analyze
flutter test

# 4. รันแอปพลิเคชันบน Chrome กำหนดพอร์ต 50000 ตามเกณฑ์ Week 16
flutter run -d chrome --web-port 50000
```
เบราว์เซอร์ Chrome จะเปิดแอปพลิเคชันที่: **`http://localhost:50000`**

---

## 7. Test Accounts (บัญชีผู้ใช้สำหรับการตรวจให้คะแนน)

| ชื่อผู้ใช้ (Username) | รหัสผ่าน (Password) | สิทธิ์ / สถานะ | ข้อมูลทดสอบในระบบ |
| :--- | :--- | :--- | :--- |
| **`alice`** | `alice123` | User ทั่วไป | มีทั้งยอดที่เพื่อนติด และยอดที่ติดเพื่อน (ทดสอบดูสรุปยอดและเคลียร์หนี้ได้ทันที) |
| **`bob`** | `bob123` | User ทั่วไป | สมาชิกร่วมหารบิล |
| **`somchai`** | `somchai123` | User ทั่วไป | สมาชิกร่วมหารบิล |
| **`admin`** | `admin123` | Superuser / Staff | ผู้ดูแลระบบ |

*(หน้าแรกของแอปพลิเคชันมีปุ่ม **Quick Presets** กดปุ่มเดียวเพื่อกรอก Username/Password ได้ทันที หรือกดปุ่ม "เข้าสู่ระบบด้วย Django OIDC (PKCE)" เพื่อทดสอบ Authorization Code Flow)*

---

## 8. Architecture & API Endpoints

### 8.1 สถาปัตยกรรมระบบ (MVVM Layer Separation)
```
[Flutter UI Views]
  └── LoginScreen, DashboardScreen, AddExpenseScreen, ExpenseDetailScreen, ProfileScreen
         │  (Observes State via Provider)
[ViewModels]
  └── AuthViewModel, ExpenseViewModel, ThemeViewModel
         │  (Invokes Repositories, Receives Result<T>)
[Repositories]
  └── AuthRepositoryRemote, ExpenseRepositoryRemote
         │  (Stateless Service Orchestration, Local Storage Persistence)
[Services & ApiClient]
  └── OidcAuthService, ExpenseApiService, Stateless ApiClient (Dio)
         │  (HTTP / Bearer Token Header)
[Django Backend]
  └── OIDC Endpoints (/openid/), Protected DRF APIs (/api/expenses/, /api/summary/, /api/settle/)
```

### 8.2 ตาราง REST API Endpoints
| Method | Endpoint | การยืนยันตัวตน | หน้าที่การทำงาน |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/auth/token/` | Public | ยืนยันตัวตนและออก OIDC Token สำหรับ Mobile Client |
| `GET` | `/openid/userinfo/` | Bearer Token | ดึง Claims ข้อมูลผู้ใช้ตามมาตรฐาน OpenID Connect |
| `GET` | `/api/expenses/` | Bearer Token | ดึงรายการค่าใช้จ่ายทั้งหมด (รองรับ `?category=...`) |
| `POST` | `/api/expenses/` | Bearer Token | สร้างบิลค่าใช้จ่ายใหม่และคำนวณส่วนหาร |
| `PUT` | `/api/expenses/<id>/` | Bearer Token | แก้ไขบิลค่าใช้จ่ายและคำนวณส่วนหารใหม่ |
| `DELETE` | `/api/expenses/<id>/` | Bearer Token | ลบรายการบิลค่าใช้จ่าย |
| `GET` | `/api/summary/` | Bearer Token | ดึงข้อมูลสรุปยอดหนี้สุทธิและยอดคงค้างแยกรายบุคคล |
| `POST` | `/api/settle/` | Bearer Token | บันทึกการเคลียร์หนี้และชำระเงินระหว่างบุคคล |
| `GET` | `/api/users/` | Bearer Token | ดึงรายชื่อสมาชิกในระบบสำหรับเลือกหารเงิน |
