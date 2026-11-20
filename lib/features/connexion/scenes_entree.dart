// ENTREE-PRAXIS : ce que Praxis fait devant la porte, situation par
// situation. Portage des scenes de la maquette « Praxis vous accueille »
// (confirmee par le directeur, 20/11/2026) : memes gestes, memes visages,
// memes attentes, memes phrases. Une situation de la page reelle sans scene
// dans la maquette garde le langage de la maquette (voir [SituationEntree]).
import 'dart:math' as math;

import '../../core/i18n/strings.g.dart';
import '../../core/vivant/entree/gestes_praxis.dart';
import '../../core/vivant/entree/praxis_reference.dart';
import '../../core/vivant/entree/regie_praxis.dart';
import '../../core/vivant/entree/scene_entree.dart';

/// Ce qui se passe sur la page d'entree, vu par Praxis. La page le calcule
/// de son etat reel ; la scene ne decide de rien.
enum SituationEntree {
  /// La personne arrive (premiere arrivee, lien d'un candidat, invitation).
  arrivee,

  /// Le serveur a ferme la session : la personne revient se connecter.
  session,

  /// Elle ecrit son adresse.
  saisie,

  /// L'adresse ecrite ne peut pas recevoir de lien.
  adresse,

  /// Le lien part.
  envoi,

  /// Le lien part depuis longtemps.
  reseauLent,

  /// Le lien est parti.
  envoye,

  /// Le lien est parti depuis longtemps, rien ne se passe.
  attenteLongue,

  /// Trop de demandes : il faut attendre.
  tropEssais,

  /// L'appareil n'a plus de connexion.
  horsLigne,

  /// La connexion est revenue.
  retourLigne,

  /// L'envoi a echoue de notre cote.
  serveur,

  /// La fenetre de Google s'ouvre.
  googleOuverte,

  /// L'adresse n'a pas d'invitation (inscriptions fermees).
  sansInvitation,
}

/// Les situations qui font sortir Praxis de la porte, meme s'il est deja la.
const Set<SituationEntree> _entrees = <SituationEntree>{
  SituationEntree.arrivee,
  SituationEntree.session,
};

/// Vrai si [situation] se joue depuis la porte.
bool situationDepuisLaPorte(SituationEntree situation, Theatre th) =>
    !th.present || _entrees.contains(situation);

/// D'ou qu'il soit, il se releve, se remet de face et revient au premier
/// plan, sans saut.
Future<void> _revenir(Theatre th, int g) async {
  final Corps px = th.px;
  th.taire();
  px
    ..faire(Geste.aucun)
    ..regarder(0, 0);
  th.eclat.cible = 1;
  if (px.assis.cible > 0.5) {
    px.assis.cible = 0;
    px.ecrase.v -= 1.2;
    await th.attendre(380, g);
  }
  if (px.tourne.cible != 0) {
    px.tourne.cible = 0;
    px.pietine = 2;
  }
  if ((px.q - 1).abs() > 0.01 || px.lat.x.abs() > 0.03) {
    px.anticipe();
    await th.attendre(130, g);
    px.allerA(1, travers: 0, vitesse: 0.32);
    await th.jusqua(() => px.arrive, g);
  }
}

