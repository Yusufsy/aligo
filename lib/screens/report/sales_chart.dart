import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:aligo/models/disbursement.dart';

class SalesChart extends StatelessWidget {
  final List<DisbursementRecord> data;

  const SalesChart({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(25),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(9.0),
          child: Column(
            children: <Widget>[
              const Text(
                "Disbursements per product in the past 30 days",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: SfCartesianChart(
                  primaryXAxis: CategoryAxis(),
                  series: <CartesianSeries>[
                    BarSeries<DisbursementRecord, String>(
                      dataSource: data,
                      xValueMapper: (DisbursementRecord record, _) =>
                          record.brand,
                      yValueMapper: (DisbursementRecord record, _) =>
                          int.parse(record.quantity),
                      color: Colors.blue,
                      // Customize the color of the bars
                      dataLabelSettings: const DataLabelSettings(
                        isVisible: true, // Show values on top of the bars
                      ),
                    ),
                  ],
                  enableAxisAnimation: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
