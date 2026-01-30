import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/AppTheme.dart';

class AppDropdown<T> extends StatefulWidget {
  const AppDropdown({
    super.key,
    this.items,
    this.value,
    this.onChanged,
    this.onPressed,
    this.text,
    this.theme = "info",
    this.icon,
    this.svgIconPath,
    this.size = "m",
    this.showTextOnBigScreen = false,
    this.showTextAlways = false,
  });

  final List<DropdownMenuItem<T>>? items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final VoidCallback? onPressed;
  final String? text;
  final String theme;
  final IconData? icon;
  final String? svgIconPath;
  final String? size;
  final bool showTextOnBigScreen;
  final bool showTextAlways;

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isConstrained = constraints.maxWidth < 100.0; // Threshold to detect constrained width
        final sizes = context.getThemeSizes('btn_${widget.size}');
        final color = context.getThemeColor('btn_${widget.theme}');
        final hoverBackground = Color.lerp(color?['background'], Colors.black, 0.2);
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
            colorFilter: ColorFilter.mode(color['text'] ?? Colors.white, BlendMode.srcIn),
          );
        } else if (widget.icon != null) {
          iconWidget = Icon(
            widget.icon,
            color: color['text'],
            size: sizes['fontSize'] + 2 ?? 16.0,
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
                  color: color['text'],
                  fontSize: sizes['fontSize'] ?? 14.0,
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.white),
            ],
          );
        } else {
          content = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              const Icon(Icons.arrow_drop_down, color: Colors.white),
            ],
          );
        }

        final height = sizes['height'] ?? 30.0;

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: Container(
            height: height,
            width: showText ? null : height,
            padding: showText ? sizes['padding'] : const EdgeInsets.all(0),
            decoration: BoxDecoration(
              color: _isHovered ? hoverBackground : color['background'],
              borderRadius: sizes['borderRadius'],
            ),
            child: widget.onPressed != null
                ? InkWell(
                    onTap: widget.onPressed,
                    borderRadius: sizes['borderRadius'],
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.center,
                        child: content,
                      ),
                    ),
                  )
                : DropdownButtonHideUnderline(
                    child: DropdownButton<T>(
                      value: widget.value,
                      onChanged: widget.onChanged,
                      items: widget.items,
                      icon: const SizedBox.shrink(), // Hide default icon since we have it in content
                      style: TextStyle(
                        color: color['text'],
                        fontSize: sizes['fontSize'] ?? 14.0,
                      ),
                      dropdownColor: color['background'],
                      borderRadius: sizes['borderRadius'],
                      isExpanded: false,
                      selectedItemBuilder: (BuildContext context) {
                        return widget.items!.map((item) {
                          return Container(
                            alignment: Alignment.center,
                            child: content,
                          );
                        }).toList();
                      },
                    ),
                  ),
          ),
        );
      },
    );
  }
}
