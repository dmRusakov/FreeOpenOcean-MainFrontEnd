import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/AppTheme.dart';
import '../../core/provider/AppThemeProvider.dart';

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    this.onPressed,
    this.text,
    this.theme = "info",
    this.icon,
    this.svgIconPath,
    this.size = "m",
    this.showTextOnBigScreen = false,
    this.showTextAlways = false,
  });

  final VoidCallback? onPressed;
  final String? text;
  final String theme;
  final IconData? icon;
  final String? svgIconPath;
  final String? size;
  final bool showTextOnBigScreen;
  final bool showTextAlways;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isConstrained = constraints.maxWidth < 100.0; // Threshold to detect constrained width
        final sizes = context.getThemeSizes('btn_${widget.size}') as Map<String, dynamic>? ?? <String, dynamic>{};
        final color = context.getThemeColor('btn_${widget.theme}') as Map<String, dynamic>? ?? <String, dynamic>{};
        final hoverBackground = Color.lerp(color['background'] as Color? ?? Colors.grey, Colors.black, 0.2);
        final deviceType = context.getDeviceType();
        final hasIcon = widget.icon != null || widget.svgIconPath != null;
        final showText = (!hasIcon && widget.text != null && widget.text!.isNotEmpty) ||
            (widget.showTextAlways || (widget.showTextOnBigScreen && (deviceType == DeviceType.desktop || deviceType == DeviceType.tv))) && widget.text != null && widget.text!.isNotEmpty ||
            (_isHovered && widget.text != null && widget.text!.isNotEmpty && !isConstrained);

        // Build an icon widget (either SVG or Icon).
        Widget iconWidget;
        if (widget.svgIconPath != null) {
          iconWidget = SvgPicture.asset(
            widget.svgIconPath!,
            colorFilter: ColorFilter.mode(color['text'] as Color? ?? Colors.white, BlendMode.srcIn),
          );
        } else if (widget.icon != null) {
          iconWidget = Icon(
            widget.icon,
            color: color['text'] as Color? ?? Colors.white,
            size: (sizes['fontSize'] as double? ?? 14.0) + 2,
          );
        } else {
          iconWidget = const SizedBox.shrink();
        }

        Widget content;
        if (showText) {
          content = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              SizedBox(width: (iconWidget is! SizedBox ? 4 : 0)),
              Text(
                widget.text!,
                style: TextStyle(
                  color: color['text'] as Color? ?? Colors.white,
                  fontSize: sizes['fontSize'] as double? ?? 14.0,
                ),
              ),
            ],
          );
        } else {
          content = iconWidget;
        }

        final height = sizes['height'] as double? ?? 30.0;

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: Container(
            height: height,
            width: showText ? null : height,
            padding: showText ? (sizes['padding'] as EdgeInsets? ?? const EdgeInsets.symmetric(horizontal: 10)) : const EdgeInsets.all(0),
            decoration: BoxDecoration(
              color: _isHovered ? hoverBackground : (color['background'] as Color? ?? Colors.grey),
              borderRadius: sizes['borderRadius'] as BorderRadius? ?? BorderRadius.circular(20),
            ),
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: sizes['borderRadius'] as BorderRadius? ?? BorderRadius.circular(20),
              child: ClipRect(
                child: Align(
                  alignment: Alignment.center,
                  child: content,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
