import 'package:flutter/services.dart';
import 'package:ibtc/DbTables/invoice-table.dart';
import 'package:ibtc/DbTables/product-item-table.dart';
import 'package:ibtc/reusable/utils.dart';
import 'package:indian_currency_to_word/indian_currency_to_word.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class Service {
  static Future<void> generateInvoice(
      Invoice data, List<ProductItem> productList) async {
    //Create a PDF document.
    final PdfDocument document = PdfDocument();
    //Add page to the PDF
    final PdfPage page = document.pages.add();
    //Get page client size
    final Size pageSize = page.getClientSize();
    //Draw rectangle
    page.graphics.drawRectangle(
      bounds: Rect.fromLTWH(0, 0, pageSize.width, pageSize.height),
    );
    //Generate PDF grid.
    final PdfGrid grid = getGrid(productList);
    //Draw the header section by creating text element
    final PdfLayoutResult result = await drawHeader(page, pageSize, grid, data);
    //Draw grid
    drawGrid(page, grid, result, data, productList);
    //Add invoice footer
    await drawFooter(page, pageSize,productList.length);
    //Save the PDF document
    final List<int> bytes = document.saveSync();
    //Dispose the document.
    document.dispose();
    //Save and launch the file.
    await Utils.downloadPdfFiles(
        bytes: bytes, invoiceNumber: data.invoiceNumber);
  }

  //Draws the invoice header
  static Future<PdfLayoutResult> drawHeader(
      PdfPage page, Size pageSize, PdfGrid grid, Invoice data) async {
    //Draw rectangle
    final ByteData imageDataByteData =
        await rootBundle.load('assets/header.png');
    final Uint8List imageData = imageDataByteData.buffer.asUint8List();
    final PdfBitmap image = PdfBitmap(imageData);

    page.graphics.drawImage(image, Rect.fromLTWH(0, 0, pageSize.width, 90));
    final PdfFont contentFont = PdfStandardFont(PdfFontFamily.helvetica, 9);
    final PdfFont boldContentFont =
        PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.bold);
    final DateFormat format = DateFormat('dd/MM/yyyy');
    final String invoiceNumber =
        'Date: ${format.format(DateTime.parse(data.date))}\r\n\r\nInvoice No: ${data.invoiceNumber}';
    final Size contentSize = contentFont.measureString(invoiceNumber);
    // ignore: leading_newlines_in_multiline_strings
    String address = '''${data.customerName}, 
        \r\n${data.customerAddress}''';

    PdfTextElement(text: "CASH INVOICE", font: boldContentFont).draw(
        page: page,
        bounds: Rect.fromLTWH(pageSize.width - (contentSize.width + 200), 110,
            contentSize.width + 30, pageSize.height - 120));

    PdfTextElement(text: invoiceNumber, font: contentFont).draw(
        page: page,
        bounds: Rect.fromLTWH(pageSize.width - (contentSize.width + 30), 120,
            contentSize.width + 30, pageSize.height - 120));

    return PdfTextElement(text: address, font: contentFont).draw(
        page: page,
        bounds: Rect.fromLTWH(30, 120,
            pageSize.width - (contentSize.width + 30), pageSize.height - 120))!;
  }

  //Draws the grid
  static void drawGrid(PdfPage page, PdfGrid grid, PdfLayoutResult result,
      Invoice data, List<ProductItem> productList) {
    //Invoke the beginCellLayout event.
    grid.beginCellLayout = (Object sender, PdfGridBeginCellLayoutArgs args) {
      final PdfGrid grid = sender as PdfGrid;
      if (args.cellIndex == grid.columns.count - 1) {
      } else if (args.cellIndex == grid.columns.count - 2) {}
    };
    //Draw the PDF grid and get the result.
    result = grid.draw(
        page: page, bounds: Rect.fromLTWH(0, result.bounds.bottom + 40, 0, 0))!;
  }

  //Draw the invoice footer data.
  static Future<void> drawFooter(PdfPage page, Size pageSize, productCount) async {
    final PdfPen linePen =
        PdfPen(PdfColor(0, 0, 0), dashStyle: PdfDashStyle.dash);
    //Draw line
    final PdfFont contentFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      9,
    );
    PdfFont boldItalicFont =
        PdfTrueTypeFont(await _getFontData('Helvetica BoldOblique.ttf'), 12);
    const String footerContent =
        '''Tel: +974 70503855, P.O.Box: 20228, C.R. No: 75133. Doha-Q\nEmail: Indianbrothers.qa@gmail.com''';

    page.graphics.drawString(
      footerContent,
      contentFont,
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
      bounds: Rect.fromLTWH(30, pageSize.height - (productCount > 20 ? 30 : 70), pageSize.width - 60, 0),
    );

    page.graphics.drawLine(
      linePen,
      Offset(0, (pageSize.height - (productCount > 20 ? 60 : 100))),
      Offset(pageSize.width, pageSize.height - (productCount > 20 ? 60 : 100)),
    );

    page.graphics.drawString(
      'Thank You For Your Business!',
      boldItalicFont,
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
      bounds: Rect.fromLTWH(30, pageSize.height - (productCount > 20 ? 90 :130), pageSize.width - 60, 0),
    );
  }

  //Create PDF grid and return
  static PdfGrid getGrid(List<ProductItem> productList) {
    // Create a PDF grid
    final PdfGrid grid = PdfGrid();
    // Specify the columns count for the grid.
    grid.columns.add(count: 4);
    // Create the header row of the grid.
    final PdfGridRow headerRow = grid.headers.add(1)[0];
    // Set style for header row
    headerRow.style.backgroundBrush = PdfSolidBrush(PdfColor(56, 78, 133));
    headerRow.style.textBrush = PdfBrushes.white;
    headerRow.style.font =
        PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold);

    headerRow.cells[0].value = 'Description';
    headerRow.cells[1].value = 'Qty';
    headerRow.cells[1].style = PdfGridCellStyle(
        format: PdfStringFormat(alignment: PdfTextAlignment.center));
    headerRow.cells[2].value = 'Unit Price';
    headerRow.cells[2].style = PdfGridCellStyle(
        format: PdfStringFormat(alignment: PdfTextAlignment.center));
    headerRow.cells[3].value = 'Total';
    headerRow.cells[3].style = PdfGridCellStyle(
        format: PdfStringFormat(alignment: PdfTextAlignment.center));

    // Add rows
    for (int i = 0; i < productList.length; i++) {
      var item = productList[i];
      addProducts(item.name!, item.quantity!, item.price!,
          (item.quantity! * item.price!), grid);
    }

    for (int i = 0; i < 30 - (productList.length - 1); i++) {
      if(productList.length < 15) {
        addEmptyRows(grid);
      }
    }
    insertSubtotal(productList, grid);
    insertTotalInWords(productList, grid);

    // Set grid columns width
    grid.columns[0].width = 350;

    for (int i = 0; i < headerRow.cells.count; i++) {
      headerRow.cells[i].style.cellPadding =
          PdfPaddings(bottom: 0, left: 5, right: 5, top: 3);
    }

    for (int i = 0; i < grid.rows.count; i++) {
      final PdfGridRow row = grid.rows[i];
      for (int j = 0; j < row.cells.count; j++) {
        final PdfGridCell cell = row.cells[j];
        if(i < productList.length || i == grid.rows.count-1 || i == grid.rows.count -2) {
          cell.style.cellPadding =
              PdfPaddings(bottom: 0, left: 5, right: 5, top: 3);
        } else {
          cell.style.cellPadding =
              PdfPaddings(bottom: 5, left: 5, right: 5, top: 5);
        }
        if (i % 2 == 1 && i != grid.rows.count - 1) {
          cell.style.backgroundBrush = PdfSolidBrush(PdfColor(240, 240, 240));
        }
      }
    }

    return grid;
  }

  static void addEmptyRows(PdfGrid grid) {
    final PdfGridRow row = grid.rows.add();
    for (int i = 0; i < row.cells.count; i++) {
      if (i != 0 && i != 3) {
        row.cells[i].style = PdfGridCellStyle(
            borders: PdfBorders(
                left: PdfPen.fromBrush(PdfSolidBrush(PdfColor(0, 0, 0)),
                    width: 1),
                right: PdfPen.fromBrush(PdfSolidBrush(PdfColor(0, 0, 0)),
                    width: 1),
                top: PdfPen.fromBrush(PdfSolidBrush(PdfColor(255, 255, 255)),
                    width: 0),
                bottom: PdfPen.fromBrush(PdfSolidBrush(PdfColor(255, 255, 255)),
                    width: 0)));
      } else if (i == 0) {
        row.cells[i].style = PdfGridCellStyle(
            borders: PdfBorders(
                left: PdfPen.fromBrush(PdfSolidBrush(PdfColor(0, 0, 0)),
                    width: 1),
                right: PdfPen.fromBrush(PdfSolidBrush(PdfColor(0, 0, 0)),
                    width: 1),
                top: PdfPen.fromBrush(PdfSolidBrush(PdfColor(255, 255, 255)),
                    width: 0),
                bottom:
                    PdfPen.fromBrush(PdfSolidBrush(PdfColor(255, 255, 255)))));
      } else if (i == 3) {
        row.cells[i].style = PdfGridCellStyle(
            borders: PdfBorders(
                right: PdfPen.fromBrush(PdfSolidBrush(PdfColor(0, 0, 0)),
                    width: 1),
                left: PdfPen.fromBrush(PdfSolidBrush(PdfColor(0, 0, 0)),
                    width: 1),
                top: PdfPen.fromBrush(PdfSolidBrush(PdfColor(255, 255, 255)),
                    width: 0),
                bottom:
                    PdfPen.fromBrush(PdfSolidBrush(PdfColor(255, 255, 255)))));
      }
    }
  }

  //Create and row for the grid.
  static void addProducts(String productName, int quantity, double price,
      double total, PdfGrid grid) {
    final PdfGridRow row = grid.rows.add();
    row.cells[0].value = productName;
    row.cells[1].value = quantity.toString();
    row.cells[1].style = PdfGridCellStyle(
        format: PdfStringFormat(alignment: PdfTextAlignment.center));
    row.cells[2].value = price.toString().replaceAll(RegExp(r'\.0*$'), '');
    row.cells[2].style = PdfGridCellStyle(
        format: PdfStringFormat(alignment: PdfTextAlignment.center));
    row.cells[3].value = total.toString().replaceAll(RegExp(r'\.0*$'), '');
    row.cells[3].style = PdfGridCellStyle(
        format: PdfStringFormat(alignment: PdfTextAlignment.center));
  }

  //Get the total amount.
  static double getTotalAmount(List<ProductItem> productList) {
    double total = 0;
    for (int i = 0; i < productList.length; i++) {
      total += (productList[i].quantity! * productList[i].price!);
    }
    return total;
  }

  // static Future<void> saveAndLaunchFile(
  //     List<int> bytes, String fileName) async {
  //   try {
  //     // Get the temporary directory for the device
  //     final directory = await getTemporaryDirectory();
  //
  //     // Create a file in the temporary directory with the given filename
  //     final file = File('${directory.path}/$fileName');
  //
  //     // Write the PDF bytes to the file
  //     await file.writeAsBytes(bytes);
  //
  //     // Platform-specific code to open the file using the default viewer
  //     final result = await OpenFile.open(file.path);
  //     if (result.type != ResultType.done) {
  //       // Handle the case when the file couldn't be opened
  //       if (kDebugMode) {
  //         print("Error opening file: ${result.message}");
  //       }
  //     }
  //   } catch (e) {
  //     // Handle any errors that occur during the process
  //     if (kDebugMode) {
  //       print("Error saving and launching file: $e");
  //     }
  //   }
  // }

  static void insertSubtotal(List<ProductItem> productList, PdfGrid grid) {
    final PdfGridRow row = grid.rows.add();
    row.cells[0].value = "";
    row.cells[1].value = "";
    row.cells[2].value = "";
    row.cells[3].value =
        getTotalAmount(productList).toString().replaceAll(RegExp(r'\.0*$'), '');
    row.cells[3].style = PdfGridCellStyle(
        format: PdfStringFormat(alignment: PdfTextAlignment.center));
  }

  static void insertTotalInWords(List<ProductItem> productList, PdfGrid grid) {
    final converter = AmountToWords();
    var word = converter
        .convertAmountToWords(getTotalAmount(productList), ignoreDecimal: false)
        .replaceAll("  Rupees", "");
    final PdfGridRow row = grid.rows.add();
    row.cells[0].value = "Total QR. $word only";
    row.cells[0].style.font =
        PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold);
    row.cells[1].value = "";
    row.cells[2].value = "Subtotal";
    row.cells[2].style.font =
        PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold);
    row.cells[3].style = PdfGridCellStyle(
        format: PdfStringFormat(alignment: PdfTextAlignment.center));
    row.cells[3].value =
        getTotalAmount(productList).toString().replaceAll(RegExp(r'\.0*$'), '');
    row.cells[3].style = PdfGridCellStyle(
        format: PdfStringFormat(alignment: PdfTextAlignment.center));
    row.cells[3].style.font =
        PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold);
  }

  static Future<List<int>> _getFontData(String fontFileName) async {
    ByteData fontData = await rootBundle.load('fonts/$fontFileName');
    return fontData.buffer.asUint8List();
  }

}
