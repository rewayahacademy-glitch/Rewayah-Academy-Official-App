// PERSONNES-UNE-PAGE, etape (b2) : l'apercu d'un candidat ou d'un enseignant
// dans la page « Personnes » (colonne de droite, a l'ordinateur).
//
// En tete, la synthese du dossier (la meme que celle du dossier complet,
// `SyntheseTeteDossier`) : ce qui manque, la piece d'identite, la derniere
// connexion, l'anciennete ; puis l'etape, le pays, les langues et la
// memorisation. En bas, les gestes : le prochain geste que l'etat permet
// (« Admettre... »), « Demander un complement », « Ecrire », et le lien vers
// le dossier complet.
//
// **Une presentation, pas une regle.** Tout vient de `lire_candidature`
// (`apercuCandidatureProvider`, deja lu par la messagerie) ; les gestes sont
// ceux de la table `gestes_proposes.dart`, lances par `lancerGesteDeLigne` (la
// meme feuille que la fiche). Aucune donnee de contact : ni courriel, ni
// telephone.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/candidature/gestes_candidature.dart';
import '../../core/candidature/modeles_candidature_detail.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/candidature/modeles_lot_candidatures.dart';
import '../../core/candidature/port_candidatures_direction.dart';
import '../../core/candidature/synthese_candidature.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../admin_candidature/geste_de_ligne.dart';
import '../admin_candidature/gestes_proposes.dart';
import '../admin_candidature/libelles_candidature.dart';
import '../admin_candidature/navigation_dossier.dart'
    show ReglagePasserAuSuivant;
import '../admin_candidature/suivant_dossier.dart' show passerAuSuivantProvider;
import '../admin_candidature/synthese_tete_dossier.dart';
import '../admin_candidatures/libelles_candidatures.dart';
import '../admin_candidatures/lot_candidatures.dart';
import '../com_messages/apercu_profil_candidat.dart';
import '../foyer/photo_eleve.dart';

/// L'apercu d'un dossier de candidat ou d'enseignant.
class ApercuCandidatPersonnes extends ConsumerStatefulWidget {
  /// Cree l'apercu de [ligne].
  const ApercuCandidatPersonnes({
    required this.ligne,
    required this.onOuvrirDossier,
    this.onChange,
    this.onSuivant,
    super.key,
  });

  /// Etape (d) : ouvre l'apercu de la personne suivante de la liste, ou `null`
  /// en fin de liste. Apres une decision enregistree, l'apercu y passe seul
  /// quand le reglage « Passer au suivant apres une decision » est actif (le
  /// meme reglage que le dossier complet).
  final VoidCallback? onSuivant;

  /// La cle de « Rester sur ce dossier ».
  static const Key cleRester = ValueKey<String>('personnes-apercu-rester');

  /// La ligne de la liste (le dossier).
  final LigneCandidature ligne;

  /// Ouvre le dossier complet.
  final VoidCallback onOuvrirDossier;

  /// Un geste a change le dossier : la page relit sa liste.
  final VoidCallback? onChange;

  /// La cle du geste principal.
  static const Key cleGestePrincipal = ValueKey<String>(
    'personnes-apercu-geste',
  );

  /// La cle de « Demander un complement ».
  static const Key cleComplement = ValueKey<String>(
    'personnes-apercu-complement',
  );

  /// La cle de « Ecrire ».
  static const Key cleEcrire = ValueKey<String>('personnes-apercu-ecrire');

  /// La cle du lien vers le dossier complet.
  static const Key cleDossier = ValueKey<String>('personnes-apercu-dossier');

  /// La cle de la phrase de retour ou d'echec d'un geste.
  static const Key cleRetour = ValueKey<String>('personnes-apercu-retour');

  @override
  ConsumerState<ApercuCandidatPersonnes> createState() =>
      _ApercuCandidatPersonnesState();
}

