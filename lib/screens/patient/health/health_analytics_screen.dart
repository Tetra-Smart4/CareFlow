import 'package:flutter/material.dart';

class HealthAnalyticsScreen extends StatelessWidget {
  const HealthAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: ['7 Days', '30 Days', '3 Months', '1 Year']
                .map(
                  (period) => ChoiceChip(
                    label: Text(period),
                    selected: period == '30 Days',
                    onSelected: (_) {},
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Blood Pressure',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '122 / 80',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 150,
                    child: CustomPaint(painter: _ChartPainter()),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const ListTile(
            title: Text('Trend'),
            subtitle: Text('Recent readings are stable.'),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final points = [
      Offset(0, size.height * .72),
      Offset(size.width * .15, size.height * .62),
      Offset(size.width * .28, size.height * .70),
      Offset(size.width * .45, size.height * .48),
      Offset(size.width * .60, size.height * .58),
      Offset(size.width * .75, size.height * .35),
      Offset(size.width * .92, size.height * .42),
    ];

    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
