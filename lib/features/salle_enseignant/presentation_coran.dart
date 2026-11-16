import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/coran/service_coran.dart';
import '../../core/session/session_controleur.dart';
import '../../core/tc_coran/moteur_mushaf.dart';
import '../../core/tc_coran/port_corpus_coran.dart';
import '../../core/video/livekit_session_provider.dart';
import '../../core/video/video_session_provider.dart';

/// L'etat du lien, pour la surface enseignante de la salle.
///
/// **Aucun second moteur n'est cree ici** : ce provider lit `moteurSalleProvider`,
/// le seul du produit, et se contente d'en republier le flux. Le panneau de
/// l'enseignant est insere DANS `salle_page`, qui tient deja cet etat dans son
/// State prive -- inaccessible d'ici, et l'API publique du panneau est figee a
/// un seul parametre par le contrat de branchement. Relire le meme flux coute un
/// abonnement, la ou passer l'etat en parametre aurait demande de rouvrir un
/// contrat que quatre autres agents consomment.
///
/// Le premier evenement est [VideoSessionProvider.etatCourant] : un panneau
/// monte apres l'entree en salle -- rotation, retour de veille -- n'attend pas le
/// prochain changement d'etat pour ouvrir ses commandes.
///
/// `isAutoDispose` **est une exigence, pas une optimisation** : voir
/// [contenuPresenteProvider], dont l'etat ne doit pas survivre a la sortie de la
/// salle. Les deux se ferment ensemble, sans quoi l'un decrirait une seance que
/// l'autre a oubliee.
final StreamProvider<EtatSalle> etatLienSalleProvider =
    StreamProvider<EtatSalle>(
      (Ref ref) => _etatsAvecCourant(ref.watch(moteurSalleProvider)),
      isAutoDispose: true,
    );

/// L'etat courant, puis les suivants.
Stream<EtatSalle> _etatsAvecCourant(VideoSessionProvider moteur) async* {
  yield moteur.etatCourant;
  yield* moteur.etats;
}

/// Le contenu presente a la classe, tel que le canal de donnees le porte.
///
/// **Le presentateur y lit ce qu'il a lui-meme publie.** Un seul chemin de
/// rendu, donc aucune divergence possible entre ce que le groupe voit et ce que
/// l'enseignant croit montrer -- et c'est pour cela qu'aucun champ « page que je
/// presente » n'existe dans cette feature. Le flux rejoue le dernier contenu
/// connu a tout nouvel abonne, y compris apres une coupure.
///
/// **`isAutoDispose` ferme une confusion de seance a seance.** Un flux ne
/// republie jamais « plus rien » : le dernier pointeur reste la derniere valeur
/// connue du provider, et `quitter()` efface le contenu du moteur sans pouvoir
/// effacer ce cache. Sans cette fermeture, l'enseignant qui entre dans son cours
/// suivant verrait la page du cours precedent -- et un « page suivante » partirait
/// de ce pointeur perime. La duree de vie du provider est donc celle du panneau :
/// une coupure ne le demonte pas, une sortie de salle si.
final StreamProvider<ContenuPresente?> contenuPresenteProvider =
    StreamProvider<ContenuPresente?>(
      // Un contenu retire (support range) se lit `null` : rien n'est
      // presente, pour l'enseignant comme pour la classe.
      (Ref ref) => ref
          .watch(moteurSalleProvider)
          .contenusPresentes
          .map((ContenuPresente c) => c.estRetire ? null : c),
      isAutoDispose: true,
    );

/// Ce qu'une demande de presentation a produit.
enum SortPresentation {
  /// Le pointeur est parti sur le canal de donnees.
  ///
  /// Il dit que la demande a ete faite, **pas que le serveur l'a acceptee** : le
  /// refus du moteur est silencieux par contrat, et la seule preuve qu'une page
  /// est presentee reste ce que le flux republie.
  envoye,

  /// La reference n'a pas pu etre situee dans le mushaf : rien n'est parti.
  ///
  /// `null` signifie « je ne sais pas », jamais « page 1 » : ouvrir la Fatiha
  /// devant une classe parce qu'une requete a echoue serait pire que ne rien
  /// presenter.
  introuvable,
}

/// Les deux gestes de presentation de l'enseignant.
///
/// Une classe et non deux fonctions libres : les deux gestes partagent la meme
/// regle -- **on ne presente jamais une page qu'on n'a pas su situer** -- et
/// c'est cette regle, plus que l'appel au moteur, qui devait vivre en un seul
/// endroit.
///
/// [QURAN-STAGE] Rien ici n'ecrit la position de lecture de qui que ce soit : ce
/// qui voyage est un pointeur ephemere, qui vit le temps de la seance dans le
/// moteur. Une page tournee pour tout le groupe n'ecrase pas le marque-page d'un
/// eleve (invariant J2), et aucune methode de `ServiceCoran` autre que les
/// lectures n'est appelee.
class PresentateurCoran {
  /// Cree le presentateur sur le conteneur de providers.
  PresentateurCoran(this._ref);

