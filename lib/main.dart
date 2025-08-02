import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(MaterialApp(home: PrinterPage()));
}

class PrinterPage extends StatefulWidget {
  @override
  _PrinterPageState createState() => _PrinterPageState();
}

class _PrinterPageState extends State<PrinterPage> {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> devices = [];
  BluetoothDevice? selectedDevice;
  bool connected = false;

  @override
  void initState() {
    super.initState();
    initBluetooth();
  }

  void initBluetooth() async {
    final List<BluetoothDevice> pairedDevices = await bluetooth
        .getBondedDevices();
    setState(() {
      devices = pairedDevices;
    });

    bluetooth.isConnected.then((isConnected) {
      setState(() {
        connected = isConnected ?? false;
      });
    });
  }

  void connect() async {
    if (selectedDevice == null) return;
    await bluetooth.connect(selectedDevice!);
    setState(() => connected = true);
  }

  void disconnect() {
    bluetooth.disconnect();
    setState(() => connected = false);
  }

  void printReceipt() async {
    if (!connected) return;

    final ByteData bytes = await rootBundle.load('assets/images/logo.png');
    final Uint8List imageBytes = bytes.buffer.asUint8List();
    final img.Image? original = img.decodeImage(imageBytes);
    if (original != null) {
      // Lebar total kertas printer (biasanya 384px atau 576px tergantung printer)
      const int paperWidth = 384;

      // Buat canvas baru dengan background putih dan ukuran sesuai printer
      final img.Image centeredImage = img.Image(paperWidth, original.height);
      img.fill(centeredImage, img.getColor(255, 255, 255)); // Putih

      // Hitung posisi gambar supaya di tengah
      final int x = ((paperWidth - original.width) / 2).round();

      // Tempelkan gambar asli ke tengah canvas
      img.copyInto(centeredImage, original, dstX: x);

      // Encode kembali ke PNG
      final Uint8List printableBytes = Uint8List.fromList(
        img.encodePng(centeredImage),
      );
      bluetooth.printImageBytes(printableBytes);
    }

    bluetooth.printNewLine();
    bluetooth.printCustom("Jl. Kendalsari", 1, 1);
    bluetooth.printNewLine();

    bluetooth.printLeftRight("Tanggal:", "25/03/2022 13:38:53", 1);
    bluetooth.printLeftRight("Faktur:", "JL/002042203251338/002", 1);
    bluetooth.printLeftRight("Bill:", "BILL/002042203251033/001", 1);
    bluetooth.printLeftRight("Kepada:", "Meja 1", 1);
    bluetooth.printLeftRight("Kasir:", "Kasir Cafe Mojo / Indra", 1);
    bluetooth.printNewLine();

    bluetooth.printCustom("=== DINE IN ===", 1, 1);
    bluetooth.printLeftRight("Indomie Goreng", "", 1);
    bluetooth.printLeftRight("1 x 4.545,45", "4.545,45", 1);
    bluetooth.printLeftRight("Indomie Kari Ayam", "", 1);
    bluetooth.printLeftRight("1 x 4.545,45", "4.545,45", 1);
    bluetooth.printNewLine();

    bluetooth.printLeftRight("Subtotal", "9.090,90", 1);
    bluetooth.printLeftRight("PPN", "909,10", 1);
    bluetooth.printLeftRight("TOTAL", "10.000", 2);
    bluetooth.printLeftRight("Bayar", "10.000", 1);
    bluetooth.printNewLine();

    bluetooth.printCustom("::Terima Kasih atas kunjungan anda::", 1, 1);
    bluetooth.printCustom("::Barang yg sudah dibeli tdk dpt tukar::", 1, 1);
    bluetooth.printNewLine();
    bluetooth.paperCut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Bluetooth Printer")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<BluetoothDevice>(
              hint: Text("Pilih Printer"),
              value: selectedDevice,
              onChanged: (device) => setState(() => selectedDevice = device),
              items: devices
                  .map(
                    (d) =>
                        DropdownMenuItem(value: d, child: Text(d.name ?? "")),
                  )
                  .toList(),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(onPressed: connect, child: Text("Hubungkan")),
                SizedBox(width: 10),
                ElevatedButton(onPressed: disconnect, child: Text("Putuskan")),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: connected ? printReceipt : null,
              child: Text("🖨️ Cetak Nota"),
            ),
          ],
        ),
      ),
    );
  }
}
