import '../../../../core/i18n/strings.g.dart';
import '../../../../core/recherche/budgets_recherche.dart';
import '../../../../core/recherche/modeles_recherche.dart';
import '../../../../core/recherche/normalisation_recherche.dart';
import '../../../../core/recherche/port_recherche.dart';
import '../../../com_messages/port_messages_metier.dart';
import '../../../com_studio/port_studio.dart';
import '../classes_supports/pagination_domaine.dart';

/// Le moteur « Fils et canaux » (RECH-D4, spec RECH-03 §3 « Communications »).
///
/// Il cherche **les fils**, pas les messages : l'interlocuteur, sa fonction et
/// l'objet auquel le fil est lie ; et les **noms des canaux** du Studio.
/// Jamais le corps d'un message, jamais l'apercu du dernier message (un apercu
/// est un morceau de message), jamais une piece jointe ni un fichier. La
/// recherche dans le texte d'un fil reste interne a ce fil, dans le module
/// Communications (`recherche_fils.dart`, `recherche_studio.dart`).
///
/// Il ne recode pas Communications : il lit `PortMessagesMetier.fils()` et
/// `PortStudio.rechercher`, dont le serveur ne rend que ce que la personne a
/// le droit de lire. Aucun droit supplementaire n'est ajoute ici. Un fil
/// qui n'est pas un fil metier (annonce, publication) est ecarte.
///
/// **Une panne de l'une des deux sources fait echouer le domaine** : un fil
/// manquant ne se fait pas passer pour « aucun resultat ».
///
/// **Reserve** : filtre local sur la liste des fils deja autorises ;
/// demonstration seulement, jamais raccorde en production.
class MoteurFils implements MoteurRechercheDomaine {
  /// Cree le moteur sur les fils metier et, si le Studio est servi, ses canaux.
  const MoteurFils({
    required this.messages,
    this.studio,
    this.espacesStudio = const <EspaceRecherche>{
      EspaceRecherche.administration,
    },
  });

  /// Les fils metier.
  final PortMessagesMetier messages;

  /// Le Studio, ou `null` quand l'application n'en a pas.
  final PortStudio? studio;

  /// Les espaces qui ont un Studio (reserve a l'administration en V1).
  final Set<EspaceRecherche> espacesStudio;

  @override
  DomaineRecherche get domaine => DomaineRecherche.fils;

  /// L'Interface guidee n'a pas de messagerie.
  @override
  Future<bool> disponiblePour(ContexteRecherche contexte) async =>
      contexte.espace != EspaceRecherche.eleveGuide;

  @override
  Future<ReponseDomaine> rechercher({
    required String requete,
    required ContexteRecherche contexte,
    String? curseur,
    int limite = BudgetsRecherche.limiteCommune,
  }) async {
    if (!await disponiblePour(contexte)) {
      return ReponseEchec(domaine, StatutRecherche.contexteRevoque);
    }
    final String cle = normaliserPourRecherche(requete);
    final List<ResumeFil> fils = await messages.fils();
    final PortStudio? leStudio = espacesStudio.contains(contexte.espace)
        ? studio
        : null;
    final List<ResumeCanal> canaux = leStudio == null
        ? const <ResumeCanal>[]
        : (await leStudio.rechercher(requete)).sansCanalAbsent().canaux;
    final List<ResultatRecherche> trouves = <ResultatRecherche>[
      for (final ResumeFil f in fils)
        if (estFilMetier(f) && correspondTousLesTermes(_champs(f), cle))
          ResultatRecherche(
            type: TypeResultat.fil,
            reference: f.id,
            titre: f.objet.libelle,
            contexte: _interlocuteurs(f),
            cible: CibleRecherche(kind: KindCible.fil, reference: f.id),
          ),
      for (final ResumeCanal c in canaux)
        if (correspondTousLesTermes(normaliserPourRecherche(c.nom), cle))
          ResultatRecherche(
            type: TypeResultat.fil,
            reference: c.id,
            titre: c.nom,
            contexte: t.recherche.contexte.canalStudio,
            cible: CibleRecherche(kind: KindCible.canal, reference: c.id),
          ),
    ];
    return pageDeResultats(
      domaine: domaine,
      contexte: contexte,
      requeteNormalisee: cle,
      trouves: trouves,
      curseur: curseur,
      limite: limite,
    );
  }

  /// Les seuls champs ou une correspondance peut tomber : ni apercu, ni texte.
  static String _champs(ResumeFil f) => normaliserPourRecherche(
    <String>[
      for (final Participant p in f.interlocuteurs) ...<String>[
        p.nomAffiche,
        ?p.fonction,
      ],
      f.objet.libelle,
    ].join(' '),
  );

  static String? _interlocuteurs(ResumeFil f) {
    final List<String> noms = <String>[
      for (final Participant p in f.interlocuteurs) p.nomAffiche,
    ];
    return noms.isEmpty ? null : noms.join(', ');
  }
}
