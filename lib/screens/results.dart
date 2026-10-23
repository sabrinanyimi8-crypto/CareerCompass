import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../career_data.dart';
import '../models.dart';
import 'career_detail.dart';
import 'ask_screen.dart';
import 'checkin_card.dart';
import 'field_icon.dart';

class ResultsTab extends StatefulWidget {
  final VoidCallback onChanged;

  const ResultsTab({super.key, required this.onChanged});

  @override
  State<ResultsTab> createState() => _ResultsTabState();
}

class _ResultsTabState extends State<ResultsTab> {
  bool showExcluded = false;

  // One result row: rank, field icon, career name and field, then the score ring.
  Widget _resultCard(BuildContext context, Result r) {
    final scheme = Theme.of(context).colorScheme;
    final isTop = r.rank == 1;
    final field = findCareer(r.careerId).field;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CareerDetailScreen(result: r),
            ),
          );
          setState(() {});
          widget.onChanged();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              SizedBox(
                width: 34,
                child: Text(
                  '#${r.rank}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
              // the icon for this career's field
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  fieldIcon(field),
                  size: 22,
                  color: scheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isTop)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.secondary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'TOP MATCH',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: scheme.onSecondary,
                          ),
                        ),
                      ),
                    Text(
                      r.careerTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      field,
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _ScoreRing(
                score: r.totalScore,
                color: isTop ? scheme.secondary : scheme.primary,
                order: r.rank,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: SizedBox(
                  width: 18,
                  child: isSaved(r.careerId)
                      ? Icon(Icons.bookmark, size: 18, color: scheme.primary)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var run = latestRun;

    if (run == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No recommendations yet. Finish the assessment on the home tab and generate your results.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        // keeps the list readable on wide screens
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // follow-up question and progress list, only shows when there is something to show
            CheckInSection(onChanged: widget.onChanged),

            Text(
              '${run.results.length} careers matched your profile',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ranked by how well they fit. Tap one to see why.',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 16),

            if (run.results.isEmpty)
              const Card(
                color: Color(0xFFFBEAE8),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Every career was ruled out by the minimum average rules. Check the list below to see '
                        'what you would need.',
                  ),
                ),
              ),

            for (var r in run.results) _resultCard(context, r),

            // The careers that got ruled out by the rules rather than scored low.
            // Hidden by default but the student can open it, they should be able to
            // see what they would need to qualify.
            if (run.excludedCareers.isNotEmpty) ...[
              const SizedBox(height: 8),
              Card(
                color: const Color(0xFFF5F5F5),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                          'Not recommended yet (${run.excludedCareers.length})'),
                      subtitle: const Text(
                          'Careers where you do not meet the minimum average'),
                      trailing: Icon(
                          showExcluded ? Icons.expand_less : Icons.expand_more),
                      onTap: () {
                        setState(() {
                          showExcluded = !showExcluded;
                        });
                      },
                    ),
                    if (showExcluded)
                      for (var e in run.excludedCareers)
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.block, size: 18),
                          title: Text(e.careerTitle),
                          subtitle: Text(e.reason),
                        ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AskScreen()),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Ask CareerCompass'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// The match score drawn as a ring that fills once when the row appears.
// Lower-ranked rows fill a little slower, so the list settles top to bottom.
class _ScoreRing extends StatelessWidget {
  final double score;
  final Color color;
  final int order;

  const _ScoreRing({
    required this.score,
    required this.color,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    final delayed = math.min(order, 10) * 70;
    final duration = reduce ? Duration.zero : Duration(milliseconds: 700 + delayed);
    final scheme = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: (score / 100).clamp(0.0, 1.0)),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return SizedBox(
          width: 58,
          height: 58,
          child: CustomPaint(
            painter: _ScoreRingPainter(
              progress: value,
              color: color,
              track: scheme.outline,
            ),
            child: child,
          ),
        );
      },
      child: Center(
        child: Text(
          score.toStringAsFixed(0),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
        ),
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;

  _ScoreRingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 5.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(arcRect, 0, 2 * math.pi, false, trackPaint);
    // starts at north and runs clockwise
    canvas.drawArc(arcRect, -math.pi / 2, 2 * math.pi * progress, false, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}