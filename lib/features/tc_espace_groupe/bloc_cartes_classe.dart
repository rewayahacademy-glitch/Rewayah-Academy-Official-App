// CARTES-PERSO-1 : l'emplacement « Cartes de la classe » de l'espace de
// classe (decision du 05/10, deleguee par le directeur ; fiche CLS-CARTES,
// `docs/current/DASH_STRATEGIE.md` annexe A).
//
// L'enseignant de la Classe touche une carte pour la modifier ; le tuteur,
// l'eleve enfant (Interface guidee) et l'eleve adulte la lisent. Le droit de
// modifier est une CAPACITE rendue par la lecture
// (`CartesClasseVM.peutModifier`), jamais un role.
//
// Cinq etats : chargement (squelette en liste), contenu, vide, erreur
// (« Reessayer »), hors ligne. Hors ligne se dit une fois (K-42) : le bandeau
// de `PageShell` est le signal ; des cartes deja lues restent affichees ; sans
// elles, `EtatSansDonnees` dit ce qui manque. Une capacite absente (production
// avant BR-1) est dite « pas encore ouvertes », sans « Reessayer ».

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/tc_groupe/cartes_classe.dart';
import '../../core/tc_horloge/horloge_supabase.dart' show dateRendue;
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import 'feuille_carte_classe.dart';

/// Une echeance rendue en mots : « Lundi 12 octobre ».
String echeanceRendue(DateTime date) => dateRendue(
  jourIso: date.weekday,
  dateIso:
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}',
);

/// Le libelle d'un modele de carte.
String libelleTypeCarte(TypeCarteClasse type) => switch (type) {
  TypeCarteClasse.annonce => t.classe.cartes.types.annonce,
  TypeCarteClasse.devoir => t.classe.cartes.types.devoir,
  TypeCarteClasse.lien => t.classe.cartes.types.lien,
  TypeCarteClasse.rappel => t.classe.cartes.types.rappel,
};

/// L'icone d'un modele de carte.
AppIcon iconeTypeCarte(TypeCarteClasse type) => switch (type) {
  TypeCarteClasse.annonce => AppIcons.info,
  TypeCarteClasse.devoir => AppIcons.lecon,
  TypeCarteClasse.lien => AppIcons.livreOuvert,
  TypeCarteClasse.rappel => AppIcons.horloge,
};

/// L'emplacement « Cartes de la classe ».
class BlocCartesClasse extends ConsumerStatefulWidget {
  /// Cree l'emplacement.
  const BlocCartesClasse({
    required this.groupeId,
    super.key,
    this.prochaineSeance,
  });

  /// La Classe.
  final String groupeId;

  /// Le debut de la prochaine seance, quand l'hote le connait : il devient
  /// l'echeance proposee d'un devoir ou d'un rappel (K-57, deduit).
  final DateTime? prochaineSeance;

  /// La cle du bloc « rien a afficher » hors ligne.
  static const Key sansDonneesKey = Key('classe.cartes.sansDonnees');

  /// La cle du lien « Ajouter une carte ».
  static const Key ajouterKey = Key('classe.cartes.ajouter');

  @override
  ConsumerState<BlocCartesClasse> createState() => _BlocCartesClasseEtat();
}

class _BlocCartesClasseEtat extends ConsumerState<BlocCartesClasse> {
  String? _message;

  void _relire() => ref.invalidate(cartesClasseProvider(widget.groupeId));

  Future<void> _editer(CarteClasse? carte) async {
    final String? retour = await AppBottomSheet.ouvrir<String>(
      context,
      titre: carte == null
          ? t.classe.cartes.feuille.titreNouvelle
          : t.classe.cartes.feuille.titreModifier(titre: carte.titre),
      constructeur: (BuildContext _) => FeuilleCarteClasse(
        groupeId: widget.groupeId,
        carte: carte,
        prochaineSeance: widget.prochaineSeance,
      ),
    );
    if (!mounted || retour == null) return;
    _relire();
    setState(() => _message = retour);
  }

  Future<void> _copier(CarteClasse carte) async {
    final String? lien = carte.lien;
    if (lien == null) return;
    await Clipboard.setData(ClipboardData(text: lien));
    if (!mounted) return;
    setState(() => _message = t.classe.cartes.lienCopie);
  }

  @override
  Widget build(BuildContext context) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final AsyncValue<CartesClasseVM> lecture = lectureHorsLigne(
      ref.watch(cartesClasseProvider(widget.groupeId)),
      horsLigne: horsLigne,
    );
    final Widget corps = sansDonneesHorsLigne(lecture, horsLigne: horsLigne)
        ? EtatSansDonnees(
            key: BlocCartesClasse.sansDonneesKey,
            quoi: t.classe.cartes.sansDonnees,
            onAction: _relire,
          )
        : BlocAsynchrone<CartesClasseVM>(
            valeur: lecture,
            squelette: const Skeleton.liste(lignes: 2),
            onReessayer: _relire,
            titreEchec: t.classe.cartes.erreurLecture,
            erreurVersEtat: (Object erreur, VoidCallback? _) =>
                erreur is CapaciteIndisponible
                ? EtatSysteme(
                    nature: NatureEtat.indisponible,
                    titre: t.classe.cartes.indisponibleTitre,
                    phrase: t.classe.cartes.indisponiblePhrase,
                    dependance: erreur.dependance,
                  )
                : null,
            // Sans carte et sans droit de modifier : un vide subi. Celui qui
            // peut modifier voit, lui, de quoi ajouter la premiere.
            estVide: (CartesClasseVM vue) =>
                vue.cartes.isEmpty && !vue.peutModifier,
            vide: EmptyState(
              message: t.classe.cartes.aucune,
              invitation: t.classe.cartes.aucuneDetail,
              icone: AppIcons.rienAAfficher,
              registre: RegistreVide.subi,
            ),
            construire: (CartesClasseVM vue) => _Contenu(
              vue: vue,
              horsLigne: horsLigne,
              onEditer: _editer,
              onCopier: _copier,
            ),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(titre: t.classe.cartes.titre),
        Ecart.vMd,
        corps,
        LocalFeedback(message: _message),
      ],
    );
  }
}

