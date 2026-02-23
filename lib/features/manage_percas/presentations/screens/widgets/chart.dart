import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

enum ChartType { bar, pie, line }

class PercaChartWidget extends StatefulWidget {
  final Map<String, double> monthlyData;

  const PercaChartWidget({
    super.key,
    required this.monthlyData,
  });

  @override
  State<PercaChartWidget> createState() => _PercaChartWidgetState();
}

class _PercaChartWidgetState extends State<PercaChartWidget> {
  late ChartType _selectedChartType;
  late List<MapEntry<String, double>> _allEntries;
  late List<MapEntry<String, double>> _filteredEntries;
  String? _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedChartType = ChartType.bar;
    _allEntries = widget.monthlyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    _filteredEntries = _allEntries;
  }

  void _updateFilteredData() {
    if (_selectedMonth == null) {
      _filteredEntries = _allEntries;
    } else {
      _filteredEntries = _allEntries
          .where((entry) => entry.key.contains(_selectedMonth!))
          .toList();
    }
    setState(() {});
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
      'Dec'
    ];
    final month = int.tryParse(parts[1]) ?? 1;
    return '${months[month]}\n${parts[0].substring(2)}';
  }

  List<String> _getMonthOptions() {
    final months = <String>{};
    for (var entry in _allEntries) {
      final parts = entry.key.split('-');
      months.add('${parts[1]}/${parts[0]}');
    }
    return months.toList()..sort();
  }

  double get _maxY {
    if (_filteredEntries.isEmpty) return 100;
    final max = _filteredEntries.fold<double>(
        0, (prev, entry) => entry.value > prev ? entry.value : prev);
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
                const Text(
                  'Filter berdasarkan bulan:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildMonthFilterButton(null, 'semua bulan'),
                      ..._getMonthOptions().map((month) {
                        return _buildMonthFilterButton(month, month);
                      }),
                    ],
                  ),
                ),
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
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMonth = month;
          });
          _updateFilteredData();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green[600] : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsInfo() {
    final total = _filteredEntries.fold<double>(0, (sum, e) => sum + e.value);
    final average = _filteredEntries.isEmpty ? 0 : total / _filteredEntries.length;
    final maxValue = _filteredEntries.fold<double>(
        0, (max, e) => e.value > max ? e.value : max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('Total', '${total.toStringAsFixed(2)} KG', Colors.blue),
          _buildStatCard(
              'Rata-rata', '${average.toStringAsFixed(2)} KG', Colors.orange),
          _buildStatCard('Max', '${maxValue.toStringAsFixed(2)} KG', Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
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
          barGroups: _filteredEntries.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value,
                  color: Colors.green[600],
                  width: 20,
                  borderRadius: BorderRadius.circular(6),
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
                  if (idx < 0 || idx >= _filteredEntries.length) return const SizedBox();
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
              tooltipBgColor: Colors.grey[800]!,
              tooltipRoundedRadius: 8,
              tooltipMargin: 10,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${_filteredEntries[groupIndex].value.toStringAsFixed(2)} KG',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    final total = _filteredEntries.fold<double>(0, (sum, e) => sum + e.value);

    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          sections: _filteredEntries.asMap().entries.map((entry) {
            final percentage = (entry.value.value / total) * 100;
            final colors = [
              Colors.green[600],
              Colors.green[500],
              Colors.green[400],
              Colors.blue[600],
              Colors.orange[600],
            ];
            return PieChartSectionData(
              value: entry.value.value,
              title: '${percentage.toStringAsFixed(1)}%',
              color: colors[entry.key % colors.length],
              radius: 100,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            );
          }).toList(),
          centerSpaceRadius: 40,
          sectionsSpace: 2,
          pieTouchData: PieTouchData(
            enabled: true,
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              // Optional: Handle touch events
            },
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
              return FlLine(
                color: Colors.grey[200],
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey[200],
                strokeWidth: 1,
              );
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
                  if (idx < 0 || idx >= _filteredEntries.length) return const SizedBox();
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
              spots: _filteredEntries
                  .asMap()
                  .entries
                  .map((entry) => FlSpot(entry.key.toDouble(), entry.value.value))
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
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green[200]!.withValues(alpha: 0.3),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.grey[800]!,
              tooltipRoundedRadius: 8,
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  return LineTooltipItem(
                    '${barSpot.y.toStringAsFixed(2)} KG',
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
