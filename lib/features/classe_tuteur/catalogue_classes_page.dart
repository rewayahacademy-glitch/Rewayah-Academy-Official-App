import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Comme partout ailleurs : le type d'une famille de providers n'est pas exporte
// par l'entree principale de Riverpod 3, il vit dans `misc.dart`.
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/appairage/service_appairage.dart' show elevesDuFoyerProvider;
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_catalogue_classes.dart';
import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/mouvement/apparition_douce.dart';
import '../../core/planning/service_planning.dart' show monFuseauProvider;
import '../../core/router/routes.dart';
import '../../core/seance_famille/seance_famille.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/ecran_resultat.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../accueil_famille/accueil_famille_page.dart';
import '../accueil_famille/bloc_seance.dart';
import 'contexte_classe.dart';

/// Le fuseau IANA dans lequel le catalogue rend les heures (contrat K6,
/// `PortCatalogueClasses.compatibles`).
///
/// Source : le fuseau de l'appelant (`monFuseauProvider`, `profiles.timezone`),
/// c'est-a-dire celui du foyer pour un tuteur (demande C-15, revue C M4,
/// branche par le coordinateur le 25/09). `null` tant qu'il n'est pas lu ou
/// s'il est illisible : rien n'est devine. Les tests le surchargent.
final Provider<String?> fuseauCatalogueProvider = Provider<String?>(
  (Ref ref) => ref.watch(monFuseauProvider).value,
);

/// Les classes proposees a un eleve, dans l'ordre rendu par le serveur.
///
/// Leve `CapaciteIndisponible` tant que le catalogue n'a pas de source
/// (production : `CatalogueClassesIndisponible`, point P1) ou qu'aucun fuseau
/// n'est connu. Aucune classe n'est jamais fabriquee cote client.
final FutureProviderFamily<List<ClasseOuverte>, String>
classesProposeesProvider = FutureProvider.family<List<ClasseOuverte>, String>((
  Ref ref,
  String eleveId,
) {
  final String? fuseau = ref.watch(fuseauCatalogueProvider);
  if (fuseau == null) {
    // Fuseau encore en lecture : rester en chargement plutot que dire
    // « pas encore ouvert » une fraction de seconde.
    if (ref.watch(monFuseauProvider).isLoading) {
      return Completer<List<ClasseOuverte>>().future;
    }
    throw const CapaciteIndisponible('DB-CRS-07');
  }
  return ref
      .watch(portCatalogueClassesProvider)
      .compatibles(eleveId: eleveId, fuseauIana: fuseau);
});

/// L'enseignant nomme : « Sayyid Prenom », ou le prenom seul quand le titre
/// n'est pas rendu (jamais devine).
String enseignantCatalogue(EnseignantSeance enseignant) {
  final String? titre = switch (enseignant.titre) {
    TitreEnseignant.sayyid => LibellesGroupe.sayyid,
    TitreEnseignant.sayyida => LibellesGroupe.sayyida,
    null => null,
  };
  return titre == null ? enseignant.prenom : '$titre ${enseignant.prenom}';
}

/// Les places restantes en mots, `null` quand le serveur ne les dit pas ou
/// que la classe n'en a plus (l'etat le dit deja).
String? placesCatalogue(ClasseOuverte classe) {
  final int? places = classe.placesRestantes;
  if (places == null ||
      places <= 0 ||
      classe.etat != EtatClasseOuverte.ouverte) {
    return null;
  }
  return places == 1
      ? t.classe.pageCatalogue.placeUne
      : t.classe.pageCatalogue.places(nombre: places);
}

/// Une seance hebdomadaire en mots : « Mardi a 18:30 · 45 min », heure lue
/// dans le fuseau de la classe (demande C-14).
String seanceCatalogue(CreneauHebdomadaire seance) {
  final List<String> jours = t.commun.dates.jours;
  final String heure =
      '${seance.heure.toString().padLeft(2, '0')}:'
      '${seance.minute.toString().padLeft(2, '0')}';
  return t.classe.pageCatalogue.seanceHebdo(
    jour: jours[(seance.jourIso - 1) % jours.length],
    heure: heure,
    duree: seance.dureeMinutes,
  );
}

/// Le parcours de la classe (cours et niveau), vide quand il n'est pas dit.
String parcoursCatalogue(ClasseOuverte classe) =>
    LibellesGroupe.coursEtNiveau(cours: classe.cours, niveau: classe.niveau);

