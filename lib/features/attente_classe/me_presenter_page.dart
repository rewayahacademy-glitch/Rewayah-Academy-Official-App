/// SUIVI-ATTENTE (S5) : « Me presenter », le geste de l'enseignant a
/// l'affectation.
///
/// Un message deja redige, modifiable, envoye par les **Messages existants**
/// aux tuteurs des eleves mineurs de la classe et aux eleves adultes : une
/// conversation par famille, ouverte par le serveur sur la paire qu'il
/// autorise (`conversationsPourObjet`, `ouvrirConversation`, `envoyer`). Ce
/// lot ne construit aucune messagerie.
///
/// - **jamais de message prive a un mineur** : le serveur ne propose que des
///   tuteurs et des adultes (un mineur n'est jamais une partie) ; l'ecran ne
///   contacte rien d'autre que ce que le serveur propose ;
/// - **aucun echange de telephone ni de contact hors de l'application** : le
///   rappel le dit, l'ecran n'en demande aucun ;
/// - **jamais deux fois** : une famille qui a deja un echange avec
///   l'enseignant ne recoit pas la presentation (comptee et dite), et la cle
///   d'idempotence de chaque envoi reste la meme a chaque nouvel essai.
///
/// Etats : chargement, contenu, vide (aucune famille ne peut recevoir de
/// message), erreur (« Reessayer »), envoi en cours, envoye, echec partiel.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/enseignant/modeles_enseignant.dart';
import '../../core/enseignant/service_enseignant.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/profil/service_profil_enseignant.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/zone_saisie.dart';
import '../com_messages/port_messages_metier.dart';

/// Les conversations que le serveur ouvre sur la classe [groupeId] : les
/// familles et les eleves adultes, jamais un mineur, jamais la direction.
final FutureProviderFamily<List<ConversationPossible>, String>
conversationsPresentationProvider = FutureProvider.autoDispose
    .family<List<ConversationPossible>, String>((
      Ref ref,
      String groupeId,
    ) async {
      final List<ConversationPossible> toutes = await ref
          .watch(portMessagesMetierProvider)
          .conversationsPourObjet(TypeObjetLie.classe, groupeId);
      return <ConversationPossible>[
        for (final ConversationPossible c in toutes)
          if (c.nature != NatureInterlocuteur.administration) c,
      ];
    });

/// Le message de presentation deja redige, au masculin ou au feminin selon
/// le titre de l'enseignant (Sayyid, Sayyida).
String messagePresentation({
  required String? titre,
  required String nom,
  required String classe,
}) => titre == 'sayyida'
    ? t.suiviAttente.mePresenter.messageSayyida(nom: nom, classe: classe)
    : t.suiviAttente.mePresenter.messageSayyid(nom: nom, classe: classe);

/// L'ecran « Me presenter » d'une classe.
class MePresenterPage extends ConsumerStatefulWidget {
  /// Cree l'ecran de la classe [groupeId].
  const MePresenterPage({required this.groupeId, super.key});

  /// La classe a laquelle l'enseignant se presente.
  final String groupeId;

  @override
  ConsumerState<MePresenterPage> createState() => _MePresenterEtat();
}

enum _Phase { saisie, envoi, fait }

class _MePresenterEtat extends ConsumerState<MePresenterPage> {
  final TextEditingController _texte = TextEditingController();
  bool _prerempli = false;
  _Phase _phase = _Phase.saisie;
  bool _vide = false;
  int _envoyes = 0;
  bool _echec = false;

  /// Une cle d'idempotence par conversation, la meme a chaque essai.
  final Map<String, String> _cles = <String, String>{};

  @override
  void dispose() {
    _texte.dispose();
    super.dispose();
  }

  void _remplir(String? classe, ProfilEnseignant? profil) {
    if (_prerempli || classe == null || profil == null) return;
    _prerempli = true;
    _texte.text = messagePresentation(
      titre: profil.titre,
      nom: profil.prenom,
      classe: classe,
    );
  }

