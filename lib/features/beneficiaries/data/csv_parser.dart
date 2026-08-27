import 'package:csv/csv.dart';

class ParsedCsv {
  const ParsedCsv({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;
}

ParsedCsv parseCsvContent(String content) {
  final csvParser = Csv();
  final rows = csvParser.decode(content);
  if (rows.isEmpty) {
    return const ParsedCsv(headers: [], rows: []);
  }
  final headers = rows.first.map((cell) => cell.toString()).toList();
  final dataRows = rows
      .skip(1)
      .map((row) => row.map((cell) => cell.toString()).toList())
      .toList();
  return ParsedCsv(headers: headers, rows: dataRows);
}
