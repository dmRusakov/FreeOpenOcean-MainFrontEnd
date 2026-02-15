// File: `front-end-main/lib/common/element/logo.dart`
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:free_open_ocean/core/theme/AppTheme.dart';
import 'package:free_open_ocean/core/provider/AppThemeProvider.dart';

class Logo extends StatefulWidget {
  const Logo({
    super.key,
    this.size = "m",
    this.onPressed,
  });

  final VoidCallback? onPressed;
  final String? size;

  @override
  State<Logo> createState() => _LogoState();
}

class _LogoState extends State<Logo> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = context.getThemeColor('btn_logo');
    final sizes = context.getThemeSizes('btn_${widget.size}');

    final background = color?['background'];
    final hoverBackground = Color.lerp(background, Colors.black, 0.2);

    final logoWidget = Container(
      height: sizes['height'],
      padding: sizes['padding'],
      alignment: Alignment.center, // vertical centering
      decoration: BoxDecoration(
        color: _isHovered ? (hoverBackground ?? background) : background,
        borderRadius: sizes['borderRadius'],
      ),
      child: Align(
        alignment: sizes['alignment'],
        child: Text(
          'FreeOpenOcean',
          textAlign: TextAlign.center,
          style: GoogleFonts.museoModerno(
            color: color?['text'],
            fontWeight: FontWeight.w400,
            fontSize: sizes['fontSize'],
          ),
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
      ),
    );

    if (widget.onPressed != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: logoWidget,
        ),
      );
    }

    return logoWidget;
  }
}
