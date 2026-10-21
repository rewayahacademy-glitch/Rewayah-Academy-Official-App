/// OFFRES-ADM-1 : la feuille « Creer la classe » d'un regroupement de
/// demandes, puis la proposition d'enseignant, puis la fin.
///
/// Trois etapes dans une seule feuille, dans l'ordre de la decision du
/// directeur (§3) :
///
/// 1. **Creer** : le resume du regroupement (« 12 demandes → 2 classes
///    possibles »), le genre de la classe (les cartes de CLASSE-FORM-1), le
///    nom deduit et son numero parmi les classes paralleles (R16). Le bouton
///    « Creer la classe » est la confirmation de l'administration ; il ne se
///    grise jamais. Un regroupement qui n'a pas atteint le quota n'a pas de
///    bouton (le serveur refuse la creation, ECHELLE-CORR-ECRANS-1) : la
///    phrase dit ce qui manque ;
/// 2. **Enseignant** : la classe est creee et ses eleves integres ; la
///    feuille dit que les familles sont prevenues que leur classe est
///    validee (decision §4). Le premier choix est preselectionne, avec sa
///    raison (genre compatible, creneaux libres aux memes jours et a la meme
///    heure, compares sans conversion de fuseau, charge), et
///    l'administration le confirme ou en choisit un autre ;
/// 3. **Fin** : « Les familles ont ete prevenues. » (enseignant affecte) ;
///    si un autre membre de la direction a confirme avant, une seule phrase
///    le dit.
///
/// Double appui : un seul envoi (drapeau d'envoi, et la meme `cleEnvoi` pour
/// toute la feuille, que le serveur rend idempotente). La cle est un UUID v4
/// tire a l'ouverture de la feuille ([nouvelleCleEnvoi]) : le parametre
/// serveur `p_cle_idempotence` est de type `uuid`. Creation concurrente
/// par deux membres de la direction : le serveur rend [CreationDejaFaite], la
/// feuille le dit et ne cree rien.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/admin/enseignants_classe.dart';
import '../../core/admin/port_classes_admin.dart' show pageClassesAdminProvider;
import '../../core/admin/port_pilotage.dart' show pagePilotageProvider;
import '../../core/admin/service_comptes.dart' show comptesProvider;
import '../../core/admin/service_groupes.dart'
    show TypePublicGroupe, groupesProvider;
import '../../core/capacites/port_enseignants_classe.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/offres/port_regroupements_admin.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/champ_etiquete.dart' show TitreChamp;
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/selecteur_personne.dart';
import '../../core/widgets/status_pill.dart';
import '../admin_groupes/bas_de_feuille.dart';
import '../admin_groupes/genre_classe_libelles.dart';
import 'regroupements_libelles.dart';

/// Une cle d'envoi neuve : un UUID v4 (le parametre serveur
/// `p_cle_idempotence` est de type `uuid`, une autre forme y leve 22P02).
String nouvelleCleEnvoi() => const Uuid().v4();

/// Ou en est la feuille.
enum EtapeFeuilleRegroupement {
  /// Le resume, le genre, le bouton de creation.
  creation,

  /// La classe existe : la proposition d'enseignant.
  enseignant,

  /// L'enseignant est confirme : les familles sont prevenues.
  termine,
}

/// La feuille d'un regroupement.
class FeuilleClasseRegroupement extends ConsumerStatefulWidget {
  /// Cree la feuille. Un regroupement dont la classe existe deja
  /// ([RegroupementDemandes.classe]) ouvre directement sur l'enseignant.
  const FeuilleClasseRegroupement({required this.regroupement, super.key});

  /// Le regroupement.
  final RegroupementDemandes regroupement;

  /// Le titre de la feuille, porte par `AppBottomSheet`.
  String get titre => regroupement.classe == null
      ? t.admin.regroupements.creer
      : t.admin.regroupements.choisirEnseignant;

  @override
  ConsumerState<FeuilleClasseRegroupement> createState() =>
      _FeuilleClasseRegroupementEtat();
}

