// LETTRE-CANDIDATS (directeur, 20/11/2026) : la lettre aux candidats
// enseignants, en page interne.
//
// « tu devras le creer ce texte en forme de site interne que les candidats
// verront dans l'espace d'attente, mais aussi dans l'espace enseignant » ;
// le lien se partage, et seule une personne connectee le lit (directeur,
// 20/11). La page vit sous `/lire` (`Routes.lettreEnseignants`) : le routeur
// l'ouvre a tout compte connecte, en attente comme actif, et envoie un
// visiteur sans session a la connexion, qui le ramene ici.
//
// Le texte vient du SERVEUR (`port_lettre.dart`), qui ne le rend qu'a un
// enseignant ou a un candidat dont les accords sont acceptes ; sinon il dit
// ce qui manque, sans une ligne du texte. Aucun texte de la lettre n'est
// compile dans l'application. Le routeur ne laisse entrer que le role
// enseignant ; le serveur decide quand meme.
//
// Les cinq etats : chargement (squelette), contenu (la lettre), refus (ce qui
// manque et le chemin), erreur (« Reessayer »), hors ligne (le bloc de ce qui
// manque, sous le bandeau de la coquille) ; capacite pas encore branchee :
// la phrase de l'etape non ouverte.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/candidature/lettre_supabase.dart' show dependanceLettre;
import '../../../core/candidature/port_ma_candidature.dart';
import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/reseau/etat_sans_donnees.dart';
import '../../../core/reseau/service_reseau.dart';
import '../../../core/router/routes.dart';
import '../../../core/session/session_controleur.dart';
import '../../../core/session/session_state.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/bloc_asynchrone.dart';
import '../../../core/widgets/carte_lignes.dart';
import '../../../core/widgets/etat_systeme.dart';
import '../../../core/widgets/lien_fleche.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/setting_row.dart';
import '../../../core/widgets/skeleton.dart';
import 'port_lettre.dart';
import 'praxis_lettre.dart';
import 'texte_lettre.dart';

/// Le nom d'un accord, dans la phrase « il vous reste a accepter ».
extension NomAccord on AccordManquant {
  /// Son nom.
  String get nom {
    final l = t.recrutement.lettre;
    return switch (this) {
      AccordManquant.contrat => l.manqueContrat,
      AccordManquant.conduite => l.manqueConduite,
      AccordManquant.cadre => l.manqueCadre,
    };
  }
}

/// La page de la lettre.
class LettreCandidatsPage extends ConsumerStatefulWidget {
  /// Cree la page.
  const LettreCandidatsPage({super.key});

  /// La cle de la page.
  static const Key cle = ValueKey<String>('lettre-candidats');

  /// La cle du verrou.
  static const Key cleVerrou = ValueKey<String>('lettre-verrou');

  /// La cle de la zone qui defile sous la tete fixe.
  static const Key cleDefilement = ValueKey<String>('lettre-defilement');

  /// La cle de la phrase « reservee aux enseignants ».
  static const Key cleReservee = ValueKey<String>('lettre-reservee');

  @override
  ConsumerState<LettreCandidatsPage> createState() => _EtatLettre();
}

class _EtatLettre extends ConsumerState<LettreCandidatsPage> {
  final ValueNotifier<MomentLettre> _moment = ValueNotifier<MomentLettre>(
    MomentLettre.accueil,
  );
  final ValueNotifier<int> _secousses = ValueNotifier<int>(0);

  @override
  void dispose() {
    _moment.dispose();
    _secousses.dispose();
    super.dispose();
  }

  void _retour() {
    final GoRouter routeur = GoRouter.of(context);
    if (routeur.canPop()) {
      routeur.pop();
    } else {
      routeur.go(Routes.racine);
    }
  }

