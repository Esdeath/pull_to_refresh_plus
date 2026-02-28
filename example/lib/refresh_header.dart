import 'package:flutter/material.dart';
import 'package:pull_to_refresh_plus/pull_to_refresh_plus.dart';

class RefreshDefaultHeader extends StatefulWidget {
  const RefreshDefaultHeader({
    super.key,
  });

  @override
  State<RefreshDefaultHeader> createState() => _RefreshDefaultHeaderState();
}

class _RefreshDefaultHeaderState extends State<RefreshDefaultHeader>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  double _angle = 0;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleOffsetChange(double offset) {
    final newAngle = offset / 15;

    if (newAngle > _angle) {
      setState(() {
        _angle = newAngle;
      });
    }

    if (!_isRefreshing && newAngle == 0 && _angle > 0) {
      _resetState();
    }
  }

  void _resetState() {
    setState(() {
      _angle = 0;
      _isRefreshing = false;
    });
    _controller.reset();
  }

  void _handleStatusChange(RefreshStatus? status) {
    if (status == RefreshStatus.refreshing && _angle > 0) {
      _isRefreshing = true;
      _controller.repeat();
    } else if (status == RefreshStatus.completed || status == RefreshStatus.failed) {
      _controller.stop();
      _isRefreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    const double size = 85;

    return CustomHeader(
      refreshStyle: RefreshStyle.behind,
      height: 120,
      onOffsetChange: _handleOffsetChange,
      onModeChange: _handleStatusChange,
      builder: (context, status) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
          child: RotationTransition(
            alignment: Alignment.center,
            turns: _controller,
            child: Transform.rotate(
              angle: _angle,
              child: Image.asset(
                'images/loading.png',
                height: size,
                width: size,
              ),
            ),
          ),
        );
      },
    );
  }
}
