import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
  late ChartType _selectedChartType;
  late List<MapEntry<String, Map<String, double>>> _allEntries;
  late List<MapEntry<String, Map<String, double>>> _filteredEntries;
  String? _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedChartType = ChartType.bar;
    _allEntries = _buildCompleteMonthlyEntries(widget.monthlyData);
    _filteredEntries = _allEntries;
  }

  @override
  void didUpdateWidget(covariant PercaChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.monthlyData != widget.monthlyData) {
      _allEntries = _buildCompleteMonthlyEntries(widget.monthlyData);

      final selectedStillExists =
          _selectedMonth == null ||
          _allEntries.any((entry) => entry.key == _selectedMonth);
      if (!selectedStillExists) {
        _selectedMonth = null;
      }

      _updateFilteredData();
    }
  }

  List<MapEntry<String, Map<String, double>>> _buildCompleteMonthlyEntries(
    Map<String, Map<String, double>> source,
  ) {
    if (source.isEmpty) return [];

    final parsedDates =
        source.keys
            .map(_parseMonthKey)
            .whereType<DateTime>()
            .toList()
          ..sort();

    if (parsedDates.isEmpty) {
      return source.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    }

    final firstMonth = DateTime(parsedDates.first.year, parsedDates.first.month);
    final lastMonth = DateTime(parsedDates.last.year, parsedDates.last.month);

    final complete = <MapEntry<String, Map<String, double>>>[];
    var current = firstMonth;
    while (!current.isAfter(lastMonth)) {
      final key = _monthToKey(current);
      final existing = source[key];
      complete.add(
        MapEntry(key, {
          'total': existing?['total'] ?? 0.0,
          'kain': existing?['kain'] ?? 0.0,
          'kaos': existing?['kaos'] ?? 0.0,
        }),
      );

      current = DateTime(current.year, current.month + 1);
    }

    return complete;
  }

  DateTime? _parseMonthKey(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null || month < 1 || month > 12) return null;
    return DateTime(year, month);
  }

  String _monthToKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  void _updateFilteredData() {
    if (_selectedMonth == null) {
      _filteredEntries = _allEntries;
    } else {
      // _selectedMonth is stored in YYYY-MM format; filter by exact key match.
      _filteredEntries =
          _allEntries.where((entry) => entry.key == _selectedMonth).toList();
    }
  }

  String _formatMonthLabel(String monthKey) {
    final parts = monthKey.split('-');
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = int.tryParse(parts[1]) ?? 1;
    return '${months[month]}\n${parts[0].substring(2)}';
  }

  List<String> _getMonthOptions() {
    final months = <String>{};
    for (var entry in _allEntries) {
      months.add(entry.key); // YYYY-MM format (same as map keys)
    }
    final options = months.toList()..sort();
    return options.reversed.toList();
  }

  /// Convert YYYY-MM key to Indonesian month label for display.
  String _monthKeyToLabel(String monthKey) {
    final parts = monthKey.split('-');
    if (parts.length == 2) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final monthNames = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      if (year != null && month != null && month >= 1 && month <= 12) {
        return '${monthNames[month]} $year';
      }
    }
    return monthKey;
  }

  double get _maxY {
    if (_filteredEntries.isEmpty) return 100;
    final max = _filteredEntries.fold<double>(
      0,
      (prev, entry) =>
          entry.value['total']! > prev ? entry.value['total']! : prev,
    );
    if (max <= 0) return 100;
    return (max * 1.2).ceil().toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart Type Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildChartTypeButton(
                  ChartType.bar,
                  'Bar Chart',
                  Icons.bar_chart,
                ),
                _buildChartTypeButton(
                  ChartType.pie,
                  'Pie Chart',
                  Icons.pie_chart,
                ),
                _buildChartTypeButton(
                  ChartType.line,
                  'Line Chart',
                  Icons.show_chart,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Month Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.filter_alt_outlined, size: 18, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    const Text(
                      'Filter berdasarkan bulan',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (_selectedMonth != null)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedMonth = null;
                            _updateFilteredData();
                          });
                        },
                        icon: const Icon(Icons.restart_alt, size: 16),
                        label: const Text('Reset'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildMonthFilterButton(null, 'Semua bulan'),
                    ..._getMonthOptions().map((month) {
                      return _buildMonthFilterButton(
                        month,
                        _monthKeyToLabel(month),
                      );
                    }),
                  ],
                ),
                if (_selectedMonth != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Menampilkan data: ${_monthKeyToLabel(_selectedMonth!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Statistics Info
          if (_filteredEntries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildStatisticsInfo(),
            ),
          const SizedBox(height: 20),

          // Chart Display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildChartTypeButton(ChartType type, String label, IconData icon) {
    final isSelected = _selectedChartType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChartType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[600] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green[600]! : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthFilterButton(String? month, String label) {
    final isSelected = _selectedMonth == month;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      avatar:
          isSelected ? const Icon(Icons.check_circle, size: 16, color: Colors.white) : null,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[800],
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      selectedColor: Colors.green[600],
      backgroundColor: Colors.grey[200],
      side: BorderSide(
        color: isSelected ? Colors.green[700]! : Colors.grey[300]!,
        width: 1.2,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      onSelected: (_) {
        setState(() {
          _selectedMonth = month;
          _updateFilteredData();
        });
      },
    );
  }

  Widget _buildStatisticsInfo() {
    final total = _filteredEntries.fold<double>(
      0,
      (sum, e) => sum + e.value['total']!,
    );
    final totalKain = _filteredEntries.fold<double>(
      0,
      (sum, e) => sum + (e.value['kain'] ?? 0.0),
    );
    final totalKaos = _filteredEntries.fold<double>(
      0,
      (sum, e) => sum + (e.value['kaos'] ?? 0.0),
    );

    final hasStockInfo =
        (widget.stockGudangLabel != null &&
            widget.stockGudangLabel!.trim().isNotEmpty) ||
        (widget.stockDibawaPenjahitLabel != null &&
            widget.stockDibawaPenjahitLabel!.trim().isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                'Total',
                '${total.toStringAsFixed(2)} KG',
                Colors.green[700]!,
              ),
              _buildStatCard(
                'Kain',
                '${totalKain.toStringAsFixed(2)} KG',
                Colors.blue[600]!,
              ),
              _buildStatCard(
                'Kaos',
                '${totalKaos.toStringAsFixed(2)} KG',
                Colors.orange[600]!,
              ),
            ],
          ),
          if (hasStockInfo) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Text(
              'Informasi stok saat ini',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            if (widget.stockGudangLabel != null &&
                widget.stockGudangLabel!.trim().isNotEmpty)
              _buildStockInfoTile(
                icon: Icons.warehouse_outlined,
                label: 'Stok Gudang',
                value: widget.stockGudangLabel!,
                color: Colors.green[700]!,
              ),
            if (widget.stockGudangLabel != null &&
                widget.stockGudangLabel!.trim().isNotEmpty &&
                widget.stockDibawaPenjahitLabel != null &&
                widget.stockDibawaPenjahitLabel!.trim().isNotEmpty)
              const SizedBox(height: 8),
            if (widget.stockDibawaPenjahitLabel != null &&
                widget.stockDibawaPenjahitLabel!.trim().isNotEmpty)
              _buildStockInfoTile(
                icon: Icons.local_shipping_outlined,
                label: 'Dibawa Penjahit',
                value: widget.stockDibawaPenjahitLabel!,
                color: Colors.indigo[600]!,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStockInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    if (_filteredEntries.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 40, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No data available for selected filter',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    switch (_selectedChartType) {
      case ChartType.bar:
        return _buildBarChart();
      case ChartType.pie:
        return _buildPieChart();
      case ChartType.line:
        return _buildLineChart();
    }
  }

  Widget _buildBarChart() {
    return AspectRatio(
      aspectRatio: 1.6,
      child: BarChart(
        BarChartData(
          maxY: _maxY,
          barGroups:
              _filteredEntries.asMap().entries.map((entry) {
                final total = entry.value.value['total']!;
                final kain = entry.value.value['kain'] ?? 0.0;
                final kaos = entry.value.value['kaos'] ?? 0.0;

                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: total,
                      color: Colors.transparent,
                      width: 20,
                      borderRadius: BorderRadius.circular(6),
                      rodStackItems: [
                        BarChartRodStackItem(0, kain, Colors.blue[600]!),
                        BarChartRodStackItem(
                          kain,
                          kain + kaos,
                          Colors.orange[600]!,
                        ),
                      ],
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: _maxY,
                        color: Colors.grey[200],
                      ),
                    ),
                  ],
                );
              }).toList(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= _filteredEntries.length) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _formatMonthLabel(_filteredEntries[idx].key),
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.grey[800]!,
              tooltipMargin: 10,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final k = _filteredEntries[groupIndex].value['kain'] ?? 0.0;
                final o = _filteredEntries[groupIndex].value['kaos'] ?? 0.0;
                final t = _filteredEntries[groupIndex].value['total']!;
                return BarTooltipItem(
                  'Total: ${t.toStringAsFixed(2)} KG\nKain: ${k.toStringAsFixed(2)} KG\nKaos: ${o.toStringAsFixed(2)} KG',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    final totalKain = _filteredEntries.fold<double>(
      0,
      (sum, e) => sum + (e.value['kain'] ?? 0.0),
    );
    final totalKaos = _filteredEntries.fold<double>(
      0,
      (sum, e) => sum + (e.value['kaos'] ?? 0.0),
    );
    final total = totalKain + totalKaos;

    if (total == 0) {
      return const SizedBox();
    }

    final percentageKain = (totalKain / total) * 100;
    final percentageKaos = (totalKaos / total) * 100;

    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: totalKain,
              title: 'Kain\n${percentageKain.toStringAsFixed(1)}%',
              color: Colors.blue[600],
              radius: 100,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            PieChartSectionData(
              value: totalKaos,
              title: 'Kaos\n${percentageKaos.toStringAsFixed(1)}%',
              color: Colors.orange[600],
              radius: 100,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
          centerSpaceRadius: 40,
          sectionsSpace: 2,
          pieTouchData: PieTouchData(
            enabled: true,
            touchCallback: (FlTouchEvent event, pieTouchResponse) {},
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    return AspectRatio(
      aspectRatio: 1.6,
      child: LineChart(
        LineChartData(
          maxY: _maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: _maxY / 5,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: Colors.grey[200], strokeWidth: 1);
            },
            getDrawingVerticalLine: (value) {
              return FlLine(color: Colors.grey[200], strokeWidth: 1);
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= _filteredEntries.length) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _formatMonthLabel(_filteredEntries[idx].key),
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots:
                  _filteredEntries
                      .asMap()
                      .entries
                      .map(
                        (entry) => FlSpot(
                          entry.key.toDouble(),
                          entry.value.value['total']!,
                        ),
                      )
                      .toList(),
              isCurved: true,
              color: Colors.green[600],
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: Colors.green[600]!,
                    strokeColor: Colors.white,
                    strokeWidth: 2,
                  );
                },
              ),
            ),
            LineChartBarData(
              spots:
                  _filteredEntries
                      .asMap()
                      .entries
                      .map(
                        (entry) => FlSpot(
                          entry.key.toDouble(),
                          entry.value.value['kain'] ?? 0.0,
                        ),
                      )
                      .toList(),
              isCurved: true,
              color: Colors.blue[600],
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: Colors.blue[600]!,
                    strokeColor: Colors.white,
                    strokeWidth: 2,
                  );
                },
              ),
            ),
            LineChartBarData(
              spots:
                  _filteredEntries
                      .asMap()
                      .entries
                      .map(
                        (entry) => FlSpot(
                          entry.key.toDouble(),
                          entry.value.value['kaos'] ?? 0.0,
                        ),
                      )
                      .toList(),
              isCurved: true,
              color: Colors.orange[600],
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: Colors.orange[600]!,
                    strokeColor: Colors.white,
                    strokeWidth: 2,
                  );
                },
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => Colors.grey[800]!,
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final title =
                      barSpot.barIndex == 0
                          ? 'Total'
                          : barSpot.barIndex == 1
                          ? 'Kain'
                          : 'Kaos';
                  return LineTooltipItem(
                    '$title: ${barSpot.y.toStringAsFixed(2)} KG',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
