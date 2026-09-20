import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/matching/service_matching.dart';
import '../../core/planning/service_planning.dart';
import '../../core/regles/service_regles.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/session/session_controleur.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bento_tile.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../disponibilites/grille_semaine.dart';

/// `ENS-06` : les heures de l'enseignant, et les eleves qui les attendent.
///
/// Ce qui se prend ici est un **eleve**, pas un creneau : la relation dure et ne
/// se rompt que par une demande tranchee par l'administration (ADR-017). Le
/// creneau n'est que l'heure du rendez-vous hebdomadaire qui en decoule.
///
/// **Onglets sur mobile seulement.** A partir de la tablette, l'ecran a la
/// place de montrer la grille et le feed a la fois : un onglet sur un ecran de
/// 1440 pixels cacherait la moitie de l'information sans raison
/// (`docs/design/08-catalogue-ecrans.md` section 2). Reprise au lot R4.
///
/// **Deux vues LOCALES, jamais deux destinations.** « Disponibilites » est une
/// destination du TUTEUR (`TUT-04`) et « Creneaux » une destination de
/// l'ENSEIGNANT : elles vivent dans deux coquilles distinctes et un enseignant
/// n'en voit jamais qu'une. Il n'y a rien a fusionner, et rien a separer.
class CreneauxPage extends StatelessWidget {
  /// Cree l'ecran des creneaux.
  const CreneauxPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Gabarit gabarit = AppGabarit.de(context);

    if (gabarit == Gabarit.mobile) {
      return const _CreneauxOnglets();
    }

    // **Les deux panneaux portent leur nom des que les onglets disparaissent.**
    // Le lot R4 a rendu l'ecran responsive et a laisse les deux libelles
    // derriere lui, dans le seul `TabBar` mobile : a partir de la tablette, la
    // grille gardait sa question en tete mais le feed n'avait plus aucun titre.
    // Une liste d'eleves sans titre a cote d'une grille d'heures ne se lit pas.
    final Widget heures = _Panneau(
      titre: t.creneaux.ongletHeures,
      child: const _OngletHeures(),
    );
    final Widget eleves = _Panneau(
      titre: t.creneaux.ongletEleves,
      child: const _OngletEleves(),
    );

    return PageShell(
      titre: t.creneaux.titre,
      child: gabarit == Gabarit.desktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: heures),
                Ecart.hXxl,
                Expanded(child: eleves),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[heures, Ecart.vXxl, eleves],
            ),
    );
  }
}

/// Un panneau nomme, hors gabarit mobile.
///
/// Il porte le libelle que le `TabBar` porte sur telephone : un seul et meme
/// mot pour la meme zone, quelle que soit la largeur.
class _Panneau extends StatelessWidget {
  const _Panneau({required this.titre, required this.child});

  final String titre;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[SectionHeader(titre: titre), Ecart.vMd, child],
  );
}

/// La presentation mobile : deux onglets, un seul panneau visible a la fois.
///
/// **Pas de `TabBarView`** : il s'appuie sur un `PageView`, qui exige une
/// hauteur bornee, alors que `PageShell` ne borne jamais la hauteur de son
/// `child` -- c'est la page entiere qui defile, meme mecanique que le reste du
/// produit. Le panneau bascule donc directement sur l'index du controleur, au
/// prix du balayage au doigt entre onglets.
class _CreneauxOnglets extends StatefulWidget {
  const _CreneauxOnglets();

  @override
  State<_CreneauxOnglets> createState() => _CreneauxOngletsEtat();
}

class _CreneauxOngletsEtat extends State<_CreneauxOnglets>
    with SingleTickerProviderStateMixin {
  late final TabController _controleur;

  @override
  void initState() {
    super.initState();
    _controleur = TabController(length: 2, vsync: this)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      titre: t.creneaux.titre,
      entete: TabBar(
        controller: _controleur,
        tabs: <Widget>[
          Tab(text: t.creneaux.ongletHeures),
          Tab(text: t.creneaux.ongletEleves),
        ],
      ),
      child: _controleur.index == 0
          ? const _OngletHeures()
          : const _OngletEleves(),
    );
  }
}

