import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'models.dart';

class Exporter {
  static final _fmt = DateFormat('dd MMM yyyy, hh:mm a');

  static String _status(Task t) => t.completed ? 'Completed' : 'Pending';

  static String _subs(Task t) => t.subtasks.isEmpty
      ? '-'
      : '${t.subtasks.where((s) => s.done).length}/${t.subtasks.length}';

  static String _esc(String v) => '"${v.replaceAll('"', '""')}"';

  static Future<File> csv(List<Task> tasks) async {
    final b = StringBuffer('Title,Description,Due,Category,Status,Repeat,Subtasks done\n');
    for (final t in tasks) {
      b.writeln([
        _esc(t.title),
        _esc(t.description),
        _esc(_fmt.format(t.dueAt)),
        _esc(t.category),
        _esc(_status(t)),
        _esc(t.repeatLabel),
        _esc(_subs(t)),
      ].join(','));
    }
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/my_tasks.csv');
    return f.writeAsString(b.toString());
  }

  static Future<File> pdf(List<Task> tasks) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (ctx) => [
          pw.Text('Seaside Tasks - My Tasks',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Exported on ${_fmt.format(DateTime.now())}'),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: ['Title', 'Due', 'Category', 'Status', 'Repeat', 'Subtasks'],
            data: [
              for (final t in tasks)
                [
                  t.title,
                  _fmt.format(t.dueAt),
                  t.category,
                  _status(t),
                  t.repeatLabel,
                  _subs(t),
                ]
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/my_tasks.pdf');
    return f.writeAsBytes(await doc.save());
  }

  static Future<void> shareCsv(List<Task> tasks) async {
    final f = await csv(tasks);
    await Share.shareXFiles([XFile(f.path)], subject: 'My tasks (CSV)');
  }

  static Future<void> sharePdf(List<Task> tasks) async {
    final f = await pdf(tasks);
    await Share.shareXFiles([XFile(f.path)], subject: 'My tasks (PDF)');
  }

  /// Opens the share sheet with the PDF attached and a text summary as the mail body;
  /// pick Gmail / any email app from there.
  static Future<void> email(List<Task> tasks) async {
    final f = await pdf(tasks);
    final pending = tasks.where((t) => !t.completed).length;
    await Share.shareXFiles(
      [XFile(f.path)],
      subject: 'My task list',
      text: 'Hi! Attached is my task list.\n'
          'Total: ${tasks.length} | Pending: $pending | Completed: ${tasks.length - pending}',
    );
  }
}