/// La pastille d'etat d'une classe proposee.
({String libelle, TonEtat ton}) etatCatalogue(EtatClasseOuverte etat) =>
    switch (etat) {
      EtatClasseOuverte.ouverte => (
        libelle: t.classe.pageCatalogue.etat.ouverte,
        ton: TonEtat.succes,
      ),
      EtatClasseOuverte.complete => (
        libelle: t.classe.pageCatalogue.etat.complete,
        ton: TonEtat.neutre,
      ),
      EtatClasseOuverte.listeAttente => (
        libelle: t.classe.pageCatalogue.etat.listeAttente,
        ton: TonEtat.avertissement,
      ),
    };

/// Le choix d'une classe pour un profil eleve (`/tuteur/classes/catalogue`).
///
/// Derive de la carte classe de l'Accueil bureau (#1, colonne gauche) et des
/// cartes de choix E1 (manifeste section 2) : une carte par classe
/// (enseignant, etat, places rendues par le serveur, horaires), une action
/// secondaire par carte ; la confirmation est une tache focalisee avec UNE
/// action principale ; le resultat suit la grammaire M5.
///
/// Production : le catalogue n'a pas de source (DB-CRS-07, 08) : la page dit
/// que le choix en ligne n'est pas encore ouvert, **aucune reservation
/// locale**. Le parcours complet est demontre en simulation (tests).
class CatalogueClassesPage extends ConsumerStatefulWidget {
  /// Cree la page.
  const CatalogueClassesPage({super.key, this.eleveId});

  /// L'eleve concerne (`?eleve=`), s'il est donne.
  final String? eleveId;

  @override
  ConsumerState<CatalogueClassesPage> createState() => _CatalogueState();
}

class _CatalogueState extends ConsumerState<CatalogueClassesPage> {
  /// La classe en cours de confirmation.
  ClasseOuverte? _choisie;

  /// La cle d'idempotence de la confirmation en cours : gardee a chaque
  /// nouvelle tentative, pour qu'un « Reessayer » ne cree jamais une seconde
  /// inscription.
  String? _cle;

  bool _envoi = false;
  Object? _erreurEnvoi;
  ResultatInscription? _resultat;

  void _choisir(ClasseOuverte classe) => setState(() {
    _choisie = classe;
    _cle = const Uuid().v4();
    _erreurEnvoi = null;
    _resultat = null;
  });

  void _revenirALaListe() => setState(() {
    _choisie = null;
    _cle = null;
    _erreurEnvoi = null;
    _resultat = null;
  });

  Future<void> _confirmer(String eleveId) async {
    final ClasseOuverte? classe = _choisie;
    final String? cle = _cle;
    if (classe == null || cle == null || _envoi) {
      return;
    }
    setState(() {
      _envoi = true;
      _erreurEnvoi = null;
    });
    try {
      final ResultatInscription resultat = await ref
          .read(portCatalogueClassesProvider)
          .inscrire(
            classeId: classe.classeId,
            eleveId: eleveId,
            cleIdempotence: cle,
          );
      if (!mounted) {
        return;
      }
      ref
        ..invalidate(classeDeLEleveProvider(eleveId))
        ..invalidate(contexteClasseProvider)
        ..invalidate(classesProposeesProvider(eleveId));
      setState(() {
        _envoi = false;
        _resultat = resultat;
      });
    } on Object catch (erreur) {
      if (!mounted) {
        return;
      }
      setState(() {
        _envoi = false;
        _erreurEnvoi = erreur;
      });
    }
  }

  void _allerALAccueil() => GoRouter.of(context).go(Routes.tuteurAccueil);

