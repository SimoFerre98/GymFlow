import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../core/providers/localization_provider.dart';
import '../../core/theme/expressive_tokens.dart';
import '../../models/exercise.dart';
import '../../models/exercise_media.dart';
import '../../services/video_availability.dart';
import 'toast_utils.dart';

/// L'esecuzione di un esercizio, senza lasciare la schermata da cui si arriva.
///
/// E un foglio modale e non una rotta nuova per la ragione che da il titolo
/// alla storia: `showModalBottomSheet` **non smonta la schermata sotto**. Da una
/// sessione attiva questo significa che il cronometro non smette di battere e
/// che nessuna serie gia registrata viene persa, perche lo stato di
/// `ActiveSessionScreen` resta esattamente dov'era.
class ExerciseVideoSheet extends ConsumerStatefulWidget {
  const ExerciseVideoSheet({super.key, required this.exercise, this.probe});

  final Exercise exercise;

  /// Interrogazione di disponibilita, sostituibile nei test.
  final VideoProbe? probe;

  /// Apre il foglio per [exercise].
  static Future<void> show(
    BuildContext context,
    Exercise exercise, {
    VideoProbe? probe,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ExerciseVideoSheet(exercise: exercise, probe: probe),
    );
  }

  @override
  ConsumerState<ExerciseVideoSheet> createState() => _ExerciseVideoSheetState();
}

class _ExerciseVideoSheetState extends ConsumerState<ExerciseVideoSheet> {
  YoutubePlayerController? _controller;
  VideoAvailability? _availability;

  bool get _hasVideo => widget.exercise.hasSpecificVideo;

  @override
  void initState() {
    super.initState();
    // Chi ha solo una ricerca non ha niente da controllare: non esiste un video
    // di cui chiedere l'esistenza.
    if (_hasVideo) _check();
  }

  Future<void> _check() async {
    final result = await VideoAvailabilityCheck.of(
      widget.exercise.videoUrl,
      probe: widget.probe,
    );
    if (!mounted) return;

    setState(() {
      _availability = result;
      if (result == VideoAvailability.available) {
        _controller = YoutubePlayerController.fromVideoId(
          videoId: YouTubeVideo.idOf(widget.exercise.videoUrl)!,
          // Il criterio "non parte da solo con l'audio a volume pieno" e
          // risolto alla radice: non parte affatto finche non lo si chiede.
          autoPlay: false,
        );
      }
    });
  }

  @override
  void dispose() {
    // Senza questo, l'audio continuerebbe a suonare dopo la chiusura del
    // foglio: la WebView sopravvive al widget finche non la si chiude.
    _controller?.close();
    super.dispose();
  }

  Future<void> _openExternally(String url) async {
    final loc = ref.read(localizationNotifierProvider);
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ToastUtils.showError(context, loc.t('video_open_failed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.expressive;
    final loc = ref.watch(localizationNotifierProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        t.spacing.xl,
        0,
        t.spacing.xl,
        t.spacing.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.exercise.name,
            style: Theme.of(context).textTheme.titleLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: t.spacing.md),
          _body(loc),
        ],
      ),
    );
  }

  Widget _body(Localization loc) {
    // Nessun video scelto: si dice com'e, invece di aprire un riproduttore
    // vuoto o di saltare fuori dall'app senza preavviso.
    if (!_hasVideo) {
      final query = widget.exercise.videoSearchQuery;
      if (query == null || query.trim().isEmpty) {
        return _Message(
          icon: Icons.videocam_off_outlined,
          text: loc.t('video_none'),
        );
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Message(
            icon: Icons.search_outlined,
            text: loc.t('video_search_only'),
          ),
          SizedBox(height: context.expressive.spacing.md),
          FilledButton.icon(
            onPressed: () => _openExternally(YouTubeVideo.searchUrl(query)),
            icon: const Icon(Icons.open_in_new),
            label: Text(loc.t('video_open_search')),
          ),
        ],
      );
    }

    return switch (_availability) {
      null => const _Waiting(),
      VideoAvailability.offline => _Message(
        icon: Icons.wifi_off_outlined,
        text: loc.t('video_offline'),
      ),
      VideoAvailability.unavailable => _Message(
        icon: Icons.error_outline,
        text: loc.t('video_unavailable'),
      ),
      VideoAvailability.available => YoutubePlayer(controller: _controller!),
    };
  }
}

/// Attesa dell'interrogazione: il foglio si apre subito e mostra questo, invece
/// di far aspettare l'utente davanti a niente.
class _Waiting extends StatelessWidget {
  const _Waiting();

  @override
  Widget build(BuildContext context) {
    return const AspectRatio(
      aspectRatio: 16 / 9,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

/// Un messaggio al posto del video: mai una schermata bianca.
class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(t.spacing.xl),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: t.shape.cornerLg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: scheme.onSurfaceVariant),
          SizedBox(height: t.spacing.md),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
