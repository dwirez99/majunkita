import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'perca_stock_data.dart';

export 'perca_stock_data.dart';

enum ChartType { bar, pie, line }

class PercaChartWidget extends StatefulWidget {
  final Map<String, Map<String, double>> monthlyData;
  final String? stockGudangLabel;
  final String? stockDibawaPenjahitLabel;

  const PercaChartWidget({
    super.key,
    required this.monthlyData,
    this.stockGudangLabel,
    this.stockDibawaPenjahitLabel,
  });

  @override
  State<PercaChartWidget> createState() => _PercaChartWidgetState();
}

class _PercaChartWidgetState extends State<PercaChartWidget> {
  ChartType _chartType = ChartType.bar;
  List<PercaStockData> _allData = [];
  List<PercaStockData> _filtered = [];

  // Bar/Line: rentang bulan terakhir
  DateRangeFilter _rangeFilter = DateRangeFilter.last6Months;
  // Pie: Hierarki Tahun → Bulan (null = default ke terbaru)
  int? _selectedYear;
  int? _selectedMonth; // 1–12
  // Bar: index yang di-tap untuk drill-down summary
  int? _drillIndex;

  // ── lifecycle ──────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _rebuildData();
  }

  @override
  void didUpdateWidget(covariant PercaChartWidget old) {
    super.didUpdateWidget(old);
    if (old.monthlyData != widget.monthlyData) _rebuildData();
  }

  // ── data preparation (tidak di dalam build) ────────────────

  void _rebuildData() {
    // Parse dan sort semua entri ke PercaStockData
    final parsed = widget.monthlyData.entries
        .map((e) => PercaStockData.fromMapEntry(e.key, e.value))
        .toList()
      ..sort((a, b) => a.period.compareTo(b.period));

    // Isi bulan kosong agar garis kontinu
    _allData = _fillGaps(parsed);

    // Default pie filter ke tahun & bulan terbaru yang tersedia.
    // Hanya reset jika kombinasi (year, month) saat ini sudah tidak valid.
    final availYears = _availableYears;
    if (availYears.isNotEmpty) {
      if (_selectedYear == null || !availYears.contains(_selectedYear)) {
        _selectedYear = availYears.last; // tahun terbaru
      }
      final monthsInYear = _monthsForYear(_selectedYear!);
      if (_selectedMonth == null || !monthsInYear.contains(_selectedMonth)) {
        _selectedMonth = monthsInYear.last; // bulan terbaru di tahun itu
      }
    }

    _applyFilter();
  }

  List<PercaStockData> _fillGaps(List<PercaStockData> src) {
    if (src.isEmpty) return [];
    final result = <PercaStockData>[];
    var cur = DateTime(src.first.period.year, src.first.period.month);
    final last = src.last.period;
    while (!cur.isAfter(last)) {
      final found = src.firstWhere(
        (d) => d.period.year == cur.year && d.period.month == cur.month,
        orElse: () => PercaStockData(period: cur, total: 0, kain: 0, kaos: 0),
      );
      result.add(found);
      cur = DateTime(cur.year, cur.month + 1);
    }
    return result;
  }

  // Sinkronisasi filter ↔ chart type
  void _applyFilter() {
    if (_chartType == ChartType.pie) {
      // Pie: filter berdasarkan kombinasi tahun + bulan yang dipilih
      _filtered = _allData.where((d) =>
        d.period.year == _selectedYear &&
        d.period.month == _selectedMonth
      ).toList();
    } else {
      // Bar/Line: N bulan terakhir
      final cutoff = DateTime.now();
      final from = DateTime(
          cutoff.year, cutoff.month - _rangeFilter.months + 1);
      _filtered = _allData.where((d) => !d.period.isBefore(from)).toList();
    }
    _drillIndex = null;
  }

  // ── pie filter helpers ─────────────────────────────────────

  /// Daftar tahun unik yang tersedia di _allData, diurutkan ascending.
  List<int> get _availableYears {
    final years = _allData.map((d) => d.period.year).toSet().toList()..sort();
    return years;
  }

  /// Daftar bulan (1–12) yang memiliki data nyata di tahun tertentu.
  /// Bulan tanpa data (zero-fill) tetap disertakan agar grid 12 bulan
  /// selalu tampil lengkap — chip-nya hanya dibuat disabled.
  List<int> get _allMonths => List.generate(12, (i) => i + 1);

  /// Bulan yang memiliki data > 0 untuk tahun tertentu.
  List<int> _monthsForYear(int year) {
    return _allData
        .where((d) => d.period.year == year && d.total > 0)
        .map((d) => d.period.month)
        .toSet()
        .toList()
      ..sort();
  }

  // ── summary helpers ────────────────────────────────────────

  // Data yang ditampilkan di summary (bar drill-down atau seluruh filter)
  List<PercaStockData> get _summaryData {
    if (_chartType == ChartType.bar &&
        _drillIndex != null &&
        _drillIndex! < _filtered.length) {
      return [_filtered[_drillIndex!]];
    }
    return _filtered;
  }

  double get _sumTotal => _summaryData.fold(0, (s, d) => s + d.total);
  double get _sumKain => _summaryData.fold(0, (s, d) => s + d.kain);
  double get _sumKaos => _summaryData.fold(0, (s, d) => s + d.kaos);

  // Tren: bandingkan periode sebelumnya
  double? get _prevTotal {
    if (_filtered.isEmpty || _chartType == ChartType.pie) return null;
    final cnt = _filtered.length;
    final prev = _allData.reversed
        .where((d) => !_filtered.contains(d))
        .take(cnt)
        .fold(0.0, (s, d) => s + d.total);
    return prev;
  }

  double get _maxY {
    if (_filtered.isEmpty) return 100;
    final m = _filtered.fold(0.0, (p, d) => d.total > p ? d.total : p);
    return m <= 0 ? 100 : (m * 1.25).ceilToDouble();
  }

  // ── build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChartTypeSelector(),
          const SizedBox(height: 16),
          _buildSmartFilter(),
          const SizedBox(height: 16),
          _buildSummaryCards(),
          const SizedBox(height: 16),
          _buildChartArea(),
          const SizedBox(height: 8),
          if (_filtered.isNotEmpty && _chartType != ChartType.pie)
            _buildLegend(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── chart type selector ────────────────────────────────────

  Widget _buildChartTypeSelector() {
    return Row(
      children: ChartType.values.map((t) {
        final sel = _chartType == t;
        final (icon, label) = switch (t) {
          ChartType.bar => (Icons.bar_chart, 'Bar'),
          ChartType.pie => (Icons.pie_chart, 'Pie'),
          ChartType.line => (Icons.show_chart, 'Line'),
        };
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _chartType = t;
              _applyFilter();
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: sel ? Colors.green[700] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                boxShadow: sel
                    ? [BoxShadow(color: Colors.green.withValues(alpha:0.35), blurRadius: 8, offset: const Offset(0, 3))]
                    : [],
              ),
              child: Column(
                children: [
                  Icon(icon, size: 22, color: sel ? Colors.white : Colors.grey[600]),
                  const SizedBox(height: 4),
                  Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : Colors.grey[600])),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── smart filter (sinkron dengan chart type) ───────────────

  Widget _buildSmartFilter() {
    if (_chartType == ChartType.pie) {
      // Pie → hierarki tahun ➔ bulan
      return _buildHierarchicalPieFilter();
    } else {
      // Bar / Line → pilih rentang
      return _buildRangeFilter();
    }
  }

  Widget _buildRangeFilter() {
    final note = _chartType == ChartType.line
        ? 'Filter rentang aktif — filter bulan tunggal dinonaktifkan untuk trendline'
        : 'Tap bar untuk drill-down ringkasan';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.date_range, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text('Rentang Waktu',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey[800])),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: DateRangeFilter.values.map((r) {
            final sel = _rangeFilter == r;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(r.label),
                selected: sel,
                showCheckmark: false,
                selectedColor: Colors.green[700],
                backgroundColor: Colors.grey[100],
                labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : Colors.grey[700]),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onSelected: (_) => setState(() {
                  _rangeFilter = r;
                  _applyFilter();
                }),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Text(note, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic)),
      ],
    );
  }

  // Hierarki Tahun ➔ Bulan untuk Pie Chart.
  // Step 1: user pilih tahun via ChoiceChip row.
  // Step 2: grid 12 bulan tetap (Jan–Des) muncul di bawah;
  //         bulan tanpa data di-disable secara visual.
  Widget _buildHierarchicalPieFilter() {
    final years = _availableYears;
    const monthShort = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
                        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final activeMonths = _selectedYear != null
        ? _monthsForYear(_selectedYear!)
        : <int>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        Row(
          children: [
            Icon(Icons.calendar_month, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text('Pilih Periode',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey[800])),
            const SizedBox(width: 4),
            Text('(komposisi satu titik waktu)',
                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
        const SizedBox(height: 10),

        // ── Step 1: Tahun ──
        Text('Tahun', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[600])),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: years.reversed.map((y) {
              final sel = _selectedYear == y;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('$y'),
                  selected: sel,
                  showCheckmark: false,
                  selectedColor: Colors.green[700],
                  backgroundColor: Colors.grey[100],
                  labelStyle: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : Colors.grey[700]),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onSelected: (_) => setState(() {
                    _selectedYear = y;
                    // Saat tahun berganti, default ke bulan terbaru yang ada datanya
                    final months = _monthsForYear(y);
                    _selectedMonth = months.isNotEmpty ? months.last : 1;
                    _applyFilter();
                  }),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // ── Step 2: Bulan (grid 12) ──
        Text('Bulan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[600])),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _allMonths.map((m) {
            final hasData = activeMonths.contains(m);
            final sel = _selectedMonth == m && _selectedYear != null;
            return ChoiceChip(
              label: Text(monthShort[m]),
              selected: sel,
              showCheckmark: false,
              // Bulan tanpa data di-disable agar tidak menyesatkan user
              selectedColor: Colors.green[700],
              disabledColor: Colors.grey[200],
              backgroundColor: Colors.grey[100],
              labelStyle: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: sel
                      ? Colors.white
                      : hasData ? Colors.grey[700] : Colors.grey[400]),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: hasData
                  ? (_) => setState(() {
                        _selectedMonth = m;
                        _applyFilter();
                      })
                  : null,
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── summary cards dengan trend indicator ──────────────────

  Widget _buildSummaryCards() {
    final prev = _prevTotal;
    final trend = prev != null && prev > 0
        ? ((_sumTotal - prev) / prev * 100)
        : null;
    final isDrilling = _chartType == ChartType.bar && _drillIndex != null;
    final subtitle = isDrilling
        ? 'Data: ${_filtered[_drillIndex!].longLabel}'
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[50]!, Colors.teal[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Ringkasan',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey[700])),
              const Spacer(),
              if (trend != null) _buildTrendBadge(trend),
              if (isDrilling) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() => _drillIndex = null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Reset Drill',
                        style: TextStyle(fontSize: 10, color: Colors.orange[800], fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(fontSize: 11, color: Colors.green[700], fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard('Total', _sumTotal, Colors.green[700]!),
              _buildStatCard('Kain', _sumKain, Colors.blue[600]!),
              _buildStatCard('Kaos', _sumKaos, Colors.orange[600]!),
            ],
          ),
          if (widget.stockGudangLabel != null || widget.stockDibawaPenjahitLabel != null) ...[
            const Divider(height: 20),
            Text('Stok Saat Ini',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[600])),
            const SizedBox(height: 8),
            if (widget.stockGudangLabel?.isNotEmpty == true)
              _buildStockTile(Icons.warehouse_outlined, 'Gudang', widget.stockGudangLabel!, Colors.green[700]!),
            if (widget.stockDibawaPenjahitLabel?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              _buildStockTile(Icons.local_shipping_outlined, 'Dibawa Penjahit',
                  widget.stockDibawaPenjahitLabel!, Colors.indigo[600]!),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTrendBadge(double trend) {
    final up = trend >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: up ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(up ? Icons.arrow_upward : Icons.arrow_downward,
              size: 12, color: up ? Colors.green[700] : Colors.red[700]),
          const SizedBox(width: 2),
          Text('${trend.abs().toStringAsFixed(1)}%',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: up ? Colors.green[700] : Colors.red[700])),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, double value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text('${value.toStringAsFixed(1)} kg',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildStockTile(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600))),
          Text(value, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ── chart area ─────────────────────────────────────────────

  Widget _buildChartArea() {
    if (_filtered.isEmpty) return _buildEmptyState();
    return switch (_chartType) {
      ChartType.bar => _buildBarChart(),
      ChartType.pie => _buildPieChart(),
      ChartType.line => _buildLineChart(),
    };
  }

  Widget _buildEmptyState() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[350]),
          const SizedBox(height: 12),
          Text('Tidak ada data untuk periode ini',
              style: TextStyle(fontSize: 14, color: Colors.grey[500], fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Coba ubah filter atau pilih bulan lain',
              style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        ],
      ),
    );
  }

  // ── bar chart ──────────────────────────────────────────────

  Widget _buildBarChart() {
    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          maxY: _maxY,
          barGroups: _filtered.asMap().entries.map((e) {
            final d = e.value;
            final index = e.key;
            final tapped = _drillIndex == index;
            // Dim bars yang tidak dipilih saat drill-down aktif
            final alpha = (_drillIndex == null || _drillIndex == index) ? 1.0 : 0.3;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: d.total,
                  width: 18,
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.transparent,
                  rodStackItems: [
                    BarChartRodStackItem(0, d.kain, Colors.blue[600]!.withValues(alpha: alpha)),
                    BarChartRodStackItem(d.kain, d.kain + d.kaos, Colors.orange[600]!.withValues(alpha: alpha)),
                  ],
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true, toY: _maxY, color: Colors.grey[100]!.withValues(alpha: alpha)),
                ),
              ],
              showingTooltipIndicators: tapped ? [0] : [],
            );
          }).toList(),
          titlesData: _axisTitles(_filtered),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            enabled: true,
            touchCallback: (event, resp) {
              if (event is FlTapUpEvent && resp?.spot != null) {
                setState(() {
                  final tapped = resp!.spot!.touchedBarGroupIndex;
                  _drillIndex = _drillIndex == tapped ? null : tapped;
                });
              }
            },
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.grey[850]!,
              getTooltipItem: (g, gi, rod, ri) {
                final d = _filtered[gi];
                return BarTooltipItem(
                  '${d.longLabel}\nTotal: ${d.total.toStringAsFixed(1)} kg\nKain: ${d.kain.toStringAsFixed(1)} | Kaos: ${d.kaos.toStringAsFixed(1)}',
                  const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ── pie chart ──────────────────────────────────────────────

  Widget _buildPieChart() {
    final d = _filtered.isNotEmpty ? _filtered.first : null;
    if (d == null || (d.kain + d.kaos) == 0) {
      return _buildEmptyState();
    }
    final total = d.kain + d.kaos;
    // Pastikan total di pie == kain + kaos (tidak menggunakan d.total secara langsung)
    final pctKain = d.kain / total * 100;
    final pctKaos = d.kaos / total * 100;

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.3,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: d.kain,
                  title: 'Kain\n${pctKain.toStringAsFixed(1)}%',
                  color: Colors.blue[600],
                  radius: 100,
                  titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                PieChartSectionData(
                  value: d.kaos,
                  title: 'Kaos\n${pctKaos.toStringAsFixed(1)}%',
                  color: Colors.orange[600],
                  radius: 100,
                  titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
              centerSpaceRadius: 36,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Total: ${total.toStringAsFixed(1)} kg  (Kain ${d.kain.toStringAsFixed(1)} + Kaos ${d.kaos.toStringAsFixed(1)})',
          style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // ── line chart ─────────────────────────────────────────────

  Widget _buildLineChart() {
    FlSpot spot(int i, double v) => FlSpot(i.toDouble(), v);
    final entries = _filtered.asMap().entries;

    return AspectRatio(
      aspectRatio: 1.5,
      child: LineChart(
        LineChartData(
          maxY: _maxY,
          minY: 0,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _maxY / 5,
            getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey[200]!, strokeWidth: 1),
          ),
          titlesData: _axisTitles(_filtered),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            _lineBar(entries.map((e) => spot(e.key, e.value.total)).toList(), Colors.green[700]!),
            _lineBar(entries.map((e) => spot(e.key, e.value.kain)).toList(), Colors.blue[600]!),
            _lineBar(entries.map((e) => spot(e.key, e.value.kaos)).toList(), Colors.orange[600]!),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => Colors.grey[850]!,
              getTooltipItems: (spots) => spots.map((s) {
                final lbl = ['Total', 'Kain', 'Kaos'][s.barIndex];
                return LineTooltipItem('$lbl: ${s.y.toStringAsFixed(1)} kg',
                    const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600));
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  LineChartBarData _lineBar(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (_, p, bar, idx) =>
            FlDotCirclePainter(radius: 4, color: color, strokeColor: Colors.white, strokeWidth: 2),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.06),
      ),
    );
  }

  // ── shared axis titles ─────────────────────────────────────

  FlTitlesData _axisTitles(List<PercaStockData> data) {
    return FlTitlesData(
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 36,
          getTitlesWidget: (v, _) =>
              Text('${v.toInt()}', style: const TextStyle(fontSize: 9)),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 38,
          getTitlesWidget: (v, _) {
            final i = v.toInt();
            if (i < 0 || i >= data.length) return const SizedBox();
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(data[i].shortLabel,
                  style: const TextStyle(fontSize: 9), textAlign: TextAlign.center),
            );
          },
        ),
      ),
    );
  }

  // ── legend ─────────────────────────────────────────────────

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _dot('Total', Colors.green[700]!),
        const SizedBox(width: 16),
        _dot('Kain', Colors.blue[600]!),
        const SizedBox(width: 16),
        _dot('Kaos', Colors.orange[600]!),
      ],
    );
  }

  Widget _dot(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w600)),
      ],
    );
  }
}
