library my_popup_snakbar;

import 'package:flutter/material.dart';
import '../../my_popup_snakbar.dart';
import 'src/safe_area_values.dart';

export 'src/notification/notification.dart';
export 'src/overlay.dart';
export 'src/overlay_keys.dart' hide KeyedOverlay;
export 'src/theme.dart';
export 'src/toast/toast.dart';
export 'src/overlay_state_finder.dart' hide findOverlayState, OverlaySupportState;

/// The length of time the notification is fully displayed.
Duration kNotificationDuration = const Duration(milliseconds: 2000);

/// Notification display or hidden animation duration.
Duration kNotificationSlideDuration = const Duration(milliseconds: 300);

class MyPopupSnakbar {
  /// Popup a notification at the top of screen.
  ///
  /// [duration] the notification display duration , overlay will auto dismiss after [duration].
  /// if null , will be set to [kNotificationDuration].
  /// if zero , will not auto dismiss in the future.
  ///
  /// [animationDuration] the notification display animation duration..
  /// if null , will be set to [kNotificationSlideDuration].
  /// if zero , will display immediately.
  ///
  /// [reverseAnimationDuration] the notification hide animation duration..
  /// if null , will be set to [kNotificationSlideDuration].
  /// if zero , will hide immediately.
  ///
  /// [position] the position of notification, default is [NotificationPosition.top],
  /// can be [NotificationPosition.top] or [NotificationPosition.bottom].
  ///
  OverlaySupportEntry showOverlayNotification(
    WidgetBuilder builder, {
    Duration? duration,
    Duration? animationDuration,
    Duration? reverseAnimationDuration,
    Key? key,
    NotificationPosition position = NotificationPosition.top,
    BuildContext? context,
    Curve? curve,
    bool dismissPreviousOverlay = true,
  }) {
    duration ??= kNotificationDuration;
    animationDuration ??= kNotificationSlideDuration;
    reverseAnimationDuration ??= kNotificationSlideDuration;
    return showOverlay(
      (context, t) {
        var alignment = MainAxisAlignment.start;
        if (position == NotificationPosition.bottom) {
          alignment = MainAxisAlignment.end;
        }
        return Column(
          mainAxisAlignment: alignment,
          children: <Widget>[
            position == NotificationPosition.top
                ? TopSlideNotification(builder: builder, progress: t)
                : BottomSlideNotification(builder: builder, progress: t)
          ],
        );
      },
      duration: duration,
      animationDuration: animationDuration,
      reverseAnimationDuration: reverseAnimationDuration,
      key: key,
      context: context,
      curve: curve,
      dismissPreviousOverlay: dismissPreviousOverlay,
    );
  }

  ///
  /// Show a simple notification above the top of window.
  ///
  OverlaySupportEntry showSimpleNotification(
    Widget content, {
    /**
     * See more [ListTile.leading].
     */
    Widget? leading,
    /**
     * See more [ListTile.subtitle].
     */
    Widget? subtitle,
    /**
     * See more [ListTile.trailing].
     */
    Widget? trailing,
    /**
     * See more [ListTile.contentPadding].
     */
    EdgeInsetsGeometry? contentPadding,
    /**
     * The background color for notification, default to [ColorScheme.secondary].
     */
    Color? background,
    /**
     * See more [ListTileTheme.textColor],[ListTileTheme.iconColor].
     */
    Color? foreground,
    /**
     * The elevation of notification, see more [Material.elevation].
     */
    double elevation = 16,
    Duration? duration,
    Duration? animationDuration,
    Duration? reverseAnimationDuration,
    Key? key,
    /**
     * True to auto hide after duration [kNotificationDuration].
     */
    bool autoDismiss = true,
    /**
     * Support left/right to dismiss notification.
     */
    @Deprecated('use slideDismissDirection instead') bool slideDismiss = false,
    /**
     * The position of notification, default is [NotificationPosition.top],
     */
    NotificationPosition position = NotificationPosition.top,
    BuildContext? context,
    /**
     * The direction in which the notification can be dismissed.
     */
    DismissDirection? slideDismissDirection,
    Curve? curve,
    bool dismissPreviousOverlay = true,
  }) {
    final dismissDirection = slideDismissDirection ??
        (slideDismiss ? DismissDirection.horizontal : DismissDirection.none);
    final entry = showOverlayNotification(
      (context) {
        return SlideDismissible(
          direction: dismissDirection,
          key: ValueKey(key),
          child: Material(
            color: background ?? Theme.of(context).colorScheme.secondary,
            elevation: elevation,
            child: SafeArea(
                bottom: position == NotificationPosition.bottom,
                top: position == NotificationPosition.top,
                child: ListTileTheme(
                  textColor:
                      foreground ?? Theme.of(context).colorScheme.onSecondary,
                  iconColor:
                      foreground ?? Theme.of(context).colorScheme.onSecondary,
                  child: ListTile(
                    leading: leading,
                    title: content,
                    subtitle: subtitle,
                    trailing: trailing,
                    contentPadding: contentPadding,
                  ),
                )),
          ),
        );
      },
      duration: autoDismiss ? duration : Duration.zero,
      animationDuration: animationDuration,
      reverseAnimationDuration: reverseAnimationDuration,
      key: key,
      position: position,
      context: context,
      curve: curve,
      dismissPreviousOverlay: dismissPreviousOverlay,
    );
    return entry;
  }

