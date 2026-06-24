import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/database/app_database.dart';
import '../../data/database/tables/tables.dart';

class ExportService {
  final AppDatabase _db;

  ExportService(this._db);

  Future<void> exportCsv() async {
    final transactions = await _db.transactionDao.getAllTransactions();
    
    List<List<dynamic>> rows = [];
    rows.add(['ID', 'Date', 'Amount', 'Type', 'Category', 'Source', 'Description', 'Reference', 'Sender']);
    
    for (var tx in transactions) {
      rows.add([
        tx.id,
        DateTime.fromMillisecondsSinceEpoch(tx.date).toIso8601String(),
        tx.amount,
        tx.transactionType,
        tx.category,
        tx.source,
        tx.description,
        tx.referenceNumber ?? '',
        tx.sender ?? '',
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    final file = await _getTempFile('mytra_export.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'Mytra Transactions CSV Export');
  }

  Future<void> exportJson() async {
    final transactions = await _db.transactionDao.getAllTransactions();
    final list = transactions.map((tx) => {
      'id': tx.id,
      'date': tx.date,
      'amount': tx.amount,
      'transactionType': tx.transactionType,
      'category': tx.category,
      'source': tx.source,
      'description': tx.description,
      'referenceNumber': tx.referenceNumber,
      'sender': tx.sender,
      'rawMessage': tx.rawMessage,
      'isManuallyEdited': tx.isManuallyEdited,
    }).toList();

    final jsonStr = jsonEncode(list);
    final file = await _getTempFile('mytra_export.json');
    await file.writeAsString(jsonStr);
    await Share.shareXFiles([XFile(file.path)], text: 'Mytra Transactions JSON Export');
  }

  Future<void> exportExcel() async {
    final transactions = await _db.transactionDao.getAllTransactions();
    
    var excel = Excel.createExcel();
    var sheet = excel['Transactions'];
    
    sheet.appendRow([
      TextCellValue('ID'),
      TextCellValue('Date'),
      TextCellValue('Amount'),
      TextCellValue('Type'),
      TextCellValue('Category'),
      TextCellValue('Source'),
      TextCellValue('Description'),
      TextCellValue('Reference'),
      TextCellValue('Sender')
    ]);

    for (var tx in transactions) {
      sheet.appendRow([
        IntCellValue(tx.id),
        TextCellValue(DateTime.fromMillisecondsSinceEpoch(tx.date).toIso8601String()),
        DoubleCellValue(tx.amount),
        TextCellValue(tx.transactionType),
        TextCellValue(tx.category),
        TextCellValue(tx.source),
        TextCellValue(tx.description),
        TextCellValue(tx.referenceNumber ?? ''),
        TextCellValue(tx.sender ?? ''),
      ]);
    }

    final fileBytes = excel.save();
    if (fileBytes != null) {
      final file = await _getTempFile('mytra_export.xlsx');
      await file.writeAsBytes(fileBytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Mytra Transactions Excel Export');
    }
  }

  Future<File> _getTempFile(String name) async {
    final dir = await getTemporaryDirectory();
    return File('${dir.path}/$name');
  }
}
