import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:gas_detector_app/widgets/gas_gauge.dart';
import 'package:gas_detector_app/widgets/quick_stats.dart';
import 'package:gas_detector_app/models/sensor_data_model.dart';
import 'package:gas_detector_app/utils/theme.dart';
import 'package:gas_detector_app/models/device_model.dart'; // Ensure path is correct
import 'package:gas_detector_app/widgets/device_card.dart'; // Ensure path is correct

void main() {
  // 1. Test the GasGauge Widget
  testWidgets('GasGauge displays correct PPM value and gauge',
      (WidgetTester tester) async {
    const testValue = 350.0;

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GasGauge(value: testValue),
        ),
      ),
    );

    // Verify the text "350" exists
    expect(find.text('350'), findsOneWidget);
    // Verify the Gauge widget is rendered
    expect(find.byType(SfRadialGauge), findsOneWidget);
  });

  // 2. Test the QuickStats Widget (Colors and Status)
  testWidgets('QuickStats shows "High" status for 600 PPM',
      (WidgetTester tester) async {
    final sensorData = SensorData(
      lpg: 600.0,
      lpgRaw: 1024, // Added
      status: 'High', // Added
      statusCode: 2, // Added
      timestamp: DateTime.now(), // Added
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickStats(sensorData: sensorData),
        ),
      ),
    );

    // Verify status text
    expect(find.text('High'), findsOneWidget);

    // Verify the value color matches Danger color
    final textWidget = tester.widget<Text>(find.text('600'));
    expect(textWidget.style?.color, isSameColorAs(AppTheme.dangerStatusColor));
  });

  // 3. Test the DeviceCard Status Indicator
  testWidgets('DeviceCard shows green indicator when online',
      (WidgetTester tester) async {
    // Mock your Device model here
    final onlineDevice =
        Device(name: "Kitchen", isOnline: true, location: "Main House");

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeviceCard(device: onlineDevice, onTap: () {}),
        ),
      ),
    );

    // Find the status indicator Container by checking its color
    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(DeviceCard),
            matching: find.byType(Container),
          )
          .first,
    );

    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, isSameColorAs(AppTheme.successColor));
  });
}
