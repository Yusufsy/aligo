import 'package:aligo/models/disbursement.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

class SalesChart extends StatelessWidget {
  final List<DisbursementRecord> data;

  const SalesChart({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<charts.Series<DisbursementRecord, String>> series = [
      charts.Series(
        id: "disbursements",
        data: data,
        domainFn: (DisbursementRecord series, _) => series.brand,
        measureFn: (DisbursementRecord series, _) => int.parse(series.quantity),
        // colorFn: (Inventory series, _) => Colors.blue,
      )
    ];

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
              ),
              Expanded(
                child: charts.BarChart(series, animate: true),
              )
            ],
          ),
        ),
      ),
    );
  }
}
