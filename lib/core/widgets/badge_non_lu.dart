// Le badge d'attention des communications (`UnreadUrgencyBadge`, spec
// section 19 ; accessibilite section 24 : « statut non lu annonce », « urgence
// annoncee par texte », « aucune information encodee uniquement par
// couleur »).
//
// Pose sur `StatusPill` : chaque pastille dit un MOT et porte une ICONE, la
// couleur ne fait que doubler l'information. Le badge lit un
// `IndicateurAttention` deja calcule par le port, jamais le role de la
// personne connectee.

import 'package:flutter/material.dart';

import '../communications/modeles_communication.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'status_pill.dart';

/// Ce qu'une pastille du badge dit : un mot, une icone, une famille.
@immutable
class _Pastille {
  const _Pastille(this.libelle, this.icone, this.ton, this.cle);

  final String libelle;
  final AppIcon icone;
  final TonEtat ton;
  final String cle;
}

/// Le badge non lu et urgence (`UnreadUrgencyBadge`).
///
/// Trois informations au plus, chacune en toutes lettres et avec son icone :
///
/// - le **niveau** quand il demande quelque chose (« Action requise »,
///   « Urgent »), ou « A lire » quand rien n'est compte ;
/// - le **nombre de non-lus** (« 3 non lus ») ;
/// - la **mention** de la personne qui lit (« Mention »).
///
/// Le niveau passe en tete : une urgence se lit avant un compte. Rien a
/// signaler ([IndicateurAttention.estVisible] faux) : rien n'est rendu, pas un
/// « 0 ». [compact] ne montre que la pastille la plus pressante, pour une
/// ligne de liste etroite ; le lecteur d'ecran entend toujours la phrase
/// entiere ([phraseSemantique]).
class BadgeNonLu extends StatelessWidget {
  /// Cree le badge.
  const BadgeNonLu({required this.indicateur, super.key, this.compact = false});

  /// Ce que le badge doit dire.
  final IndicateurAttention indicateur;

  /// Vrai : une seule pastille visible, la plus pressante.
  final bool compact;

  /// La cle de la pastille du niveau, pour les tests.
  static const ValueKey<String> cleNiveau = ValueKey<String>('badge-niveau');

  /// La cle de la pastille des non-lus, pour les tests.
  static const ValueKey<String> cleNonLus = ValueKey<String>('badge-non-lus');

  /// La cle de la pastille de mention, pour les tests.
  static const ValueKey<String> cleMention = ValueKey<String>('badge-mention');

  /// Le mot d'un niveau d'attention.
  static String libelleNiveau(NiveauAttention niveau) {
    final b = t.com.socle.composants.badge;
    return switch (niveau) {
      NiveauAttention.information => b.information,
      NiveauAttention.aLire => b.aLire,
      NiveauAttention.actionRequise => b.actionRequise,
      NiveauAttention.urgent => b.urgent,
    };
  }

  /// L'icone d'un niveau d'attention.
  static AppIcon iconeNiveau(NiveauAttention niveau) => switch (niveau) {
    NiveauAttention.information => AppIcons.info,
    NiveauAttention.aLire => AppIcons.oeil,
    NiveauAttention.actionRequise => AppIcons.flecheAction,
    NiveauAttention.urgent => AppIcons.avertissement,
  };

  /// La famille d'un niveau d'attention : l'alerte pour l'urgence seule.
  static TonEtat tonNiveau(NiveauAttention niveau) => switch (niveau) {
    NiveauAttention.information => TonEtat.neutre,
    NiveauAttention.aLire => TonEtat.accent,
    NiveauAttention.actionRequise => TonEtat.avertissement,
    NiveauAttention.urgent => TonEtat.alerte,
  };

  /// Le compte visible des non-lus (« 1 non lu », « 3 non lus »).
  static String libelleNonLus(int nombre) {
    final b = t.com.socle.composants.badge;
    return nombre == 1 ? b.nonLuUn : b.nonLus(nombre: nombre);
  }

  /// La phrase entiere lue par le lecteur d'ecran, ou `null` si rien n'est a
  /// dire.
  static String? phraseSemantique(IndicateurAttention indicateur) {
    if (!indicateur.estVisible) return null;
    final b = t.com.socle.composants.badge;
    final List<String> morceaux = <String>[
      if (_niveauDit(indicateur)) libelleNiveau(indicateur.niveau),
      if (indicateur.nonLus == 1)
        b.nonLuUnSemantique
      else if (indicateur.nonLus > 1)
        b.nonLusSemantique(nombre: indicateur.nonLus),
      if (indicateur.mention) b.mentionSemantique,
    ];
    return morceaux.join(', ');
  }

  /// Vrai si le niveau merite sa propre pastille : il demande quelque chose,
  /// ou il dit « A lire » sans compte qui le dirait deja.
  static bool _niveauDit(IndicateurAttention i) =>
      i.niveau.estAuMoins(NiveauAttention.actionRequise) ||
      (i.niveau == NiveauAttention.aLire && i.nonLus == 0);

  List<_Pastille> _pastilles() {
    final b = t.com.socle.composants.badge;
    final IndicateurAttention i = indicateur;
    return <_Pastille>[
      if (_niveauDit(i))
        _Pastille(
          libelleNiveau(i.niveau),
          iconeNiveau(i.niveau),
          tonNiveau(i.niveau),
          'niveau',
        ),
      if (i.nonLus > 0)
        _Pastille(
          libelleNonLus(i.nonLus),
          AppIcons.notifications,
          TonEtat.accent,
          'non-lus',
        ),
      if (i.mention)
        _Pastille(b.mention, AppIcons.profil, TonEtat.accent, 'mention'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final String? phrase = phraseSemantique(indicateur);
    if (phrase == null) return const SizedBox.shrink();
    final List<_Pastille> toutes = _pastilles();
    final List<_Pastille> vues = compact ? toutes.take(1).toList() : toutes;
    return Semantics(
      container: true,
      label: phrase,
      excludeSemantics: true,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: <Widget>[
          for (final _Pastille p in vues)
            StatusPill(
              key: ValueKey<String>('badge-${p.cle}'),
              libelle: p.libelle,
              ton: p.ton,
              marqueur: _IconeBadge(icone: p.icone, ton: p.ton),
            ),
        ],
      ),
    );
  }
}

/// L'icone d'une pastille du badge, a l'encre de sa paire douce : elle prend
/// la place du disque de couleur, si bien que l'etat se lit sans la couleur.
class _IconeBadge extends StatelessWidget {
  const _IconeBadge({required this.icone, required this.ton});

  final AppIcon icone;
  final TonEtat ton;

  /// Deux fois le disque de statut, comme l'icone d'une seance annulee.
  static const double _taille = AppSpacing.lg;

  @override
  Widget build(BuildContext context) => Icon(
    icone.actif,
    size: _taille,
    color: AppPalette.of(context).paireDe(ton).onBackground,
  );
}
