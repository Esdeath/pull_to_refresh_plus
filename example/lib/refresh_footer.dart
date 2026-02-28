import 'package:flutter/material.dart';
import 'package:pull_to_refresh_simple/pull_to_refresh_simple.dart';

class RefreshDefaultFooter extends StatefulWidget {
  const RefreshDefaultFooter({super.key});

  @override
  State<RefreshDefaultFooter> createState() => _RefreshDefaultFooterState();
}

class _RefreshDefaultFooterState extends State<RefreshDefaultFooter> {
  double _ballSize1 = 0.0;
  double _ballSize2 = 0.0;
  double _ballSize3 = 0.0;

  // 动画阶段
  int _animationPhase = 1;

  // 动画过渡时间
  final Duration _ballSizeDuration = const Duration(milliseconds: 200);

  // 是否运行动画
  bool _isAnimated = false;

  // 循环动画
  void _loopAnimated() {
    Future.delayed(_ballSizeDuration, () {
      if (!mounted) return;

      if (_isAnimated) {
        setState(() {
          _updateBallSizes();
        });

        _animationPhase++;
        _animationPhase = _animationPhase >= 5 ? 1 : _animationPhase;
        _loopAnimated();
      } else {
        _resetAnimation();
      }
    });
  }

  // 更新球体大小
  void _updateBallSizes() {
    switch (_animationPhase) {
      case 1:
        _ballSize1 = 13.0;
        _ballSize2 = 6.0;
        _ballSize3 = 13.0;
        break;
      case 2:
        _ballSize1 = 20.0;
        _ballSize2 = 13.0;
        _ballSize3 = 6.0;
        break;
      case 3:
        _ballSize1 = 13.0;
        _ballSize2 = 20.0;
        _ballSize3 = 13.0;
        break;
      default:
        _ballSize1 = 6.0;
        _ballSize2 = 13.0;
        _ballSize3 = 20.0;
        break;
    }
  }

  // 重置动画状态
  void _resetAnimation() {
    setState(() {
      _ballSize1 = 0.0;
      _ballSize2 = 0.0;
      _ballSize3 = 0.0;
      _animationPhase = 1;
    });
  }

  // 处理加载状态变化
  void _handleModeChange(LoadStatus? mode) {
    if (mode == LoadStatus.loading) {
      _isAnimated = true;
      setState(() {
        _ballSize1 = 6.0;
        _ballSize2 = 13.0;
        _ballSize3 = 20.0;
      });
      _loopAnimated();
    } else {
      _isAnimated = false;
    }
  }

  // 构建球体组件
  Widget _buildBall(double size, Color color) {
    return SizedBox(
      width: 20.0,
      height: 20.0,
      child: Center(
        child: ClipOval(
          child: AnimatedContainer(
            color: color,
            height: size,
            width: size,
            duration: _ballSizeDuration,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor.withAlpha(204); // 0.8 alpha

    return CustomFooter(
      height: 50,
      onModeChange: _handleModeChange,
      builder: (context, status) {
        if (status == LoadStatus.loading) {
          return Container(
            alignment: Alignment.center,
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBall(_ballSize1, color),
                const SizedBox(width: 5.0),
                _buildBall(_ballSize2, color),
                const SizedBox(width: 5.0),
                _buildBall(_ballSize3, color),
              ],
            ),
          );
        } else {
          return Container(
            height: 50,
            alignment: Alignment.center,
            child: const Text(
              '上拉以加载',
              style: TextStyle(
                fontSize: 20,
                color: Colors.blue,
              ),
            ),
          );
        }
      },
    );
  }
}
