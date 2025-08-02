import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latihanflutter/services/api_service.dart';
import 'dart:convert';
import '../widgets/user_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> users = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      final token = await ApiService.getToken();
      final response = await ApiService.useApi(
        ApiService.getToken().toString(),
        json.encode({"param": "getUsers"}),
        "user",
      );
      setState(() {
        users = response as List<dynamic>;
      });
    } catch (e) {
      debugPrint("❌ Error fetchUsers: $e");
    }
  }

  void showAddUserDialog() {
    TextEditingController email = TextEditingController();
    TextEditingController password = TextEditingController();
    TextEditingController namaDepan = TextEditingController();
    TextEditingController namaBelakang = TextEditingController();
    String jenisKelamin = 'Laki-laki';
    DateTime? tanggalLahir;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Tambah User"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: email,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: password,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                TextField(
                  controller: namaDepan,
                  decoration: const InputDecoration(labelText: 'Nama Depan'),
                ),
                TextField(
                  controller: namaBelakang,
                  decoration: const InputDecoration(labelText: 'Nama Belakang'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text("Jenis Kelamin: "),
                    Expanded(
                      child: RadioListTile(
                        value: "Laki-laki",
                        groupValue: jenisKelamin,
                        onChanged: (value) => setStateDialog(() {
                          jenisKelamin = value.toString();
                        }),
                        title: const Text("L"),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile(
                        value: "Perempuan",
                        groupValue: jenisKelamin,
                        onChanged: (value) => setStateDialog(() {
                          jenisKelamin = value.toString();
                        }),
                        title: const Text("P"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text("Tanggal Lahir: "),
                    Expanded(
                      child: Text(
                        tanggalLahir != null
                            ? tanggalLahir.toString().split(' ')[0]
                            : 'Belum dipilih',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: DateTime(2000),
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now(),
                        );
                        if (selected != null) {
                          setStateDialog(() {
                            tanggalLahir = selected;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final body = json.encode({
                    "param": "create",
                    "email": email.text,
                    "password": password.text,
                    "namaDepan": namaDepan.text,
                    "namaBelakang": namaBelakang.text,
                    "jenisKelamin": jenisKelamin,
                    "tanggalLahir": tanggalLahir?.toIso8601String().split(
                      'T',
                    )[0],
                  });

                  final response = await ApiService.useApi(
                    await ApiService.getToken().toString(),
                    body,
                    "user",
                  );

                  if (response != null) {
                    Navigator.pop(ctx);
                    fetchUsers();
                  }
                } catch (e) {
                  debugPrint("❌ Gagal simpan user: $e");
                }
              },
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User List")),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddUserDialog,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: users.length,
        itemBuilder: (context, index) {
          return UserCard(user: users[index], onRefresh: fetchUsers);
        },
      ),
    );
  }
}
