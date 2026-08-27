import 'package:dif_pass/features/beneficiaries/data/csv_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseCsvContent splits the header row from the data rows', () {
    final result = parseCsvContent('Name,Table\nJane Doe,5\nJohn Smith,9\n');

    expect(result.headers, ['Name', 'Table']);
    expect(result.rows, [
      ['Jane Doe', '5'],
      ['John Smith', '9'],
    ]);
  });

  test('parseCsvContent returns empty headers and rows for empty content', () {
    final result = parseCsvContent('');

    expect(result.headers, isEmpty);
    expect(result.rows, isEmpty);
  });
}
