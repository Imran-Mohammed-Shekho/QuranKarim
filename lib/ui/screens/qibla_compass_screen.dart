import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../models/prayer_time_model.dart';
import '../../services/device_compass_service.dart';
import '../../services/location_service.dart';
import '../../services/qibla_service.dart';
import '../../state/app_settings_controller.dart';

class LiveQiblaCompassScreen extends StatefulWidget {
  const LiveQiblaCompassScreen({super.key});

  @override
  State<LiveQiblaCompassScreen> createState() => _LiveQiblaCompassScreenState();
}

class _LiveQiblaCompassScreenState extends State<LiveQiblaCompassScreen> {
  final LocationService _locationService = LocationService();

  DeviceLocation? _location;
  String? _errorMessage;
  LocationFailureType? _failureType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _failureType = null;
    });

    final result = await _locationService.getCurrentLocation();
    if (!mounted) {
      return;
    }

    setState(() {
      _location = result.location;
      _errorMessage = result.message;
      _failureType = result.failureType;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<AppSettingsController>().strings;
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.qiblaCompassTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_location == null) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.qiblaCompassTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.65),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_off_rounded,
                    size: 52,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage ?? strings.prayerLoadFailed,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loadLocation,
                    child: Text(strings.retry),
                  ),
                  if (_failureType == LocationFailureType.servicesDisabled) ...[
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _locationService.openLocationSettings,
                      child: Text(strings.openLocationSettings),
                    ),
                  ],
                  if (_failureType ==
                      LocationFailureType.permissionDeniedForever) ...[
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _locationService.openAppSettings,
                      child: Text(strings.openAppSettings),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return QiblaCompassScreen(location: _location!);
  }
}

class QiblaCompassScreen extends StatefulWidget {
  const QiblaCompassScreen({super.key, required this.location});

  final DeviceLocation location;

  @override
  State<QiblaCompassScreen> createState() => _QiblaCompassScreenState();
}

class _QiblaCompassScreenState extends State<QiblaCompassScreen> {
  final DeviceCompassService _compassService = DeviceCompassService();
  StreamSubscription<double>? _headingSubscription;

  double? _heading;
  bool _compassAvailable = false;