  /// Le profil de l'adresse, s'il est l'un de ceux du foyer (K1).
  ProfilEleveFoyer? _eleveDemande(List<ProfilEleveFoyer>? profils) {
    for (final ProfilEleveFoyer p in profils ?? <ProfilEleveFoyer>[]) {
      if (p.eleveId == widget.eleveId) {
        return p;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<ProfilEleveFoyer>> profils = ref.watch(
      profilsElevesFoyerProvider,
    );
    final ProfilEleveFoyer? eleve = _eleveDemande(profils.value);
    final ClasseOuverte? choisie = _choisie;
    final bool confirmation = choisie != null && _resultat == null;

    final Widget corps;
    if (profils.hasValue && eleve == null) {
      // Un identifiant d'adresse est une demande, jamais une autorisation.
      corps = EtatSysteme(
        nature: NatureEtat.introuvable,
        titre: t.classe.pageCatalogue.eleveInconnuTitre,
        phrase: t.classe.pageCatalogue.eleveInconnuPhrase,
        libelleAction: t.classe.pageCatalogue.resultat.retourAccueil,
        onAction: _allerALAccueil,
      );
    } else if (eleve == null) {
      corps = BlocAsynchrone<List<ProfilEleveFoyer>>(
        valeur: profils,
        squelette: const _Squelette(),
        onReessayer: () => ref.invalidate(elevesDuFoyerProvider),
        construire: (_) => const SizedBox.shrink(),
      );
    } else if ((_resultat, choisie) case (
      final ResultatInscription resultat,
      final ClasseOuverte classe,
    )) {
      final String eleveId = eleve.eleveId;
      corps = _Resultat(
        resultat: resultat,
        classe: classe,
        prenom: eleve.prenom,
        onVoirClasse: () =>
            GoRouter.of(context)
                .go(Routes.classePour(classe.classeId, eleveId: eleveId)),
        onAutresClasses: _revenirALaListe,
        onAccueil: _allerALAccueil,
      );
    } else if (choisie != null) {
      final String eleveId = eleve.eleveId;
      corps = _Confirmation(
        classe: choisie,
        prenom: eleve.prenom,
        envoi: _envoi,
        erreur: _erreurEnvoi,
        onConfirmer: () => _confirmer(eleveId),
      );
    } else {
      corps = _Liste(eleve: eleve, onChoisir: _choisir);
    }

    return PageShell(
      titre: confirmation
          ? t.classe.pageCatalogue.confirmerTitre
          : t.classe.catalogue,
      sousTitre: eleve == null
          ? null
          : t.classe.pageCatalogue.pour(prenom: eleve.prenom),
      // Tache focalisee : le retour de la confirmation revient a la liste,
      // celui de la liste a l'Accueil, d'ou vient « Choisir une classe ».
      onRetour: confirmation ? _revenirALaListe : _allerALAccueil,
      child: corps,
    );
  }
}

/// La liste des classes proposees, et ce qu'il faut savoir a cote.
class _Liste extends ConsumerWidget {
  const _Liste({required this.eleve, required this.onChoisir});

  final ProfilEleveFoyer eleve;
  final ValueChanged<ClasseOuverte> onChoisir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return ColonnesSousPage(
      principal: LectureClasse<List<ClasseOuverte>>(
        valeur: ref.watch(classesProposeesProvider(eleve.eleveId)),
        phraseIndisponible: t.classe.pageCatalogue.indisponible,
        onReessayer: () =>
            ref.invalidate(classesProposeesProvider(eleve.eleveId)),
        vide: EtatSysteme(
          nature: NatureEtat.aucunResultat,
          titre: t.classe.pageCatalogue.aucune,
          phrase: t.classe.pageCatalogue.aucuneDetail(prenom: eleve.prenom),
        ),
        construire: (List<ClasseOuverte> classes) => classes.isEmpty
            ? EtatSysteme(
                nature: NatureEtat.aucunResultat,
                titre: t.classe.pageCatalogue.aucune,
                phrase: t.classe.pageCatalogue.aucuneDetail(
                  prenom: eleve.prenom,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Semantics(
                    header: true,
                    child: Text(
                      t.classe.pageCatalogue.proposees,
                      style: palette.inkStrong.applyTo(
                        textes.titleMedium ?? const TextStyle(),
                      ),
                    ),
                  ),
                  Ecart.vMd,
                  for (int i = 0; i < classes.length; i++) ...<Widget>[
                    if (i > 0) Ecart.vLg,
                    ElementEchelonne(
                      index: i,
                      child: CarteClasseOuverte(
                        classe: classes[i],
                        onChoisir: () => onChoisir(classes[i]),
                      ),
                    ),
                  ],
                ],
              ),
      ),
      precisions: const _Precisions(),
    );
  }
}

/// Une classe proposee : l'enseignant et la classe, les horaires, l'etat et
/// les places ; l'action secondaire qui ouvre la confirmation. Une classe
/// complete sans liste d'attente n'a aucune action (un bouton qui ne peut
/// pas aboutir n'est pas rendu).
class CarteClasseOuverte extends StatelessWidget {
  /// Cree la carte.
  const CarteClasseOuverte({required this.classe, super.key, this.onChoisir});

  /// La classe.
  final ClasseOuverte classe;

  /// Ouvre la confirmation ; `null` : carte en lecture seule.
  final VoidCallback? onChoisir;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool large = classeEnColonnes(context);
    final ({String libelle, TonEtat ton}) etat = etatCatalogue(classe.etat);
    final String? places = placesCatalogue(classe);
    final VoidCallback? choisir = onChoisir;
    final String? action = switch (classe.etat) {
      EtatClasseOuverte.ouverte => t.classe.pageCatalogue.choisir,
      EtatClasseOuverte.listeAttente => t.classe.pageCatalogue.rejoindreAttente,
      EtatClasseOuverte.complete => null,
    };
    final TextStyle discret = palette.inkMuted.applyTo(
      (large ? textes.bodyLarge : textes.bodyMedium) ?? const TextStyle(),
    );

