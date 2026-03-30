import 'dart:ui';

import 'package:flutter/material.dart';

enum PdfDrawTool { pen, highlighter, eraser, text }

class DrawStroke {
  final PdfDrawTool tool;
  final Color color;
  final double width;
  final int page;
  final List<Offset> points;

  DrawStroke({
    required this.tool,
    required this.color,
    required this.width,
    required this.page,
    required this.points,
  });
}

class TextNote {
  final int page;
  final Offset position;
  final String text;
  final Color color;

  TextNote({
    required this.page,
    required this.position,
    required this.text,
    required this.color,
  });
}

class PdfDrawingOverlay extends StatefulWidget {
  final bool isDrawingMode;
  final int currentPage;
  final int totalPages;

  const PdfDrawingOverlay({
    super.key,
    required this.isDrawingMode,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  State<PdfDrawingOverlay> createState() => _PdfDrawingOverlayState();
}

class _PdfDrawingOverlayState extends State<PdfDrawingOverlay> {
  final List<DrawStroke> _strokes = [];
  final List<TextNote> _notes = [];
  final List<Object> _undoStack = []; // DrawStroke or TextNote

  PdfDrawTool _currentTool = PdfDrawTool.pen;
  Color _currentColor = Colors.yellowAccent;
  double _currentWidth = 3.0;

  // Simple preset colors for pen/highlighter/text
  final List<Color> _colors = [
    Colors.yellowAccent,
    Colors.redAccent,
    Colors.lightBlueAccent,
    Colors.greenAccent,
    Colors.white,
  ];

  DrawStroke? _activeStroke;

  bool get _isActive => widget.isDrawingMode && widget.totalPages > 0;

  void _startStroke(Offset position) {
    if (!_isActive || _currentTool == PdfDrawTool.text) return;
    if (_currentTool == PdfDrawTool.eraser) {
      _eraseAt(position);
      return;
    }
    final stroke = DrawStroke(
      tool: _currentTool,
      color: _currentTool == PdfDrawTool.highlighter
          ? _currentColor.withOpacity(0.4)
          : _currentColor,
      width: _currentTool == PdfDrawTool.highlighter ? 10.0 : _currentWidth,
      page: widget.currentPage,
      points: [position],
    );
    setState(() {
      _activeStroke = stroke;
      _strokes.add(stroke);
      _undoStack.add(stroke);
    });
  }

  void _updateStroke(Offset position) {
    if (!_isActive || _currentTool == PdfDrawTool.text) return;
    if (_currentTool == PdfDrawTool.eraser) {
      _eraseAt(position);
      return;
    }
    if (_activeStroke == null) return;
    setState(() {
      _activeStroke!.points.add(position);
    });
  }

  void _endStroke() {
    _activeStroke = null;
  }

  void _eraseAt(Offset position) {
    // Remove strokes on current page that are close to the touch point
    const double hitRadius = 12.0;
    setState(() {
      _strokes.removeWhere((stroke) {
        if (stroke.page != widget.currentPage) return false;
        return stroke.points.any(
          (p) => (p - position).distance <= hitRadius,
        );
      });
      _notes.removeWhere((note) {
        if (note.page != widget.currentPage) return false;
        return (note.position - position).distance <= hitRadius;
      });
    });
  }

  Future<void> _addTextNote(Offset position) async {
    if (!_isActive) return;
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add note'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Write your note here',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (text == null || text.isEmpty) return;
    final note = TextNote(
      page: widget.currentPage,
      position: position,
      text: text,
      color: _currentColor,
    );
    setState(() {
      _notes.add(note);
      _undoStack.add(note);
    });
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    final last = _undoStack.removeLast();
    setState(() {
      if (last is DrawStroke) {
        _strokes.remove(last);
      } else if (last is TextNote) {
        _notes.remove(last);
      }
    });
  }

  void _clearCurrentPage() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear drawings'),
        content: const Text(
          'Do you want to remove all drawings and notes on this page?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _strokes.removeWhere(
                  (s) => s.page == widget.currentPage,
                );
                _notes.removeWhere(
                  (n) => n.page == widget.currentPage,
                );
              });
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isActive) {
      // When drawing mode is off, keep a transparent, non-interactive layer.
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Drawing surface
        Positioned.fill(
          child: Listener(
            onPointerDown: (event) {
              final pos = event.localPosition;
              if (_currentTool == PdfDrawTool.text) {
                _addTextNote(pos);
              } else {
                _startStroke(pos);
              }
            },
            onPointerMove: (event) {
              _updateStroke(event.localPosition);
            },
            onPointerUp: (_) => _endStroke(),
            child: CustomPaint(
              painter: _PdfDrawingPainter(
                strokes: _strokes.where((s) => s.page == widget.currentPage).toList(),
                notes: _notes.where((n) => n.page == widget.currentPage).toList(),
              ),
            ),
          ),
        ),

        // Toolbar
        Positioned(
          right: 16,
          top: 16,
          child: _buildToolbar(context),
        ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Card(
      color: Colors.black.withOpacity(0.75),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _toolButton(
                  icon: Icons.edit,
                  selected: _currentTool == PdfDrawTool.pen,
                  tooltip: 'Pen',
                  onTap: () {
                    setState(() {
                      _currentTool = PdfDrawTool.pen;
                      _currentWidth = 3.0;
                      _currentColor = Colors.yellowAccent;
                    });
                  },
                ),
                _toolButton(
                  icon: Icons.border_color,
                  selected: _currentTool == PdfDrawTool.highlighter,
                  tooltip: 'Highlighter',
                  onTap: () {
                    setState(() {
                      _currentTool = PdfDrawTool.highlighter;
                      _currentWidth = 10.0;
                      _currentColor = Colors.yellowAccent;
                    });
                  },
                ),
                _toolButton(
                  icon: Icons.text_fields,
                  selected: _currentTool == PdfDrawTool.text,
                  tooltip: 'Text note',
                  onTap: () {
                    setState(() {
                      _currentTool = PdfDrawTool.text;
                      _currentWidth = 3.0;
                      _currentColor = Colors.yellowAccent;
                    });
                  },
                ),
                _toolButton(
                  icon: Icons.auto_fix_normal,
                  selected: _currentTool == PdfDrawTool.eraser,
                  tooltip: 'Eraser',
                  onTap: () {
                    setState(() {
                      _currentTool = PdfDrawTool.eraser;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Colors
            Row(
              mainAxisSize: MainAxisSize.min,
              children: _colors
                  .map(
                    (c) => GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentColor = c;
                        });
                      },
                      child: Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _currentColor == c ? Colors.white : Colors.black54,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 6),
            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.undo, size: 18, color: Colors.white),
                  tooltip: 'Undo',
                  onPressed: _undoStack.isNotEmpty ? _undo : null,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep, size: 18, color: Colors.white),
                  tooltip: 'Clear page',
                  onPressed: _clearCurrentPage,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Page ${widget.currentPage}/${widget.totalPages}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolButton({
    required IconData icon,
    required bool selected,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(
        icon,
        size: 18,
        color: selected ? Colors.amber : Colors.white70,
      ),
      tooltip: tooltip,
      onPressed: onTap,
    );
  }
}

class _PdfDrawingPainter extends CustomPainter {
  final List<DrawStroke> strokes;
  final List<TextNote> notes;

  _PdfDrawingPainter({
    required this.strokes,
    required this.notes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    for (final note in notes) {
      final textSpan = TextSpan(
        text: note.text,
        style: TextStyle(
          color: note.color,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        maxLines: 3,
      )..layout(maxWidth: size.width * 0.6);

      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          note.position.dx,
          note.position.dy,
          tp.width + 12,
          tp.height + 8,
        ),
        const Radius.circular(8),
      );

      final bgPaint = Paint()
        ..color = Colors.black.withOpacity(0.6)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(bgRect, bgPaint);
      tp.paint(canvas, Offset(note.position.dx + 6, note.position.dy + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _PdfDrawingPainter oldDelegate) {
    return oldDelegate.strokes != strokes || oldDelegate.notes != notes;
  }
}

