import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../manage_percas/domain/perca_provider.dart';
import '../../../../core/utils/image_capture_helper.dart';


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
  
  // List untuk menyimpan semua stok yang sudah diinput
  final List<Map<String, dynamic>> _stockList = [];
  
  // Flag untuk menentukan apakah sedang dalam mode input stok atau upload bukti
  bool _isInputStockMode = true;

  // Fungsi untuk mengambil foto dengan kamera menggunakan ImageCaptureHelper
  Future<void> _pickImage() async {
    await ImageCaptureHelper.showCaptureFlow(
      context: context,
      onSubmit: (File imageFile) async {
        // Set image file ke state
        setState(() {
          _imageFile = imageFile;
        });
        
        // Tidak perlu melakukan penyimpanan di sini karena ini hanya untuk pratinjau
        // Penyimpanan akan dilakukan di _finishAddingStock
      },
    );
  }

  // Fungsi untuk menambahkan stok ke list
  void _addStockToList() {
    if (_formKey.currentState!.validate() && 
        _selectedPabrikId != null && 
        _selectedJenis != null) {
      
      setState(() {
        _stockList.add({
          'idFactory': _selectedPabrikId!,
          'dateEntry': _selectedDate,
          'jenis': _selectedJenis!,
          'weight': double.parse(_beratController.text),
        });
        
        // Clear jenis dan berat untuk input berikutnya
        _selectedJenis = null;
        _beratController.clear();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stok ${_stockList.length} berhasil ditambahkan')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap lengkapi semua data')),
      );
    }
  }

  // Fungsi untuk beralih ke mode upload bukti
  void _switchToUploadMode() {
    if (_stockList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap tambahkan minimal satu stok terlebih dahulu')),
      );
      return;
    }
    
    setState(() {
      _isInputStockMode = false;
    });
  }

  // Fungsi untuk menyelesaikan proses dan menyimpan semua data
  Future<void> _finishAddingStock() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap ambil foto bukti pengambilan terlebih dahulu')),
      );
      return;
    }

    try {
      // Tampilkan loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      // Gunakan provider untuk menyimpan multiple stocks
      await ref.read(addPercaNotifierProvider.notifier).addMultiplePercaStocks(_stockList, _imageFile!);
      
      // Periksa apakah ada error
      final state = ref.read(addPercaNotifierProvider);
      
      // Tutup loading
      if (mounted) Navigator.of(context).pop();
      
      if (state.hasError) {
        // Jika ada error, tampilkan pesan error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan: ${state.error}')),
          );
        }
      } else {
        // Jika berhasil, tampilkan pesan sukses dan kembali ke dashboard
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Semua stok berhasil disimpan!')),
          );
          
          // Kembali ke dashboard/halaman sebelumnya
          Navigator.pop(context);
        }
      }
    } catch (e) {
      // Tutup loading jika ada error
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Fungsi untuk menghapus stok dari list
  void _removeStockFromList(int index) {
    setState(() {
      _stockList.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pabrikListState = ref.watch(factoryListProvider);
    final addPercaState = ref.watch(addPercaNotifierProvider);
    final List<String> jenisPercaList = ['Kaos', 'Kain']; // Contoh data statis

    return Scaffold(
      appBar: AppBar(
        title: Text(_isInputStockMode ? 'Tambah Stok Perca' : 'Upload Bukti Pengambilan'),
      ),
      body: addPercaState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _isInputStockMode ? _buildInputStockForm(pabrikListState, jenisPercaList) : _buildUploadProofForm(),
            ),
    );
  }

  // Widget untuk form input stok
  Widget _buildInputStockForm(AsyncValue pabrikListState, List<String> jenisPercaList) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dropdown Nama Pabrik
          pabrikListState.when(
            data: (pabrikList) {
              return DropdownButtonFormField<String>(
                value: _selectedPabrikId,
                hint: const Text('Pilih Nama Pabrik'),
                items: pabrikList.map<DropdownMenuItem<String>>((pabrik) {
                  return DropdownMenuItem<String>(
                    value: pabrik.id,
                    child: Text(pabrik.factoryName),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedPabrikId = value),
                validator: (value) => value == null ? 'Pabrik tidak boleh kosong' : null,
              );
            },
            loading: () => DropdownButtonFormField<String>(
              items: const [],
              onChanged: null,
              decoration: const InputDecoration(
                hintText: 'Loading pabrik...',
              ),
            ),
            error: (err, stack) => DropdownButtonFormField<String>(
              items: const [],
              onChanged: null,
              decoration: InputDecoration(
                hintText: 'Error: $err',
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Input Tanggal
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
            items: jenisPercaList.map<DropdownMenuItem<String>>((jenis) {
              return DropdownMenuItem<String>(value: jenis, child: Text(jenis));
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

          // Daftar stok yang sudah diinput
          if (_stockList.isNotEmpty) ...[
            const Text(
              'Stok yang sudah diinput:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...List.generate(_stockList.length, (index) {
              final stock = _stockList[index];
              return Card(
                child: ListTile(
                  title: Text('${stock['jenis']} - ${stock['berat']} KG'),
                  subtitle: Text('Tanggal: ${MaterialLocalizations.of(context).formatShortDate(stock['tglMasuk'])}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeStockFromList(index),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],

          // Tombol Lanjut (untuk menambah stok)
          ElevatedButton(
            onPressed: _addStockToList,
            child: const Text('Lanjut'),
          ),
          const SizedBox(height: 16),

          // Tombol untuk beralih ke upload bukti
          if (_stockList.isNotEmpty)
            ElevatedButton(
              onPressed: _switchToUploadMode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Upload Bukti Pengambilan'),
            ),
        ],
      ),
    );
  }

  // Widget untuk form upload bukti
  Widget _buildUploadProofForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ringkasan stok yang akan disimpan
        const Text(
          'Ringkasan Stok yang Akan Disimpan:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        ...List.generate(_stockList.length, (index) {
          final stock = _stockList[index];
          return Card(
            child: ListTile(
              title: Text('${stock['jenis']} - ${stock['berat']} KG'),
              subtitle: Text('Tanggal: ${MaterialLocalizations.of(context).formatShortDate(stock['tglMasuk'])}'),
            ),
          );
        }),
        
        const SizedBox(height: 24),
        
        // Tombol Foto Bukti (dengan pratinjau)
        OutlinedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.camera_alt),
          label: Text(_imageFile == null ? 'AMBIL FOTO BUKTI' : 'GANTI FOTO BUKTI'),
        ),
        if (_imageFile != null) ...[
          const SizedBox(height: 8),
          Text(
            'Gambar dipilih: ${_imageFile!.path.split('/').last}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
        const SizedBox(height: 24),

        // Tombol Selesai
        ElevatedButton(
          onPressed: _finishAddingStock,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Selesai'),
        ),
        const SizedBox(height: 16),

        // Tombol Kembali ke Input Stok
        TextButton(
          onPressed: () {
            setState(() {
              _isInputStockMode = true;
            });
          },
          child: const Text('Kembali ke Input Stok'),
        ),
      ],
    );
  }
}