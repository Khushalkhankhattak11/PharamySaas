import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class AppTableColumn {
  final String label;
  final TextAlign align;
  final int flex;
  final double? width;

  const AppTableColumn({
    required this.label,
    this.align = TextAlign.left,
    this.flex = 1,
    this.width,
  });
}

class AppDataTable extends StatelessWidget {
  final List<AppTableColumn> columns;
  final List<List<Widget>> rows;
  final List<Widget>? mobileCards;
  final double minWidth;

  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.mobileCards,
    this.minWidth = 600.0,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isPhone = MediaQuery.of(context).size.width < 600;

    if (isPhone && mobileCards != null && mobileCards!.isNotEmpty) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: mobileCards!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, idx) => mobileCards![idx],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: tokens.colors.line, width: 1),
                ),
              ),
              child: Row(
                children: columns.map((col) {
                  Widget headerCell = Text(
                    col.label,
                    textAlign: col.align,
                    style: tokens.typography.tableHeader,
                  );

                  if (col.width != null) {
                    return SizedBox(width: col.width, child: headerCell);
                  }
                  return Expanded(flex: col.flex, child: headerCell);
                }).toList(),
              ),
            ),
            // Rows
            ...rows.asMap().entries.map((entry) {
              final idx = entry.key;
              final rowCells = entry.value;
              final isLast = idx == rows.length - 1;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(color: tokens.colors.line, width: 1),
                        ),
                ),
                child: Row(
                  children: rowCells.asMap().entries.map((cellEntry) {
                    final colIdx = cellEntry.key;
                    final cellWidget = cellEntry.value;
                    final col = colIdx < columns.length ? columns[colIdx] : null;

                    if (col?.width != null) {
                      return SizedBox(width: col!.width, child: cellWidget);
                    }
                    return Expanded(
                      flex: col?.flex ?? 1,
                      child: cellWidget,
                    );
                  }).toList(),
                ),
              );
            }),
          ],
        );

        if (constraints.maxWidth < minWidth) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: minWidth,
              child: tableWidget,
            ),
          );
        }

        return tableWidget;
      },
    );
  }
}