class _FeuilleClasseRegroupementEtat
    extends ConsumerState<FeuilleClasseRegroupement> {
  late ClasseSansEnseignant? _classe = widget.regroupement.classe;
  late EtapeFeuilleRegroupement _etape = _classe == null
      ? EtapeFeuilleRegroupement.creation
      : EtapeFeuilleRegroupement.enseignant;

  /// Une seule cle pour toute la feuille : deux pressions, ou une pression
  /// apres une reponse perdue, reprennent la meme creation cote serveur. Une
  /// nouvelle ouverture de la feuille tire une nouvelle cle.
  final String _cleEnvoi = nouvelleCleEnvoi();

  GenreClasse? _genre;
  String? _enseignantId;
  int? _integres;
  String? _enseignantNom;
  bool _envoi = false;
  bool _dejaCreee = false;
  bool _dejaAffecte = false;
  String? _message;

  RegroupementDemandes get _r => widget.regroupement;
  TypePublicGroupe get _type => typeDe(_r.public);

  /// La liste de la page se relit apres tout changement que le serveur a
  /// confirme (ou refuse parce qu'un autre l'a fait avant).
  void _relireListe() => ref
    ..invalidate(regroupementsAdminProvider)
    ..invalidate(pageClassesAdminProvider)
    ..invalidate(pagePilotageProvider);

  Future<void> _creer() async {
    // Double appui : le second ne part pas.
    if (_envoi || !_r.pret) return;
    final GenreClasse? genre = _genre;
    if (genre == null) {
      setState(() => _message = t.admin.groupes.formulaire.manqueGenre);
      return;
    }
    final PortRegroupementsAdmin? port = ref.read(
      portRegroupementsAdminProvider,
    );
    if (port == null) return;
    setState(() {
      _envoi = true;
      _message = null;
    });
    ResultatCreationClasse? resultat;
    try {
      resultat = await port.creerClasse(
        regroupementId: _r.id,
        genre: genre,
        libelle: nomDeduit(_r, genre),
        cleEnvoi: _cleEnvoi,
      );
    } on Object {
      resultat = null;
    }
    if (!mounted) return;
    setState(() {
      _envoi = false;
      switch (resultat) {
        case null:
          _message = t.admin.regroupements.nonConfirmee;
        case ClasseCreee(
          :final ClasseSansEnseignant classe,
          :final int elevesIntegres,
        ):
          _classe = classe;
          _integres = elevesIntegres;
          _etape = EtapeFeuilleRegroupement.enseignant;
        case CreationDejaFaite():
          _dejaCreee = true;
        case CreationRefusee(:final String motif):
          _message = t.admin.regroupements.refusee(motif: motif);
      }
    });
    if (resultat is ClasseCreee || resultat is CreationDejaFaite) {
      _relireListe();
    }
  }

  Future<void> _affecter(
    ClasseSansEnseignant classe,
    List<EnseignantClasse>? lignes,
    String? choisie,
  ) async {
    if (_envoi) return;
    final GenreClasse? genre = classe.genre ?? _genre;
    final EnseignantClasse? choisi = lignes
        ?.where((EnseignantClasse l) => l.enseignant.id == choisie)
        .firstOrNull;
    final String? manque = choisie == null
        ? t.admin.groupes.manqueEnseignant
        : choisi == null
        ? t.admin.groupes.formulaire.manqueListeEnseignants
        : !choisi.choisissable
        ? manqueEnseignantClasse(
            choisi,
            genre ?? GenreClasse.indetermine,
            _type,
          )
        : null;
    if (manque != null || choisi == null) {
      setState(() => _message = manque);
      return;
    }
    final PortRegroupementsAdmin? port = ref.read(
      portRegroupementsAdminProvider,
    );
    if (port == null) return;
    setState(() {
      _envoi = true;
      _message = null;
    });
    ResultatAffectation? resultat;
    try {
      resultat = await port.affecterEnseignant(
        classeId: classe.classeId,
        enseignantId: choisi.enseignant.id,
      );
    } on Object {
      // Sans reponse, rien n'est suppose (D5) : « non confirme ».
      resultat = null;
    }
    if (!mounted) return;
    setState(() {
      _envoi = false;
      if (resultat == null) {
        _message = t.admin.regroupements.affectationNonConfirmee;
      } else {
        _dejaAffecte = resultat == ResultatAffectation.dejaAffecte;
        _enseignantNom = choisi.enseignant.libelle;
        _etape = EtapeFeuilleRegroupement.termine;
      }
    });
    if (resultat != null) {
      _relireListe();
      // La charge et les creneaux pris de l'enseignant changent avec cette
      // affectation : toute la famille est relue (sinon la collision ne se
      // verrait plus a la prochaine ouverture), comme apres une creation.
      ref
        ..invalidate(enseignantsDuPortProvider)
        ..invalidate(groupesProvider);
    }
  }

  @override
  Widget build(BuildContext context) => switch (_etape) {
    EtapeFeuilleRegroupement.creation => _creation(context),
    EtapeFeuilleRegroupement.enseignant => _enseignant(context, _classe!),
    EtapeFeuilleRegroupement.termine => _termine(context, _classe!),
  };

  Widget _creation(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final r = t.admin.regroupements;
    final f = t.admin.groupes.formulaire;
    // Ce que la source des enseignants sait : la consequence annoncee par
    // chaque carte de genre est celle qui se produira (CLASSE-FORM-1).
    final List<EnseignantPropose> lus =
        ref.watch(enseignantsPourClasseProvider(_type)).value ??
        const <EnseignantPropose>[];
    final bool genreConnu = lus.any((EnseignantPropose e) => e.genre != null);

    return Column(
      key: const ValueKey<String>('regroupement-feuille-creation'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TexteSansCoupure(
          _r.decoupage.classes > 1
              ? r.contexteReparti
              : r.contexte(n: _r.nombreEleves),
          style: textes.bodyMedium,
        ),
        Ecart.vMd,
        // R3 : le decoupage est dit avant la confirmation, jamais deduit
        // apres coup.
        TexteSansCoupure(
          r.decoupage(detail: libelleDecoupage(_r.decoupage)),
          key: const ValueKey<String>('regroupement-decoupage'),
          style: textes.titleSmall,
        ),
        // R1, R16 : la classe s'ajoute aux classes deja ouvertes sur la
        // meme cle, aucune n'est ecrasee.
        if (_r.classesExistantes case final int n when n > 0) ...<Widget>[
          Ecart.vSm,
          TexteSansCoupure(
            r.classesExistantes(n: n),
            key: const ValueKey<String>('regroupement-classes-existantes'),
            style: textes.bodyMedium,
          ),
        ],
        Ecart.vLg,
        ...espacer(lignesRegroupement(_r)),
        Ecart.vLg,
        EtatQuota(regroupement: _r),
        Ecart.vXxl,
        TitreChamp(f.titreGenre, style: textes.titleMedium, obligatoire: true),
        Ecart.vMd,
        ChoiceCardGroup(
          autoriserSaisieLibre: false,
          options: <OptionChoix>[
            for (final GenreClasse g in GenreClasse.values)
              OptionChoix(
                cle: ValueKey<String>('regroupement-genre-${g.name}'),
                valeur: g.name,
                libelle: libelleGenreClasse(g, _type),
                description: detailGenreClasse(
                  g,
                  _type,
                  genreConnu: genreConnu,
                ),
              ),
          ],
          onChange: (ReponseChoix choix) => setState(() {
            _genre = GenreClasse.values
                .where((GenreClasse g) => choix.valeurs.contains(g.name))
                .firstOrNull;
            _message = null;
          }),
        ),
        Ecart.vXl,
        LigneCleValeur(
          key: const ValueKey<String>('regroupement-nom'),
          cle: f.titreNom,
          valeur: nomDeduitDistinct(_r, _genre),
        ),
        Ecart.vXs,
        TexteSansCoupure(r.nomDetail, style: textes.bodySmall),
        if (_message case final String message) ...<Widget>[
          Ecart.vMd,
          MessageAlerte(
            message,
            key: const ValueKey<String>('regroupement-message'),
          ),
        ],
        Ecart.vXxl,
        if (_dejaCreee) ...<Widget>[
          Semantics(
            liveRegion: true,
            child: TexteSansCoupure(
              r.dejaCreee,
              key: const ValueKey<String>('regroupement-deja-creee'),
              style: AppPalette.of(context).inkStrong
                  .applyTo(textes.bodyMedium ?? const TextStyle()),
            ),
          ),
          Ecart.vLg,
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ActionPrincipale(
              key: const ValueKey<String>('regroupement-fermer'),
              libelle: t.commun.fermer,
              niveau: NiveauAction.secondaire,
              pleineLargeur: false,
              onPress: () => Navigator.of(context).pop(),
            ),
          ),
        ] else if (_r.pret)
          BasDeFeuille(
            key: const ValueKey<String>('regroupement-creer'),
            libelle: r.creer,
            enCours: _envoi,
            horsLigne: f.horsLigne,
            onPress: () => unawaited(_creer()),
          ),
      ],
    );
  }

  Widget _enseignant(BuildContext context, ClasseSansEnseignant classe) {
    final TextTheme textes = Theme.of(context).textTheme;
    final r = t.admin.regroupements;
    final GenreClasse? genre = classe.genre ?? _genre;
    final AsyncValue<List<EnseignantPropose>> source = ref.watch(
      enseignantsPourClasseProvider(_type),
    );
    final AsyncValue<List<EnseignantClasse>> classes = source.hasError
        ? AsyncError<List<EnseignantClasse>>(
            source.error!,
            source.stackTrace ?? StackTrace.empty,
          )
        : source.hasValue
        ? AsyncData<List<EnseignantClasse>>(
            classerEnseignants(
              source.requireValue,
              genre: genre,
              creneaux: creneauxDe(_r),
            ),
          )
        : const AsyncLoading<List<EnseignantClasse>>();
    final List<EnseignantClasse>? lignes = classes.value;
    // Le premier choix est propose d'office ; l'administration le confirme
    // ou en choisit un autre.
    final String? choisie =
        _enseignantId ??
        lignes
            ?.where((EnseignantClasse l) => l.plusAdapte)
            .firstOrNull
            ?.enseignant
            .id;
    final List<EnseignantPropose> lus =
        source.value ?? const <EnseignantPropose>[];
    final bool sourceComplete =
        lus.any((EnseignantPropose e) => e.genre != null) &&
        lus.any((EnseignantPropose e) => e.creneauxLibres != null);

    final AsyncValue<List<PersonneProposee>> personnes = classes.hasValue
        ? AsyncData<List<PersonneProposee>>(<PersonneProposee>[
            for (final EnseignantClasse l in classes.requireValue)
              PersonneProposee(
                id: l.enseignant.id,
                nom: l.enseignant.libelle,
                identifiant: l.enseignant.identifiant,
                mention: mentionEnseignant(l, avecCreneau: true),
                raisonIndisponible: raisonEnseignant(l, genre, _type),
              ),
          ])
        : classes.hasError
        ? AsyncError<List<PersonneProposee>>(
            classes.error!,
            classes.stackTrace ?? StackTrace.empty,
          )
        : const AsyncLoading<List<PersonneProposee>>();

    final int? integres = _integres;
    return Column(
      key: const ValueKey<String>('regroupement-feuille-enseignant'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          liveRegion: true,
          child: TexteSansCoupure(
            integres == null
                ? r.classeAttend(libelle: nomClasseRegroupee(classe))
                : r.creee(n: integres, libelle: nomClasseRegroupee(classe)),
            key: const ValueKey<String>('regroupement-creee'),
            style: textes.titleSmall,
          ),
        ),
        Ecart.vXs,
        // Decision du 09/10, §4 : la creation vaut « Classe validee » pour
        // les familles ; le serveur les en previent a la creation.
        TexteSansCoupure(
          r.famillesClasseValidee,
          key: const ValueKey<String>('regroupement-familles-classe-validee'),
          style: textes.bodyMedium,
        ),
        Ecart.vLg,
        ...espacer(lignesRegroupement(_r)),
        Ecart.vXxl,
        TitreChamp(r.enseignantTitre, style: textes.titleMedium),
        Ecart.vXs,
        TexteSansCoupure(r.enseignantContexte, style: textes.bodySmall),
        Ecart.vMd,
        SelecteurPersonne(
          sorte: SortePersonne.enseignant,
          personnes: personnes,
          choisie: choisie,
          obligatoire: true,
          aide: sourceComplete
              ? t.admin.groupes.formulaire.aideEnseignant
              : t.admin.groupes.formulaire.aideEnseignantSansSource,
          onChoix: (PersonneProposee p) => setState(() {
            _enseignantId = p.id;
            _message = null;
          }),
          onReessayer: () {
            ref.invalidate(enseignantsDuPortProvider(_type));
            ref.invalidate(comptesProvider);
          },
        ),
        if (_message case final String message) ...<Widget>[
          Ecart.vMd,
          MessageAlerte(
            message,
            key: const ValueKey<String>('regroupement-message'),
          ),
        ],
        Ecart.vXxl,
        if (classe.peutAffecterEnseignant)
          BasDeFeuille(
            key: const ValueKey<String>('regroupement-confirmer'),
            libelle: r.confirmerEnseignant,
            enCours: _envoi,
            horsLigne: r.enseignantHorsLigne,
            onPress: () => unawaited(_affecter(classe, lignes, choisie)),
          )
        else
          TexteSansCoupure(
            r.affectationNonOuverte,
            key: const ValueKey<String>('regroupement-affectation-fermee'),
            style: textes.bodyMedium,
          ),
      ],
    );
  }

  Widget _termine(BuildContext context, ClasseSansEnseignant classe) {
    final TextTheme textes = Theme.of(context).textTheme;
    final r = t.admin.regroupements;
    final String? nom = _enseignantNom;
    return Column(
      key: const ValueKey<String>('regroupement-feuille-termine'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Un autre membre de la direction a confirme avant : une seule
        // phrase, sans « Les familles ont ete prevenues », que ce choix-ci
        // n'a pas provoque.
        if (_dejaAffecte)
          Semantics(
            liveRegion: true,
            child: TexteSansCoupure(
              r.dejaAffecte,
              key: const ValueKey<String>('regroupement-deja-affecte'),
              style: textes.titleMedium,
            ),
          )
        else ...<Widget>[
          if (nom != null) ...<Widget>[
            TexteSansCoupure(
              r.termineDetail(
                libelle: nomClasseRegroupee(classe),
                enseignant: nom,
              ),
              style: textes.bodyMedium,
            ),
            Ecart.vLg,
          ],
          Semantics(
            liveRegion: true,
            child: TexteSansCoupure(
              r.famillesPrevenues,
              key: const ValueKey<String>('regroupement-familles-prevenues'),
              style: textes.titleMedium,
            ),
          ),
        ],
        Ecart.vXxl,
        // Fermer marche aussi sans reseau : pas de repli hors ligne ici.
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: ActionPrincipale(
            key: const ValueKey<String>('regroupement-terminer'),
            libelle: t.commun.fermer,
            pleineLargeur: AppGabarit.de(context) != Gabarit.desktop,
            onPress: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}

/// Les lignes d'un regroupement : heure de reference, autres fuseaux,
/// public, langue, eleves. **Aucun nom d'eleve.**
List<Widget> lignesRegroupement(RegroupementDemandes g) {
  final r = t.admin.regroupements;
  return <Widget>[
    // C-11 bis : une heure commune se dit une fois ; sinon chaque jour avec
    // la sienne, et le fuseau de reference sur sa propre ligne.
    if (libelleReference(g) case final String reference) ...<Widget>[
      LigneCleValeur(cle: r.cleJours, valeur: libelleJours(g.jours)),
      LigneCleValeur(cle: r.cleHeure, valeur: reference, chiffres: true),
    ] else ...<Widget>[
      LigneCleValeur(
        key: ValueKey<String>('regroupement-jours-heures-${g.id}'),
        cle: r.cleJoursHeures,
        valeur: libelleJoursHeures(g),
      ),
      LigneCleValeur(cle: r.cleFuseau, valeur: libelleFuseau(g)),
    ],
    if (g.autresFuseaux.isNotEmpty)
      LigneCleValeur(cle: r.cleAilleurs, valeur: libelleAutresFuseaux(g)),
    LigneCleValeur(cle: r.clePublic, valeur: nomPublic(g.public)),
    LigneCleValeur(cle: r.cleLangue, valeur: g.langueNom),
    LigneCleValeur(
      key: ValueKey<String>('regroupement-demandes-${g.id}'),
      cle: r.cleEleves,
      valeur: libelleDemandesClasses(g),
      chiffres: true,
    ),
  ];
}

/// Des lignes separees de 8.
List<Widget> espacer(List<Widget> lignes) => <Widget>[
  for (int i = 0; i < lignes.length; i++) ...<Widget>[
    if (i > 0) Ecart.vSm,
    lignes[i],
  ],
];

/// L'etat du quota : « Prete » ou « Incomplete », avec sa phrase. Trois
/// signaux, jamais la couleur seule : la pastille (ton et mot), et la
/// phrase. Incomplete : la phrase dit combien de demandes manquent et que la
/// classe pourra etre creee quand le regroupement sera pret (le serveur
/// refuse avant) ; elle ne promet ni ouverture ni arrivee ulterieure.
class EtatQuota extends StatelessWidget {
  /// Cree l'etat.
  const EtatQuota({required this.regroupement, super.key});

  /// Le regroupement.
  final RegroupementDemandes regroupement;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final r = t.admin.regroupements;
    final RegroupementDemandes g = regroupement;
    final String phrase = g.pret ? r.pretDetail : r.manquent(n: g.manquants);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        StatusPill(
          key: ValueKey<String>(
            g.pret
                ? 'regroupement-pret-${g.id}'
                : 'regroupement-incomplet-${g.id}',
          ),
          libelle: g.pret ? r.pret : r.incomplete,
          ton: g.pret ? TonEtat.succes : TonEtat.avertissement,
        ),
        Ecart.vSm,
        TexteSansCoupure(
          phrase,
          key: ValueKey<String>('regroupement-phrase-quota-${g.id}'),
          style: textes.bodyMedium,
        ),
      ],
    );
  }
}