class _ApercuCandidatPersonnesState
    extends ConsumerState<ApercuCandidatPersonnes> {
  /// La phrase du dernier geste (retour ou echec), ou `null`.
  String? _message;
  bool _echec = false;
  bool _enCours = false;

  /// Le dossier se lit avant la feuille : le bouton le montre, pas au-dela.
  bool _lecture = false;

  /// Le passage au suivant attend son instant (la phrase reste lisible).
  Timer? _passage;

  @override
  void dispose() {
    _passage?.cancel();
    super.dispose();
  }

  /// Reste sur ce dossier : le suivant ne s'ouvre pas. La decision, elle, est
  /// deja enregistree ; la liste se relit.
  void _rester() {
    _passage?.cancel();
    setState(() => _passage = null);
    widget.onChange?.call();
  }

  Future<void> _geste(GesteCandidature geste, CapacitesCandidatures c) async {
    if (_enCours) return;
    setState(() {
      _enCours = true;
      _lecture = true;
      _message = null;
    });
    final ResultatGesteDeLigne r = await lancerGesteDeLigne(
      context,
      ref,
      ligne: widget.ligne,
      geste: geste,
      capacites: c,
      cocherManquants: true,
      onLu: () {
        if (mounted) setState(() => _lecture = false);
      },
    );
    if (!mounted) return;
    // Decision enregistree, reglage actif, une personne suit : l'apercu passe
    // a elle apres un instant. La liste ne se relit qu'apres : relue avant,
    // la personne traitee pourrait sortir du filtre et l'apercu se vider.
    final VoidCallback? suivant = widget.onSuivant;
    final bool passer =
        r.issue == IssueGesteDeLigne.fait &&
        suivant != null &&
        ref.read(passerAuSuivantProvider);
    if (r.aRelire) {
      ref.invalidate(apercuCandidatureProvider(widget.ligne.id));
      if (!passer) widget.onChange?.call();
    }
    setState(() {
      _enCours = false;
      _lecture = false;
      _message = passer ? t.recrutement.suivant.decisionEnregistree : r.message;
      _echec = r.echec;
      if (passer) {
        _passage = Timer(AppMouvement.retourLocalMaintien, () {
          if (!mounted) return;
          suivant();
          widget.onChange?.call();
        });
      }
    });
  }

  void _ecrire(CapacitesCandidatures c) {
    // La feuille d'ecriture de la file, pour une seule personne.
    unawaited(
      ouvrirFeuilleLot(
        context,
        geste: GesteLot.ecrire,
        ids: <String>[widget.ligne.id],
        capacites: c,
        onRapport: (RapportLot _) {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String id = widget.ligne.id;
    return BlocAsynchrone<ApercuCandidature>(
      valeur: ref.watch(apercuCandidatureProvider(id)),
      squelette: const Skeleton.texte(),
      titreEchec: t.admin.candidatures.liste.dossierIllisible,
      onReessayer: () => ref.invalidate(apercuCandidatureProvider(id)),
      construire: (ApercuCandidature a) => _contenu(context, a.detail),
    );
  }

  Widget _contenu(BuildContext context, DetailCandidature detail) {
    final s = t.recrutement.dossier3.synthese;
    final LigneCandidature l = detail.ligne;
    final CapacitesCandidatures caps =
        ref.watch(capacitesCandidaturesProvider).value ??
        const CapacitesCandidatures();
    final GestesProposes gestes = gestesProposesPourLigne(
      l,
      caps,
      sansResponsable: true,
    );
    final GesteCandidature? principal = gestes.principal;
    final bool complement =
        principal != GesteCandidature.demanderComplement &&
        gestes.autres.contains(GesteCandidature.demanderComplement);
    final String nom = nomAffiche(l);
    final Map<String, String> synthese = <String, String>{
      for (final LigneSynthese ligne in syntheseDuDossier(detail))
        ligne.cle: ligne.valeur,
    };
    final AppPalette palette = AppPalette.of(context);
    final TextStyle corps =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AvatarNom.enLigne(
          prenom: nom,
          avatar: PhotoEleve(
            prenom: nom,
            cleAvatar: null,
            personneId: null,
            diametre: AppAvatar.moyen,
          ),
          nom: nom,
          diametre: AppAvatar.moyen,
          roleWidget: StatusPill(
            libelle: libelleEtatCourant(
              issue: l.issue,
              enPause: l.enPause,
              etape: l.etape,
              etat: l.etat,
            ),
            ton: TonEtat.neutre,
          ),
        ),
        if (_message case final String message) ...<Widget>[
          Ecart.vMd,
          Semantics(
            liveRegion: true,
            child: Text(
              message,
              key: ApercuCandidatPersonnes.cleRetour,
              style: (_echec ? palette.inkAlert : palette.inkStrong).applyTo(
                corps,
              ),
            ),
          ),
        ],
        Ecart.vLg,
        // La synthese du dossier complet, a l'identique.
        SyntheseTeteDossier(
          detail: detail,
          accepter: principal ?? GesteCandidature.demanderComplement,
        ),
        if (libellePays(l.paysResidence) case final String pays)
          LigneCleValeur(cle: t.com.messages.apercu.pays, valeur: pays),
        if (synthese[s.langues] case final String langues)
          LigneCleValeur(cle: s.langues, valeur: langues),
        if (synthese[s.memorisation] case final String memorisation)
          LigneCleValeur(cle: s.memorisation, valeur: memorisation),
        Ecart.vLg,
        // Les gestes : un seul bouton plein (K-56), les autres en contour.
        // Choix de formulaire, pas un filtre : des actions sur le dossier.
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            if (principal != null)
              ActionPrincipale(
                key: ApercuCandidatPersonnes.cleGestePrincipal,
                libelle: libelleGeste(principal),
                pleineLargeur: false,
                enCours: _lecture,
                onPress: () => unawaited(_geste(principal, caps)),
              ),
            if (complement)
              ActionPrincipale(
                key: ApercuCandidatPersonnes.cleComplement,
                libelle: libelleGeste(GesteCandidature.demanderComplement),
                niveau: NiveauAction.secondaire,
                pleineLargeur: false,
                onPress: () => unawaited(
                  _geste(GesteCandidature.demanderComplement, caps),
                ),
              ),
            if (caps.peutAgirEnLot)
              ActionPrincipale(
                key: ApercuCandidatPersonnes.cleEcrire,
                libelle: libelleGesteLot(GesteLot.ecrire),
                libelleSemantique: t.com.messages.entree.ecrireA(nom: nom),
                niveau: NiveauAction.secondaire,
                pleineLargeur: false,
                onPress: () => _ecrire(caps),
              ),
          ],
        ),
        if (_passage != null) ...<Widget>[
          Ecart.vSm,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: LienFleche(
              key: ApercuCandidatPersonnes.cleRester,
              libelle: t.recrutement.suivant.rester,
              fleche: false,
              alignerEnDebut: true,
              onPress: _rester,
            ),
          ),
        ],
        // Le meme reglage que le dossier complet : automatique ou manuel.
        if (widget.onSuivant != null) ...<Widget>[
          Ecart.vLg,
          const ReglagePasserAuSuivant(),
        ],
        Ecart.vMd,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: LienFleche(
            key: ApercuCandidatPersonnes.cleDossier,
            libelle: t.com.messages.apercu.voirDossier,
            alignerEnDebut: true,
            onPress: widget.onOuvrirDossier,
          ),
        ),
      ],
    );
  }
}