  bool get _supportsLiveCompass =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _startCompass();
  }

  void _startCompass() {
    if (!_supportsLiveCompass) {
      return;
    }

    _headingSubscription = _compassService.headingStream().listen(
      (heading) {
        if (!mounted) {
          return;
        }
        setState(() {
          _heading = heading;
          _compassAvailable = true;
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!mounted) {
          return;
        }
        setState(() {
          _heading = null;
          _compassAvailable = false;
        });
      },
      cancelOnError: false,
    );
  }

  @override
  void dispose() {
    _headingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final strings = context.watch<AppSettingsController>().strings;
    final qiblaService = QiblaService();
    final qiblaBearing = qiblaService.qiblaBearing(widget.location);
    final heading = _heading;
    final hasHeading = _compassAvailable && heading != null && !heading.isNaN;
    final rotationDegrees = hasHeading
        ? qiblaService.needleRotation(
            qiblaBearing: qiblaBearing,
            heading: heading,
          )
        : qiblaBearing;
    final difference = hasHeading
        ? qiblaService.angularDifference(
            qiblaBearing: qiblaBearing,
            heading: heading,
          )
        : 0.0;
    final signedTurn = hasHeading
        ? _signedTurnDelta(qiblaBearing: qiblaBearing, heading: heading)
        : 0.0;
    final aligned = hasHeading && difference <= 8;

    return Scaffold(
      appBar: AppBar(title: Text(strings.qiblaCompassTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            strings.qiblaCompassSubtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.22),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.location.city,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  strings.qiblaBearingLabel(
                    qiblaBearing.round(),
                    qiblaService.cardinalDirection(qiblaBearing),
                  ),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _statusText(strings, aligned, difference),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.9),
                  ),
                ),
                if (hasHeading) ...[
                  const SizedBox(height: 16),
                  _TurnInstructionCard(
                    turnDegrees: signedTurn,
                    aligned: aligned,
                    colorScheme: colorScheme,
                    theme: theme,
                    strings: strings,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.68),
              ),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: 280,
                  height: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _CompassRing(colorScheme: colorScheme),
                      const _NorthMarker(),
                      Positioned(
                        top: 26,
                        child: _DirectionBadge(
                          icon: Icons.smartphone_rounded,
                          label: hasHeading ? 'YOU' : 'DEVICE',
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          foregroundColor: colorScheme.onSurface,
                        ),
                      ),
                      AnimatedRotation(
                        turns: ((heading ?? 0) / 360),
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        child: Icon(
                          Icons.navigation_rounded,
                          size: 78,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.42,
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: rotationDegrees / 360,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.navigation_rounded,
                              size: 96,
                              color: aligned
                                  ? colorScheme.primary
                                  : colorScheme.secondary,
                            ),
                            const SizedBox(height: 6),
                            _DirectionBadge(
                              icon: Icons.explore_rounded,
                              label: strings.qiblaLabel.toUpperCase(),
                              backgroundColor: aligned
                                  ? colorScheme.primaryContainer
                                  : colorScheme.secondaryContainer,
                              foregroundColor: aligned
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSecondaryContainer,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.surface,
                            width: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    _MetaChip(
                      label: hasHeading
                          ? strings.compassHeadingLabel(heading.round())
                          : strings.qiblaCompassUnavailable,
                    ),
                    _MetaChip(
                      label: strings.qiblaBearingShort(qiblaBearing.round()),
                    ),
                    if (hasHeading)
                      _MetaChip(
                        label: aligned
                            ? strings.qiblaAligned
                            : strings.qiblaTurnBy(difference.round()),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _hintText(strings),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  String _statusText(AppStrings strings, bool aligned, double difference) {
    if (_compassAvailable && _heading != null) {
      return aligned
          ? strings.qiblaAligned
          : strings.qiblaTurnBy(difference.round());
    }
    return strings.qiblaCompassUnavailable;
  }

  String _hintText(AppStrings strings) {
    if (_supportsLiveCompass) {
      return strings.qiblaCompassHint;
    }
    return strings.qiblaCompassUnavailable;
  }

  double _signedTurnDelta({
    required double qiblaBearing,
    required double heading,
  }) {
    return (((qiblaBearing - heading) + 540) % 360) - 180;
  }
}

class _CompassRing extends StatelessWidget {
  const _CompassRing({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [colorScheme.surface, colorScheme.surfaceContainerHighest],
        ),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Stack(
        children: const [
          _Marker(
            alignment: Alignment.topCenter,
            padding: EdgeInsets.only(top: 54),
            label: 'N',
          ),
          _Marker(
            alignment: Alignment.bottomCenter,
            padding: EdgeInsets.only(bottom: 20),
            label: 'S',
          ),
          _Marker(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.only(left: 20),
            label: 'W',
          ),
          _Marker(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20),
            label: 'E',
          ),
        ],
      ),
    );
  }
}

class _NorthMarker extends StatelessWidget {
  const _NorthMarker();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Positioned(
      top: 12,
      child: Column(
        children: [
          Icon(Icons.arrow_drop_up_rounded, size: 34, color: colorScheme.error),
          Text(
            'N',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({
    required this.alignment,
    required this.padding,
    required this.label,
  });

  final Alignment alignment;
  final EdgeInsets padding;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: padding,
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _DirectionBadge extends StatelessWidget {
  const _DirectionBadge({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TurnInstructionCard extends StatelessWidget {
  const _TurnInstructionCard({
    required this.turnDegrees,
    required this.aligned,
    required this.colorScheme,
    required this.theme,
    required this.strings,
  });

  final double turnDegrees;
  final bool aligned;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final turnLeft = turnDegrees < 0;
    final magnitude = turnDegrees.abs().round();
    final icon = aligned
        ? Icons.check_circle_rounded
        : turnLeft
        ? Icons.turn_left_rounded
        : Icons.turn_right_rounded;
    final title = aligned
        ? strings.qiblaAligned
        : '${turnLeft ? 'LEFT' : 'RIGHT'}  $magnitude°';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.onPrimary, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
