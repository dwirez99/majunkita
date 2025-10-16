import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../domain/perca_provider.dart';
// TODO: import preview_proof_screen.dart

class AddPercaScreen extends ConsumerStatefulWidget {
  const AddPercaScreen({super.key});

  @override
  ConsumerState<AddPercaScreen> createState() => _AddPercaScreenState();
}

class _AddPercaScreenState extends ConsumerState<AddPercaScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPabrikId;
  DateTime _selectedDate = DateTime.now();
  String? _selectedJenis;
  final _beratController = TextEditingController();
  File? _imageFile;

  // Fungsi untuk memilih gambar
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _imageFile != null) {
      // TODO: Kumpulkan data dan navigasi ke halaman preview
      // Navigator.push(context, MaterialPageRoute(builder: (context) => ...));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap lengkapi semua data dan pilih gambar bukti.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pabrikListState = ref.watch(pabrikListProvider);
    final List<String> jenisPercaList = ['Kaos', 'Kain', 'Katun', 'Lainnya']; // Contoh data statis

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Stok Perca')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dropdown Nama Pabrik
              pabrikListState.when(
                data: (pabrikList) => DropdownButtonFormField<String>(
                  value: _selectedPabrikId,
                  hint: const Text('Pilih Nama Pabrik'),
                  items: pabrikList.map((pabrik) {
                    return DropdownMenuItem(
                      value: pabrik.id,
                      child: Text(pabrik.namaPabrik),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedPabrikId = value),
                  validator: (value) => value == null ? 'Pabrik tidak boleh kosong' : null,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error: $err'),
              ),
              const SizedBox(height: 16),

              // Input Tanggal (simplified)
              ListTile(
                title: Text('Tanggal Ambil: ${MaterialLocalizations.of(context).formatShortDate(_selectedDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) setState(() => _selectedDate = pickedDate);
                },
              ),
              const SizedBox(height: 16),

              // Dropdown Jenis Perca
              DropdownButtonFormField<String>(
                value: _selectedJenis,
                hint: const Text('Pilih Jenis Perca'),
                items: jenisPercaList.map((jenis) {
                  return DropdownMenuItem(value: jenis, child: Text(jenis));
                }).toList(),
                onChanged: (value) => setState(() => _selectedJenis = value),
                validator: (value) => value == null ? 'Jenis tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),

              // Input Berat
              TextFormField(
                controller: _beratController,
                decoration: const InputDecoration(labelText: 'Berat (KG)'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Berat tidak boleh kosong' : null,
              ),
              const SizedBox(height: 24),
              
              // Tombol Pilih Bukti
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt),
                label: Text(_imageFile == null ? 'PILIH BUKTI PENGAMBILAN' : 'GANTI BUKTI'),
              ),
              if (_imageFile != null) ...[
                  const SizedBox(height: 8),
                  Text('Gambar dipilih: ${_imageFile!.path.split('/').last}', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
              ],
              const SizedBox(height: 24),
              
              // Tombol Lanjut
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Lanjut'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}