import 'package:flutter/material.dart';

// import your real helper:
import 'package:aligo/helpers/inventory_helper.dart';

/// Simple model for the horizontal summary
class ProductSummary {
  final String name;
  final int qty;

  ProductSummary({required this.name, required this.qty});
}

/// ---- Drop this widget into your Home page where the "per-product summary" goes.
class PerProductHorizontalSummary extends StatelessWidget {
  final Future<List<ProductSummary>> summariesFuture;

  const PerProductHorizontalSummary({
    Key? key,
    required this.summariesFuture,
  }) : super(key: key);

  Color _bgForQty(int q) {
    if (q <= 5) return const Color(0xFFE53935); // red
    if (q <= 10) return const Color(0xFFFFC107); // amber
    return const Color(0xFF9E9E9E); // grey
  }

  Color _fgForQty(int q) {
    if (q <= 5) return Colors.white;
    if (q <= 10) return Colors.black87;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    // keep the whole strip RTL like your mock
    return Directionality(
      textDirection: TextDirection.rtl,
      child: FutureBuilder<List<ProductSummary>>(
        future: summariesFuture,
        initialData: const [],
        builder: (ctx, snap) {
          final items = snap.data ?? const <ProductSummary>[];
          if (snap.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 76,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          if (items.isEmpty) {
            return const SizedBox(
              height: 76,
              child: Center(child: Text('لا توجد بيانات مخزون')),
            );
          }

          return SizedBox(
            height: 76, // matches compact chips row in the mock
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final p = items[i];
                final bg = _bgForQty(p.qty);
                final fg = _fgForQty(p.qty);

                return Container(
                  width: 96, // compact tile width similar to design
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DefaultTextStyle(
                    style: TextStyle(color: fg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // two-line product name, centered
                        Text(
                          p.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // quantity (bold)
                        Text(
                          p.qty.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