  Future<void> _envoyer(List<ConversationPossible> cibles) async {
    final String texte = _texte.text.trim();
    if (texte.isEmpty) {
      setState(() => _vide = true);
      return;
    }
    setState(() {
      _phase = _Phase.envoi;
      _echec = false;
      _vide = false;
    });
    final PortMessagesMetier port = ref.read(portMessagesMetierProvider);
    int envoyes = 0;
    bool echec = false;
    for (final ConversationPossible c in cibles) {
      try {
        final FilMetier? fil = await port.ouvrirConversation(c);
        if (fil == null) {
          echec = true;
          continue;
        }
        await port.envoyer(
          fil.id,
          texte,
          _cles.putIfAbsent(c.cle, () => const Uuid().v4()),
        );
        envoyes++;
      } on Object {
        echec = true;
      }
    }
    if (!mounted) return;
    setState(() {
      _envoyes += envoyes;
      _echec = echec;
      _phase = echec ? _Phase.saisie : _Phase.fait;
    });
    // Les familles jointes ont maintenant un fil : la liste se relit, pour que
    // celles qui l'ont recu ne soient plus des cibles.
    ref.invalidate(conversationsPresentationProvider(widget.groupeId));
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    String? classe;
    for (final GroupeEnseignant g
        in ref.watch(groupesEnseignantProvider).value ??
            const <GroupeEnseignant>[]) {
      if (g.id == widget.groupeId) classe = g.libelle;
    }
    final ProfilEnseignant? profil = ref.watch(profilEnseignantProvider).value;
    _remplir(classe, profil);

    return PageShell(
      titre: t.suiviAttente.mePresenter.titre,
      sousTitre: t.suiviAttente.mePresenter.contexte,
      onRetour: () {
        final GoRouter? routeur = GoRouter.maybeOf(context);
        if (routeur == null) return;
        if (routeur.canPop()) {
          routeur.pop();
        } else {
          routeur.go(Routes.enseignantClasses);
        }
      },
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppPage.largeurFormulaire,
          ),
          child: BlocAsynchrone<List<ConversationPossible>>(
            key: const ValueKey<String>('presenter-bloc'),
            valeur: ref.watch(
              conversationsPresentationProvider(widget.groupeId),
            ),
            squelette: Semantics(
              label: t.suiviAttente.mePresenter.chargement,
              child: const ExcludeSemantics(child: Skeleton.liste(lignes: 3)),
            ),
            onReessayer: () => ref.invalidate(
              conversationsPresentationProvider(widget.groupeId),
            ),
            titreEchec: t.suiviAttente.mePresenter.erreur,
            estVide: (List<ConversationPossible> l) =>
                l.isEmpty && _phase != _Phase.fait,
            vide: EmptyState(
              key: const ValueKey<String>('presenter-vide'),
              message: t.suiviAttente.mePresenter.aucune,
              icone: AppIcons.discussion,
              registre: RegistreVide.subi,
            ),
            construire: (List<ConversationPossible> toutes) {
              final List<ConversationPossible> cibles = <ConversationPossible>[
                for (final ConversationPossible c in toutes)
                  if (c.filId == null) c,
              ];
              final int deja = toutes.length - cibles.length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (_phase == _Phase.fait) ...<Widget>[
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        t.suiviAttente.mePresenter.envoye(n: _envoyes),
                        key: const ValueKey<String>('presenter-envoye'),
                        style: palette.inkSuccess.applyTo(
                          textes.titleMedium ?? const TextStyle(),
                        ),
                      ),
                    ),
                    Ecart.vLg,
                  ] else ...<Widget>[
                    ZoneSaisie(
                      cleChamp: const ValueKey<String>('presenter-texte'),
                      controleur: _texte,
                      libelle: t.suiviAttente.mePresenter.champ,
                      minLignes: 6,
                      maxLignes: 12,
                      onChanged: (String _) {
                        if (_vide) setState(() => _vide = false);
                      },
                      erreur: _vide ? t.suiviAttente.mePresenter.vide : null,
                    ),
                    Ecart.vMd,
                    TexteSansCoupure(
                      t.suiviAttente.mePresenter.rappel,
                      key: const ValueKey<String>('presenter-rappel'),
                      style: palette
                          .encreSecondaireSur(palette.surfaceCanvas)
                          .applyTo(textes.bodySmall ?? const TextStyle()),
                    ),
                  ],
                  if (deja > 0) ...<Widget>[
                    Ecart.vMd,
                    Text(
                      t.suiviAttente.mePresenter.dejaEcrit(n: deja),
                      key: const ValueKey<String>('presenter-deja'),
                      style: palette
                          .encreSecondaireSur(palette.surfaceCanvas)
                          .applyTo(textes.bodySmall ?? const TextStyle()),
                    ),
                  ],
                  if (_echec) ...<Widget>[
                    Ecart.vMd,
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        t.suiviAttente.mePresenter.echec,
                        key: const ValueKey<String>('presenter-echec'),
                        style: palette.inkAlert.applyTo(
                          textes.bodyMedium ?? const TextStyle(),
                        ),
                      ),
                    ),
                  ],
                  if (_phase != _Phase.fait && cibles.isNotEmpty) ...<Widget>[
                    Ecart.vLg,
                    ActionPrincipale(
                      key: const ValueKey<String>('presenter-envoyer'),
                      libelle: t.suiviAttente.mePresenter.envoyer,
                      pleineLargeur: false,
                      enCours: _phase == _Phase.envoi,
                      onPress: () => unawaited(_envoyer(cibles)),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
