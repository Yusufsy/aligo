import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:aligo/models/inventory.dart';

class InventoryChart extends StatelessWidget {
  final List<Inventory> data;

  const InventoryChart({Key? key, required this.data}) : super(key: key);

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
                "Inventory",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: SfCartesianChart(
                  primaryXAxis: const CategoryAxis(),
                  series: <CartesianSeries>[
                    BarSeries<Inventory, String>(
                      dataSource: data,
                      xValueMapper: (Inventory inventory, _) => inventory.brand,
                      yValueMapper: (Inventory inventory, _) =>
                          int.parse(inventory.quantity),
                      color: Colors.blue,
                      // Customize the color
                      dataLabelSettings: const DataLabelSettings(
                        isVisible: true,
                      ),
                    )
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
