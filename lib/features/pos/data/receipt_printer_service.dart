import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../shared/models/pharmacy_model.dart';
import '../../../shared/models/sale_model.dart';

class ReceiptPrinterService {
  static Future<Uint8List> generateReceiptPdf({
    required SaleModel sale,
    required PharmacyModel pharmacy,
    bool is80mm = true,
  }) async {
    final pdf = pw.Document();

    final pageFormat = is80mm
        ? const PdfPageFormat(
            80 * PdfPageFormat.mm,
            double.infinity,
            marginAll: 4 * PdfPageFormat.mm,
          )
        : PdfPageFormat.a4;

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final formattedDate = dateFormat.format(sale.createdAt);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header
              pw.Text(
                pharmacy.name,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: is80mm ? 14 : 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (pharmacy.address != null) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  pharmacy.address!,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: is80mm ? 8 : 10),
                ),
              ],
              if (pharmacy.phone != null) ...[
                pw.Text(
                  'Tel: ${pharmacy.phone}',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: is80mm ? 8 : 10),
                ),
              ],
              if (pharmacy.licenseNo != null) ...[
                pw.Text(
                  'Licence: ${pharmacy.licenseNo}',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: is80mm ? 7 : 9, color: PdfColors.grey700),
                ),
              ],
              if (pharmacy.receiptHeader != null && pharmacy.receiptHeader!.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  pharmacy.receiptHeader!,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: is80mm ? 8 : 10, fontStyle: pw.FontStyle.italic),
                ),
              ],
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 0.5),

              // Invoice Metadata
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Invoice #: ${sale.invoiceNo}', style: pw.TextStyle(fontSize: is80mm ? 9 : 11, fontWeight: pw.FontWeight.bold)),
                  pw.Text(formattedDate, style: pw.TextStyle(fontSize: is80mm ? 8 : 10)),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Customer: ${sale.customerName}', style: pw.TextStyle(fontSize: is80mm ? 8 : 10)),
                  pw.Text('Cashier: ${sale.cashierName ?? 'Staff'}', style: pw.TextStyle(fontSize: is80mm ? 8 : 10)),
                ],
              ),
              pw.Divider(thickness: 0.5),

              // Table Headers
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 5,
                    child: pw.Text('Item Description', style: pw.TextStyle(fontSize: is80mm ? 8 : 10, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('Qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: is80mm ? 8 : 10, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('Price', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: is80mm ? 8 : 10, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('Total', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: is80mm ? 8 : 10, fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),

              // Items
              ...sale.items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 5,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(item.medicineName, style: pw.TextStyle(fontSize: is80mm ? 8 : 10, fontWeight: pw.FontWeight.bold)),
                            if (item.batchNo != null)
                              pw.Text('Batch: ${item.batchNo}', style: pw.TextStyle(fontSize: is80mm ? 6 : 8, color: PdfColors.grey700)),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text('${item.quantity}', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: is80mm ? 8 : 10)),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(item.unitPrice.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: is80mm ? 8 : 10)),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(item.total.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: is80mm ? 8 : 10, fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }),

              pw.Divider(thickness: 0.5),

              // Summary
              _buildSummaryRow('Subtotal:', '${pharmacy.currency} ${sale.subtotal.toStringAsFixed(2)}', is80mm),
              if (sale.discount > 0)
                _buildSummaryRow('Discount:', '- ${pharmacy.currency} ${sale.discount.toStringAsFixed(2)}', is80mm),
              pw.SizedBox(height: 2),
              _buildSummaryRow(
                'Grand Total:',
                '${pharmacy.currency} ${sale.total.toStringAsFixed(2)}',
                is80mm,
                isBold: true,
              ),
              pw.SizedBox(height: 2),
              _buildSummaryRow('Payment Method:', sale.paymentMethod, is80mm),

              pw.Divider(thickness: 0.5),

              // Invoice QR Code for quick reprint lookup
              pw.SizedBox(height: 4),
              pw.Container(
                width: 60,
                height: 60,
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: 'INV-${sale.invoiceNo}',
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text('Scan to Reprint: INV-${sale.invoiceNo}', style: pw.TextStyle(fontSize: is80mm ? 6 : 8, color: PdfColors.grey600)),

              // Footer
              if (pharmacy.receiptFooter != null && pharmacy.receiptFooter!.isNotEmpty) ...[
                pw.SizedBox(height: 6),
                pw.Text(
                  pharmacy.receiptFooter!,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: is80mm ? 7 : 9),
                ),
              ],
              pw.SizedBox(height: 4),
              pw.Text('Powered by PharmaCare SaaS', style: pw.TextStyle(fontSize: is80mm ? 6 : 8, color: PdfColors.grey500)),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  static pw.Widget _buildSummaryRow(String label, String value, bool is80mm, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: is80mm ? (isBold ? 10 : 8) : (isBold ? 12 : 10),
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: is80mm ? (isBold ? 11 : 8) : (isBold ? 13 : 10),
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> printReceipt({
    required SaleModel sale,
    required PharmacyModel pharmacy,
  }) async {
    final pdfBytes = await generateReceiptPdf(sale: sale, pharmacy: pharmacy);

    // On Web and Mobile: uses Printing.layoutPdf which natively triggers
    // browser print preview dialog on Web and system print service on mobile/desktop
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: 'Receipt_${sale.invoiceNo}.pdf',
    );
  }
}

