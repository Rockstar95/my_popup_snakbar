import 'package:flutter/material.dart';

import '../../my_popup_snakbar.dart';

class Toast extends StatelessWidget {
  /// Show the view or text notification for a short period of time.
  /// This time could be user-definable.
  // ignore: constant_identifier_names
  static const LENGTH_SHORT = Duration(milliseconds: 2000);

  /// Show the view or text notification for a long period of time.
  /// This time could be user-definable.
  // ignore: constant_identifier_names
  static const LENGTH_LONG = Duration(milliseconds: 3500);

  final Widget content;

  const Toast({Key? key, required this.content}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final toastTheme = OverlaySupportTheme.toast(context);
    return SafeArea(
      maintainBottomViewPadding: true,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: DefaultTextStyle(
          style: TextStyle(color: toastTheme?.textColor),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: toastTheme?.alignment ?? const Alignment(0, 0.618),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  color: toastTheme?.background,
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