/// Les cartes, et pour l'enseignant la phrase de contexte et l'ajout.
class _Contenu extends StatelessWidget {
  const _Contenu({
    required this.vue,
    required this.horsLigne,
    required this.onEditer,
    required this.onCopier,
  });

  final CartesClasseVM vue;
  final bool horsLigne;
  final Future<void> Function(CarteClasse? carte) onEditer;
  final Future<void> Function(CarteClasse carte) onCopier;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    // Hors ligne, rien ne s'enregistrerait : les cartes ne se pressent plus
    // et l'ajout n'est pas rendu (jamais grise). Une phrase dit quand ce sera
    // possible, sans redire le reseau (K-42).
    final bool modifiable = vue.peutModifier && !horsLigne;
    final List<CarteClasse> cartes = trierCartes(vue.cartes);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (vue.peutModifier) ...<Widget>[
          Text(
            modifiable
                ? (cartes.isEmpty
                      ? t.classe.cartes.aucuneEnseignant
                      : t.classe.cartes.contexteEnseignant)
                : t.classe.cartes.modificationPlusTard,
            style: textes.bodyMedium,
          ),
          if (cartes.isNotEmpty) Ecart.vLg,
        ],
        PileCartes(
          children: <Widget>[
            for (final CarteClasse carte in cartes)
              VueCarteClasse(
                key: ValueKey<String>('carte-classe-${carte.id}'),
                carte: carte,
                onModifier: modifiable ? () => onEditer(carte) : null,
                onCopierLien: () => onCopier(carte),
              ),
          ],
        ),
        if (modifiable) ...<Widget>[
          Ecart.vMd,
          if (vue.peutAjouter)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: LienFleche(
                key: BlocCartesClasse.ajouterKey,
                libelle: t.classe.cartes.ajouter,
                icone: AppIcons.ajouter,
                onPress: () => onEditer(null),
              ),
            )
          else
            Text(
              t.classe.cartes.limite(max: BornesCarteClasse.cartesMax),
              style: textes.bodySmall,
            ),
        ],
      ],
    );
  }
}

/// Une carte de la Classe.
///
/// [onModifier] non nul (l'enseignant, en ligne) : TOUTE la carte se presse
/// et ouvre sa modification ; le lien se lit alors en clair, sans bouton
/// (jamais un bouton dans un bouton). Sinon, le lien est une action : une
/// ligne avec fleche en presentation standard, un bouton pleine largeur en
/// Interface guidee (decision du 05/10 : « lien en bouton »).
class VueCarteClasse extends StatelessWidget {
  /// Cree la carte.
  const VueCarteClasse({
    required this.carte,
    required this.onCopierLien,
    super.key,
    this.onModifier,
  });

  /// La carte.
  final CarteClasse carte;

  /// Ouvre la modification, ou nul quand la carte se lit seulement.
  final VoidCallback? onModifier;

  /// Copie le lien de la carte.
  final VoidCallback onCopierLien;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final bool guidee = AppMetriques.of(context).estEnfant;
    final String? texte = carte.texte;
    final String? lien = carte.lien;
    final DateTime? echeance = carte.echeance;
    final TextStyle discret = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final VoidCallback? modifier = onModifier;

    final Widget contenu = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // En Interface guidee, le modele ne se dit pas : le titre et le texte
        // suffisent (decision du 05/10).
        if (!guidee) ...<Widget>[
          Row(
            children: <Widget>[
              ExcludeSemantics(
                child: Icon(
                  iconeTypeCarte(carte.type).repos,
                  size: AppSpacing.lg,
                ),
              ),
              Ecart.hSm,
              Expanded(
                child: Text(libelleTypeCarte(carte.type), style: discret),
              ),
              if (modifier != null)
                ExcludeSemantics(
                  child: Icon(AppIcons.crayon.repos, size: AppSpacing.lg),
                ),
            ],
          ),
          Ecart.vSm,
        ],
        Text(carte.titre, style: textes.titleSmall),
        if (texte != null && texte.isNotEmpty) ...<Widget>[
          Ecart.vXs,
          Text(texte, style: textes.bodyMedium),
        ],
        if (echeance != null) ...<Widget>[
          Ecart.vSm,
          Text(
            t.classe.cartes.echeance(date: echeanceRendue(echeance)),
            style: guidee ? textes.bodyMedium : discret,
          ),
        ],
        if (lien != null && lien.isNotEmpty) ...<Widget>[
          Ecart.vSm,
          if (modifier != null)
            Text(lien, style: discret)
          else if (guidee)
            ActionPrincipale(
              libelle: t.classe.cartes.copierLien(titre: carte.titre),
              niveau: NiveauAction.secondaire,
              onPress: onCopierLien,
            )
          else
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: LienFleche(
                libelle: t.classe.cartes.copierLien(titre: carte.titre),
                onPress: onCopierLien,
              ),
            ),
        ],
      ],
    );

    return AppCard(
      onPress: modifier,
      libelleSemantique: modifier == null
          ? null
          : t.classe.cartes.modifierLecteur(titre: carte.titre),
      child: contenu,
    );
  }
}