/// Onglet 1 : la meme grille que `TUT-04`, au sens litteral.
class _OngletHeures extends ConsumerStatefulWidget {
  const _OngletHeures();

  @override
  ConsumerState<_OngletHeures> createState() => _OngletHeuresEtat();
}

class _OngletHeuresEtat extends ConsumerState<_OngletHeures> {
  bool _enCours = false;
  bool _erreur = false;
  String? _confirmation;

  /// Nomme une case : c'est ce qui manquait a l'etat « enregistre ».
  ///
  /// Sans le jour et l'heure, la confirmation dit qu'« un » creneau est passe,
  /// pas lequel : au troisieme tap d'affilee, l'enseignant ne sait plus si
  /// c'est le sien qui a abouti.
  String _nommer(Creneau creneau) => t.enseignant.creneaux.heureLibelle(
    jour: t.disponibilites.joursLongs[creneau.jour - 1],
    heure: '${creneau.heure}',
  );

  /// Les heures qui portent deja un eleve : le **conflit** de la grille.
  ///
  /// Sans ce calcul, une case sur laquelle un eleve est engage est indiscernable
  /// d'une case libre. Le conflit se **voit**, il ne se bloque pas : retirer une
  /// disponibilite n'annule aucun cours (`weekly_availability` et
  /// `teacher_student_assignments` sont deux tables), et refuser le geste serait
  /// une regle metier qu'aucun document ne pose. L'ecran dit donc ce que le
  /// retrait fait, et ce qu'il ne fait pas.
  ///
  /// Deduplique : deux eleves sur la meme heure ne font qu'un conflit, et
  /// l'enumeration ne repete pas « mardi 17 h, mardi 17 h ».
  List<Creneau> _engagements(List<Affectation> affectations, String monId) =>
      <Creneau>{
        for (final Affectation a in affectations)
          if (a.active && a.enseignantId == monId) a.creneau,
      }.toList();

  bool _engagee(List<Creneau> engagements, Creneau creneau) =>
      engagements.any(
        (Creneau e) => e.jour == creneau.jour && e.heure == creneau.heure,
      );

