import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../my_popup_snakbar.dart';
import 'overlay_keys.dart';
import 'overlay_state_finder.dart';
import 'safe_area_values.dart';
import 'top_bounce_container.dart';

part 'overlay_animation.dart';

part 'overlay_entry.dart';

/// To build a widget with animated value.
/// [progress] : the progress of overlay animation from 0 - 1
///
/// A simple use case is [TopSlideNotification] in [showOverlayNotification].
///
typedef AnimatedOverlayWidgetBuilder = Widget Function(
    BuildContext context, double progress);

OverlayEntry? previousEntry;

/// Basic api to show overlay widget.
///
/// [duration] : the overlay display duration , overlay will auto dismiss after [duration].
/// if null , will be set to [kNotificationDuration].
/// if zero , will not auto dismiss in the future.
///
/// [builder] : see [AnimatedOverlayWidgetBuilder].
///
/// [curve] : adjust the rate of change of an animation.
///
/// [key] : to identify a OverlayEntry.
///
/// for example:
/// ```dart
/// final key = ValueKey('my overlay');
///
/// // step 1: popup a overlay
/// showOverlay(builder, key: key);
///
/// // step 2: popup a overlay use the same key
/// showOverlay(builder2, key: key);
/// ```
///
/// If the notification1 of step1 is showing, the step2 will dismiss previous notification1.
///
/// If you want notification1' exist to prevent step2, please see [ModalKey]
///
///
OverlaySupportEntry showOverlay(
  AnimatedOverlayWidgetBuilder builder, {
  Curve? curve,
  Duration? duration,
  Key? key,
  BuildContext? context,
  Duration? animationDuration,
  Duration? reverseAnimationDuration,
  bool dismissPreviousOverlay = true,
}) {
  assert(key is! GlobalKey);

  final overlaySupport = findOverlayState(context: context);
  final overlay = overlaySupport?.overlayState;
  if (overlaySupport == null || overlay == null) {
    assert(() {
      debugPrint('overlay not available, dispose this call : $key');
      return true;
    }());
    return OverlaySupportEntry.empty();
  }

  final overlayKey = key ?? UniqueKey();

  final oldSupportEntry = overlaySupport.getEntry(key: overlayKey);
  if (oldSupportEntry != null && key is ModalKey) {
    // Do nothing for modal key if there be a OverlayEntry hold the same model key
    // and it is showing.
    return oldSupportEntry;
  }

  if (dismissPreviousOverlay && previousEntry != null && previousEntry!.mounted) {
    previousEntry?.remove();
  }

  final dismissImmediately = key is TransientKey;
  // If we got a showing overlaySupport with [key], we should dismiss it before showing a new.
  oldSupportEntry?.dismiss(animate: !dismissImmediately);

  final GlobalKey<_AnimatedOverlayState> stateKey = GlobalKey<_AnimatedOverlayState>();
  final OverlayEntry entry = OverlayEntry(builder: (context) {
    return KeyedOverlay(
      key: overlayKey,
      child: _AnimatedOverlay(
        key: stateKey,
        builder: builder,
        curve: curve,
        animationDuration: animationDuration ?? kNotificationSlideDuration,
        reverseAnimationDuration: reverseAnimationDuration ?? kNotificationSlideDuration,
        duration: duration ?? kNotificationDuration,
        overlayKey: overlayKey,
        overlaySupportState: overlaySupport,
        onDismissed: () {

        },
      ),
    );
  });

  final supportEntry = OverlaySupportEntry._internal(entry, overlayKey, stateKey, overlaySupport);
  overlaySupport.addEntry(supportEntry, key: overlayKey);
  overlay.insert(entry);
  previousEntry = entry;

  return supportEntry;
}

enum DismissType { onTap, onSwipe, none }

typedef ControllerCallback = void Function(AnimationController);

/// Widget that controls all animations
class TopSnackBar extends StatefulWidget {
  const TopSnackBar({
    Key? key,
    required this.child,
    required this.onDismissed,
    required this.animationDuration,
    required this.reverseAnimationDuration,
    required this.displayDuration,
    required this.padding,
    required this.curve,
    required this.reverseCurve,
    required this.safeAreaValues,
    required this.dismissDirections,
    this.onTap,
    this.persistent = false,
    this.onAnimationControllerInit,
    this.dismissType = DismissType.onTap,
  }) : super(key: key);

  final Widget child;
  final VoidCallback onDismissed;
  final Duration animationDuration;
  final Duration reverseAnimationDuration;
  final Duration displayDuration;
  final VoidCallback? onTap;
  final ControllerCallback? onAnimationControllerInit;
  final bool persistent;
  final EdgeInsets padding;
  final Curve curve;
  final Curve reverseCurve;
  final SafeAreaValues safeAreaValues;
  final DismissType dismissType;
  final List<DismissDirection> dismissDirections;

  @override
  _TopSnackBarState createState() => _TopSnackBarState();
}

class _TopSnackBarState extends State<TopSnackBar>
    with SingleTickerProviderStateMixin {
  late final Animation<Offset> _offsetAnimation;
  late final AnimationController _animationController;

  Timer? _timer;

  final _offsetTween = Tween(begin: const Offset(0, -1), end: Offset.zero);

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
      reverseDuration: widget.reverseAnimationDuration,
    );
    _animationController.addStatusListener(
      (status) {
        if (status == AnimationStatus.completed && !widget.persistent) {
          _timer = Timer(widget.displayDuration, () {
            if (mounted) {
              _animationController.reverse();
            }
          });
        }
        if (status == AnimationStatus.dismissed) {
          _timer?.cancel();
          widget.onDismissed.call();
        }
      },
    );

    widget.onAnimationControllerInit?.call(_animationController);

    _offsetAnimation = _offsetTween.animate(
      CurvedAnimation(
        parent: _animationController,
        curve: widget.curve,
        reverseCurve: widget.reverseCurve,
      ),
    );
    if (mounted) {
      _animationController.forward();
    }
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.padding.top,
      left: widget.padding.left,
      right: widget.padding.right,
      child: SlideTransition(
        position: _offsetAnimation,
        child: SafeArea(
          top: widget.safeAreaValues.top,
          bottom: widget.safeAreaValues.bottom,
          left: widget.safeAreaValues.left,
          right: widget.safeAreaValues.right,
          minimum: widget.safeAreaValues.minimum,
          maintainBottomViewPadding:
              widget.safeAreaValues.maintainBottomViewPadding,
          child: _buildDismissibleChild(),
        ),
      ),
    );
  }

  /// Build different type of [Widget] depending on [DismissType] value
  Widget _buildDismissibleChild() {
    switch (widget.dismissType) {
      case DismissType.onTap:
        return TapBounceContainer(
          onTap: () {
            widget.onTap?.call();
            if (!widget.persistent && mounted) {
              _animationController.reverse();
            }
          },
          child: widget.child,
        );
      case DismissType.onSwipe:
        var childWidget = widget.child;
        for (final direction in widget.dismissDirections) {
          childWidget = Dismissible(
            direction: direction,
            key: UniqueKey(),
            dismissThresholds: const {DismissDirection.up: 0.2},
            confirmDismiss: (direction) async {
              if (!widget.persistent && mounted) {
                if (direction == DismissDirection.down) {
                  await _animationController.reverse();
                } else {
                  _animationController.reset();
                }
              }
              return false;
            },
            child: childWidget,
          );
        }
        return childWidget;
      case DismissType.none:
        return widget.child;
    }
  }
}