    return AppCard(
      marge: large ? AppSpacing.xl : AppSpacing.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  classe.libelle,
                  style: palette.inkStrong.applyTo(
                    (large ? textes.titleLarge : textes.titleMedium) ??
                        const TextStyle(),
                  ),
                ),
                Ecart.vSm,
                // Photo publique de l'enseignant quand l'hote saura la
                // resoudre (DB-CRS-09), sinon son initiale. AVATAR-1 : couple
                // avatar + nom du composant partage, au plus une ligne de role.
                AvatarNom.enLigne(
                  prenom: classe.enseignant.prenom,
                  nom: enseignantCatalogue(classe.enseignant),
                  pays: classe.enseignant.pays,
                  role: switch (parcoursCatalogue(classe)) {
                    final String p when p.isNotEmpty => p,
                    _ => null,
                  },
                  styleNom: discret,
                  styleRole: discret,
                ),
              ],
            ),
          ),
          Ecart.vLg,
          const FiletHorizontal(),
          Ecart.vLg,
          if (classe.seances.isEmpty)
            Text(t.classe.pageCatalogue.horairesAbsents, style: discret)
          else ...<Widget>[
            for (final CreneauHebdomadaire s in classe.seances)
              Text(
                seanceCatalogue(s),
                style: AppTypography.tabulaire(
                  palette.inkStrong.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
              ),
            if (classe.fuseauIana case final String fuseau) ...<Widget>[
              Ecart.vXs,
              Text(
                t.classe.pageCatalogue.fuseauClasse(fuseau: fuseau),
                style: discret,
              ),
            ],
          ],
          Ecart.vMd,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              StatusPill(libelle: etat.libelle, ton: etat.ton),
              if (places != null)
                Text(
                  places,
                  style: AppTypography.tabulaire(
                    palette.inkStrong.applyTo(
                      textes.bodyMedium ?? const TextStyle(),
                    ),
                  ),
                ),
            ],
          ),
          if (action != null && choisir != null) ...<Widget>[
            Ecart.vLg,
            _ActionAjustee(
              large: large,
              child: ActionPrincipale(
                libelle: action,
                niveau: NiveauAction.secondaire,
                pleineLargeur: !large,
                fleche: true,
                onPress: choisir,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Une action a la largeur de son libelle sur bureau, pleine largeur sur
/// telephone.
///
/// ponytail: `ActionPrincipale` centre son libelle par `Container.alignment`,
/// ce qui l'etire a toute la largeur offerte meme avec `pleineLargeur: false`
/// (demande C-16) : `IntrinsicWidth` la ramene a son contenu. Plafond : une
/// passe de mesure de plus, negligeable pour un bouton.
class _ActionAjustee extends StatelessWidget {
  const _ActionAjustee({required this.large, required this.child});

  final bool large;
  final Widget child;

  @override
  Widget build(BuildContext context) => large
      ? Align(
          alignment: AlignmentDirectional.centerStart,
          child: IntrinsicWidth(child: child),
        )
      : child;
}

/// Ce qu'il faut savoir avant de choisir : une carte, des filets.
class _Precisions extends StatelessWidget {
  const _Precisions();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle discret = palette.inkMuted.applyTo(
      (classeEnColonnes(context) ? textes.bodyLarge : textes.bodyMedium) ??
          const TextStyle(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            t.classe.pageCatalogue.precisionsTitre,
            style: palette.inkStrong.applyTo(
              textes.titleMedium ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vMd,
        AppCard(
          marge: AppSpacing.lg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(t.classe.pageCatalogue.precisionEnseignant, style: discret),
              Ecart.vMd,
              const FiletHorizontal(),
              Ecart.vMd,
              Text(t.classe.pageCatalogue.precisionPlaces, style: discret),
              Ecart.vMd,
              const FiletHorizontal(),
              Ecart.vMd,
              Text(t.classe.pageCatalogue.precisionReserve, style: discret),
            ],
          ),
        ),
      ],
    );
  }
}

/// La confirmation : la classe choisie, la meme classe et le meme enseignant
/// pour toute la semaine, puis UNE action principale. Une reponse perdue se
/// reessaie avec la meme cle (aucune seconde inscription).
class _Confirmation extends StatelessWidget {
  const _Confirmation({
    required this.classe,
    required this.prenom,
    required this.envoi,
    required this.erreur,
    required this.onConfirmer,
  });

  final ClasseOuverte classe;
  final String prenom;
  final bool envoi;
  final Object? erreur;
  final VoidCallback onConfirmer;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool attente = classe.etat == EtatClasseOuverte.listeAttente;
    final bool large = classeEnColonnes(context);
    final Object? echec = erreur;
    final bool indisponible = echec is CapaciteIndisponible;

    final Widget contenu = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          attente
              ? t.classe.pageCatalogue.confirmerAttentePhrase(prenom: prenom)
              : t.classe.pageCatalogue.confirmerPhrase(prenom: prenom),
          style: palette.inkStrong.applyTo(
            (large ? textes.titleMedium : textes.bodyLarge) ??
                const TextStyle(),
          ),
        ),
        Ecart.vLg,
        CarteClasseOuverte(classe: classe),
        Ecart.vLg,
        Text(
          t.classe.pageCatalogue.memeEnseignant(
            enseignant: enseignantCatalogue(classe.enseignant),
          ),
          style: palette.inkMuted.applyTo(
            (large ? textes.bodyLarge : textes.bodyMedium) ?? const TextStyle(),
          ),
        ),
        if (echec != null) ...<Widget>[
          Ecart.vLg,
          EtatSysteme(
            nature: indisponible
                ? NatureEtat.indisponible
                : NatureEtat.echecServeur,
            phrase: indisponible
                ? t.classe.pageCatalogue.envoiIndisponible
                : t.classe.pageCatalogue.envoiIncertain,
            dependance: indisponible ? echec.dependance : null,
          ),
        ],
        if (!indisponible) ...<Widget>[
          Ecart.vXl,
          _ActionAjustee(
            large: large,
            child: ActionPrincipale(
              libelle: echec != null
                  ? t.commun.reessayer
                  : attente
                  ? t.classe.pageCatalogue.confirmerAttente
                  : t.classe.pageCatalogue.confirmer,
              fleche: echec == null,
              enCours: envoi,
              pleineLargeur: !large,
              onPress: envoi ? null : onConfirmer,
            ),
          ),
        ],
      ],
    );
    return ColonnesSousPage(principal: contenu);
  }
}

