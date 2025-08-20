import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActiveMeetingBanner extends StatelessWidget {
  final int meetingId;
  const ActiveMeetingBanner({Key? key, required this.meetingId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.yellow[100],
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meeting #$meetingId is ACTIVE',
                    style: GoogleFonts.redHatDisplay(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Remember to end the meeting after all records are captured.',
                    style: GoogleFonts.redHatDisplay(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