  // Praxis suit la lecture (directeur, 20/11 : « il est en haut, il saute et
  // rebondit avec le scroll pour suivre ») : quand il est la, la tete de la
  // page (titre court et bande de Praxis, sous les 160 points de WEB-BUREAU
  // B6) reste fixe et le corps defile seul, avec la seule barre de
  // defilement de l'ecran. Ecart date a DECISION-DEFILEMENT, sur ordre du
  // directeur : `REGLES-NOUVELLES.md`, I4.
  Widget _page({required Widget corps, bool guide = false}) {
    final Widget lecture = Align(
      alignment: AlignmentDirectional.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppPage.largeurLecture),
        child: corps,
      ),
    );
    return PageShell(
      key: LettreCandidatsPage.cle,
      titre: t.recrutement.lettre.nom,
      onRetour: _retour,
      defilante: !guide,
      // La bande de Praxis a la largeur de la lecture (WEB-BUREAU B4).
      enteteSecondaire: guide
          ? Align(
              alignment: AlignmentDirectional.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppPage.largeurLecture,
                ),
                child: PraxisLettre(moment: _moment, secousses: _secousses),
              ),
            )
          : null,
      child: guide
          ? SingleChildScrollView(
              key: LettreCandidatsPage.cleDefilement,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[lecture, Ecart.vSection],
              ),
            )
          : lecture,
    );
  }

  // LETTRE-SERVEUR (relecture S3, 21/11/2026) : chargement, echec, hors
  // ligne et guide indisponible vivent dans la page du guide elle-meme, avec
  // son retour (`pop`, sinon la racine) ; jamais la page de la candidature,
  // dont le retour mene au portail d'attente.
  @override
  Widget build(BuildContext context) {
    final String langue = TranslationProvider.of(context).locale.languageCode;
    final AsyncValue<LectureLettre> valeur = ref.watch(lettreProvider(langue));
    if (!valeur.hasValue) {
      final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
      final String echec = t.recrutement.lettre.nonCharge;
      return _page(
        corps: BlocAsynchrone<LectureLettre>(
          valeur: valeur,
          squelette: const Skeleton.liste(lignes: 3),
          titreEchec: echec,
          onReessayer: () => ref.invalidate(lettreProvider(langue)),
          erreurVersEtat: (Object erreur, VoidCallback? reessayer) {
            if (erreur is CapaciteIndisponible) {
              return const GuideIndisponible();
            }
            if (erreur is HorsLigneCandidature || horsLigne) {
              return EtatSansDonnees(quoi: echec, onAction: reessayer);
            }
            return null;
          },
          construire: (LectureLettre _) => const SizedBox.shrink(),
        ),
      );
    }
    final LectureLettre lu = valeur.requireValue;
    if (!lu.acces) {
      // Ecrire a la direction : la messagerie du candidat tant que le compte
      // est en attente, celle de l'espace enseignant sinon.
      final bool enAttente =
          ref.watch(sessionProvider).porte == PorteAcces.attente;
      return _page(
        corps: lu.raison == RaisonRefusLettre.accords && lu.manques.isNotEmpty
            ? VerrouLettre(
                manques: lu.manques,
                acceptable: lu.acceptable,
                cheminEcrire: enAttente
                    ? Routes.attenteMessages
                    : Routes.enseignantMessages,
              )
            : Text(
                t.recrutement.lettre.reservee,
                key: LettreCandidatsPage.cleReservee,
              ),
      );
    }
    return _page(
      guide: true,
      corps: ContenuLettre(
        parties: lu.parties,
        moment: _moment,
        secousses: _secousses,
      ),
    );
  }
}

/// « Le guide n'est pas encore disponible. », sans « Reessayer » : une
/// capacite absente (fonction pas encore installee) ne revient pas en
/// insistant.
class GuideIndisponible extends StatelessWidget {
  /// Cree le bloc.
  const GuideIndisponible({super.key});

  /// La cle du bloc.
  static const Key cle = ValueKey<String>('lettre-indisponible');

  @override
  Widget build(BuildContext context) => EtatSysteme(
    key: cle,
    nature: NatureEtat.indisponible,
    phrase: t.recrutement.lettre.indisponible,
    dependance: dependanceLettre,
  );
}

/// Le verrou : ce qui manque, et le chemin pour l'accepter ; quand le compte
/// ne peut pas l'accepter lui-meme ([acceptable] faux), la direction ouvre
/// l'acces : on lui ecrit, jamais un lien vers un ecran sans issue.
class VerrouLettre extends StatelessWidget {
  /// Cree le verrou.
  const VerrouLettre({
    required this.manques,
    this.acceptable = true,
    this.cheminEcrire = Routes.attenteMessages,
    super.key,
  });

  /// Les accords qui manquent.
  final List<AccordManquant> manques;

  /// Vrai quand le compte peut accepter lui-meme ce qui manque.
  final bool acceptable;

  /// Ou ecrire a la direction, quand [acceptable] est faux.
  final String cheminEcrire;

  /// La cle de la phrase « la direction ouvre l'acces ».
  static const Key cleDirection = ValueKey<String>('lettre-verrou-direction');

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle corps = palette.inkStrong.applyTo(
      textes.bodyLarge ?? const TextStyle(),
    );
    final l = t.recrutement.lettre;
    // Le contrat et le code de conduite se signent sur la page des accords ;
    // l'engagement religieux, sur la sienne.
    final String chemin =
        manques.contains(AccordManquant.contrat) ||
            manques.contains(AccordManquant.conduite)
        ? Routes.attenteAccords
        : Routes.attenteCadre;
    return Column(
      key: LettreCandidatsPage.cleVerrou,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            l.verrouTitre,
            style: palette.inkStrong.applyTo(
              textes.titleLarge ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vMd,
        Text(l.verrouIntro, style: corps),
        Ecart.vSm,
        for (final AccordManquant m in manques)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text('• ${m.nom}', style: corps),
          ),
        Ecart.vXl,
        // Un seul bouton plein : accepter ce qui manque, ou, quand le compte
        // ne le peut pas, ecrire a la direction (K-56).
        if (!acceptable) ...<Widget>[
          Text(l.directionOuvre, key: VerrouLettre.cleDirection, style: corps),
          Ecart.vXl,
        ],
        ActionPrincipale(
          libelle: acceptable ? l.completer : l.ecrireDirection,
          onPress: () =>
              GoRouter.of(context).go(acceptable ? chemin : cheminEcrire),
        ),
      ],
    );
  }
}

