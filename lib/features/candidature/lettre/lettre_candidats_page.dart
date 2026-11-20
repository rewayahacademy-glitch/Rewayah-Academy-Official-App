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

import '../../../core/i18n/strings.g.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/carte_lignes.dart';
import '../../../core/widgets/lien_fleche.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/setting_row.dart';
import '../lecture_page.dart';
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

  Widget _page({required Widget corps, bool guide = false}) => PageShell(
    key: LettreCandidatsPage.cle,
    titre: t.recrutement.lettre.titre,
    onRetour: _retour,
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
    child: Align(
      alignment: AlignmentDirectional.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppPage.largeurLecture),
        child: corps,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final String langue = TranslationProvider.of(context).locale.languageCode;
    return lecturePage<LectureLettre>(
      ref: ref,
      titre: t.recrutement.lettre.titre,
      valeur: ref.watch(lettreProvider(langue)),
      titreEchec: t.recrutement.lettre.nonCharge,
      onReessayer: () => ref.invalidate(lettreProvider(langue)),
      construire: (LectureLettre lu) {
        if (!lu.acces) {
          return _page(
            corps:
                lu.raison == RaisonRefusLettre.accords && lu.manques.isNotEmpty
                ? VerrouLettre(manques: lu.manques)
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
      },
    );
  }
}

/// Le verrou : ce qui manque, et le chemin pour l'accepter.
class VerrouLettre extends StatelessWidget {
  /// Cree le verrou.
  const VerrouLettre({required this.manques, super.key});

  /// Les accords qui manquent.
  final List<AccordManquant> manques;

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
        ActionPrincipale(
          libelle: l.completer,
          onPress: () => GoRouter.of(context).go(chemin),
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