  final Ref _ref;

  /// Presente une page du mushaf, par son numero.
  ///
  /// La page est lue avant d'etre presentee, pour deux raisons : le pointeur
  /// porte aussi une sourate et un verset, et une page sans verset signifie que
  /// le corpus n'est pas installe -- ce qui ne se presente pas.
  ///
  /// PAGES-FLUIDES (directeur, 12/11/2026 : « tourner une page donne
  /// l'impression que ca plante ») : **une seule lecture, celle du rendu**
  /// ([pageCorpusProvider]). La page lue ici est celle que la salle affiche
  /// ensuite, sans seconde requete. Deja lue (cas normal : les pages voisines
  /// sont prechargees par `PageCoranSalle`), elle part tout de suite, sans
  /// rien attendre. Pas encore lue, [pageEnPreparationProvider] le dit a
  /// l'ecran de l'enseignant pendant la lecture (l'ancienne page reste) ; la
  /// classe ne la recoit qu'une fois lue. Une page illisible ou vide ne se
  /// presente jamais ([SortPresentation.introuvable]).
  Future<SortPresentation> presenterPage(int page) async {
    final AsyncValue<PageCorpus?> deja = _ref.read(pageCorpusProvider(page));
    final PageCorpus? lue;
    if (deja.hasValue && !deja.hasError) {
      lue = deja.value;
    } else {
      final PreparationPage preparation = _ref.read(
        pageEnPreparationProvider.notifier,
      )..commencer(page);
      try {
        lue = await _ref.read(pageCorpusProvider(page).future);
      } on Object {
        // La lecture a echoue : on ne sait pas situer la page, rien ne part.
        return SortPresentation.introuvable;
      } finally {
        preparation.finir(page);
      }
    }
    final List<VersetCorpus> versets = lue?.versets ?? const <VersetCorpus>[];
    if (versets.isEmpty) {
      return SortPresentation.introuvable;
    }
    final VersetCorpus premier = versets.first;
    return _presenter(
      page: page,
      sourate: premier.sourate,
      verset: premier.numero,
    );
  }

  /// Presente un verset, « 2:255 », en situant d'abord sa page.
  Future<SortPresentation> presenterVerset({
    required int sourate,
    required int verset,
  }) async {
    final int? page = await _ref.read(
      pageDuVersetProvider((sourate: sourate, verset: verset)).future,
    );
    if (page == null) {
      return SortPresentation.introuvable;
    }
    return _presenter(page: page, sourate: sourate, verset: verset);
  }

  /// Range la page presentee (lot salle 3, directeur, 25/10/2026) : la
  /// classe revient au tableau ou a la scene. Rien n'est efface ; « Ouvrir
  /// le Coran » la presente de nouveau.
  Future<void> fermer() => _ref
      .read(moteurSalleProvider)
      .presenterContenu(
        ContenuPresente.retire(
          presentePar: _ref.read(sessionProvider).profileId ?? '',
          emisLe: DateTime.now(),
        ),
      );

  Future<SortPresentation> _presenter({
    required int page,
    required int sourate,
    required int verset,
  }) async {
    await _ref.read(moteurSalleProvider).presenterContenu(
      ContenuPresente(
        page: page,
        sourate: sourate,
        verset: verset,
        // L'identite repond « qui a tourne la page ». Elle ne decide d'aucun
        // droit : la barriere est `can_publish_data` dans le jeton signe, et
        // c'est le serveur qui la fait respecter.
        presentePar: _ref.read(sessionProvider).profileId ?? '',
        emisLe: DateTime.now(),
      ),
    );
    return SortPresentation.envoye;
  }
}

/// PAGES-FLUIDES (directeur, 12/11/2026) : la page que l'enseignant vient de
/// demander et qui n'est pas encore lue, ou `null`. L'ecran de l'enseignant
/// le montre tout de suite (il a compris le geste) ; la page presentee a la
/// classe, elle, ne change qu'une fois la page lue.
final NotifierProvider<PreparationPage, int?> pageEnPreparationProvider =
    NotifierProvider<PreparationPage, int?>(PreparationPage.new);

/// La page en cours de lecture avant d'etre presentee.
class PreparationPage extends Notifier<int?> {
  @override
  int? build() => null;

  /// La lecture de [page] commence.
  void commencer(int page) => state = page;

  /// La lecture de [page] est finie (lue ou en echec). Une demande plus
  /// recente garde sa marque.
  void finir(int page) {
    if (state == page) state = null;
  }
}

/// Le presentateur employe par la surface enseignante de la salle.
final Provider<PresentateurCoran> presentateurCoranProvider =
    Provider<PresentateurCoran>(PresentateurCoran.new);
