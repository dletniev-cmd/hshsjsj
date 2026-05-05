import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';
import '../theme/solar_icons.dart';
import 'glass_surface.dart';

/// Floating top bar — transparent background, glass pill buttons.
/// Matches the #topbar + #topbar-blur layout in the HTML prototype.
class TopBar extends StatefulWidget {
  final int nodeCount;
  final VoidCallback? onMenuTap;
  final VoidCallback? onLayersTap;
  final VoidCallback? onExportTap;

  const TopBar({
    super.key,
    this.nodeCount = 0,
    this.onMenuTap,
    this.onLayersTap,
    this.onExportTap,
  });

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> with SingleTickerProviderStateMixin {
  late AnimationController _saveCtrl;
  bool _showSaved = false;

  @override
  void initState() {
    super.initState();
    _saveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    // Simulate auto-save flicker after 2s
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showSaved = true);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _showSaved = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _saveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Stack(
        children: [
          // Gradient veil (topbar-blur equivalent)
          IgnorePointer(
            child: Container(
              height: top + 88,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.35, 0.65, 1.0],
                  colors: [
                    Color(0xE0000000),
                    Color(0xB8000000),
                    Color(0x73000000),
                    Color(0x00000000),
                  ],
                ),
              ),
            ),
          ),
          // Actual bar content
          Positioned(
            top: top + 10,
            left: 12,
            right: 12,
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  // Logo
                  const _Logo(),
                  const SizedBox(width: 10),

                  // Node count badge
                  _NodeCountBadge(count: widget.nodeCount),

                  const SizedBox(width: 8),

                  // Auto-save tag
                  AnimatedOpacity(
                    opacity: _showSaved ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: _AutoSaveTag(),
                  ),

                  const Spacer(),

                  // Layers button
                  GlassButton(
                    onTap: widget.onLayersTap,
                    minWidth: 40,
                    child: SvgPicture.string(
                      SolarIcons.layers,
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        AppColors.text,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Export button
                  GlassButton(
                    onTap: widget.onExportTap,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.string(
                          SolarIcons.menu,
                          width: 18,
                          height: 18,
                          colorFilter: const ColorFilter.mode(
                            AppColors.text,
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: 'BotFlow',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.accent,
                letterSpacing: -0.5,
                shadows: [
                  Shadow(
                    color: Color(0x8C000000),
                    blurRadius: 14,
                  ),
                ],
              ),
            ),
            TextSpan(
              text: ' builder',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: AppColors.textDim,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NodeCountBadge extends StatelessWidget {
  final int count;
  const _NodeCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count nodes',
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textDim,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _AutoSaveTag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent3.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.string(
            SolarIcons.checkCircle,
            width: 12,
            height: 12,
            colorFilter: const ColorFilter.mode(
              AppColors.accent3,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'Saved',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.accent3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