/// Le resultat rendu par le serveur, dans la grammaire M5.
class _Resultat extends StatelessWidget {
  const _Resultat({
    required this.resultat,
    required this.classe,
    required this.prenom,
    required this.onVoirClasse,
    required this.onAutresClasses,
    required this.onAccueil,
  });

  final ResultatInscription resultat;
  final ClasseOuverte classe;
  final String prenom;
  final VoidCallback onVoirClasse;
  final VoidCallback onAutresClasses;
  final VoidCallback onAccueil;

  @override
  Widget build(BuildContext context) {
    final r = t.classe.pageCatalogue.resultat;
    final String nom = classe.libelle;
    return switch (resultat.statut) {
      StatutInscription.inscrit => EcranResultat(
        icone: AppIcons.succes,
        ton: TonEtat.succes,
        titre: r.inscritTitre,
        phrase: r.inscritPhrase(prenom: prenom, classe: nom),
        libelleAction: r.voirClasse,
        onAction: onVoirClasse,
        libelleSecondaire: r.retourAccueil,
        onSecondaire: onAccueil,
      ),
      StatutInscription.enAttenteValidation => EcranResultat(
        icone: AppIcons.attente,
        titre: r.validationTitre,
        phrase: r.validationPhrase(prenom: prenom, classe: nom),
        libelleAction: r.retourAccueil,
        onAction: onAccueil,
      ),
      StatutInscription.listeAttente => EcranResultat(
        icone: AppIcons.attente,
        ton: TonEtat.avertissement,
        titre: r.listeAttenteTitre,
        phrase: r.listeAttentePhrase(prenom: prenom, classe: nom),
        libelleAction: r.retourAccueil,
        onAction: onAccueil,
      ),
      StatutInscription.refuse => EcranResultat(
        icone: AppIcons.avertissement,
        ton: TonEtat.alerte,
        titre: r.refuseTitre,
        phrase: r.refusePhrase(prenom: prenom),
        libelleAction: r.autresClasses,
        onAction: onAutresClasses,
        libelleSecondaire: r.retourAccueil,
        onSecondaire: onAccueil,
      ),
    };
  }
}

/// La forme de la page pendant la premiere lecture des profils.
class _Squelette extends StatelessWidget {
  const _Squelette();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Skeleton(hauteur: AppSpacing.respiration * 3),
      Ecart.vMd,
      Skeleton(hauteur: AppSpacing.respiration * 3),
    ],
  );
}
