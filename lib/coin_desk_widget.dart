import 'dart:async';

import 'package:bueno_tracker/coin_desk_api.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CoinDeskScreen extends StatefulWidget {
  const CoinDeskScreen({super.key});

  @override
  State<CoinDeskScreen> createState() => _CoinDeskScreenState();
}

class _CoinDeskScreenState extends State<CoinDeskScreen> {
  late Map<String, dynamic> _data = {};
  late Map<String, dynamic> _historicalData = {};
  late List<FlSpot> _dataPoints = [];
  late String _startDate;
  late String _endDate;
  late Timer _timer;

  String _selectedCurrency = 'EUR';

  @override
  void initState() {
    super.initState();

    final lastThreeMonthts = getLastThreeMonths();

    _startDate = lastThreeMonthts.values.last;
    _endDate = lastThreeMonthts.values.first;

    fetchCurrentPrice();
    fetchHistoricalPrice();

    _timer = Timer.periodic(const Duration(seconds: 30), (Timer timer) async {
      fetchCurrentPrice();
      fetchHistoricalPrice();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> fetchCurrentPrice() async {
    try {
      final newData = await CoinDeskApi.fetchData();
      setState(() {
        _data = newData;
      });
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  Future<void> fetchHistoricalPrice() async {
    try {
      final newData = await CoinDeskApi.fetchHistoricalData(
        start: _startDate,
        end: _endDate,
        currency: _selectedCurrency,
      );
      List<FlSpot> dataPoints = [];
      newData['bpi'].forEach((key, value) {
        double price = double.parse(value.toString());
        dataPoints.add(FlSpot(dataPoints.length.toDouble(), price));
      });
      setState(() {
        _historicalData = newData;
        _dataPoints = dataPoints;
      });
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  double getMonthNumberFromDate(String dateString) {
    List<String> parts = dateString.split("-");
    String monthString = parts[1];
    return double.parse(monthString);
  }

  List<Color> gradientColors = [
    Colors.cyan.shade300,
    Colors.blue.shade500,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade400,
      resizeToAvoidBottomInset: false,
      body: InkWell(
        onTap: _showCurrencyDialog,
        child: Center(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _data == {}
                    ? const Center(child: CircularProgressIndicator())
                    : _data.isEmpty
                        ? const Center(child: Text('No data available'))
                        : Center(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Text(
                                //     'Bitcoin Price: ${_data['bpi'][_selectedCurrency]['rate']} ${_data['bpi'][_selectedCurrency]['description']}'),
                                // Text('Last Updated: ${_data['time']['updated']}'),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      "${_selectedCurrency == 'EUR' ? '€' : _selectedCurrency == 'USD' ? '\$' : _selectedCurrency == 'GBP' ? '£' : ''} ${_data['bpi'][_selectedCurrency]['rate']}",
                                      style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width *
                                                0.14,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                _historicalData == {}
                    ? const Center(child: CircularProgressIndicator())
                    : _dataPoints.isEmpty
                        ? Container()
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: AspectRatio(
                                  aspectRatio: 1.2,
                                  child: LineChart(
                                    LineChartData(
                                      gridData: FlGridData(show: false),
                                      titlesData: FlTitlesData(show: false),
                                      borderData: FlBorderData(show: false),
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: _dataPoints,
                                          isCurved: true,
                                          color: Colors.blue,
                                          barWidth: 10,
                                          isStrokeCapRound: false,
                                          belowBarData:
                                              BarAreaData(show: false),
                                          preventCurveOverShooting: true,
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.grey.shade500,
                                              Colors.grey.shade600,
                                              Colors.blue.shade800,
                                            ],
                                          ),
                                        ),
                                      ],
                                      minY: 0, // titlesInLines: false,
                                      minX: 0,
                                      maxX: _dataPoints.length.toDouble() - 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, String> getLastThreeMonths() {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    final List<String> monthNames = [
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

    Map<String, String> lastThreeMonths = {};

    for (int i = 0; i < 3; i++) {
      int month = currentMonth - i;
      int year = currentYear;

      if (month <= 0) {
        month += 12;
        year--;
      }

      final date = DateTime(year, month);
      final monthName = monthNames[month - 1];
      final isoDate = date.toIso8601String().substring(0, 10);

      lastThreeMonths[monthName] = isoDate;
    }

    return lastThreeMonths;
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Currency:'),
          content: SizedBox(
            height: 100,
            width: 200,
            child: DropdownButton<String>(
              value: _selectedCurrency,
              items: _data['bpi']
                  .keys
                  .map<DropdownMenuItem<String>>((String currency) {
                return DropdownMenuItem<String>(
                  value: currency,
                  child: Text(currency),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCurrency = newValue!;
                });
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
  }
}
