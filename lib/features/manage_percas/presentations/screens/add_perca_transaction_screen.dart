import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../manage_tailors/data/models/tailor_model.dart';
import '../../domain/providers/perca_transactions_provider.dart';

/// Konversi kode karung dari DB (K-45, B-25) ke tampilan UI (Kaos-45, Kain-25)
String _readableSackCode(String code) {
  if (code.startsWith('K-')) {
    return 'Kaos-${code.substring(2)}';
  } else if (code.startsWith('B-')) {
    return 'Kain-${code.substring(2)}';
  }
  return code;
}

class AddPercaTransactionScreen extends ConsumerStatefulWidget {
  const AddPercaTransactionScreen({super.key});

  @override
  ConsumerState<AddPercaTransactionScreen> createState() =>
      _AddPercaTransactionScreenState();
}

class _AddPercaTransactionScreenState
    extends ConsumerState<AddPercaTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  // Key untuk me-reset tampilan DropdownButtonFormField saat admin menekan
  // "Batal" pada dialog peringatan sisa perca.
  final _tailorDropdownKey = GlobalKey<FormFieldState<String>>();

  // Selected values
  String? _selectedTailorId;
  String? _selectedTailorName;
  String? _selectedSackCode;
  String? _selectedPercaType;
  final _sackCountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  // Info dari stok tersedia (akan di-update saat sack_code dipilih)
  int _availableSacks = 0;
  double _availableWeight = 0;
  double _weightPerSack = 0; // Berat per karung
  double _calculatedWeight = 0; // Total berat otomatis dihitung

  @override
  void initState() {
    super.initState();
    // Auto-hitung total berat saat jumlah karung berubah
    _sackCountController.addListener(_calculateWeight);
  }

  void _calculateWeight() {
    final count = int.tryParse(_sackCountController.text) ?? 0;
    setState(() {
      _calculatedWeight = _weightPerSack * count;
    });
  }

  // List transaksi yang sudah diinput (sebelum submit)
  final List<Map<String, dynamic>> _transactionList = [];

  // Flag lock tailor & tanggal
  bool _isLocked = false;
  final _tailorReadonlyController = TextEditingController();
  final _tanggalReadonlyController = TextEditingController();

  /// Hitung jumlah karung yang sudah ditambahkan ke daftar transaksi per kode
  int _addedSacksForCode(String sackCode) {
    int count = 0;
    for (var trx in _transactionList) {
      if (trx['sackCode'] == sackCode) {
        count += (trx['sackCount'] as int);
      }
    }
    return count;
  }

  void _onSackCodeSelected(Map<String, dynamic> item) {
    final sackCode = item['sack_code'] as String? ?? '';
    final percaType = item['perca_type'] as String? ?? '-';
    final totalSacks = (item['total_sacks'] as num?)?.toInt() ?? 0;
    final totalWeight = (item['total_weight'] as num?)?.toDouble() ?? 0;

    // Kurangi dengan jumlah yang sudah ditambahkan ke daftar
    final alreadyAdded = _addedSacksForCode(sackCode);
    final remainingSacks = totalSacks - alreadyAdded;
    final weightPerSack = totalSacks > 0 ? totalWeight / totalSacks : 0.0;
    final remainingWeight = weightPerSack * remainingSacks;

    setState(() {
      _selectedSackCode = sackCode;
      _selectedPercaType = percaType;
      _availableSacks = remainingSacks;
      _availableWeight = remainingWeight;
      _weightPerSack = weightPerSack;
      _calculatedWeight = 0;
      _sackCountController.clear();
    });
  }

  void _addTransactionToList() {
    if (_formKey.currentState!.validate() &&
        _selectedTailorId != null &&
        _selectedSackCode != null) {
      final sackCount = int.parse(_sackCountController.text);

      setState(() {
        _transactionList.add({
          'idTailor': _selectedTailorId!,
          'tailorName': _selectedTailorName ?? '',
          'sackCode': _selectedSackCode!,
          'percaType': _selectedPercaType ?? '-',
          'sackCount': sackCount,
          'dateEntry': _selectedDate,
          'totalWeight': _calculatedWeight,
        });

        // Lock tailor & tanggal after first entry
        if (!_isLocked) {
          _isLocked = true;
          _tailorReadonlyController.text = _selectedTailorName ?? '';
          _tanggalReadonlyController.text = MaterialLocalizations.of(
            context,
          ).formatShortDate(_selectedDate);
        }

        // Clear for next entry
        _selectedSackCode = null;
        _selectedPercaType = null;
        _sackCountController.clear();
        _availableSacks = 0;
        _availableWeight = 0;
        _weightPerSack = 0;
        _calculatedWeight = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Transaksi ${_transactionList.length} berhasil ditambahkan',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lengkapi semua data'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeTransaction(int index) {
    setState(() {
      _transactionList.removeAt(index);
      if (_transactionList.isEmpty) {
        _isLocked = false;
        _tailorReadonlyController.clear();
        _tanggalReadonlyController.clear();
      }
    });
  }

  /// Tampilkan dialog peringatan jika sisa perca penjahit > [threshold] Kg.
  /// Ini adalah bahan perca mentah yang masih ada di rumah penjahit dan belum diproses.
  /// Tujuan: pastikan admin menanyakan stok sisa sebelum memberikan bahan perca baru
  /// agar tidak ada bahan perca yang tersesat atau tidak teraccounting.
  Future<bool> _showSisaPercaWarning(
    TailorModel tailor, {
    double threshold = 5.0,
  }) async {
    if (tailor.totalStock <= threshold) return true; // tidak perlu peringatan

    final sisaFmt =
        tailor.totalStock == tailor.totalStock.truncateToDouble()
            ? tailor.totalStock.toStringAsFixed(0)
            : tailor.totalStock.toStringAsFixed(1);

    final proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber[700],
              size: 48,
            ),
            title: const Text(
              'Peringatan: Sisa bahan perca Cukup Banyak',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Penjahit "${tailor.name}" masih memiliki estimasi sisa bahan perca/limbah '
              'sebanyak $sisaFmt Kg.\n\n'
              'Pastikan menanyakan sisa bahan perca tersebut sebelum memberikan bahan perca baru.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                child: const Text('Batal'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Lanjutkan'),
              ),
            ],
          ),
    );

    return proceed ?? false;
  }

  Future<void> _submitTransactions() async {
    if (_transactionList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap tambahkan minimal satu transaksi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      // Proses seluruh transaksi SEKALIGUS via 1 RPC (Bulk Processing)
      // Ini menjamin backend tidak akan memecah pesan WA menjadi beberapa bagian.
      final notifier = ref.read(percaTransactionNotifierProvider.notifier);
      
      final items = _transactionList.map((trx) => {
        'sackCode': trx['sackCode'],
        'sackCount': trx['sackCount'],
      }).toList();

      final result = await notifier.processBulkTransactions(
        idTailor: _transactionList.first['idTailor'],
        dateEntry: _transactionList.first['dateEntry'],
        items: items,
      );

      if (mounted) Navigator.of(context).pop(); // Tutup loading

      // Ambil total dari response RPC bulk
      final double totalWeight = (result['total_weight_kg'] as num?)?.toDouble() ?? 0;
      final int totalSacks = (result['total_sacks_taken'] as num?)?.toInt() ?? 0;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Berhasil! $totalSacks karung ($totalWeight KG) diberikan ke penjahit.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _sackCountController.removeListener(_calculateWeight);
    _sackCountController.dispose();
    _tailorReadonlyController.dispose();
    _tanggalReadonlyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tailorListState = ref.watch(tailorListForTransactionProvider);
    final sackSummaryState = ref.watch(availableSackSummaryProvider);
    final notifierState = ref.watch(percaTransactionNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Transaksi Perca'),
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat Ulang Data',
            onPressed: () {
              ref.invalidate(tailorListForTransactionProvider);
              ref.invalidate(availableSackSummaryProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data sedang dimuat ulang...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body:
          notifierState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Header Info ──
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.green[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Pilih penjahit, kode karung, dan jumlah karung yang akan diberikan.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.green[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Pilih Penjahit ──
                      const Text(
                        'Penjahit',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (_isLocked)
                        TextFormField(
                          controller: _tailorReadonlyController,
                          readOnly: true,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.person),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        )
                      else
                        tailorListState.when(
                          data: (tailorList) {
                            return DropdownButtonFormField<String>(
                              key: _tailorDropdownKey,
                              value: _selectedTailorId,
                              hint: const Text('Pilih Penjahit'),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              items:
                                  tailorList.map<DropdownMenuItem<String>>((
                                    tailor,
                                  ) {
                                    return DropdownMenuItem<String>(
                                      value: tailor.id,
                                      child: Text(tailor.name),
                                    );
                                  }).toList(),
                              onChanged: (value) async {
                                final selected = tailorList.firstWhere(
                                  (t) => t.id == value,
                                );
                                // Simpan nilai sebelumnya agar bisa di-restore
                                final previousId = _selectedTailorId;
                                final previousName = _selectedTailorName;

                                // Tampilkan peringatan jika sisa perca > 5 Kg
                                final proceed = await _showSisaPercaWarning(
                                  selected,
                                );
                                if (!proceed) {
                                  // Admin memilih Batal — kembalikan ke pilihan sebelumnya
                                  // agar tampilan Dropdown sinkron dengan state.
                                  setState(() {
                                    _selectedTailorId = previousId;
                                    _selectedTailorName = previousName;
                                  });
                                  // Reset nilai yang ditampilkan dropdown ke previousId
                                  _tailorDropdownKey.currentState?.didChange(
                                    previousId,
                                  );
                                  return;
                                }
                                setState(() {
                                  _selectedTailorId = value;
                                  _selectedTailorName = selected.name;
                                });
                              },
                              validator:
                                  (value) =>
                                      value == null
                                          ? 'Penjahit tidak boleh kosong'
                                          : null,
                            );
                          },
                          loading:
                              () =>
                                  _buildLoadingDropdown('Loading penjahit...'),
                          error: (err, _) => _buildErrorDropdown('Error: $err'),
                        ),
                      const SizedBox(height: 16),

                      // ── Tanggal Transaksi ──
                      const Text(
                        'Tanggal Transaksi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (_isLocked)
                        TextFormField(
                          controller: _tanggalReadonlyController,
                          readOnly: true,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.calendar_today),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        )
                      else
                        InkWell(
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              setState(() => _selectedDate = pickedDate);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[400]!),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  MaterialLocalizations.of(
                                    context,
                                  ).formatShortDate(_selectedDate),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // ── Pilih Kode Karung (Sack Code) ──
                      const Text(
                        'Kode Karung',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      sackSummaryState.when(
                        data: (summaryList) {
                          if (summaryList.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.orange[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber,
                                    color: Colors.orange[700],
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Tidak ada stok perca tersedia di gudang.',
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Filter: hitung sisa karung setelah dikurangi yang sudah ditambahkan
                          final filteredList =
                              summaryList.where((item) {
                                final code = item['sack_code'] as String? ?? '';
                                final totalSacks =
                                    (item['total_sacks'] as num?)?.toInt() ?? 0;
                                final alreadyAdded = _addedSacksForCode(code);
                                return (totalSacks - alreadyAdded) > 0;
                              }).toList();

                          if (filteredList.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green[700],
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Semua kode karung sudah ditambahkan ke daftar.',
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          Map<String, dynamic>? dropdownValue;
                          try {
                            dropdownValue = filteredList.firstWhere(
                              (item) => item['sack_code'] == _selectedSackCode,
                            );
                          } catch (_) {
                            dropdownValue = null;
                          }

                          return DropdownButtonFormField<Map<String, dynamic>>(
                            value: dropdownValue,
                            hint: const Text('Pilih Kode Karung'),
                            isExpanded: true,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.qr_code),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items:
                                filteredList.map<
                                  DropdownMenuItem<Map<String, dynamic>>
                                >((item) {
                                  final code =
                                      item['sack_code'] as String? ?? '-';
                                  final percaType =
                                      item['perca_type'] as String? ?? '-';
                                  final totalSacks =
                                      (item['total_sacks'] as num?)?.toInt() ??
                                      0;
                                  final totalWeight =
                                      (item['total_weight'] as num?)
                                          ?.toDouble() ??
                                      0;

                                  // Hitung sisa setelah dikurangi yang sudah ditambahkan
                                  final alreadyAdded = _addedSacksForCode(code);
                                  final remainingSacks =
                                      totalSacks - alreadyAdded;
                                  final weightPerSack =
                                      totalSacks > 0
                                          ? totalWeight / totalSacks
                                          : 0.0;
                                  final remainingWeight =
                                      weightPerSack * remainingSacks;

                                  return DropdownMenuItem<Map<String, dynamic>>(
                                    value: item,
                                    child: Text(
                                      '${_readableSackCode(code)}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                _onSackCodeSelected(value);
                              }
                            },
                            validator:
                                (value) =>
                                    value == null
                                        ? 'Kode karung tidak boleh kosong'
                                        : null,
                          );
                        },
                        loading: () => _buildLoadingDropdown('Loading stok...'),
                        error: (err, _) => _buildErrorDropdown('Error: $err'),
                      ),
                      const SizedBox(height: 12),

                      // ── Info Stok Tersedia ──
                      if (_selectedSackCode != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.inventory_2,
                                      color: Colors.blue[700],
                                      size: 28,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$_availableSacks',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[800],
                                      ),
                                    ),
                                    Text(
                                      'Karung Tersedia',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.blue[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 50,
                                color: Colors.blue[200],
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.scale,
                                      color: Colors.blue[700],
                                      size: 28,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _availableWeight.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[800],
                                      ),
                                    ),
                                    Text(
                                      'KG Total Tersedia',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.blue[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 50,
                                color: Colors.blue[200],
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.monitor_weight,
                                      color: Colors.blue[700],
                                      size: 28,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _weightPerSack.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[800],
                                      ),
                                    ),
                                    Text(
                                      'KG / Karung',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.blue[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // ── Jumlah Karung ──
                      const Text(
                        'Jumlah Karung yang Diambil',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _sackCountController,
                        decoration: InputDecoration(
                          hintText: 'Masukkan jumlah karung',
                          prefixIcon: const Icon(Icons.shopping_bag),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Jumlah karung tidak boleh kosong';
                          }
                          final count = int.tryParse(value);
                          if (count == null || count <= 0) {
                            return 'Masukkan angka yang valid';
                          }
                          if (_selectedSackCode != null &&
                              count > _availableSacks) {
                            return 'Melebihi stok tersedia ($_availableSacks karung)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // ── Auto-Sum Total Berat ──
                      if (_calculatedWeight > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calculate,
                                    color: Colors.green[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Total Berat:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${_calculatedWeight.toStringAsFixed(1)} KG',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),

                      // ── Tombol Tambah ke Daftar ──
                      ElevatedButton.icon(
                        onPressed: _addTransactionToList,
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah ke Daftar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[400],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Daftar Transaksi ──
                      if (_transactionList.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Daftar Transaksi:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${_transactionList.length} item',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...List.generate(_transactionList.length, (
                                index,
                              ) {
                                final trx = _transactionList[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  elevation: 1,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.green[100],
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[800],
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      '${_readableSackCode(trx['sackCode'] as String)} (${trx['percaType']}) — ${trx['sackCount']} karung',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${(trx['totalWeight'] as double).toStringAsFixed(1)} KG',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed:
                                          () => _removeTransaction(index),
                                    ),
                                  ),
                                );
                              }),
                              const Divider(),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total Karung:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${_transactionList.fold<int>(0, (sum, t) => sum + (t['sackCount'] as int))} karung',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total Berat:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${_transactionList.fold<double>(0, (sum, t) => sum + (t['totalWeight'] as double)).toStringAsFixed(1)} KG',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Tombol Submit ──
                        ElevatedButton.icon(
                          onPressed: _submitTransactions,
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Simpan Semua Transaksi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildLoadingDropdown(String hint) {
    return DropdownButtonFormField<String>(
      items: const [],
      onChanged: null,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildErrorDropdown(String hint) {
    return DropdownButtonFormField<String>(
      items: const [],
      onChanged: null,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
