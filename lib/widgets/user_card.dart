import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latihanflutter/services/api_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserCard extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onRefresh;

  const UserCard({super.key, required this.user, required this.onRefresh});

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _animation;
  DateTime? selectedDate;
  String selectedGender = "Laki-laki";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  void toggleCard() {
    setState(() {
      _isExpanded = !_isExpanded;
      _isExpanded ? _controller.forward() : _controller.reverse();
    });
  }

  void showEditDialog() {
    TextEditingController namaDepan = TextEditingController(
      text: widget.user['namaDepan'],
    );
    TextEditingController namaBelakang = TextEditingController(
      text: widget.user['namaBelakang'],
    );
    TextEditingController email = TextEditingController(
      text: widget.user['email'],
    );
    String jenisKelamin = widget.user['jenisKelamin'];
    DateTime? tanggalLahir = DateTime.tryParse(
      widget.user['tanggalLahir'] ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Edit User"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: namaDepan,
                      decoration: const InputDecoration(
                        labelText: 'Nama Depan',
                      ),
                    ),
                    TextField(
                      controller: namaBelakang,
                      decoration: const InputDecoration(
                        labelText: 'Nama Belakang',
                      ),
                    ),
                    TextField(
                      controller: email,
                      enabled: false,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    Row(
                      children: [
                        const Text("Jenis Kelamin: "),
                        Expanded(
                          child: RadioListTile(
                            value: "Laki-laki",
                            groupValue: jenisKelamin,
                            onChanged: (value) {
                              setState(() => jenisKelamin = value.toString());
                            },
                            title: const Text("L"),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile(
                            value: "Perempuan",
                            groupValue: jenisKelamin,
                            onChanged: (value) {
                              setState(() => jenisKelamin = value.toString());
                            },
                            title: const Text("P"),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: tanggalLahir ?? DateTime.now(),
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => tanggalLahir = picked);
                        }
                      },
                      child: Text(
                        tanggalLahir == null
                            ? "Pilih Tanggal Lahir"
                            : "Tanggal: ${tanggalLahir!.toLocal().toIso8601String().split('T')[0]}",
                      ),
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
                    final body = json.encode({
                      "param": "updateUser",
                      "email": email.text,
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
                    Navigator.pop(ctx);
                    widget.onRefresh();
                  },
                  child: const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus User"),
        content: const Text("Apakah Anda yakin ingin menghapus user ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              final body = json.encode({
                "param": "deleteUser",
                "email": widget.user['email'],
              });

              final response = await ApiService.useApi(
                await ApiService.getToken().toString(),
                body,
                "user",
              );
              Navigator.pop(ctx);
              widget.onRefresh();
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = "${widget.user['namaDepan']} ${widget.user['namaBelakang']}";
    final avatarUrl =
        "https://ui-avatars.com/api/?name=${widget.user['namaDepan']}+${widget.user['namaBelakang']}";

    return GestureDetector(
      onTap: toggleCard,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(avatarUrl),
                ),
                const SizedBox(width: 12),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizeTransition(
              sizeFactor: _animation,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      height: 150,
                      child: FlutterMap(
                        options: MapOptions(
                          center: LatLng(-7.2575, 112.7521),
                          zoom: 12,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.app',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(avatarUrl),
                    ),
                    title: Text(name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Email: ${widget.user['email']}"),
                        Text("Jenis Kelamin: ${widget.user['jenisKelamin']}"),
                        Text(
                          "Tanggal Lahir: " +
                              widget.user['tanggalLahir'].substring(0, 10),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 6,
                          shadowColor: Colors.blueAccent.withOpacity(0.6),
                        ),
                        onPressed: showEditDialog,
                        child: const Text(
                          "Edit",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 6,
                          shadowColor: Colors.redAccent.withOpacity(0.6),
                        ),
                        onPressed: confirmDelete,
                        child: const Text(
                          "Hapus",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
