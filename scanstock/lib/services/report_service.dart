import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';
import '../models/producto.dart';

class SaveResult {
  final File file;
  final String displayPath;
  final String folderName;

  SaveResult({
    required this.file,
    required this.displayPath,
    required this.folderName,
  });
}

class ReportService {
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  static const String _appFolderName = 'ScanStock';

  Future<Directory> _getReportsDirectory() async {
    Directory baseDir;

    if (Platform.isAndroid) {
      // En Android, usar el directorio externo de la app (accesible desde archivos)
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        // Subir niveles para llegar a un directorio más accesible
        // /storage/emulated/0/Android/data/com.scanstock.scanstock/files
        // Lo dejamos ahí pero creamos subcarpeta ScanStock/Reportes
        baseDir = externalDir;
      } else {
        baseDir = await getApplicationDocumentsDirectory();
      }
    } else {
      // En iOS, usar documentos (accesible desde Files app)
      baseDir = await getApplicationDocumentsDirectory();
    }

    // Crear carpeta ScanStock/Reportes
    final reportsDir = Directory('${baseDir.path}/$_appFolderName/Reportes');
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }

    return reportsDir;
  }

  String _getDisplayPath(String fullPath) {
    if (Platform.isAndroid) {
      // Mostrar ruta simplificada para Android
      if (fullPath.contains('Android/data')) {
        final parts = fullPath.split('Android/data');
        if (parts.length > 1) {
          return 'Android/data${parts[1]}';
        }
      }
      return fullPath.split('/').skip(3).join('/');
    } else {
      // Para iOS mostrar solo la parte relevante
      return '$_appFolderName/Reportes/${fullPath.split('/').last}';
    }
  }

  Future<File> generatePdfReport(List<Producto> productos) async {
    final pdf = pw.Document();

    final now = DateTime.now();
    final totalProducts = productos.length;
    final totalValue = productos.fold<double>(0, (sum, p) => sum + p.precio);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader(now),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          _buildPdfSummary(totalProducts, totalValue),
          pw.SizedBox(height: 20),
          _buildPdfTable(productos),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final fileName = 'inventario_${DateFormat('yyyyMMdd_HHmmss').format(now)}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  pw.Widget _buildPdfHeader(DateTime date) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'ScanStock',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.Text(
              'Reporte de Inventario',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Generado: ${_dateFormat.format(date)}',
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey700,
          ),
        ),
        pw.Divider(thickness: 2, color: PdfColors.blue800),
        pw.SizedBox(height: 10),
      ],
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Pagina ${context.pageNumber} de ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
      ),
    );
  }

  pw.Widget _buildPdfSummary(int totalProducts, double totalValue) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total Productos', totalProducts.toString()),
          _buildSummaryItem('Valor Total', _currencyFormat.format(totalValue)),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  pw.Widget _buildPdfTable(List<Producto> productos) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
      headerHeight: 30,
      cellHeight: 25,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerRight,
      },
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(3),
        3: const pw.FlexColumnWidth(1.5),
      },
      headers: ['Codigo', 'Nombre', 'Descripcion', 'Precio'],
      data: productos.map((p) => [
        p.codigoBarras,
        p.nombre,
        p.descripcion ?? '-',
        _currencyFormat.format(p.precio),
      ]).toList(),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
    );
  }

  Future<File> generateExcelReport(List<Producto> productos) async {
    final excel = Excel.createExcel();
    final sheet = excel['Inventario'];

    excel.setDefaultSheet('Inventario');
    excel.delete('Sheet1');

    final headerStyle = CellStyle(
      backgroundColorHex: ExcelColor.blue600,
      fontColorHex: ExcelColor.white,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );

    final headers = ['Codigo de Barras', 'Nombre', 'Descripcion', 'Precio'];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    sheet.setColumnWidth(0, 20);
    sheet.setColumnWidth(1, 30);
    sheet.setColumnWidth(2, 40);
    sheet.setColumnWidth(3, 15);

    for (var i = 0; i < productos.length; i++) {
      final p = productos[i];
      final row = i + 1;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue(p.codigoBarras);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
        .value = TextCellValue(p.nombre);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
        .value = TextCellValue(p.descripcion ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
        .value = DoubleCellValue(p.precio);
    }

    final summaryRow = productos.length + 2;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: summaryRow))
      .value = TextCellValue('TOTAL:');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: summaryRow))
      .cellStyle = CellStyle(bold: true);

    final totalValue = productos.fold<double>(0, (sum, p) => sum + p.precio);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: summaryRow))
      .value = DoubleCellValue(totalValue);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: summaryRow))
      .cellStyle = CellStyle(bold: true);

    final output = await getTemporaryDirectory();
    final now = DateTime.now();
    final fileName = 'inventario_${DateFormat('yyyyMMdd_HHmmss').format(now)}.xlsx';
    final file = File('${output.path}/$fileName');

    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }

    return file;
  }

  Future<void> shareFile(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Reporte de Inventario - ScanStock',
    );
  }

  Future<void> openFile(File file) async {
    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done) {
      throw Exception(result.message);
    }
  }

  Future<SaveResult> saveToDevice(File file) async {
    final reportsDir = await _getReportsDirectory();
    final fileName = file.path.split('/').last;
    final newPath = '${reportsDir.path}/$fileName';

    final savedFile = await file.copy(newPath);
    final displayPath = _getDisplayPath(savedFile.path);

    return SaveResult(
      file: savedFile,
      displayPath: displayPath,
      folderName: '$_appFolderName/Reportes',
    );
  }

  Future<List<File>> getSavedReports() async {
    try {
      final reportsDir = await _getReportsDirectory();
      final files = await reportsDir.list().toList();

      return files
          .whereType<File>()
          .where((f) => f.path.endsWith('.pdf') || f.path.endsWith('.xlsx'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path)); // Más recientes primero
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteReport(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  String getFileType(File file) {
    if (file.path.endsWith('.pdf')) return 'PDF';
    if (file.path.endsWith('.xlsx')) return 'Excel';
    return 'Archivo';
  }

  String getFileName(File file) {
    return file.path.split('/').last;
  }

  String getHowToAccess() {
    if (Platform.isAndroid) {
      return 'Abre la app "Archivos" o cualquier explorador de archivos y busca la carpeta de la aplicacion ScanStock';
    } else {
      return 'Abre la app "Archivos", ve a "En mi iPhone/iPad" y busca la carpeta ScanStock';
    }
  }
}
