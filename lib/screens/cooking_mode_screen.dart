import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/recipe.dart';
import '../widgets/step_illustration.dart';

/// Modo cocina: un paso a la vez, letra grande, temporizadores y pantalla
/// siempre encendida.
class CookingModeScreen extends StatefulWidget {
  const CookingModeScreen({super.key, required this.recipe});

  final Recipe recipe;

  @override
  State<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen> {
  final _pageController = PageController();
  int _page = 0;

  // Un temporizador activo a la vez, ligado al paso que lo inició.
  int? _timerStep;
  DateTime? _timerEnd;
  Duration _timerRemaining = Duration.zero;
  Duration _timerTotal = Duration.zero;
  bool _timerPaused = false;
  Timer? _ticker;

  List<RecipeStep> get steps => widget.recipe.steps;
  bool get _isLastPage => _page == steps.length;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pageController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // ---------- Temporizador ----------
  void _startTimer(int stepIndex, int minutes) {
    _ticker?.cancel();
    final total = Duration(minutes: minutes);
    setState(() {
      _timerStep = stepIndex;
      _timerTotal = total;
      _timerRemaining = total;
      _timerEnd = DateTime.now().add(total);
      _timerPaused = false;
    });
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  void _tick() {
    if (_timerEnd == null || _timerPaused) return;
    final remaining = _timerEnd!.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _ticker?.cancel();
      final step = _timerStep;
      setState(() {
        _timerRemaining = Duration.zero;
        _timerEnd = null;
      });
      _onTimerDone(step);
    } else {
      setState(() => _timerRemaining = remaining);
    }
  }

  void _togglePause() {
    setState(() {
      if (_timerPaused) {
        _timerEnd = DateTime.now().add(_timerRemaining);
        _timerPaused = false;
      } else {
        _timerPaused = true;
      }
    });
  }

  void _cancelTimer() {
    _ticker?.cancel();
    setState(() {
      _timerStep = null;
      _timerEnd = null;
      _timerPaused = false;
    });
  }

  Future<void> _onTimerDone(int? step) async {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Text('⏰', style: TextStyle(fontSize: 40)),
        title: const Text('¡Tiempo cumplido!'),
        content: Text(
          step == null
              ? 'El temporizador terminó.'
              : 'Terminó el tiempo del paso ${step + 1}.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Listo'),
          ),
        ],
      ),
    );
    if (mounted) setState(() => _timerStep = null);
  }

  String _format(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = (_page + 1) / (steps.length + 1);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.name, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          tooltip: 'Salir del modo cocina',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: progress),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_timerStep != null && _timerStep != _page)
              _MiniTimerBar(
                label: 'Paso ${_timerStep! + 1}',
                time: _format(_timerRemaining),
                paused: _timerPaused,
                onTap: () => _goTo(_timerStep!),
              ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: steps.length + 1,
                onPageChanged: (p) => setState(() => _page = p),
                itemBuilder: (context, index) {
                  if (index == steps.length) return const _DonePage();
                  final step = steps[index];
                  return _StepPage(
                    recipe: widget.recipe,
                    index: index,
                    total: steps.length,
                    step: step,
                    timer: step.timerMinutes == null
                        ? null
                        : _StepTimer(
                            minutes: step.timerMinutes!,
                            active: _timerStep == index,
                            remaining: _format(_timerRemaining),
                            fraction: _timerTotal.inMilliseconds == 0
                                ? 0
                                : _timerRemaining.inMilliseconds /
                                      _timerTotal.inMilliseconds,
                            paused: _timerPaused,
                            onStart: () =>
                                _startTimer(index, step.timerMinutes!),
                            onPause: _togglePause,
                            onCancel: _cancelTimer,
                          ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 56),
                      ),
                      onPressed: _page == 0 ? null : () => _goTo(_page - 1),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Anterior'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 56),
                        backgroundColor: _isLastPage ? scheme.tertiary : null,
                      ),
                      onPressed: _isLastPage
                          ? () => Navigator.of(context).pop()
                          : () => _goTo(_page + 1),
                      icon: Icon(
                        _isLastPage ? Icons.check : Icons.arrow_forward,
                      ),
                      label: Text(_isLastPage ? 'Terminar' : 'Siguiente'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepPage extends StatelessWidget {
  const _StepPage({
    required this.recipe,
    required this.index,
    required this.total,
    required this.step,
    this.timer,
  });

  final Recipe recipe;
  final int index;
  final int total;
  final RecipeStep step;
  final Widget? timer;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepIllustration(recipe: recipe, step: step),
          const SizedBox(height: 20),
          Text(
            'Paso ${index + 1} de $total',
            style: text.titleMedium?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            step.text,
            style: text.headlineSmall?.copyWith(height: 1.4, fontSize: 26),
          ),
          if (timer != null) ...[const SizedBox(height: 32), timer!],
        ],
      ),
    );
  }
}

class _StepTimer extends StatelessWidget {
  const _StepTimer({
    required this.minutes,
    required this.active,
    required this.remaining,
    required this.fraction,
    required this.paused,
    required this.onStart,
    required this.onPause,
    required this.onCancel,
  });

  final int minutes;
  final bool active;
  final String remaining;
  final double fraction;
  final bool paused;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!active) {
      return FilledButton.tonalIcon(
        style: FilledButton.styleFrom(minimumSize: const Size(220, 64)),
        onPressed: onStart,
        icon: const Icon(Icons.timer_outlined, size: 28),
        label: Text(
          'Iniciar temporizador · $minutes min',
          style: const TextStyle(fontSize: 18),
        ),
      );
    }
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: CircularProgressIndicator(
                value: fraction,
                strokeWidth: 6,
                backgroundColor: scheme.surface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                remaining,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onPrimaryContainer,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            IconButton.filled(
              tooltip: paused ? 'Continuar' : 'Pausar',
              iconSize: 28,
              onPressed: onPause,
              icon: Icon(paused ? Icons.play_arrow : Icons.pause),
            ),
            IconButton(
              tooltip: 'Cancelar temporizador',
              onPressed: onCancel,
              icon: const Icon(Icons.stop),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniTimerBar extends StatelessWidget {
  const _MiniTimerBar({
    required this.label,
    required this.time,
    required this.paused,
    required this.onTap,
  });

  final String label;
  final String time;
  final bool paused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                paused ? Icons.pause_circle : Icons.timer,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Temporizador · $label',
                  style: TextStyle(color: scheme.onPrimaryContainer),
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: scheme.onPrimaryContainer,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonePage extends StatelessWidget {
  const _DonePage();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            Text(
              '¡Buen provecho!',
              style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Terminaste la receta.',
              style: text.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
