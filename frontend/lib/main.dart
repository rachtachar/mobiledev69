import 'dart:convert'; // สำคัญ: ใช้แปลง JSON (jsonDecode และ jsonEncode)
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // เพิ่มการ import http

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // แก้ไข syntax: เติม ColorScheme
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Week14 Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  final TextEditingController _accessCtrl = TextEditingController();
  final TextEditingController _refreshCtrl = TextEditingController();

  // ฟังก์ชันยิง API ไปรับ Token จาก Django Backend
  Future<void> _apiToken() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    // เช็กว่ากรอกข้อมูลครบหรือไม่
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอก Username และ Password')),
      );
      return;
    }

    // กำหนด URL ของ Django (ปรับ IP ตามสภาพแวดล้อมที่รัน)
    // - Android Emulator: http://10.0.2.2:8000/api/token/
    // - iOS / Web: http://127.0.0.1:8000/api/token/
    final url = Uri.parse('http://10.80.23.45/api/token/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        // ถ้ารหัสถูกต้อง Django SimpleJWT จะตอบกลับมาเป็น JSON:
        // {"access": "...", "refresh": "..."}
        final Map<String, dynamic> data = jsonDecode(response.body);

        setState(() {
          _accessCtrl.text = data['access'] ?? '';
          _refreshCtrl.text = data['refresh'] ?? '';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ดึง Tokenสำเร็จ!')),
          );
        }
      } else {
        // กรณี Username หรือ Password ไม่ถูกต้อง (HTTP 401)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เข้าสู่ระบบไม่สำเร็จ: ${response.body}')),
          );
        }
      }
    } catch (e) {
      // กรณีเชื่อมต่อ Serverไม่ได้
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถเชื่อมต่อ Server ได้: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _accessCtrl.dispose();
    _refreshCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            // แก้ไข syntax: เติม MainAxisAlignment
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Enter username and password'),
              TextField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 20),
              const Text('Access/Refresh Token'),
              TextField(
                controller: _accessCtrl,
                readOnly: true, // ตั้งเป็นอ่านอย่างเดียว
                decoration: const InputDecoration(labelText: 'Access Token'),
              ),
              TextField(
                controller: _refreshCtrl,
                readOnly: true, // ตั้งเป็นอ่านอย่างเดียว
                decoration: const InputDecoration(labelText: 'Refresh Token'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _apiToken,
        tooltip: 'Access',
        child: const Icon(Icons.favorite),
      ),
    );
  }
}