/// La lettre : en-tete, sommaire, puis les quatorze parties.
class ContenuLettre extends StatefulWidget {
  /// Cree le contenu.
  const ContenuLettre({
    required this.parties,
    required this.moment,
    required this.secousses,
    super.key,
  });

  /// Les parties rendues par le serveur, dans l'ordre de lecture.
  final List<PartieLettre> parties;

  /// La partie lue, que Praxis suit.
  final ValueNotifier<MomentLettre> moment;

  /// Le compteur des reprises du defilement.
  final ValueNotifier<int> secousses;

  /// La cle du sommaire.
  static const Key cleSommaire = ValueKey<String>('lettre-sommaire');

  /// La cle de la partie [n] (1 a 14).
  static Key clePartie(int n) => ValueKey<String>('lettre-partie-$n');

  @override
  State<ContenuLettre> createState() => _EtatContenu();
}

class _EtatContenu extends State<ContenuLettre> {
  final GlobalKey _sommaire = GlobalKey();
  late final List<GlobalKey> _parties = List<GlobalKey>.generate(
    widget.parties.length,
    (_) => GlobalKey(),
  );
  ScrollPosition? _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ScrollPosition? nouvelle = Scrollable.maybeOf(context)?.position;
    if (nouvelle != _position) {
      _position?.removeListener(_suivre);
      _position?.isScrollingNotifier.removeListener(_reprise);
      _position = nouvelle
        ?..addListener(_suivre)
        ..isScrollingNotifier.addListener(_reprise);
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_suivre);
    _position?.isScrollingNotifier.removeListener(_reprise);
    super.dispose();
  }

  // Une reprise du defilement : Praxis fait un petit saut.
  void _reprise() {
    if (_position?.isScrollingNotifier.value ?? false) {
      widget.secousses.value++;
    }
  }

  // La partie lue : la derniere dont le titre a passe le tiers de l'ecran.
  void _suivre() {
    final double seuil = MediaQuery.sizeOf(context).height / 3;
    int lue = 1;
    for (int k = 0; k < _parties.length; k++) {
      final RenderObject? r = _parties[k].currentContext?.findRenderObject();
      if (r is! RenderBox || !r.attached) continue;
      if (r.localToGlobal(Offset.zero).dy <= seuil) lue = k + 1;
    }
    widget.moment.value = MomentLettre.pourPartie(lue);
  }

  void _aller(GlobalKey cle) {
    final BuildContext? c = cle.currentContext;
    if (c != null) Scrollable.ensureVisible(c);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final l = t.recrutement.lettre;
    final List<PartieLettre> parties = widget.parties;
    final TextStyle muet = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    // La derniere partie (« Pour decider ») n'a pas de numero.
    String numero(int k) => k < parties.length - 1 ? '${k + 1}. ' : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            insecables(l.titre),
            style: palette.inkStrong.applyTo(
              textes.titleMedium ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vSm,
        Text(
          insecables(l.chapeau),
          style: palette.inkStrong.applyTo(
            textes.bodyLarge ?? const TextStyle(),
          ),
        ),
        Ecart.vSm,
        Text('${l.duree} · ${insecables(l.miseAJour)}', style: muet),
        Ecart.vXxl,
        Semantics(
          key: _sommaire,
          header: true,
          child: Text(
            l.sommaire,
            key: ContenuLettre.cleSommaire,
            style: palette.inkStrong.applyTo(
              textes.titleLarge ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vSm,
        // Le sommaire : une seule carte a lignes fines, une ligne par partie,
        // alignee au debut (K-55, comme les reglages).
        CarteLignes(
          lignes: <Widget>[
            for (int k = 0; k < parties.length; k++)
              SettingRow(
                title: '${numero(k)}${parties[k].titre}',
                lien: true,
                libelleSemantique: l.allerA(titre: parties[k].titre),
                onPress: () => _aller(_parties[k]),
              ),
          ],
        ),
        for (int k = 0; k < parties.length; k++) ...<Widget>[
          Ecart.vSection,
          Semantics(
            key: _parties[k],
            header: true,
            child: Text(
              '${numero(k)}${insecables(parties[k].titre)}',
              key: ContenuLettre.clePartie(k + 1),
              style: palette.inkStrong.applyTo(
                textes.titleLarge ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vLg,
          CorpsLettre(brut: parties[k].corps),
          Ecart.vMd,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: LienFleche(
              alignerEnDebut: true,
              libelle: l.revenirSommaire,
              onPress: () => _aller(_sommaire),
            ),
          ),
        ],
      ],
    );
  }
}
