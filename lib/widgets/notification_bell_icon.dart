import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/notification_provider.dart';

/// A bell icon with an animated unread badge.
/// Drop this anywhere in your AppBar actions:
///
/// ```dart
/// appBar: AppBar(
///   actions: const [NotificationBellIcon()],
/// )
/// ```
class NotificationBellIcon extends StatelessWidget {
  final Color? iconColor;
  final double iconSize;

  const NotificationBellIcon({
    super.key,
    this.iconColor,
    this.iconSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        final unread = provider.unreadCount;

        return InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: () => Navigator.pushNamed(context, '/notifications'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  unread > 0
                      ? Icons.notifications
                      : Icons.notifications_none_outlined,
                  size: iconSize,
                  color: iconColor ?? Colors.black87,
                ),
                if (unread > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: _BadgeBubble(count: unread),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BadgeBubble extends StatefulWidget {
  final int count;
  const _BadgeBubble({required this.count});

  @override
  State<_BadgeBubble> createState() => _BadgeBubbleState();
}

class _BadgeBubbleState extends State<_BadgeBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void didUpdateWidget(_BadgeBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Text(
          widget.count > 99 ? '99+' : '${widget.count}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}