  Future<void> _basculer(
    String monId,
    List<Creneau> engagements,
    Creneau creneau,
    bool posee,
  ) async {
    // Retirer une heure engagee n'annule pas le cours : la relation dure et ne
    // se rompt que par une demande de reaffectation (ADR-017). Le geste passe,
    // et la confirmation dit exactement cela plutot que « retire » tout court.
    final bool engagee = posee && _engagee(engagements, creneau);

    setState(() {
      _enCours = true;
      _erreur = false;
    });
    try {
      final ServicePlanning service = ref.read(servicePlanningProvider);
      if (posee) {
        await service.retirer(profilId: monId, creneau: creneau);
      } else {
        await service.poser(profilId: monId, creneau: creneau);
      }
      ref
        ..invalidate(disponibilitesProvider(monId))
        // Les heures decident du feed : le laisser tel quel montrerait des
        // eleves qu'on ne peut plus prendre, ou en cacherait qu'on pourrait.
        ..invalidate(elevesEnAttenteProvider);
      if (mounted) {
        setState(() {
          final String heure = _nommer(creneau);
          _confirmation = switch ((posee, engagee)) {
            (true, true) => t.enseignant.creneaux.retraitEngage(heure: heure),
            (true, false) => t.enseignant.creneaux.heureRetiree(heure: heure),
            (false, _) => t.enseignant.creneaux.heureEnregistree(heure: heure),
          };
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _erreur = true;
          _confirmation = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _enCours = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final String? monId = ref.watch(sessionProvider).profileId;

    if (monId == null) {
      // La session n'a pas encore livre l'identifiant : c'est un CHARGEMENT,
      // pas un vide. L'ecran rendait ici un `EmptyState` avec une invitation
      // vide, c'est-a-dire ni l'un ni l'autre des deux etats.
      return const Skeleton.liste(lignes: 6);
    }

    final AsyncValue<String> fuseau = ref.watch(monFuseauProvider);
    final AsyncValue<List<Creneau>> creneaux = ref.watch(
      disponibilitesProvider(monId),
    );
    final AsyncValue<List<Affectation>> affectations = ref.watch(
      affectationsProvider,
    );
    // Tant que la reponse n'est pas la, l'appareil est repute en ligne : un
    // bandeau affiche pendant la premiere frame clignoterait a chaque montage.
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;

    // Jamais par le type d'execution de l'`AsyncValue` : Riverpod 3 relance un
    // provider en echec et repasse par `AsyncLoading` en conservant `hasError`.
    final bool lisible = fuseau.hasValue && creneaux.hasValue;
    final bool echec = fuseau.hasError || creneaux.hasError;

    if (!lisible) {
      if (echec) {
        return EmptyState(
          message: t.enseignant.creneaux.grilleErreur,
          invitation: t.enseignant.creneaux.grilleErreurDetail,
          icone: AppIcons.avertissement,
          libelleAction: t.commun.reessayer,
          onAction: () {
            ref.invalidate(monFuseauProvider);
            ref.invalidate(disponibilitesProvider(monId));
          },
        );
      }
      // **Aucune heure affichee avant que le fuseau ait repondu.** La grille
      // se repliait sur 'Europe/Paris' code en dur : un enseignant de Conakry
      // lisait ses heures en heure de Paris, puis les voyait changer.
      return const Skeleton.liste(lignes: 6);
    }

    final List<Creneau> poses = creneaux.requireValue;
    final List<Creneau> engagements = _engagements(
      affectations.value ?? const <Affectation>[],
      monId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(t.disponibilites.titreEnseignant, style: textes.titleMedium),
        Ecart.vXs,
        Text(t.disponibilites.consigneEnseignant, style: textes.bodySmall),
        Ecart.vMd,
        GrilleSemaine(
          creneaux: poses,
          fuseau: fuseau.requireValue,
          // Hors ligne, la grille reste CONSULTABLE mais inerte : une case
          // pressee sans reseau echouerait apres le geste, et un bouton qui ne
          // peut pas aboutir n'est pas rendu (`lib/CLAUDE.md`).
          enCours: _enCours || horsLigne,
          onBasculer: (Creneau creneau, bool posee) =>
              _basculer(monId, engagements, creneau, posee),
        ),
        Ecart.vSm,
        Text(
          switch (poses.length) {
            0 => t.enseignant.creneaux.aucuneHeure,
            1 => t.disponibilites.poseeUne,
            _ => t.disponibilites.posees(nombre: '${poses.length}'),
          },
          style: textes.bodySmall,
        ),
        Ecart.vXs,
        Text(t.disponibilites.effetEnseignant, style: textes.bodySmall),
        if (horsLigne) ...<Widget>[
          Ecart.vSm,
          Text(
            t.enseignant.creneaux.horsLigneGrille,
            style: palette.inkWarning.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
        if (engagements.isNotEmpty) ...<Widget>[
          Ecart.vSm,
          Text(
            // Le conflit se VOIT, avant tout geste : une case engagee et une
            // case libre ne se distinguent autrement par rien.
            engagements.length == 1
                ? t.enseignant.creneaux.heureEngagee(
                    heures: _nommer(engagements.single),
                  )
                : t.enseignant.creneaux.heuresEngagees(
                    heures: engagements.map(_nommer).join(', '),
                  ),
            style: palette.inkWarning.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
        if (_erreur || echec) ...<Widget>[
          Ecart.vSm,
          Text(
            t.disponibilites.erreur,
            style: palette.inkAlert.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
        Ecart.vSm,
        // L'etat « enregistre », nomme. `enCours` figeait la grille sans
        // jamais dire qu'une case etait passee : l'enseignant tapait, la
        // couleur changeait, et rien ne distinguait un enregistrement reussi
        // d'un rendu optimiste.
        LocalFeedback(message: _confirmation),
      ],
    );
  }
}

/// Onglet 2 : les eleves en attente, anciennete d'abord.
class _OngletEleves extends ConsumerStatefulWidget {
  const _OngletEleves();

  @override
  ConsumerState<_OngletEleves> createState() => _OngletElevesEtat();
}

class _OngletElevesEtat extends ConsumerState<_OngletEleves> {
  String? _priseEnCours;
  String? _erreur;

  /// Au-dela de ce delai, la demande porte un lisere : sans lui, une famille
  /// peut rester en bas de liste sans que personne ne le remarque.
  static const int joursAvantSignal = 3;

  Future<void> _prendre(EleveEnAttente eleve) async {
    setState(() {
      _priseEnCours = eleve.eleveId;
      _erreur = null;
    });
    try {
      await ref
          .read(serviceMatchingProvider)
          .prendre(eleveId: eleve.eleveId, creneau: eleve.creneau);
    } on Object catch (erreur) {
      // La base tranche, pas l'ecran : si un autre enseignant vient de prendre
      // cet eleve, le refus vient de la, et il est NOMME plutot que recopie.
      if (mounted) {
        setState(() => _erreur = _messageRefus(erreur));
      }
    } finally {
      if (mounted) {
        // **Le feed se relit dans les DEUX cas, succes comme refus.** Sur refus
        // de concurrence, la ligne de l'eleve deja pris restait a l'ecran avec
        // son bouton actif : un second tap redonnait la meme erreur. Rien ne se
        // bricole en memoire -- la base dit ce qui reste a prendre, l'ecran le
        // relit.
        ref
          ..invalidate(elevesEnAttenteProvider)
          ..invalidate(affectationsProvider)
          ..invalidate(seancesProvider);
        setState(() => _priseEnCours = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final String? monId = ref.watch(sessionProvider).profileId;

    if (monId == null) {
      return const Skeleton.carteEleve(lignes: 3);
    }

    final AsyncValue<List<EleveEnAttente>> feed = ref.watch(
      elevesEnAttenteProvider,
    );
    final AsyncValue<List<Affectation>> affectations = ref.watch(
      affectationsProvider,
    );
    // **Par `regle_effective()`, pas par la vue des regles.** La vue ne joint a
    // un profil que les cles qui ont un sens pour son role : y chercher une cle
    // absente rend zero sans qu'aucune erreur ne se produise.
    final AsyncValue<int> plafondLu = ref.watch(
      valeurRegleProvider((profilId: monId, cle: CleRegle.plafondEleves)),
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;

    final bool lisible =
        feed.hasValue && affectations.hasValue && plafondLu.hasValue;
    final bool echec =
        feed.hasError || affectations.hasError || plafondLu.hasError;

    // Le refus de la base se rend AVANT et AU-DESSUS de tout le reste, gate de
    // chargement comprise : une prise refusee relit le feed, et si le message
    // vivait dans le seul chemin « contenu », il disparaitrait pendant cette
    // relecture pour revenir ensuite.
    final Widget? refus = _erreur == null
        ? null
        : Text(
            _erreur!,
            style: palette.inkAlert.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          );

    if (!lisible) {
      // Sans cet etat, un feed illisible etait indiscernable d'un feed vide :
      // `hasValue` faux, donc meme pas l'`EmptyState`, donc un ecran muet.
      final Widget corps = echec
          ? EmptyState(
              message: t.enseignant.creneaux.feedErreur,
              invitation: t.enseignant.creneaux.feedErreurDetail,
              icone: AppIcons.avertissement,
              libelleAction: t.commun.reessayer,
              onAction: () {
                ref.invalidate(elevesEnAttenteProvider);
                ref.invalidate(affectationsProvider);
                ref.invalidate(
                  valeurRegleProvider((
                    profilId: monId,
                    cle: CleRegle.plafondEleves,
                  )),
                );
              },
            )
          : const Skeleton.carteEleve(lignes: 3);

      if (refus == null) {
        return corps;
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[refus, Ecart.vMd, corps],
      );
    }

    final int suivis = affectations.requireValue
        .where((Affectation a) => a.active && a.enseignantId == monId)
        .length;
    final int plafond = plafondLu.requireValue;
    final bool auPlafond = plafond > 0 && suivis >= plafond;

    // L'anciennete ordonne la liste ici, et non dans la requete : sans ce tri,
    // la famille qui attend depuis le plus longtemps se retrouvait en bas, ce
    // qui vide le matching de son interet.
    final List<EleveEnAttente> eleves = parAnciennete(feed.requireValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (plafond > 0)
          Text(
            t.creneaux.mesEleves(nombre: '$suivis', plafond: '$plafond'),
            style: textes.bodySmall,
          ),
        Ecart.vMd,
        if (horsLigne) ...<Widget>[
          // La prise est impossible hors ligne, et c'est DIT : le bandeau de
          // `PageShell` annonce la coupure, pas ce qu'elle empeche ici.
          Text(
            t.enseignant.creneaux.horsLignePrise,
            style: palette.inkWarning.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vMd,
        ],
        if (auPlafond) ...<Widget>[
          // Le bouton « Prendre » n'est pas rendu au plafond : un bouton qui
          // echoue apres le geste coute plus cher qu'un bouton absent.
          Text(
            t.creneaux.plafondAtteint(nombre: '$suivis'),
            style: textes.bodyMedium,
          ),
          Ecart.vSm,
          ActionPrincipale(
            libelle: t.creneaux.plafondDemander,
            onPress: () => _ouvrirDemande(context, monId, plafond),
            niveau: NiveauAction.secondaire,
          ),
          Ecart.vLg,
        ],
        if (refus != null) ...<Widget>[refus, Ecart.vMd],
        if (eleves.isEmpty)
          // Sans bouton : l'enseignant ne peut rien faire d'une file vide, sauf
          // proposer d'autres heures -- ce que l'invitation dit.
          EmptyState(
            message: t.creneaux.aucunEleve,
            invitation: t.creneaux.aucunEleveDetail,
          )
        else
          for (final EleveEnAttente eleve in eleves)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _CarteEleve(
                eleve: eleve,
                enCours: _priseEnCours == eleve.eleveId,
                // Au plafond comme hors ligne, la carte reste visible :
                // l'enseignant doit pouvoir constater qui attend avant de
                // demander plus, ou avant de retrouver du reseau.
                avecBouton: !auPlafond && !horsLigne,
                onPrendre: () => _prendre(eleve),
              ),
            ),
      ],
    );
  }

  Future<void> _ouvrirDemande(
    BuildContext context,
    String monId,
    int plafond,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext contexteFeuille) =>
          _FeuilleDemande(monId: monId, plafondActuel: plafond),
    );
  }
}

/// Ce que la base a refuse, reconnu depuis sa phrase.
///
/// **Un pis-aller assume, pas un contrat.** `prendre_eleve()` et
/// `guard_assignment_cap()` rendent des PHRASES SQL non traduites ; les montrer
/// telles quelles ferait dependre un libelle d'interface d'une chaine de
/// migration. Le vrai remede est un code d'erreur ferme cote base : il est
/// demande dans `docs/parallel-reports/CONTRACT_REQUEST_D.md`. En attendant, on
/// reconnait la phrase et on affiche la notre, avec un repli qui recopie le
/// message brut plutot que d'avaler un refus qu'on n'avait pas prevu.
enum _Refus {
  /// Un autre enseignant a gagne la course. C'est le cas de concurrence.
  dejaPris,

  /// L'eleve avait deja un enseignant avant que l'ecran ne se rafraichisse.
  dejaSuivi,

  /// Le foyer ne propose plus ce creneau.
  creneauRetire,

  /// Le creneau ne croise plus les heures de l'enseignant.
  horsMesHeures,

  /// Le trigger de plafond a refuse l'insertion.
  plafond,

  /// Tout le reste : on recopie, on n'invente pas.
  inconnu,
}

_Refus _refusDe(Object erreur) {
  final String brut = erreur.toString().toLowerCase();
  // L'ordre compte : « autre enseignant » se teste avant « un enseignant »,
  // sinon le conflit de concurrence serait lu comme un eleve deja suivi.
  if (brut.contains('autre enseignant')) {
    return _Refus.dejaPris;
  }
  if (brut.contains('deja un enseignant')) {
    return _Refus.dejaSuivi;
  }
  if (brut.contains('propose par ce foyer')) {
    return _Refus.creneauRetire;
  }
  if (brut.contains('vos disponibilites')) {
    return _Refus.horsMesHeures;
  }
  if (brut.contains('plafond d')) {
    return _Refus.plafond;
  }
  return _Refus.inconnu;
}

String _messageRefus(Object erreur) => switch (_refusDe(erreur)) {
  _Refus.dejaPris => t.enseignant.creneaux.refusDejaPris,
  _Refus.dejaSuivi => t.enseignant.creneaux.refusDejaSuivi,
  _Refus.creneauRetire => t.enseignant.creneaux.refusCreneauRetire,
  _Refus.horsMesHeures => t.enseignant.creneaux.refusHorsMesHeures,
  _Refus.plafond => t.enseignant.creneaux.refusPlafond,
  _Refus.inconnu => t.creneaux.erreur(message: _brut(erreur)),
};

String _brut(Object erreur) {
  final String brut = erreur.toString();
  // Les exceptions Postgrest portent le message metier en clair : c'est lui
  // qu'il faut montrer, pas le type de l'exception.
  final int deuxPoints = brut.indexOf(': ');
  return deuxPoints >= 0 && deuxPoints + 2 < brut.length
      ? brut.substring(deuxPoints + 2)
      : brut;
}

/// Une ligne du feed : **un creneau compatible**, pas un eleve.
///
/// Le meme eleve apparait autant de fois qu'il propose d'heures que
/// l'enseignant peut tenir. Compter les cartes annoncerait quatre familles la
/// ou une seule attend.
///
/// **Aucune coordonnee de famille n'est rendue ici** (ADR-008) : prenom,
/// identifiant immuable, niveau declare, jour et heure, anciennete. Ni nom de
/// famille, ni courriel, ni telephone, ni identifiant de foyer -- et le modele
/// `EleveEnAttente` n'en porte aucun, il n'y a donc rien a oublier de masquer.
class _CarteEleve extends StatelessWidget {
  const _CarteEleve({
    required this.eleve,
    required this.enCours,
    required this.avecBouton,
    required this.onPrendre,
  });

  final EleveEnAttente eleve;
  final bool enCours;
  final bool avecBouton;
  final VoidCallback onPrendre;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final int jours = eleve.joursDAttente(DateTime.now());
    final bool signale = jours >= _OngletElevesEtat.joursAvantSignal;

    return BentoTile(
      // Le lisere de l'attente : il ne remplace pas le texte, il le double.
      surface: signale ? palette.surfaceWarning : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(eleve.prenom, style: textes.titleMedium),
          Text(eleve.identifiantImmuable, style: textes.bodySmall),
          if (eleve.niveau != null)
            Text(
              t.creneaux.niveau(niveau: eleve.niveau!),
              style: textes.bodySmall,
            ),
          Ecart.vXs,
          Text(switch (jours) {
            0 => t.creneaux.attendAujourdhui,
            1 => t.creneaux.attendUnJour,
            _ => t.creneaux.attendDepuis(jours: '$jours'),
          }, style: textes.bodySmall),
          Ecart.vSm,
          if (avecBouton)
            ActionPrincipale(
              libelle: t.creneaux.prendre(
                jour: t.disponibilites.joursLongs[eleve.creneau.jour - 1],
                heure: '${eleve.creneau.heure}',
              ),
              onPress: onPrendre,
              enCours: enCours,
            ),
        ],
      ),
    );
  }
}

/// La demande d'augmentation de plafond, faite par l'enseignant pour lui-meme.
class _FeuilleDemande extends ConsumerStatefulWidget {
  const _FeuilleDemande({required this.monId, required this.plafondActuel});

  final String monId;
  final int plafondActuel;

  @override
  ConsumerState<_FeuilleDemande> createState() => _FeuilleDemandeEtat();
}

class _FeuilleDemandeEtat extends ConsumerState<_FeuilleDemande> {
  final TextEditingController _motif = TextEditingController();
  int? _valeur;
  bool _enCours = false;
  String? _erreur;
  bool _envoyee = false;

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    final int? valeur = _valeur;
    if (valeur == null || _motif.text.trim().isEmpty) {
      setState(() => _erreur = t.creneaux.demandeMotifRequis);
      return;
    }
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await ref
          .read(serviceMatchingProvider)
          .demander(
            sorte: SorteDemande.plafond,
            sujetId: widget.monId,
            motif: _motif.text.trim(),
            valeur: valeur,
          );
      if (mounted) {
        setState(() => _envoyee = true);
      }
    } on Object catch (erreur) {
      if (mounted) {
        setState(() => _erreur = _brut(erreur));
      }
    } finally {
      if (mounted) {
        setState(() => _enCours = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppMetriques metriques = AppMetriques.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: metriques.marge,
        end: metriques.marge,
        top: metriques.marge,
        bottom: MediaQuery.viewInsetsOf(context).bottom + metriques.marge,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(t.creneaux.demandeTitre, style: textes.titleMedium),
          Ecart.vMd,
          if (_envoyee)
            Text(t.creneaux.demandeEnvoyee, style: textes.bodyMedium)
          else if (horsLigne)
            // Une demande deposee sans reseau se perdrait : elle ne passe pas
            // par la file hors ligne des rapports.
            Text(
              t.enseignant.creneaux.horsLigneDemande,
              style: palette.inkWarning.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            )
          else ...<Widget>[
            ChoiceCardGroup(
              options: <OptionChoix>[
                for (int de = 1; de <= 3; de++)
                  OptionChoix(
                    valeur: '${widget.plafondActuel + de}',
                    libelle: t.creneaux.eleves(
                      nombre: '${widget.plafondActuel + de}',
                    ),
                  ),
              ],
              onChange: (ReponseChoix reponse) => setState(() {
                _valeur = int.tryParse(
                  reponse.valeurs.isEmpty
                      ? reponse.saisieLibre ?? ''
                      : reponse.valeurs.first,
                );
              }),
            ),
            Ecart.vMd,
            TextField(
              controller: _motif,
              decoration: InputDecoration(labelText: t.creneaux.demandeMotif),
              // Sans ceci, le bouton ne se reconstruit pas a la frappe et
              // reste inerte alors que le motif est saisi (piege de l'etape 3).
              onChanged: (String _) => setState(() {}),
              maxLines: 2,
            ),
            if (_erreur != null) ...<Widget>[
              Ecart.vSm,
              Text(
                _erreur!,
                style: palette.inkAlert.applyTo(
                  textes.bodySmall ?? const TextStyle(),
                ),
              ),
            ],
            Ecart.vMd,
            ActionPrincipale(
              libelle: t.creneaux.demandeEnvoyer,
              enCours: _enCours,
              onPress: _valeur == null || _motif.text.trim().isEmpty
                  ? null
                  : _envoyer,
            ),
          ],
        ],
      ),
    );
  }
}
