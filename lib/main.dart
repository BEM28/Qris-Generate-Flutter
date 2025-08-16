import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qristes/helper.dart';

void main() => runApp(const MaterialApp(home: DemoPage()));

class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: isi dengan RAW QRIS STATIS hasil scan poster/print (string panjang TLV)
    const staticQrisFromScan = "";

    // contoh nominal: 25000 (tanpa titik/koma)
    const amount = "25000";

    String? qrDynamic;
    String? err;
    try {
      qrDynamic = buildDynamicQris(staticQrisFromScan, amount);
    } catch (e) {
      err = e.toString();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('QRIS Dynamic')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (qrDynamic != null) ...[
                QrImageView(data: qrDynamic, size: 260),
                const SizedBox(height: 16),
                const Text("Scan pakai GoPay/OVO/DANA, nominal ke-lock."),
              ] else ...[
                const Text("Gagal generate dynamic QRIS"),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