/// La scene de [situation]. [avant] est la situation qu'elle remplace ;
/// [rtl] retourne les gestes de cote ; [large] ecarte Praxis du cote oppose
/// au formulaire ; [sansArobase] choisit la phrase de l'adresse fautive.
ScenePraxis sceneEntree(
  SituationEntree situation, {
  required bool depuisPorte,
  required SituationEntree? avant,
  required bool rtl,
  required bool large,
  bool sansArobase = true,
}) => (Theatre th, int g) async {
  final Corps px = th.px;
  final Traductions$connexion$praxis$fr dit = t.connexion.praxis;
  Future<void> att(int ms) => th.attendre(ms, g);
  // Le bord de la route ou il s'ecarte : cote oppose au formulaire.
  final double bord = large ? (rtl ? 0.62 : -0.62) : (rtl ? -0.4 : 0.4);
  if (depuisPorte) {
    await th.arriver(g, vite: situation != SituationEntree.arrivee);
  } else {
    await _revenir(th, g);
  }
  switch (situation) {
    case SituationEntree.arrivee:
      if (th.reduit) {
        // « Reduire les effets » : l'etat final d'emblee, la phrase utile
        // posee entiere, aucun geste.
        px
          ..faire(Geste.aucun)
          ..poser(Expr.sourire)
          ..regarder(0, 0);
        await th.parler(dit.adresseEtPorte, g, tenir: 2);
        break;
      }
      px
        ..faire(Geste.salut)
        ..poser(Expr.sourire);
      await att(250);
      await th.parler(dit.bonjour, g, tenir: 1.2);
      px
        ..faire(Geste.pointe)
        ..regarder(0, 0.9);
      await th.parler(dit.adresseEtPorte, g, tenir: 2);
      px
        ..faire(Geste.aucun)
        ..regarder(0, 0);
    case SituationEntree.session:
      px
        ..poser(Expr.desole)
        ..faire(Geste.desole);
      await att(250);
      await th.parler(dit.session, g);
      px
        ..faire(Geste.pointe)
        ..poser(Expr.sourire)
        ..regarder(0, 0.9);
      await att(1600);
      px
        ..faire(Geste.aucun)
        ..regarder(0, 0);
    case SituationEntree.saisie:
      // Il regarde ce qui s'ecrit ; la page le fait reagir a l'arobase et a
      // l'adresse complete ([reactionArobase], [reactionAdresseComplete]).
      px
        ..poser(Expr.neutre)
        ..regarder(0, 1);
    case SituationEntree.adresse:
      px
        ..sursaut()
        ..poser(Expr.etonne)
        ..regarder(0, 1);
      await att(600);
      px.faire(Geste.pointe);
      await th.parler(sansArobase ? dit.adresse : dit.adresseIncomplete, g);
      px.poser(Expr.reflexion);
    case SituationEntree.envoi:
      px
        ..cote = rtl ? 1 : -1
        ..tourne.cible = 0.16
        ..pietine = 2
        ..poser(Expr.concentre)
        ..faire(Geste.envoie)
        ..regarder(rtl ? 0.5 : -0.5, -0.8);
      await att(330);
      th.etincelle();
      await th.parler(dit.envoi, g, tenir: 1.3);
      px
        ..faire(Geste.pied)
        ..poser(Expr.attente);
    case SituationEntree.reseauLent:
      px
        ..cote = rtl ? 1 : -1
        ..tourne.cible = 0.12
        ..poser(Expr.attente)
        ..faire(Geste.montre)
        ..regarder(-0.5, 0.7);
      await att(1300);
      px
        ..regarder(0, 0)
        ..faire(Geste.pied);
      await th.parler(dit.reseauLent, g);
      for (int i = 0; i < 3; i++) {
        px
          ..faire(Geste.envoie)
          ..regarder(rtl ? 0.5 : -0.5, -0.8);
        await att(330);
        th.etincelle();
        await att(1500);
        px
          ..faire(Geste.pied)
          ..regarder(0, 0);
        await att(2600);
      }
    case SituationEntree.envoye:
      px
        ..poser(Expr.joie)
        ..faire(Geste.joie);
      await att(300);
      await th.parler(dit.envoye, g);
      px
        ..faire(Geste.aucun)
        ..poser(Expr.sourire);
    case SituationEntree.attenteLongue:
      // Il regarde l'heure, va s'asseoir au bord de la route, baille, puis
      // propose de renvoyer.
      px
        ..poser(Expr.attente)
        ..faire(Geste.montre)
        ..regarder(-0.5, 0.7);
      await att(1400);
      px
        ..faire(Geste.aucun)
        ..regarder(bord.sign * 0.7, 0.2)
        ..anticipe();
      await att(140);
      px.allerA(1, travers: bord, vitesse: 0.3);
      await th.jusqua(() => px.arrive, g);
      px
        ..regarder(0, 0)
        ..assis.cible = 1
        ..faire(Geste.genoux);
      await att(1100);
      px
        ..faire(Geste.montre)
        ..regarder(-0.5, 0.7);
      await att(1500);
      px
        ..faire(Geste.baille)
        ..poser(Expr.baille);
      await att(1300);
      px
        ..poser(Expr.sourire)
        ..faire(Geste.genoux)
        ..regarder(0, 0);
      await att(300);
      px.faire(Geste.pointe);
      await th.parler(dit.attenteLongue, g);
      px.faire(Geste.genoux);
    case SituationEntree.tropEssais:
      px
        ..poser(Expr.sourire)
        ..faire(Geste.pause);
      await att(250);
      await th.parler(dit.tropEssais, g);
      px
        ..faire(Geste.respire)
        ..poser(Expr.paisible);
    case SituationEntree.horsLigne:
      // La porte s'eteint : toute la scene perd sa lumiere. Il se retourne
      // pour voir.
      th.eclat.cible = 0.2;
      await att(350);
      px
        ..sursaut()
        ..poser(Expr.etonne)
        ..cote = rtl ? 1 : -1
        ..tourne.cible = 0.34
        ..pietine = 2
        ..regarder(rtl ? 0.6 : -0.6, -0.8);
      await att(1000);
      px
        ..tourne.cible = 0
        ..pietine = 2
        ..faire(Geste.cherche)
        ..poser(Expr.reflexion);
      await att(1500);
      px
        ..faire(Geste.desole)
        ..poser(Expr.desole)
        ..regarder(0, 0);
      await th.parler(dit.horsLigne, g);
      px.faire(Geste.aucun);
    case SituationEntree.retourLigne:
      if (avant != SituationEntree.horsLigne || depuisPorte) {
        th.eclat.cible = 0.2;
        px.poser(Expr.desole);
        await att(900);
      }
      th.eclat.cible = 1.12;
      await att(350);
      px
        ..poser(Expr.joie)
        ..faire(Geste.applaudit)
        ..sauter(240);
      await th.parler(dit.retourLigne, g);
      th.eclat.cible = 1;
      px
        ..faire(Geste.aucun)
        ..poser(Expr.sourire);
    case SituationEntree.serveur:
      px
        ..poser(Expr.gene)
        ..faire(Geste.gene);
      await att(500);
      await th.parler(dit.serveur, g);
      px
        ..faire(Geste.pointe)
        ..poser(Expr.sourire)
        ..regarder(0, 0.9);
      await att(1500);
      px
        ..faire(Geste.aucun)
        ..regarder(0, 0);
    case SituationEntree.googleOuverte:
      // Il s'ecarte pour laisser la place a la fenetre, et attend poliment.
      px
        ..poser(Expr.sourire)
        ..regarder(-bord.sign * 0.5, 0.6)
        ..anticipe();
      await att(130);
      px.allerA(1, travers: bord * 0.8, vitesse: 0.3);
      await th.jusqua(() => px.arrive, g);
      px.faire(Geste.suivre);
      await th.parler(dit.googleOuverte, g);
      px
        ..faire(Geste.pied)
        ..poser(Expr.attente);
    case SituationEntree.sansInvitation:
      px
        ..poser(Expr.desole)
        ..faire(Geste.non);
      await att(400);
      await th.parler(dit.googleRefuse, g);
      px
        ..faire(Geste.pointe)
        ..poser(Expr.sourire)
        ..regarder(0, 0.9);
      await att(1500);
      px
        ..faire(Geste.aucun)
        ..regarder(0, 0);
  }
};

