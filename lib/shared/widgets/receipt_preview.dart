import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class ReceiptLineItem {
  final String name;
  final int qty;
  final double price;

  const ReceiptLineItem({
    required this.name,
    required this.qty,
    required this.price,
  });

  double get total => qty * price;
}

class ReceiptPreview extends StatelessWidget {
  final String pharmacyName;
  final String? address;
  final String? phone;
  final String invoiceNumber;
  final DateTime? date;
  final String? cashierName;
  final List<ReceiptLineItem> items;
  final double subtotal;
  final double discount;
  final double total;
  final String? footer;

  const ReceiptPreview({
    super.key,
    required this.pharmacyName,
    this.address,
    this.phone,
    required this.invoiceNumber,
    this.date,
    this.cashierName,
    required this.items,
    required this.subtotal,
    this.discount = 0.0,
    required this.total,
    this.footer,
  });

  Widget _buildDashedDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boxWidth = constraints.constrainWidth();
          const dashWidth = 4.0;
          const dashSpace = 3.0;
          final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
          return Flex(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            direction: Axis.horizontal,
            children: List.generate(dashCount, (_) {
              return const SizedBox(
                width: dashWidth,
                height: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0xFF6B7280)),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveDate = date ?? DateTime.now();
    final formattedDate =
        '${effectiveDate.day.toString().padLeft(2, '0')}/${effectiveDate.month.toString().padLeft(2, '0')}/${effectiveDate.year} ${effectiveDate.hour.toString().padLeft(2, '0')}:${effectiveDate.minute.toString().padLeft(2, '0')}';

    const monoStyle = TextStyle(
      fontFamily: 'Courier',
      fontSize: 12,
      height: 1.7,
      color: Color(0xFF111827),
      letterSpacing: -0.2,
    );

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 290),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadiusTokens.square),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Centered Header
            Text(
              pharmacyName,
              textAlign: TextAlign.center,
              style: monoStyle.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (address != null && address!.isNotEmpty)
              Text(
                address!,
                textAlign: TextAlign.center,
                style: monoStyle.copyWith(fontSize: 11),
              ),
            if (phone != null && phone!.isNotEmpty)
              Text(
                'Tel: $phone',
                textAlign: TextAlign.center,
                style: monoStyle.copyWith(fontSize: 11),
              ),
            _buildDashedDivider(),

            // Meta
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Inv: #$invoiceNumber', style: monoStyle),
                Text(formattedDate, style: monoStyle.copyWith(fontSize: 11)),
              ],
            ),
            if (cashierName != null)
              Text('Cashier: $cashierName', style: monoStyle),
            _buildDashedDivider(),

            // Items List
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.qty}x ${item.name}',
                          style: monoStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rs ${item.total.toStringAsFixed(0)}',
                        style: monoStyle,
                      ),
                    ],
                  ),
                )),
            _buildDashedDivider(),

            // Subtotal & Discount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal', style: monoStyle),
                Text('Rs ${subtotal.toStringAsFixed(0)}', style: monoStyle),
              ],
            ),
            if (discount > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Discount', style: monoStyle),
                  Text('-Rs ${discount.toStringAsFixed(0)}', style: monoStyle),
                ],
              ),
            _buildDashedDivider(),

            // Bold TOTAL
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL',
                  style: monoStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Rs ${total.toStringAsFixed(0)}',
                  style: monoStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            _buildDashedDivider(),

            // Centered Footer
            Text(
              footer ?? 'Thank you for your visit!\nGoods once sold are not returnable.',
              textAlign: TextAlign.center,
              style: monoStyle.copyWith(fontSize: 11, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

