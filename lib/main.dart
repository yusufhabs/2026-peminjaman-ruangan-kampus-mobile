import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Peminjaman Ruangan',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F4E79)),
        useMaterial3: true,
      ),
      home: const PeminjamanPage(),
    );
  }
}

class Peminjaman {
  final int id;
  final String namaPeminjam;
  final String nomorRuangan;
  final String tanggalPinjam;
  final String tanggalKembali;
  final String keperluan;
  final String status;

  Peminjaman({
    required this.id,
    required this.namaPeminjam,
    required this.nomorRuangan,
    required this.tanggalPinjam,
    required this.tanggalKembali,
    required this.keperluan,
    required this.status,
  });

  factory Peminjaman.fromJson(Map<String, dynamic> json) {
    return Peminjaman(
      id: json['id'],
      namaPeminjam: json['namaPeminjam'] ?? '',
      nomorRuangan: json['nomorRuangan'] ?? '',
      tanggalPinjam: json['tanggalPinjam'] ?? '',
      tanggalKembali: json['tanggalKembali'] ?? '',
      keperluan: json['keperluan'] ?? '',
      status: json['status'] ?? 'menunggu',
    );
  }
}

class PeminjamanPage extends StatefulWidget {
  const PeminjamanPage({super.key});

  @override
  State<PeminjamanPage> createState() => _PeminjamanPageState();
}

class _PeminjamanPageState extends State<PeminjamanPage> {
  final String apiUrl = 'http://localhost:5248/api/peminjaman';
  List<Peminjaman> data = [];
  bool loading = false;
  String search = '';

  final _formKey = GlobalKey<FormState>();
  final _namaPeminjamController = TextEditingController();
  final _nomorRuanganController = TextEditingController();
  final _keperluanController = TextEditingController();
  DateTime? _tanggalPinjam;
  DateTime? _tanggalKembali;
  String _status = 'menunggu';
  int? _editId;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => loading = true);
    try {
      final uri = Uri.parse(apiUrl).replace(
        queryParameters: search.isNotEmpty ? {'search': search} : null,
      );
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final List json = jsonDecode(res.body);
        setState(() => data = json.map((e) => Peminjaman.fromJson(e)).toList());
      }
    } catch (e) {
      showError('Gagal memuat data');
    }
    setState(() => loading = false);
  }

  Future<void> saveData() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tanggalPinjam == null || _tanggalKembali == null) {
      showError('Tanggal pinjam dan kembali wajib diisi');
      return;
    }

    final body = jsonEncode({
      'namaPeminjam': _namaPeminjamController.text,
      'nomorRuangan': _nomorRuanganController.text,
      'tanggalPinjam': _tanggalPinjam!.toIso8601String(),
      'tanggalKembali': _tanggalKembali!.toIso8601String(),
      'keperluan': _keperluanController.text,
      'status': _status,
    });

    try {
      http.Response res;
      if (_editId != null) {
        res = await http.put(
          Uri.parse('$apiUrl/$_editId'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        );
      } else {
        res = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: body,
        );
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        Navigator.pop(context);
        clearForm();
        fetchData();
      } else {
        showError('Gagal menyimpan data');
      }
    } catch (e) {
      showError('Gagal menyimpan data');
    }
  }

  Future<void> deleteData(int id) async {
    try {
      final res = await http.delete(Uri.parse('$apiUrl/$id'));
      if (res.statusCode == 200) {
        fetchData();
      }
    } catch (e) {
      showError('Gagal menghapus data');
    }
  }

  Future<void> updateStatus(int id, String status) async {
    try {
      await http.patch(
        Uri.parse('$apiUrl/$id/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(status),
      );
      fetchData();
    } catch (e) {
      showError('Gagal mengubah status');
    }
  }

  void clearForm() {
    _namaPeminjamController.clear();
    _nomorRuanganController.clear();
    _keperluanController.clear();
    _tanggalPinjam = null;
    _tanggalKembali = null;
    _status = 'menunggu';
    _editId = null;
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  Color statusColor(String status) {
    if (status == 'disetujui') return Colors.green;
    if (status == 'ditolak') return Colors.red;
    return Colors.orange;
  }

  void showForm({Peminjaman? item}) {
    if (item != null) {
      _namaPeminjamController.text = item.namaPeminjam;
      _nomorRuanganController.text = item.nomorRuangan;
      _keperluanController.text = item.keperluan;
      _tanggalPinjam = DateTime.parse(item.tanggalPinjam);
      _tanggalKembali = DateTime.parse(item.tanggalKembali);
      _status = item.status;
      _editId = item.id;
    } else {
      clearForm();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _editId != null ? 'Edit Peminjaman' : 'Tambah Peminjaman',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F4E79)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _namaPeminjamController,
                    decoration: const InputDecoration(labelText: 'Nama Peminjam *', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nomorRuanganController,
                    decoration: const InputDecoration(labelText: 'Nomor Ruangan *', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _keperluanController,
                    decoration: const InputDecoration(labelText: 'Keperluan', border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) setModalState(() => _tanggalPinjam = date);
                          },
                          child: Text(_tanggalPinjam == null
                              ? 'Tanggal Pinjam'
                              : 'Pinjam: ${_tanggalPinjam!.toLocal().toString().split(' ')[0]}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) setModalState(() => _tanggalKembali = date);
                          },
                          child: Text(_tanggalKembali == null
                              ? 'Tanggal Kembali'
                              : 'Kembali: ${_tanggalKembali!.toLocal().toString().split(' ')[0]}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                    items: ['menunggu', 'disetujui', 'ditolak']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setModalState(() => _status = v!),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: saveData,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1F4E79)),
                          child: Text(_editId != null ? 'Update' : 'Simpan', style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () { Navigator.pop(context); clearForm(); },
                          child: const Text('Batal'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peminjaman Ruangan', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1F4E79),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Cari nama atau ruangan...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                setState(() => search = v);
                fetchData();
              },
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : data.isEmpty
                    ? const Center(child: Text('Tidak ada data peminjaman'))
                    : ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          final item = data[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(item.namaPeminjam, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Ruangan: ${item.nomorRuangan}'),
                                  Text('Keperluan: ${item.keperluan.isEmpty ? "-" : item.keperluan}'),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusColor(item.status),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(item.status, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Color(0xFF2E75B6)),
                                    onPressed: () => showForm(item: item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => deleteData(item.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showForm(),
        backgroundColor: const Color(0xFF1F4E79),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}