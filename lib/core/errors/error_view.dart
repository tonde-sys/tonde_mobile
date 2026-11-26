import 'package:flutter/material.dart';
import 'package:tonde/core/errors/app_exception.dart';
import 'package:tonde/core/errors/user_message.dart';
import 'package:tonde/core/logging/app_logger.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Affichage unifié d'une erreur : une icône, une phrase, une action, et le
/// détail technique replié.
///
/// L'écran ne doit jamais montrer `DioException`, un statut HTTP ou un message
/// du serveur non traduit. Ce qui reste visible sans action de l'utilisateur :
/// la phrase, et une référence courte à donner au support. Le reste est
/// derrière « Détails techniques » — présent pour le diagnostic, jamais imposé.
class ErrorView extends StatefulWidget {
  const ErrorView({
    super.key,
    required this.error,
    this.onAction,
    this.compact = false,
  });

  /// Erreur brute ; sa traduction est faite ici, à un seul endroit.
  final Object error;

  /// Comportement de l'action principale. Sans lui, aucun bouton n'est affiché :
  /// une action sans destination serait un bouton mort.
  final VoidCallback? onAction;

  /// Version resserrée, pour une carte ou une section plutôt qu'un écran entier.
  final bool compact;

  @override
  State<ErrorView> createState() => _ErrorViewState();
}

class _ErrorViewState extends State<ErrorView> {
  late final String _incidentId = incidentIdFor(widget.error);

  @override
  void initState() {
    super.initState();
    // Journalisé une fois par affichage, avec la même référence que l'écran :
    // c'est ce qui permet au support de retrouver la trace exacte.
    //
    // Rien de sensible n'est écrit : ni jeton, ni corps de requête, ni message
    // du serveur (il peut recopier une saisie de l'utilisateur).
    final error = widget.error;
    AppLogger.debug(
      'incident=$_incidentId '
      'type=${error.runtimeType}'
      '${error is ApiException ? ' code=${error.code} status=${error.statusCode}' : ''}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = userMessageFor(l10n, widget.error);
    final colorScheme = Theme.of(context).colorScheme;
    final actionLabel = actionLabelFor(l10n, message.action);

    final content = Column(
      mainAxisSize: widget.compact ? MainAxisSize.min : MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          _iconFor(widget.error),
          size: widget.compact ? 36 : 56,
          color: colorScheme.error,
        ),
        SizedBox(height: widget.compact ? 8 : 16),
        Text(
          message.message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (message.detail != null) ...[
          const SizedBox(height: 6),
          Text(
            message.detail!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (actionLabel != null && widget.onAction != null) ...[
          const SizedBox(height: 16),
          FilledButton(
            onPressed: widget.onAction,
            child: Text(actionLabel),
          ),
        ],
        const SizedBox(height: 8),
        _TechnicalDetails(error: widget.error, incidentId: _incidentId),
      ],
    );

    if (widget.compact) {
      return Padding(padding: const EdgeInsets.all(16), child: content);
    }
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: content,
        ),
      ),
    );
  }

  /// L'icône dit la nature de la panne avant la phrase : réseau coupé, serveur
  /// en difficulté, ou refus métier.
  IconData _iconFor(Object error) {
    if (error is NetworkException ||
        error is RequestTimeoutException ||
        error is SecureConnectionException) {
      return Icons.wifi_off_outlined;
    }
    if (error is ApiException && error.statusCode >= 500) {
      return Icons.cloud_off_outlined;
    }
    return Icons.info_outline;
  }
}

/// Détail replié : référence d'incident, type d'erreur, code et statut.
///
/// Replié par défaut, mais présent : sans lui, un utilisateur qui appelle le
/// support ne peut rien transmettre d'exploitable, et le support ne peut pas
/// distinguer « panne » de « quota atteint ».
class _TechnicalDetails extends StatelessWidget {
  const _TechnicalDetails({required this.error, required this.incidentId});

  final Object error;
  final String incidentId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final error = this.error;

    final lines = <String>[
      l10n.errIncident(incidentId),
      if (error is ApiException && error.code != null) error.code!,
      if (error is ApiException) 'HTTP ${error.statusCode}',
    ];

    return Theme(
      // Le thème retire les séparateurs des ExpansionTile : ici on veut la
      // ligne discrète standard, pas une carte.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text(
          l10n.errTechnicalDetails,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        children: [
          SelectableText(
            lines.join('\n'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