  /// Popup a message in front of screen.
  ///
  /// [duration] : the duration to show a toast,
  /// for most situation, you can use [Toast.LENGTH_SHORT] and [Toast.LENGTH_LONG]
  ///
  void toast(
    String message, {
    Duration duration = Toast.LENGTH_SHORT,
    BuildContext? context,
    bool dismissPreviousOverlay = true,
    Duration? animationDuration,
    Duration? reverseAnimationDuration,
  }) {
    if (duration <= Duration.zero) {
      //fast fail
      return;
    }

    showOverlay(
      (context, t) {
        return IgnorePointer(
          child: Opacity(
            opacity: t,
            child: Toast(content: Text(message)),
          ),
        );
      },
      curve: Curves.ease,
      key: const ValueKey('overlay_toast'),
      duration: duration,
      context: context,
      animationDuration: animationDuration,
      reverseAnimationDuration: reverseAnimationDuration,
      dismissPreviousOverlay: dismissPreviousOverlay,
    );
  }

  /// The [overlayState] argument is used to add specific overlay state.
/// If you are sure that there is a overlay state in your [BuildContext],
/// You can get it [Overlay.of(BuildContext)]
/// Displays a widget that will be passed to [child] parameter above the current
/// contents of the app, with transition animation
///
/// The [child] argument is used to pass widget that you want to show
///
/// The [animationDuration] argument is used to specify duration of
/// enter transition
///
/// The [reverseAnimationDuration] argument is used to specify duration of
/// exit transition
///
/// The [displayDuration] argument is used to specify duration displaying
///
/// The [onTap] callback of [_TopSnackBar]
///
/// The [persistent] argument is used to make snack bar persistent, so
/// [displayDuration] will be ignored. Default is false.
///
/// The [onAnimationControllerInit] callback is called on internal
/// [AnimationController] has been initialized.
///
/// The [padding] argument is used to specify amount of outer padding
///
/// [curve] and [reverseCurve] arguments are used to specify curves
/// for in and out animations respectively
///
/// The [safeAreaValues] argument is used to specify the arguments of the
/// [SafeArea] widget that wrap the snackbar.
///
/// The [dismissType] argument specify which action to trigger to
/// dismiss the snackbar. Defaults to `TopSnackBarDismissType.onTap`
///
/// The [dismissDirection] argument specify in which direction the snackbar
/// can be dismissed. This argument is only used when [dismissType] is equal
/// to `DismissType.onSwipe`. Defaults to `[DismissDirection.up]`
  void showTopSnackBar(
    OverlayState overlayState,
    Widget child, {
    Duration animationDuration = const Duration(milliseconds: 1200),
    Duration reverseAnimationDuration = const Duration(milliseconds: 550),
    Duration displayDuration = const Duration(milliseconds: 3000),
    VoidCallback? onTap,
    bool persistent = false,
    ControllerCallback? onAnimationControllerInit,
    EdgeInsets padding = const EdgeInsets.all(16),
    Curve curve = Curves.elasticOut,
    Curve reverseCurve = Curves.linearToEaseOut,
    SafeAreaValues safeAreaValues = const SafeAreaValues(),
    DismissType dismissType = DismissType.onTap,
    List<DismissDirection> dismissDirection = const [DismissDirection.up],
  }) {
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (_) {
        return TopSnackBar(
          onDismissed: () {
            overlayEntry.remove();
            previousEntry = null;
          },
          animationDuration: animationDuration,
          reverseAnimationDuration: reverseAnimationDuration,
          displayDuration: displayDuration,
          onTap: onTap,
          persistent: persistent,
          onAnimationControllerInit: onAnimationControllerInit,
          padding: padding,
          curve: curve,
          reverseCurve: reverseCurve,
          safeAreaValues: safeAreaValues,
          dismissType: dismissType,
          dismissDirections: dismissDirection,
          child: child,
        );
      },
    );

    if (previousEntry != null && previousEntry!.mounted) {
      previousEntry?.remove();
    }

    overlayState.insert(overlayEntry);
    previousEntry = overlayEntry;
  }
}