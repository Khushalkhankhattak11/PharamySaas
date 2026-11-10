import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

enum LabelLayoutType {
  thermal50x30('50 x 30 mm Thermal Label'),
  roll80mm('80 mm Roll'),
  a4Sheet('A4 Sheet Grid');

  final String label;
  const LabelLayoutType(this.label);
}

class QrLabelItem {
  final String medicineName;
  final String qrCode;
  final double price;
  final String currency;
  final String? batchNo;
  final String? expiryDate;
  final int copies;

  const QrLabelItem({
    required this.medicineName,
    required this.qrCode,
    required this.price,
    this.currency = 'USD',
    this.batchNo,
    this.expiryDate,
    this.copies = 1,
  });
}

class QrLabelService {
  static Future<Uint8List> generateLabelsPdf({
    required List<QrLabelItem> items,
    required LabelLayoutType layout,
  }) async {
    final pdf = pw.Document();

    if (layout == LabelLayoutType.thermal50x30) {
      // 50mm x 30mm page format (approx 141.7 x 85.0 points)
      const pageFormat = PdfPageFormat(50 * PdfPageFormat.mm, 30 * PdfPageFormat.mm, marginAll: 2 * PdfPageFormat.mm);

      for (final item in items) {
        for (int i = 0; i < item.copies; i++) {
          pdf.addPage(
            pw.Page(
              pageFormat: pageFormat,
              build: (pw.Context context) {
                return pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 58,
                      height: 58,
                      child: pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: item.qrCode,
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(
                            item.medicineName,
                            maxLines: 2,
                            overflow: pw.TextOverflow.clip,
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Price: ${item.currency} ${item.price.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
                          ),
                          if (item.batchNo != null) ...[
                            pw.Text(
                              'B: ${item.batchNo}',
                              style: const pw.TextStyle(fontSize: 6),
                            ),
                          ],
                          if (item.expiryDate != null) ...[
                            pw.Text(
                              'Exp: ${item.expiryDate}',
                              style: const pw.TextStyle(fontSize: 6),
                            ),
                          ],
                          pw.Text(
                            item.qrCode,
                            style: const pw.TextStyle(fontSize: 5, color: PdfColors.grey700),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        }
      }
    } else if (layout == LabelLayoutType.roll80mm) {
      // 80mm roll width, roll length can fit multiple labels
      const pageFormat = PdfPageFormat(80 * PdfPageFormat.mm, 120 * PdfPageFormat.mm, marginAll: 4 * PdfPageFormat.mm);

      for (final item in items) {
        for (int i = 0; i < item.copies; i++) {
          pdf.addPage(
            pw.Page(
              pageFormat: pageFormat,
              build: (pw.Context context) {
                return pw.Center(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        item.medicineName,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Container(
                        width: 100,
                        height: 100,
                        child: pw.BarcodeWidget(
                          barcode: pw.Barcode.qrCode(),
                          data: item.qrCode,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        '${item.currency} ${item.price.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                      if (item.batchNo != null)
                        pw.Text('Batch: ${item.batchNo} | Exp: ${item.expiryDate ?? ''}',
                            style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(item.qrCode, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    ],
                  ),
                );
              },
            ),
          );
        }
      }
    } else {
      // A4 Grid Sheet (3 columns x 7 rows = 21 labels per page)
      final allLabels = <QrLabelItem>[];
      for (final item in items) {
        for (int i = 0; i < item.copies; i++) {
          allLabels.add(item);
        }
      }

      const labelsPerPage = 21;
      for (int i = 0; i < allLabels.length; i += labelsPerPage) {
        final pageItems = allLabels.skip(i).take(labelsPerPage).toList();

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(10 * PdfPageFormat.mm),
            build: (pw.Context context) {
              return pw.GridView(
                crossAxisCount: 3,
                childAspectRatio: 2.2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: pageItems.map((lbl) {
                  return pw.Container(
                    padding: const pw.EdgeInsets.all(4),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Container(
                          width: 45,
                          height: 45,
                          child: pw.BarcodeWidget(
                            barcode: pw.Barcode.qrCode(),
                            data: lbl.qrCode,
                          ),
                        ),
                        pw.SizedBox(width: 4),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(
                                lbl.medicineName,
                                maxLines: 1,
                                overflow: pw.TextOverflow.clip,
                                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                              ),
                              pw.Text(
                                '${lbl.currency} ${lbl.price.toStringAsFixed(2)}',
                                style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
                              ),
                              if (lbl.batchNo != null)
                                pw.Text('B: ${lbl.batchNo}', style: const pw.TextStyle(fontSize: 6)),
                              if (lbl.expiryDate != null)
                                pw.Text('Exp: ${lbl.expiryDate}', style: const pw.TextStyle(fontSize: 6)),
                              pw.Text(lbl.qrCode, style: const pw.TextStyle(fontSize: 5, color: PdfColors.grey700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        );
      }
    }

    return await pdf.save();
  }

  static Future<void> printOrPreview({
    required List<QrLabelItem> items,
    required LabelLayoutType layout,
  }) async {
    final pdfBytes = await generateLabelsPdf(items: items, layout: layout);
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: 'PharmaCare_Labels.pdf',
    );
  }
}