/// L'arobase vient d'etre ecrit : il sourit et hoche.
void reactionArobase(Theatre th) {
  th.px
    ..poser(Expr.sourire)
    ..pendV += 5
    ..hoche.v += 3;
}

/// L'adresse est complete : « Parfait. ».
ScenePraxis reactionAdresseComplete() => (Theatre th, int g) async {
  th.px
    ..faire(Geste.hoche)
    ..poser(Expr.joie);
  await th.parler(t.connexion.praxis.parfait, g, tenir: 0.9);
  th.px.poser(Expr.sourire);
};

/// Les reactions au toucher : jamais deux fois de suite la meme.
class ReactionsToucher {
  final math.Random _hasard = math.Random();
  int _derniere = -1;

  static const List<(Geste, Expr)> _poses = <(Geste, Expr)>[
    (Geste.aucun, Expr.etonne),
    (Geste.joie, Expr.joie),
    (Geste.salut, Expr.sourire),
    (Geste.chapeau, Expr.sourire),
    (Geste.non, Expr.joie),
    (Geste.coeur, Expr.gene),
  ];

  String _texte(int i) {
    final Traductions$connexion$praxis$fr dit = t.connexion.praxis;
    return switch (i) {
      0 => dit.toucherOui,
      1 => dit.toucherChatouille,
      2 => dit.toucherLa,
      5 => dit.toucherBonjour,
      _ => '',
    };
  }

  /// La reaction suivante.
  ScenePraxis suivante() {
    int i = _hasard.nextInt(_poses.length);
    if (i == _derniere) {
      i = (i + 1 + _hasard.nextInt(_poses.length - 1)) % _poses.length;
    }
    _derniere = i;
    final (Geste geste, Expr expr) = _poses[i];
    final String texte = _texte(i);
    return (Theatre th, int g) async {
      final Corps px = th.px;
      px
        ..ecrase.v += 1.4
        ..pendV += 6
        ..poser(expr)
        ..faire(geste);
      if (geste == Geste.aucun) px.sursaut();
      if (geste == Geste.non && !th.reduit && px.tourne.cible == 0) {
        // Un tour complet sur lui-meme, en sautant.
        px
          ..sauter(300)
          ..tourne.x = 2
          ..pietine = 4;
      }
      if (texte.isNotEmpty) {
        // Le toucher ne coupe pas la scene : la phrase part sans l'attendre.
        // ignore: unawaited_futures
        th.dire(texte, tenir: 1);
      }
      await th.attendre(1900, g);
      // Il reprend sa contenance, sauf si la scene lui a donne autre chose.
      if (px.expr == expr) px.poser(Expr.sourire);
      if (px.geste == geste) px.faire(Geste.aucun);
    };
  }
}
