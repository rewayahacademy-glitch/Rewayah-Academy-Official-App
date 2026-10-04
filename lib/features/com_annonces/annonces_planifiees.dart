// Les annonces publiees et planifiees de l'Administration des communications
// (COM-W04, spec section 17 ; COM-BR-10).
//
// Deux sections lues par le meme port (`PortAnnonces.annoncesAdministration`)
// : les annonces publiees sur la periode du serveur, puis les planifiees. Une
// ligne dit le titre, l'audience, la date et son etat en mot (« Publiee »,
// « Planifiee ») : cet etat vient de la lecture serveur, jamais d'une
// supposition de l'ecran (spec section 20).
//
// Ce que la maquette montre et qui n'est pas repris : la fleche de tendance,
// les vues et les commentaires d'une annonce (une annonce n'est pas un fil,
// spec section 13.3 ; UX_REVIEW L0, ecart 16).
//
// Donnees de demonstration : la section le dit en clair (« Démonstration »)
// sous son titre (COM-BR-A08).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/vue_etat_communication.dart';
import '../suivi_foyer/filtres_historique.dart';
import 'port_annonces.dart';

/// L'etat propre a une erreur de lecture de l'Administration des
/// communications : hors ligne, la phrase de la spec section 22 ; sinon le
/// traitement par defaut de `BlocAsynchrone` (capacite absente sans
/// « Reessayer », echec avec « Reessayer »).
Widget? etatErreurAdministration(
  WidgetRef ref,
  Object erreur,
  VoidCallback? reessayer,
) {
  if (ref.read(horsLigneProvider).value ?? false) {
    return VueEtatCommunication(
      etat: EtatCommunication.horsLigne,
      onReessayer: reessayer,
    );
  }
  return null;
}

/// La marque « Démonstration » d'une section dont les donnees sont des
/// fixtures : un mot et une pastille, jamais la couleur seule.
class MarqueDemonstration extends StatelessWidget {
  /// Cree la marque.
  const MarqueDemonstration({super.key});

  /// La cle de la marque, pour les tests.
  static const ValueKey<String> cle = ValueKey<String>(
    'administration-demonstration',
  );

  @override
  Widget build(BuildContext context) {
    final a = t.com.annonces.administration;
    return Semantics(
      key: cle,
      label: a.demoDetail,
      excludeSemantics: true,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: StatusPill(libelle: a.demo, ton: TonEtat.neutre),
      ),
    );
  }
}

/// L'en-tete d'une section de l'Administration : titre, nombre (zero
/// compris), et la marque de demonstration s'il y a lieu.
class EnTeteSectionAdministration extends StatelessWidget {
  /// Cree l'en-tete.
  const EnTeteSectionAdministration({
    required this.titre,
    super.key,
    this.compteur,
    this.demonstration = false,
    this.detail,
  });

  /// Le titre de la section.
  final String titre;

  /// Le nombre d'elements, s'il est connu.
  final int? compteur;

  /// Vrai pour des donnees de demonstration.
  final bool demonstration;

  /// Une phrase sous le titre, facultative.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String? d = detail;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(titre: titre, compteur: compteur),
        if (d != null) ...<Widget>[
          Ecart.vXs,
          Text(
            d,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
        if (demonstration) ...<Widget>[Ecart.vSm, const MarqueDemonstration()],
      ],
    );
  }
}

/// Une section d'annonces de l'Administration : les publiees, ou les
/// planifiees ([etat]).
class SectionAnnoncesAdministration extends ConsumerWidget {
  /// Cree la section.
  const SectionAnnoncesAdministration({required this.etat, super.key});

  /// Publiees ou planifiees.
  final EtatAnnonce etat;

  /// La cle d'une section, pour les tests.
  static ValueKey<String> cleSection(EtatAnnonce etat) =>
      ValueKey<String>('administration-section-${etat.name}');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = t.com.annonces.administration;
    final String titre = switch (etat) {
      EtatAnnonce.publiee => a.publiees.titre,
      EtatAnnonce.planifiee => a.planifiees.titre,
    };
    final AsyncValue<AnnoncesAdministration> lue = ref.watch(
      annoncesAdministrationProvider,
    );
    final AnnoncesAdministration? vue = lue.value;
    final List<AnnonceAdministration>? liste = vue == null ? null : _liste(vue);
    return Column(
      key: cleSection(etat),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        EnTeteSectionAdministration(
          titre: titre,
          compteur: lue.hasError ? null : liste?.length,
          demonstration: vue?.demonstration ?? false,
        ),
        Ecart.vMd,
        BlocAsynchrone<AnnoncesAdministration>(
          valeur: lue,
          squelette: const Skeleton.liste(lignes: 2),
          onReessayer: () => ref.invalidate(annoncesAdministrationProvider),
          erreurVersEtat: (Object e, VoidCallback? r) =>
              etatErreurAdministration(ref, e, r),
          estVide: (AnnoncesAdministration v) => _liste(v).isEmpty,
          vide: EtatSysteme(
            nature: NatureEtat.aucunResultat,
            titre: switch (etat) {
              EtatAnnonce.publiee => a.publiees.vide,
              EtatAnnonce.planifiee => a.planifiees.vide,
            },
            phrase: '',
          ),
          construire: (AnnoncesAdministration v) => GroupeReglages(
            lignes: <LigneRubrique>[
              for (final AnnonceAdministration annonce in _liste(v))
                ligneAnnonceAdministration(annonce),
            ],
          ),
        ),
      ],
    );
  }

  List<AnnonceAdministration> _liste(AnnoncesAdministration v) =>
      switch (etat) {
        EtatAnnonce.publiee => v.publiees,
        EtatAnnonce.planifiee => v.planifiees,
      };
}

/// La ligne d'une annonce : titre, pastille d'etat (un mot), « audience ·
/// date ».
LigneRubrique ligneAnnonceAdministration(AnnonceAdministration annonce) {
  final a = t.com.annonces.administration;
  final DateTime le = annonce.le.toLocal();
  final String date = dateCourte(le);
  final String heure = heureMinute(le);
  return switch (annonce.etat) {
    EtatAnnonce.publiee => LigneRubrique(
      libelle: annonce.titre,
      pastille: StatusPill(libelle: a.publiees.pastille, ton: TonEtat.succes),
      legende: a.publiees.legende(
        cible: annonce.cible.libelle,
        date: date,
        heure: heure,
      ),
    ),
    EtatAnnonce.planifiee => LigneRubrique(
      libelle: annonce.titre,
      pastille: StatusPill(libelle: a.planifiees.pastille, ton: TonEtat.accent),
      legende: a.planifiees.legende(
        cible: annonce.cible.libelle,
        date: date,
        heure: heure,
      ),
    ),
  };
}
