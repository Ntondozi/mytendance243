import 'package:flutter/material.dart';

class ExpandableTextWidget extends StatefulWidget {
  final String text;
  final int maxLines;

  const ExpandableTextWidget({super.key, required this.text, this.maxLines = 3});

  @override
  State<ExpandableTextWidget> createState() => _ExpandableTextWidgetState();
}

class _ExpandableTextWidgetState extends State<ExpandableTextWidget> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final span = TextSpan(
        text: widget.text,
        style: const TextStyle(fontSize: 14, color: Colors.black),
      );
      final tp = TextPainter(
        text: span,
        maxLines: widget.maxLines,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: constraints.maxWidth);

      final isOverflow = tp.didExceedMaxLines;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.text,
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.justify,
            maxLines: isExpanded ? null : widget.maxLines,
            overflow: TextOverflow.fade,
          ),
          if (isOverflow)
            GestureDetector(
              onTap: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
              child: Text(
                isExpanded ? "moins" : "...plus",
                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      );
    });
  }
}
