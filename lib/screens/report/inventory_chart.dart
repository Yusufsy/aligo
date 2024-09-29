import 'package:flutter/material.dart';
import 'package:aligo/models/inventory.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class InventoryChart extends StatelessWidget {
  final List<Inventory> data;

  const InventoryChart({Key? key, required this.data}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    List<charts.Series<Inventory, String>> series = [
      charts.Series(
        id: "inventory",
        data: data,
        domainFn: (Inventory series, _) => series.brand,
        measureFn: (Inventory series, _) => int.parse(series.quantity),
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
                "Inventory",
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