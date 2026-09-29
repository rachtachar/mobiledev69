# SplitSquad — แอปพลิเคชันหารค่าใช้จ่ายกลุ่ม & สรุปยอดค้างชำระ

**SplitSquad** เป็นระบบแอปพลิเคชันมือถือแบบ Full-Stack ที่พัฒนาขึ้นเพื่อบูรณาการองค์ความรู้การพัฒนาโมบายแอปพลิเคชันครบทั้ง 5 สัปดาห์ (Week 11–15):
- **Week 11 & 15:** สถาปัตยกรรมระดับมืออาชีพ Google Compass MVVM ร่วมกับ Dependency Injection (`MultiProvider`, Constructor Injection)
- **Week 12:** ระบบหลังบ้าน Django REST Framework ร่วมกับมาตรฐานความปลอดภัย **OpenID Connect (OIDC)** และ Bearer Token Authentication
- **Week 13:** โครงสร้างข้อมูลชั้น Data Layer (Stateless `ApiClient`, Result Pattern `Result<T>` สำหรับดักจับ Exception ปลอดภัย, Domain Models, Repositories)
- **Week 14:** ระบบฟอร์มและการตรวจสอบความถูกต้อง (Flutter `Form`, `GlobalKey<FormState>`, `TextFormField`, RegEx Validators, `FocusNode`, `TextEditingController`)

---

## 🏗️ สถาปัตยกรรมระบบ (System Architecture)

```
[View Layer] (lib/views/)
  • LoginScreen (เข้าสู่ระบบ OIDC พร้อม Quick Presets)
  • DashboardScreen (ภาพรวมยอดหนี้สุทธิ, ฟิลเตอร์หมวดหมู่, รายการบิล)
  • AddExpenseScreen (ฟอร์มบันทึกบิล, ตรวจสอบความถูกต้อง, สรุปส่วนแบ่งเรียลไทม์)
  • ExpenseDetailScreen (รายละเอียดผู้ร่วมหารและสถานะการจ่าย)
  • ProfileScreen (ข้อมูล OIDC Claims และบันทึกการคืนเงิน)
        │
        ▼ (Listens via ChangeNotifier)
[ViewModel Layer] (lib/viewmodels/)
  • AuthViewModel (ควบคุมสถานะการยืนยันตัวตน)
  • ExpenseViewModel (ควบคุมรายการบิล, ยอดสุทธิ, และการกรองข้อมูล)
        │
        ▼ (Constructor Injection)
[Repository Layer] (lib/data/repositories/)
  • AuthRepository / AuthRepositoryRemote
  • ExpenseRepository / ExpenseRepositoryRemote (คืนค่า Result<T> Success/Failure)
        │
        ▼ (Stateless HTTP Calls)
[Service Layer] (lib/data/services/)
  • OidcAuthService (เชื่อมต่อ /api/auth/token/ และ /openid/userinfo/)
  • ExpenseApiService (เชื่อมต่อ /api/expenses/, /api/summary/, /api/settle/)
        │
        ▼ (Dio Client with Bearer Token Header)
[Django Backend] (port 8000)
  • OIDC Provider (/openid/)
  • Protected REST API (/api/)
```

---

## 🚀 วิธีการรันระบบ (Quick Start)

### 1. ฝั่ง Backend (Django ด้วย uv)
เปิด Terminal (PowerShell):
```powershell
cd backend
uv run manage.py migrate
uv run manage.py seed_splitsquad_data
uv run manage.py runserver 0.0.0.0:8000
```
*ระบบจะรันบน `http://127.0.0.1:8000`*

### 2. ฝั่ง Frontend (Flutter)
เปิด Terminal อีกหน้าต่างหนึ่ง:
```powershell
cd frontend
flutter pub get
flutter test
flutter run -d windows
# หรือรันบนเว็บเบราว์เซอร์: flutter run -d chrome
```

---

## 👥 บัญชีผู้ใช้ทดสอบเริ่มต้น (Dev Accounts)

| ชื่อผู้ใช้ (Username) | รหัสผ่าน (Password) | บทบาท / ชื่อที่แสดง |
| :--- | :--- | :--- |
| `alice` | `alice123` | Alice Chen (มีทั้งยอดเพื่อนติดและยอดติดเพื่อน) |
| `bob` | `bob123` | Bob Smith |
| `somchai` | `somchai123` | Somchai Jaidee |
| `admin` | `admin123` | System Administrator (Superuser) |

*(ในหน้า Login ของแอป มีปุ่ม **Quick Presets** ให้กดเพื่อกรอกรหัสผ่านอัตโนมัติได้อย่างรวดเร็ว)*

---

## 📡 Protected API Endpoints

| Method | Endpoint | สิทธิ์ | คำอธิบาย |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/auth/token/` | สาธารณะ | ยืนยันรหัสผ่านและออก OIDC Token |
| `GET` | `/openid/userinfo/` | Bearer Token | ดึง Claims ข้อมูลส่วนบุคคลตามมาตรฐาน OIDC |
| `GET` | `/api/summary/` | Bearer Token | คำนวณสรุปยอดหนี้สุทธิและยอดแยกรายบุคคล |
| `GET` | `/api/expenses/` | Bearer Token | ดึงรายการบิล (รองรับ `?category=...`) |
| `POST` | `/api/expenses/` | Bearer Token | สร้างบิลใหม่และแบ่งส่วนหารอัตโนมัติ |
| `DELETE` | `/api/expenses/<id>/` | Bearer Token | ลบรายการบิล |
| `GET` | `/api/users/` | Bearer Token | ดึงรายชื่อเพื่อนร่วมกลุ่มเพื่อเลือกหารเงิน |
| `POST` | `/api/settle/` | Bearer Token | บันทึกการคืนเงินระหว่างบุคคล |
