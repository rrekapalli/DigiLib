import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Different types of loading states
enum LoadingType { circular, linear, skeleton, shimmer, dots }

/// A simple loading spinner widget
class LoadingSpinner extends StatelessWidget {
  final double? size;
  final Color? color;
  final double strokeWidth;

  const LoadingSpinner({
    super.key,
    this.size,
    this.color,
    this.strokeWidth = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size ?? 32,
      height: size ?? 32,
      child: CircularProgressIndicator(
        color: color,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

/// A versatile loading widget that can display different loading states
class LoadingWidget extends StatelessWidget {
  final LoadingType type;
  final String? message;
  final double? size;
  final Color? color;
  final bool showMessage;

  const LoadingWidget({
    super.key,
    this.type = LoadingType.circular,
    this.message,
    this.size,
    this.color,
    this.showMessage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLoadingIndicator(context),
          if (showMessage && message != null) ...[
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    switch (type) {
      case LoadingType.circular:
        return SizedBox(
          width: size ?? 32,
          height: size ?? 32,
          child: CircularProgressIndicator(color: color, strokeWidth: 3),
        );

      case LoadingType.linear:
        return SizedBox(
          width: size ?? 200,
          child: LinearProgressIndicator(
            color: color,
            backgroundColor: color?.withValues(alpha: 0.2),
          ),
        );

      case LoadingType.skeleton:
        return _SkeletonLoader(size: size ?? 200);

      case LoadingType.shimmer:
        return _ShimmerLoader(size: size ?? 200);

      case LoadingType.dots:
        return _DotsLoader(color: color);
    }
  }
}

/// Loading overlay that can be shown over existing content
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? loadingMessage;
  final LoadingType loadingType;
  final Color? overlayColor;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingMessage,
    this.loadingType = LoadingType.circular,
    this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: overlayColor ?? Colors.black.withOpacity(0.3),
            child: LoadingWidget(type: loadingType, message: loadingMessage),
          ),
      ],
    );
  }
}

/// A skeleton loader for content placeholders
class _SkeletonLoader extends StatefulWidget {
  final double size;

  const _SkeletonLoader({required this.size});

  @override
  State<_SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<_SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          children: [
            Container(
              width: widget.size,
              height: 20,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: _animation.value),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: widget.size * 0.7,
              height: 16,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: _animation.value),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: widget.size * 0.9,
              height: 16,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: _animation.value),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A shimmer loader effect
class _ShimmerLoader extends StatefulWidget {
  final double size;

  const _ShimmerLoader({required this.size});

  @override
  State<_ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<_ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
              colors: [
                Theme.of(context).colorScheme.surfaceContainerHighest,
                Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                Theme.of(context).colorScheme.surfaceContainerHighest,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Animated dots loader
class _DotsLoader extends StatefulWidget {
  final Color? color;

  const _DotsLoader({this.color});

  @override
  State<_DotsLoader> createState() => _DotsLoaderState();
}

class _DotsLoaderState extends State<_DotsLoader>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    _startAnimations();
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (widget.color ?? Theme.of(context).colorScheme.primary)
                    .withValues(alpha: 0.3 + (_animations[index].value * 0.7)),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Progress indicator with percentage and message
class ProgressIndicator extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String? message;
  final String? percentage;
  final bool showPercentage;
  final Color? color;

  const ProgressIndicator({
    super.key,
    required this.progress,
    this.message,
    this.percentage,
    this.showPercentage = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final displayPercentage = percentage ?? '${(progress * 100).round()}%';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: progress,
                color: color,
                backgroundColor: color?.withValues(alpha: 0.2),
              ),
            ),
            if (showPercentage) ...[
              const SizedBox(width: AppConstants.defaultPadding),
              Text(
                displayPercentage,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Circular progress indicator with percentage in the center
class CircularProgressWithLabel extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String? label;
  final double size;
  final Color? color;
  final double strokeWidth;

  const CircularProgressWithLabel({
    super.key,
    required this.progress,
    this.label,
    this.size = 80,
    this.color,
    this.strokeWidth = 6,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: strokeWidth,
              color: color,
              backgroundColor: color?.withValues(alpha: 0.2),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(progress * 100).round()}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (label != null)
                  Text(
                    label!,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading state for lists with skeleton items
class ListLoadingState extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const ListLoadingState({super.key, this.itemCount = 5, this.itemHeight = 80});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          height: itemHeight,
          margin: const EdgeInsets.symmetric(
            horizontal: AppConstants.defaultPadding,
            vertical: 4,
          ),
          child: const _SkeletonLoader(size: double.infinity),
        );
      },
    );
  }
}

/// Loading state for grid views
class GridLoadingState extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double childAspectRatio;

  const GridLoadingState({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: AppConstants.defaultPadding,
        mainAxisSpacing: AppConstants.defaultPadding,
      ),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return const _SkeletonLoader(size: double.infinity);
      },
    );
  }
}
