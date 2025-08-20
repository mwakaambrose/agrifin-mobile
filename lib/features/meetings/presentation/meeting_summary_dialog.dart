import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MeetingSummaryDialog extends StatelessWidget {
  final void Function(String) onSave;

  const MeetingSummaryDialog({Key? key, required this.onSave})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    String summary = '';
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        'Meeting Summary',
        style: GoogleFonts.redHatDisplay(fontWeight: FontWeight.bold),
      ),
      content: TextField(
        autofocus: true,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Enter meeting summary/notes...',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: (val) => summary = val,
      ),
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: GoogleFonts.redHatDisplay(),
          ),
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: GoogleFonts.redHatDisplay(fontWeight: FontWeight.bold),
          ),
          onPressed: () => Navigator.pop(context, summary),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
