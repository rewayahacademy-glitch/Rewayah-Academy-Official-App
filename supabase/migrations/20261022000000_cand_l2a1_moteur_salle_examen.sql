-- CAND-L2A1 (22/10/2026) : moteur des gestes du module des candidatures et
-- Salle d'examen cote candidat (questionnaire, envoi, retrait).
--
-- Decisions du directeur : docs/current/DECISION-CANDIDATURES-2026-10-21.md
-- (CAND-Q02 lot serveur borne sur la base de test ; CAND-Q05 paiement ;
-- CAND-Q07 separation femmes/hommes en base ; CAND-Q11 cadre religieux ;
-- CAND-Q13 parcours en arabe ; CAND-Q15 langues par code).
-- Specification consolidee : SPEC_CONSOLIDEE_CANDIDATURES_2026-10-21.md,
-- sections 2.1 (ce qui se demande en Salle d'examen), 2.2 (conditions de
-- remuneration lues au serveur), 4.1, 4.2 (transitions), 4.3 (blocages), 5.1
-- (cles de paiement fixees par L6), 8 (droits), 9 (cadre religieux publie
-- seulement apres validation juridique et accord du directeur ; langues par
-- code), 10 (/attente et CAND-01), 11 (ligne L2) et 12.1 (L2-8, L2-9, L2-10,
-- L2-11). Contrat : CONTRAT_PORTS_CANDIDATURES.md, regles transverses et
-- section 3 (PortMaCandidature : conditionsRemuneration, questionnaire,
-- envoyerReponses, retirer ; l'etat se lit par etat_dossier()). Besoins :
-- DEPENDANCES_BACKEND.md, CAND-BR-04 (moteur), CAND-BR-10, CAND-BR-11,
-- CAND-BR-12. Tarifs : DECISION-TARIFS-2026-10-18.md (paie revue le 19/10).
--
-- Ce lot pose :
-- * le MOTEUR des transitions, partage par tous les gestes du module (ce lot
--   et les suivants) : une table privee des regles (source permise de chaque
--   geste de la section 4.2), puis trois aides privees appelees dans cet
--   ordre par chaque RPC de geste :
--   - private.candidature_geste_ouvrir : arguments, auteur, verrou de la cle
--     et de la ligne, absente, portee par genre (hors_portee rendu et trace
--     comme une lecture hors portee de CAND-L1), rejeu de la cle
--     d'idempotence, version attendue, regle (etape, etat, issue, pause,
--     condition), motif et modele exiges ; tout refus est RENDU, sans
--     ecriture (sauf la trace hors portee) ;
--   - private.candidature_geste_appliquer : ecrit le nouvel etat (cible de la
--     regle et changements admis), la version, la derniere activite, une
--     ligne candidature_evenements (avant, apres, auteur, instant UTC, motif
--     interne garde au serveur) et une ligne audit_logs (jamais le motif) ;
--   - private.candidature_geste_conclure : garde le resultat sous la cle
--     d'idempotence et le rend ;
-- * le questionnaire versionne de la Salle d'examen (table
--   public.candidature_questionnaires, version salle-examen-1), ses listes
--   fermees (langues du referentiel langues_cours par code, et les codes ISO
--   639 hors referentiel du mappage ; pays ISO 3166-1 de
--   lib/core/i18n/pays_iso.dart ; fuseaux IANA ; operateurs confirmes du pays
--   de versement), l'enregistrement du brouillon et le controle de
--   completude ;
-- * la transition 6 (le candidat envoie : a_completer vers en_examen) et la
--   transition 17 par le candidat (retrait, CAND-03) ;
-- * la sorte d'accord du cadre religieux et pedagogique
--   (teacher_religious_framework, CAND-BR-11), SANS version requise publiee
--   (section 9) : tant que le directeur ne l'a pas publiee, la transition 6
--   est impossible en base ;
-- * les conditions de remuneration lisibles par un candidat en attente
--   (CAND-BR-12) et leur acceptation enregistree comme un accord
--   (teacher_pay_conditions, version de la politique acceptee) ;
-- * etat_dossier() etendu pour le candidat (cle candidature), corps de
--   20261021210400_pe_code_conduite_avant_activation.sql recopie, toutes ses
--   cles gardees ;
-- * repris apres relecture (22/10) : la portee par genre du journal d'audit
--   (journal_audit, journal_audit_filtres, lecture directe d'audit_logs) et
--   des accords (contract_acceptances), puisque ce lot est le premier a
--   ecrire des lignes dont l'auteur est un candidat (C15) ; la declaration de
--   paiement de L6 lue sur les seuls documents envoyes
--   (private.paiement_declaration, corps de 20261021220100 recopie, C8).
--
-- Choix faits dans ce lot, a relire :
-- * C1 la table des regles porte TOUTES les transitions a geste de la section
--   4.2 (3, 6, 7, 10 a 28, plus le brouillon, qui n'est pas une transition) :
--   le moteur refuse ainsi en base, des aujourd'hui, un geste en pause (L2-9)
--   ou sans motif (L2-10). Les gestes de la direction (L2A2), des entretiens
--   (L4) et de la salle 3 (L2B) n'ont pas encore de RPC : leurs lignes ne
--   servent qu'au moteur ; chaque lot y ajoute ses predicats propres (par
--   exemple les controles nommes de la transition 10) dans sa RPC, et corrige
--   sa ligne par migration s'il le faut. Les transitions automatiques 8 et 9
--   restent dans private.paiement_recalculer (L6) ;
-- * C2 ordre des refus d'un geste : argument invalide (22023) ; auteur
--   different de la session, direction inactive ou au genre inconnu (42501) ;
--   absente ; hors_portee (trace) ; rejeu de la cle ; conflit_candidature
--   (version perimee, version courante rendue : nom de PORTS, regles
--   transverses) ; transition_interdite (etape, etat, issue et pause rendus,
--   raison pause ou etat) ; motif_requis ; modele_requis. Puis, propres au
--   geste : questionnaire_perime, conflit_brouillon (C7), reponses_invalides,
--   reponses_incompletes, accord_remuneration_requis,
--   conditions_indisponibles, conditions_perimees (C11),
--   engagement_non_accepte. Un refus ne laisse aucune ecriture. Un motif est
--   normalise avant tout controle : les blancs de tete et de queue (espace,
--   tabulation, fin de ligne, espaces Unicode) sont retires, et un motif fait
--   de blancs vaut absent (L2-10) ;
-- * C3 idempotence (PORTS, regles transverses) : table
--   public.candidature_gestes, en ajout seul ; une cle vaut pour une
--   candidature, un geste et un auteur ; la meme cle rejouee rend le premier
--   resultat (marque rejoue = true), sans aucune ecriture, meme si la version
--   a change depuis ; une cle reutilisee pour un autre geste, une autre
--   candidature ou un autre auteur est refusee (cle_idempotence_reutilisee).
--   Seules les reussites sont gardees : un refus se rejoue avec la meme cle.
--   Un verrou consultatif par cle serialise deux appels concurrents. Le
--   brouillon (C7) n'y entre pas : seule sa derniere cle est gardee, une
--   ligne par candidature (public.candidature_brouillon_cles, mise a jour a
--   chaque enregistrement) ; une cle de brouillon plus ancienne rejouee est
--   une cle neuve, refusee par la version du document (conflit_brouillon),
--   sans ecriture. Aucun resultat garde ne porte une reponse : un brouillon
--   garde sa version, la version du questionnaire, les champs manquants et
--   complet ; un envoi et un retrait gardent l'etat relu par etat_dossier()
--   (codes, versions, jamais une reponse ni un motif) ;
-- * C4 portee des gestes de la direction : son cote seulement (spec 8.1,
--   candidatures.decider "de son cote") ; l'exception super-admin de 0088
--   reste une exception de LECTURE (spec 8.1, dernier alinea) : un geste de
--   l'autre cote, super-admin compris, est rendu hors_portee et trace comme
--   une lecture hors portee de CAND-L1 (private.cand_hors_portee) ;
-- * C5 le refus (16) et le retrait (17) levent la pause : une issue terminale
--   n'est pas en pause ; l'evenement le dit (pauseLevee). A soumettre au
--   directeur (spec 0.2 bis) ;
-- * C6 questionnaire (spec 2.1, CAND-01) : les reponses sont des CODES ;
--   aucune saisie libre ; une valeur hors liste est refusee
--   (reponses_invalides, champ nomme). Les listes que la spec ne fixe pas
--   (niveau de lecture et de tajwid, riwayat, experience ;
--   les langues, la memorisation, l'ijaza, les publics et les classes
--   souhaitees sont decides le 22/10, C17) sont des propositions a soumettre
--   au directeur (spec 0.2 bis), comme les libelles : le serveur rend des codes, l'ecran les
--   affiche par cles i18n fr et ar (jamais un code brut) ;
-- * C7 brouillon (au serveur, CAND-F15 : choix a soumettre au directeur,
--   spec 0.2 bis) : un document de source candidat marque brouillon, a la
--   version courante du questionnaire, est mis a jour ; sinon un document neuf
--   est ecrit. Le document porte sa propre version (1 a l'ecriture, plus un a
--   chaque brouillon) : versionAttendue d'un brouillon est la version du
--   brouillon ouvert (0 sans brouillon), refus conflit_brouillon sinon. Le
--   brouillon ne change jamais la version de la candidature : un
--   enregistrement automatique entre la lecture de la direction et son geste
--   ne refuse pas ce geste (relecture du 22/10). Il ne touche que la derniere
--   activite de la candidature, sans evenement ni audit (ce n'est pas une
--   transition). A l'envoi, le document perd la marque brouillon et recoit
--   envoye_le ; apres un complement demande, un nouveau brouillon ouvre un
--   document neuf : chaque envoi reste lisible. Toutes les questions se
--   rouvrent apres un complement (la fiche CAND-01 n'en rouvrirait que les
--   questions nommees : a soumettre au directeur, spec 0.2 bis) ;
-- * C8 le paiement se recalcule a l'envoi (transition 6), comme le demande
--   l'en-tete de L6 (R8) : private.paiement_recalculer(id, 'reponses'), qui
--   peut enchainer la transition 8 (paiement_non_disponible). Un brouillon
--   n'est pas une declaration : private.paiement_declaration (L6) ne lit plus
--   que les documents de source candidat qui ne sont pas des brouillons (un
--   document ecrit hors de ce lot, sans la marque, reste une declaration), si
--   bien que la colonne paiement et le calcul en direct ne divergent jamais
--   apres un brouillon ;
-- * C9 le cadre religieux s'accepte par la page d'accords existante
--   (insertion directe dans contract_acceptances, PORTS section 3), a la
--   seule version requise, par le titulaire d'une candidature enseignant en
--   cours en Salle d'examen ou en Salle de verification et d'entretien, au
--   compte en attente, provisoire ou actif, non expire (policy RESTRICTIVE,
--   qui lit la candidature par public.cadre_religieux_acceptable) ; aucune
--   version requise n'est publiee ici. La policy n'appelle pas app_role() :
--   l'inventaire des policies sans app_account_valid() (dix depuis CAND-L1B)
--   ne change pas ; elle n'ouvre rien, elle restreint ;
-- * C10 conditions de remuneration : la paie par eleve present et par heure
--   vit en base (politiques_commerciales, taux_eleve_heure_*_mineur, 1,99 $ et
--   1,57 $ depuis 20261019130000) ; la part de l'enseignant (47 %) n'y
--   vivait nulle part : ce lot pose le referentiel minimal
--   public.politique_part_enseignant (une ligne par version de politique,
--   ajout seul), garni pour la v2.0.0 depuis
--   docs/current/tarifs-2026-10-18.json (enseignant.part_du_prix_pour_mille).
--   La politique rendue au candidat est celle en vigueur si elle porte une
--   paie par eleve present, sinon la prochaine publiee qui en porte une (la
--   v1.0.0 en vigueur jusqu'au 31/10 ne paie qu'a l'heure de classe, valeur
--   caduque) ; sa date d'effet est rendue. Une politique sans sa ligne de
--   part de l'enseignant n'est pas rendue (conditions indisponibles, envoi
--   refuse) : la part s'affiche toujours (CAND-BR-12). Aucun montant n'est
--   rendu au candidat, ni le taux par eleve present et par heure ni la devise :
--   decision du directeur du 22/10/2026 (docs/current/DECISION-TARIFS-2026-10-18.md,
--   section du 22/10), la repartition se dit en pourcentages seulement, qui
--   veut les montants les demande a l'administration. Le taux reste lu pour
--   choisir la politique qui paie par eleve present, jamais pour etre rendu.
--   La regle de l'eleve absent, la periode de versement et les frais ne sont
--   pas en base : ils ne sont pas rendus (CAND-BR-12) ;
-- * C11 l'accord de remuneration ("J'accepte de recevoir ma remuneration
--   par au moins un moyen valide par Rewayah") s'enregistre a l'envoi, comme
--   un accord teacher_pay_conditions a la version de la politique LUE par le
--   candidat : l'envoi porte la version affichee, et une politique changee
--   depuis rend conditions_perimees (version courante rendue) sans ecriture ;
--   aucun compte ne l'insere directement (policy RESTRICTIVE) ; le document de
--   reponses porte aussi accordRemuneration (cle lue par L6) ;
-- * C12 etat_dossier() gagne la cle candidature : etape, etat, issue, pause
--   (modele seulement, jamais le motif), version, questionnaire (versions,
--   perime, champs manquants), cadre religieux, conditions, paiement (la
--   dimension de L6 en direct, ses quatre codes seulement, jamais une
--   decision ni une note : etats de CAND-01, spec 10), aCompleter (en Salle
--   d'examen : questionnaire, cadre religieux ; en Salle de verification et
--   d'entretien : cadre religieux a une version requise neuve, spec 4.3),
--   complementDemande, peutEnvoyer et envoiBloque. complementDemande rend les
--   codes de details.aCompleter du dernier evenement de transition qui en
--   porte (transitions 7, 9 de L6 et 23), tant que l'etape n'a pas change,
--   que l'issue est en cours et qu'aucun envoi (transition 6) ne l'a suivi ;
--   en salle 2, il reste jusqu'au changement d'etape ou jusqu'a une demande
--   plus recente (L2A2 ecrit la transition 23). Jamais un motif interne, une
--   note, un responsable ni un evenement. Un compte sans candidature lit
--   {"candidature": false} ;
-- * C13 le pays de residence et le fuseau declares sont recopies dans la
--   candidature (colonnes de CAND-L1, lues par les listes) a l'envoi
--   (transition 6), jamais par un brouillon ;
-- * C14 noms : aucune RPC client de ce lot ne contient "candidature"
--   (scenario de CAND-L1, controle (a) : etat_dossier() reste la seule
--   lecture de l'etat) ; aucune aide privee ne commence par cand_ (le
--   scenario de CAND-L1 en compte neuf) ;
-- * C15 portee par genre du journal (CAND-Q07, spec 8.2 et 8.3 ; relecture
--   du 22/10). Avant ce lot, toute ligne d'audit_logs sur une candidature
--   venait d'une session de la direction ; l'envoi et le retrait en ecrivent
--   une dont l'auteur est le candidat, et journal_audit() nommait cet auteur
--   a toute la direction, des deux cotes. Le cote d'une ligne
--   (private.journal_portee, ligne a ligne pour la policy et journal_audit ;
--   la vue privee private.audit_logs_cotes, ensembliste, pour les comptes de
--   journal_audit_filtres) :
--   celui de la candidature qu'elle vise (table
--   candidatures ou candidature_contacts, ligne = identifiant) ; sinon celui
--   de la candidature avant la salle 3 que porte son auteur (regle de
--   CAND-L1B) ; sinon, pour une lecture de liste de CAND-L1, celui du lecteur
--   (les deux sous l'exception super-admin) ; une trace de l'exception
--   super-admin qui ne vise pas une candidature compte des lignes de l'autre
--   cote : les deux cotes. Une ligne sans cote reste lisible par toute la
--   direction. journal_audit() et journal_audit_filtres() (corps de
--   0016_masquage_coherent_en_observation.sql et de
--   0015_administration_voit_les_personnes.sql recopies) ne rendent et ne
--   comptent que les lignes du cote du lecteur ; un lecteur au genre inconnu
--   n'en lit aucune qui ait un cote ; le super-admin lit les deux cotes et
--   chaque appel qui en rend de l'autre cote laisse une trace
--   (candidature_exception_super_admin, motif exception_super_admin_kyc,
--   nombre de lignes), comme C13 de CAND-L1. L'auteur porteur d'une
--   candidature avant la salle 3 est rendu par la reference CAND-, jamais par
--   son nom (8.3). La lecture directe d'audit_logs est bornee par une policy
--   RESTRICTIVE, sans l'exception super-admin (une lecture directe ne se
--   journalise pas : l'exception passe par journal_audit()). Les accords
--   (contract_acceptances) d'un compte qui porte une candidature avant la
--   salle 3 ne se lisent que de son cote (policy RESTRICTIVE, la regle de
--   profiles_compte_candidat_portee de CAND-L1B). verifier_chaine_audit
--   reste sans portee : elle ne rend que des comptes de maillons. Les deux
--   policies n'appellent pas app_role() dans leur texte (leurs fonctions le
--   lisent) : l'inventaire des policies sans app_account_valid() (dix) ne
--   change pas. Une tentative hors portee de la direction vise une
--   candidature de l'autre cote : sa trace ne se lit que de ce cote-la, pas
--   par son auteur (a soumettre au directeur, spec 0.2 bis) ;
-- * C16 changements admis par geste (relecture du 22/10) : chaque regle
--   nomme les colonnes que l'appelant peut poser (admis) ; tout autre
--   changement est refuse (22023) ; ceux qui s'appliquent sont recopies,
--   avant et apres, dans l'evenement (details.changements). Un responsable
--   pose est un membre actif de la direction du meme cote que la candidature
--   (4.2, ligne 28), sinon 42501 ;
-- * C17 questionnaire selon les reponses du directeur du 22/10/2026
--   (docs/current/DECISION-CANDIDATURES-2026-10-21.md, section 1 ter ;
--   audit CANDIDATURES/AUDIT_QUESTIONNAIRE_SALLE_EXAMEN_2026-10-22.md). La
--   version salle-examen-1 n'est appliquee nulle part : elle se corrige ici,
--   sur place, sans version suivante.
--   - languesExplication : aucun plafond (pas de max : le plafond est le
--     nombre d'options, sans doublon) ; l'arabe (ar) n'est pas une langue de
--     cours (cle "exclure" du champ) mais reste un choix de langueMaternelle,
--     qui devient facultative ; poular, peul et fulfulde sont une seule
--     entree, le code poular du referentiel langues_cours (plus de ff) ; les
--     langues du public vise y sont : poular, francais et english du
--     referentiel, puis hors referentiel man (malinke, maninka), sus
--     (soussou), sw (swahili), ha (haoussa), wo, bm (bambara), snk (soninke)
--     et mnk (mandinka), codes ISO 639 de la convention de MAPPAGE 3.2 (une
--     langue ouverte plus tard dans langues_cours prend ce code) ; "autre"
--     est la sortie "autre langue" : un code, jamais un texte libre, que la
--     copie en salle 3 (L2B) ne recopie pas dans teacher_profiles.languages ;
--   - memorisation et ijaza sont deux questions : niveauMemorisationDeclare
--     (la quantite : aucune, moins_10_juz, de_10_a_29_juz, coran_entier) et
--     ijazaPresentable (oui, pret_test, non) ;
--   - publics : les tranches d'age au choix, au moins une (6_9, 10_13,
--     14_17, adultes) ;
--   - classesSouhaitees (1, 2 ou 3 dans la definition) remplace
--     heuresParSemaine. Le plafond de trois Classes par enseignant est celui
--     de la decision du 22/10, reglable par la direction (reglage
--     enseignant.classes_max) : les migrations 20261022000200 et
--     20261022000300 font proposer de 1 a ce maximum et accepter de 1 a 80,
--     sans nouvelle version du questionnaire ;
--   - moyensAccessibles : champ FACULTATIF et purement informatif, la liste
--     de tous les moyens connus du referentiel de paiement de L6 (les
--     operateurs actifs du catalogue, meme ceux qu'aucun pays ne confirme).
--     Il deroge a "les candidats ne voient que les options confirmees"
--     (options_paiement_confirmees, L6) sans rien dire de ce qui est
--     confirme. Il n'est JAMAIS lu par le calcul du paiement
--     (private.paiement_declaration ne lit que paysVersement, compteBancaire
--     et operateurs) ni par un controle (le controle questionnaire_complet de
--     L2A2 l'ecarte comme operateurs) : la condition d'entree en salle 2
--     reste paiement_compatible ;
--   - la continuite (tenir sa Classe aux memes jours et heures) est une
--     clause du texte des conditions acceptees : rien dans ce questionnaire ;
--   - les codes d'une liste de valeurs peuvent commencer par un chiffre.
-- * C18 disponibilites declarees, au format que lit l'affectation (directeur,
--   22/10/2026 : « les formulaires de base ne sont pas des references [...] la
--   grille horaire [...] est-ce qu'elle peut couvrir tout ce que l'academie a
--   besoin pour determiner reellement les creneaux de l'enseignant et les
--   faire matcher avec ceux de l'eleve ? »). Une Classe, ce sont trois seances
--   par semaine aux memes jours, a une heure de debut ENTIERE
--   (offres_horaires.heure_locale, groupe_creneaux.hour_local), de 60 ou 90
--   minutes (offres_horaires.duree_minutes) ; l'affectation lit
--   weekly_availability (weekday ISO 1 a 7, hour_local entiere 0 a 23,
--   timezone_iana). La premiere forme du champ (creneaux a la demi-heure, avec
--   un second fuseau) ne pouvait y entrer qu'en devinant. Le champ est
--   maintenant une liste de plages par jour :
--       [{"jour": 1, "debut": "18:00", "fin": "21:00"}, ...]
--   - jour ISO 1 (lundi) a 7 ; debut "HH:00" ; fin "HH:00" ou "24:00" ; fin
--     apres debut, donc au moins une heure par plage ; au moins une plage
--     (champ requis) ; au plus 168 (7 jours de 24 plages d'une heure : le plus
--     que permette l'absence de chevauchement) ;
--   - deux plages d'un meme jour ne se recouvrent pas. Le refus est rendu avec
--     sa cause nommee : reponses_invalides, champs [disponibilitesDeclarees],
--     motifs {disponibilitesDeclarees: plages_qui_se_chevauchent} (la cle
--     motifs n'est rendue que si une cause est nommee). Une plage identique a
--     une autre se recouvre ; deux plages qui se touchent (18 h-19 h puis
--     19 h-21 h) ne se recouvrent pas ;
--   - aucun fuseau dans la grille : les heures sont celles de fuseauIana, le
--     seul fuseau du questionnaire, jamais converties (« Fuseaux IANA en
--     stockage, UTC pour les instants »). Une plage ne passe pas minuit : de
--     22 h a 1 h, deux plages (jour D de 22:00 a 24:00, jour D+1 de 00:00 a
--     01:00) ;
--   - l'ancienne forme ({fuseau, creneaux}) est invalide (version non
--     appliquee, corrigee sur place comme le reste de C17).
--   Comment les plages deviennent des lignes de weekly_availability a
--   l'entree en salle 3 (L2B ; PAS ECRIT ICI : aucune fonction n'ecrit
--   weekly_availability pour un candidat, et la spec 2.1 la demande apres
--   l'entree) : une ligne par heure couverte, c'est-a-dire, pour chaque plage,
--   une ligne pour chaque heure h de debut a fin - 1 :
--   (profile_id du compte enseignant, weekday = jour, hour_local = h,
--   timezone_iana = fuseauIana). Lundi 18:00-21:00 donne les heures 18, 19 et
--   20 du jour 1 ; mercredi 22:00-24:00 donne 22 et 23 du jour 3 ; une plage
--   de n heures donne n lignes. La cle unique (profile_id, weekday,
--   hour_local) ignore le fuseau, mais fuseauIana est unique et c'est le meme
--   que l'entree recopie dans teacher_profiles.timezone_iana (mon_fuseau()) ;
--   l'absence de chevauchement garantit qu'aucune heure n'est produite deux
--   fois (ON CONFLICT DO NOTHING reste la ceinture). weekly_availability n'a
--   aucun droit de modification (une case se pose ou se retire). La regle
--   vaut que la copie soit directe ou un brouillon confirme par l'enseignant
--   (a trancher en L2B). Le scenario de ce lot pose cette regle
--   d'expansion et prouve qu'une plage valide donne des lignes que la table
--   accepte et que le predicat d'affectation lit heure par heure.
--   Ce que l'import ne fait pas : les formulaires d'origine ne donnent aucun
--   jour (« de 8 h a 10 h du soir », sans jour), donc rien ne pre-remplit ce
--   champ (MAPPAGE_IMPORT_FORMULAIRES.md 3.5).
--   Ce qui MANQUE, cote affectation et hors de ce lot (non corrige ici), pour
--   qu'un cours adulte de 90 minutes soit compare correctement, c'est-a-dire
--   avec DEUX heures couvertes. Constat teste localement le 22/10, sur le
--   predicat app_private.verifier_affectation_enseignant_base (corps de
--   20261021210200, renomme par 20261022000200) :
--   - il lit une duree UNIQUE, le reglage session_duration_minutes (60 par
--     defaut, 20261021210200:121), pour toutes les Classes, alors que l'offre
--     porte sa duree (offres_horaires.duree_minutes, 60 enfant et 90 adulte,
--     0043:326, 0043:536-537) et que groupes n'a aucune colonne de duree ;
--   - la couverture exige qu'UNE SEULE ligne d'une heure contienne toute la
--     seance (busy_debut <= debut et busy_debut + 1 h >= debut + duree,
--     20261021210200:199) : deux heures declarees (18 h et 19 h) ne couvrent
--     donc jamais une seance de 90 minutes commencant a 18 h. Teste : avec les
--     lignes 18 et 19 du mercredi et la duree 90, « enseignant non disponible :
--     jour 3, heure 18 » ; avec la duree 60 (defaut), une Classe adulte est
--     acceptee sur la seule heure 18, dont elle depasse la fin de 30 minutes ;
--   - les collisions (20261021210200:255-256) et le plafond horaire
--     (20261021210200:167) comptent aussi la meme duree pour les deux Classes
--     en presence, alors qu'une Classe adulte occupe 90 minutes.
--   Pour une comparaison correcte : (1) la duree de chaque Classe lue a la
--   Classe (colonne de duree posee a la creation depuis l'offre, ou lue par
--   groupes.offre_id, a defaut par le public) et non au reglage global ; (2)
--   une couverture par l'UNION des lignes consecutives : une seance de d
--   minutes commencant a l'heure H exige les lignes H a H + ceil(d / 60) - 1
--   (deux lignes pour 90 minutes), en passant au jour suivant apres l'heure 23
--   (jour 7 vers jour 1) ; (3) collisions et plafond calcules avec la duree
--   propre a chaque Classe ; (4) la meme lecture cote eleve (le motif de
--   l'eleve est aussi heure par heure) et dans enseignants_pour_classe et
--   enseignants_pour_public (creneaux libres : pour une Classe de 90 minutes,
--   l'heure H n'est utilisable que si H et H + 1 sont libres).
--
-- Conservation (CAND-Q21, CAND-BR-14, spec 8.4) : public.candidature_gestes
-- (en ajout seul, aucun effacement, pas meme par le proprietaire) garde le
-- premier resultat des envois, retraits et gestes de la direction, sans
-- reponse ni motif ; public.candidature_brouillon_cles garde une ligne par
-- candidature (la derniere cle de brouillon) et s'efface avec elle. Le lot de
-- conservation les nomme avec le journal des evenements de CAND-L1.
--
-- Hors de ce lot : gestes de la direction (L2A2) ; controles nommes, salle 3,
-- decider_dossier, garde 0089 etendue (L2B) ; entretiens (L4 : le retrait
-- d'une candidature dont l'entretien est planifie le journalise seulement,
-- entretienPlanifie) ; inscription, import et pre-remplissage (L3) ;
-- notifications et courriels (L5 : marqueur aNotifier seulement) ; etape des
-- accords en base pour le contrat et l'avis (L2, apres la reponse sur les
-- accords en trois moments, spec 0.3).
BEGIN;

-- ============================================================
-- 1. Complements de CAND-L1 : modeles de message, envoi des reponses
-- ============================================================

ALTER TABLE public.candidatures
  ADD COLUMN pause_modele text NULL CHECK (pause_modele ~ '^[a-z][a-z0-9_]{1,59}$'),
  ADD COLUMN issue_modele text NULL CHECK (issue_modele ~ '^[a-z][a-z0-9_]{1,59}$');
-- Le modele de message d'une pause n'existe que pendant la pause ; celui d'un
-- refus, que pour une candidature refusee (spec 4.2, transitions 16 et 18).
ALTER TABLE public.candidatures ADD CONSTRAINT candidatures_pause_modele_en_pause
  CHECK (en_pause OR pause_modele IS NULL);
ALTER TABLE public.candidatures ADD CONSTRAINT candidatures_issue_modele_refusee
  CHECK (issue = 'refusee' OR issue_modele IS NULL);
COMMENT ON COLUMN public.candidatures.pause_modele IS
  'CAND-L2A1 : cle du modele de message de la pause (liste fermee des modeles valides, L2A2 et L5) ; '
  'rendue au candidat par etat_dossier(), jamais le motif interne.';
COMMENT ON COLUMN public.candidatures.issue_modele IS
  'CAND-L2A1 : cle du modele de message du refus ; rendue au candidat par etat_dossier(), jamais le motif interne.';

ALTER TABLE public.candidature_reponses
  ADD COLUMN envoye_le timestamptz NULL,
  ADD COLUMN brouillon boolean NOT NULL DEFAULT false,
  ADD COLUMN version integer NOT NULL DEFAULT 1 CHECK (version >= 1);
-- Un brouillon est un document du candidat, jamais envoye (C7). Un document
-- ecrit hors de ce lot n'a pas la marque : il reste une declaration (C8).
ALTER TABLE public.candidature_reponses ADD CONSTRAINT candidature_reponses_brouillon_candidat
  CHECK (NOT brouillon OR (source = 'candidat' AND envoye_le IS NULL));
COMMENT ON COLUMN public.candidature_reponses.envoye_le IS
  'CAND-L2A1 : instant de l envoi (transition 6) ; nul pour un brouillon (C7).';
COMMENT ON COLUMN public.candidature_reponses.brouillon IS
  'CAND-L2A1 : document du candidat pas encore envoye (C7) ; jamais lu comme declaration de paiement (C8).';
COMMENT ON COLUMN public.candidature_reponses.version IS
  'CAND-L2A1 : version du document, un de plus a chaque brouillon (versionAttendue du brouillon, C7).';

-- ============================================================
-- 2. Referentiels du questionnaire
-- ============================================================

-- Les pays ISO 3166-1 alpha-2 de lib/core/i18n/pays_iso.dart (249 codes, dans
-- le meme ordre), la table que le candidat lit pour ses deux pays (spec 5.1).
CREATE TABLE private.pays_iso_3166 (
  code text PRIMARY KEY CHECK (code ~ '^[A-Z]{2}$'),
  rang smallint NOT NULL UNIQUE CHECK (rang >= 1)
);
INSERT INTO private.pays_iso_3166 (code, rang)
SELECT p.code, p.rang::smallint
FROM pg_catalog.unnest(ARRAY[
  'AF','AX','AL','DZ','AS','AD','AO','AI','AQ','AG','AR','AM','AW','AU','AT','AZ','BS','BH','BD','BB',
  'BY','BE','BZ','BJ','BM','BT','BO','BQ','BA','BW','BV','BR','IO','BN','BG','BF','BI','CV','KH','CM',
  'CA','KY','CF','TD','CL','CN','CX','CC','CO','KM','CG','CD','CK','CR','CI','HR','CU','CW','CY','CZ',
  'DK','DJ','DM','DO','EC','EG','SV','GQ','ER','EE','SZ','ET','FK','FO','FJ','FI','FR','GF','PF','TF',
  'GA','GM','GE','DE','GH','GI','GR','GL','GD','GP','GU','GT','GG','GN','GW','GY','HT','HM','VA','HN',
  'HK','HU','IS','IN','ID','IR','IQ','IE','IM','IL','IT','JM','JP','JE','JO','KZ','KE','KI','KP','KR',
  'KW','KG','LA','LV','LB','LS','LR','LY','LI','LT','LU','MO','MG','MW','MY','MV','ML','MT','MH','MQ',
  'MR','MU','YT','MX','FM','MD','MC','MN','ME','MS','MA','MZ','MM','NA','NR','NP','NL','NC','NZ','NI',
  'NE','NG','NU','NF','MK','MP','NO','OM','PK','PW','PS','PA','PG','PY','PE','PH','PN','PL','PT','PR',
  'QA','RE','RO','RU','RW','BL','SH','KN','LC','MF','PM','VC','WS','SM','ST','SA','SN','RS','SC','SL',
  'SG','SX','SK','SI','SB','SO','ZA','GS','SS','ES','LK','SD','SR','SJ','SE','CH','SY','TW','TJ','TZ',
  'TH','TL','TG','TK','TO','TT','TN','TR','TM','TC','TV','UG','UA','AE','GB','US','UM','UY','UZ','VU',
  'VE','VN','VG','VI','WF','EH','YE','ZM','ZW'
]::text[]) WITH ORDINALITY AS p(code, rang);

-- La forme d'une definition de questionnaire (fonction pure, lue par la
-- contrainte de la table) : un objet, des champs aux codes uniques, chacun
-- d'un type ferme ; un champ de choix porte soit une liste de valeurs
-- (codes), soit un referentiel nomme ; un booleen ou des creneaux n'en
-- portent pas.
CREATE FUNCTION private.questionnaire_definition_valide(p jsonb)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_c jsonb;
  v_type text;
BEGIN
  IF p IS NULL OR pg_catalog.jsonb_typeof(p) <> 'object'
     OR pg_catalog.jsonb_typeof(p -> 'champs') IS DISTINCT FROM 'array'
     OR pg_catalog.jsonb_array_length(p -> 'champs') = 0 THEN
    RETURN false;
  END IF;
  IF p ? 'languesHorsReferentiel' THEN
    IF pg_catalog.jsonb_typeof(p -> 'languesHorsReferentiel') <> 'array' THEN
      RETURN false;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(p -> 'languesHorsReferentiel') l
               WHERE pg_catalog.jsonb_typeof(l) <> 'string') THEN
      RETURN false;
    END IF;
    -- Un code ISO 639 (deux ou trois lettres), ou "autre" : la sortie
    -- "autre langue" (C17), jamais un texte libre.
    IF EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements_text(p -> 'languesHorsReferentiel') l(code)
               WHERE l.code !~ '^([a-z]{2,3}|autre)$') THEN
      RETURN false;
    END IF;
    IF (SELECT pg_catalog.count(DISTINCT l) FROM pg_catalog.jsonb_array_elements(p -> 'languesHorsReferentiel') l)
       <> pg_catalog.jsonb_array_length(p -> 'languesHorsReferentiel') THEN
      RETURN false;
    END IF;
  END IF;
  FOR v_c IN SELECT c FROM pg_catalog.jsonb_array_elements(p -> 'champs') AS c LOOP
    IF pg_catalog.jsonb_typeof(v_c) <> 'object'
       OR pg_catalog.jsonb_typeof(v_c -> 'code') IS DISTINCT FROM 'string'
       OR (v_c ->> 'code') !~ '^[a-z][A-Za-z0-9]{1,59}$'
       OR pg_catalog.jsonb_typeof(v_c -> 'requis') IS DISTINCT FROM 'boolean'
       OR pg_catalog.jsonb_typeof(v_c -> 'type') IS DISTINCT FROM 'string' THEN
      RETURN false;
    END IF;
    v_type := v_c ->> 'type';
    IF v_type NOT IN ('choix', 'choix_multiple', 'booleen', 'creneaux') THEN
      RETURN false;
    END IF;
    IF v_type IN ('choix', 'choix_multiple') THEN
      IF (v_c ? 'valeurs') = (v_c ? 'liste') THEN
        RETURN false;
      END IF;
      IF v_c ? 'liste' AND (pg_catalog.jsonb_typeof(v_c -> 'liste') IS DISTINCT FROM 'string'
                            OR (v_c ->> 'liste') NOT IN ('langues', 'pays', 'fuseaux', 'operateurs_confirmes', 'moyens_connus')) THEN
        RETURN false;
      END IF;
      IF v_c ? 'valeurs' THEN
        IF pg_catalog.jsonb_typeof(v_c -> 'valeurs') <> 'array'
           OR pg_catalog.jsonb_array_length(v_c -> 'valeurs') = 0 THEN
          RETURN false;
        END IF;
        IF EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(v_c -> 'valeurs') v
                   WHERE pg_catalog.jsonb_typeof(v) <> 'string') THEN
          RETURN false;
        END IF;
        IF EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements_text(v_c -> 'valeurs') v(code)
                   WHERE v.code !~ '^[a-z0-9][a-z0-9_]{0,59}$')
           OR (SELECT pg_catalog.count(DISTINCT v) FROM pg_catalog.jsonb_array_elements(v_c -> 'valeurs') v)
              <> pg_catalog.jsonb_array_length(v_c -> 'valeurs') THEN
          RETURN false;
        END IF;
      END IF;
    ELSIF v_c ? 'valeurs' OR v_c ? 'liste' THEN
      RETURN false;
    END IF;
    -- "exclure" (C17) : des codes de langue que ce champ ne propose pas bien
    -- qu'ils soient dans la liste "langues" (l'arabe n'est pas une langue de
    -- cours). Sans autre usage.
    IF v_c ? 'exclure' THEN
      IF (v_c ->> 'liste') IS DISTINCT FROM 'langues'
         OR pg_catalog.jsonb_typeof(v_c -> 'exclure') <> 'array'
         OR pg_catalog.jsonb_array_length(v_c -> 'exclure') = 0
         OR EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(v_c -> 'exclure') e
                    WHERE pg_catalog.jsonb_typeof(e) <> 'string' OR (e #>> '{}') !~ '^([a-z]{2,3}|autre)$')
         OR (SELECT pg_catalog.count(DISTINCT e) FROM pg_catalog.jsonb_array_elements(v_c -> 'exclure') e)
            <> pg_catalog.jsonb_array_length(v_c -> 'exclure') THEN
        RETURN false;
      END IF;
    END IF;
    IF (v_c ? 'min' AND (pg_catalog.jsonb_typeof(v_c -> 'min') <> 'number' OR (v_c ->> 'min') !~ '^[0-9]{1,3}$'))
       OR (v_c ? 'max' AND (pg_catalog.jsonb_typeof(v_c -> 'max') <> 'number' OR (v_c ->> 'max') !~ '^[0-9]{1,3}$')) THEN
      RETURN false;
    END IF;
    IF coalesce((v_c ->> 'min')::integer, 0) > coalesce((v_c ->> 'max')::integer, 999) THEN
      RETURN false;
    END IF;
  END LOOP;
  RETURN (SELECT pg_catalog.count(DISTINCT c ->> 'code') FROM pg_catalog.jsonb_array_elements(p -> 'champs') c)
         = pg_catalog.jsonb_array_length(p -> 'champs');
END;
$function$;

-- Le questionnaire versionne (revue R7, spec 1 point 1) : une version publiee
-- ne change plus (declencheur) ; une seule version courante par type.
-- Publier une version, c'est une migration : inserer la suivante et retirer
-- la marque courante de la precedente. Les reponses gardent leur version.
CREATE TABLE public.candidature_questionnaires (
  version text PRIMARY KEY CHECK (version ~ '^[a-z][a-z0-9-]{2,39}$'),
  type_code text NOT NULL REFERENCES public.candidature_types(code),
  definition jsonb NOT NULL CHECK (private.questionnaire_definition_valide(definition)),
  courant boolean NOT NULL DEFAULT false,
  publie_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);
CREATE UNIQUE INDEX candidature_questionnaires_courant_uidx
  ON public.candidature_questionnaires (type_code) WHERE courant;

CREATE FUNCTION private.questionnaire_immuable()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'CAND-L2A1 : une version publiee du questionnaire ne s''efface pas'
      USING ERRCODE = '55000';
  END IF;
  IF NEW.version IS DISTINCT FROM OLD.version
     OR NEW.type_code IS DISTINCT FROM OLD.type_code
     OR NEW.definition IS DISTINCT FROM OLD.definition
     OR NEW.publie_le IS DISTINCT FROM OLD.publie_le THEN
    RAISE EXCEPTION 'CAND-L2A1 : une version publiee du questionnaire ne change pas : publier la suivante'
      USING ERRCODE = '55000';
  END IF;
  RETURN NEW;
END;
$function$;
CREATE TRIGGER candidature_questionnaires_immuable
  BEFORE UPDATE OR DELETE ON public.candidature_questionnaires
  FOR EACH ROW EXECUTE FUNCTION private.questionnaire_immuable();

-- Version 1, Salle d'examen du type enseignant (spec 2.1, ligne Salle
-- d'examen ; CAND-01 ; MAPPAGE_IMPORT_FORMULAIRES.md section 3 pour les codes
-- deja fixes ; L6 pour paysVersement, compteBancaire, operateurs). Les cles
-- reprennent celles du mappage, pour que le pre-remplissage de L3 s'y range.
-- Listes proposees, a soumettre au directeur (spec 0.2 bis) : riwayat (les
-- vingt riwayat des dix lectures), niveauLectureTajwid, experienceDebutants
-- (oui, non). Decidees le 22/10 (C17) : langues,
-- memorisation, ijaza, publics, classes souhaitees ; moyensAccessibles
-- (informatif) est nouveau. Les disponibilites (C18) sont des plages par jour
-- ISO (1 = lundi) a bornes en heures entieres, dans le fuseau de fuseauIana. Les langues proposees : poular, francais et
-- english (referentiel langues_cours), puis les codes de languesHorsReferentiel
-- dans l'ordre ; "autre" ferme la liste.
INSERT INTO public.candidature_questionnaires (version, type_code, definition, courant)
VALUES ('salle-examen-1', 'enseignant', $definition$
{
  "languesHorsReferentiel": ["man", "sus", "sw", "ha", "wo", "bm", "snk", "mnk", "ar", "ps", "ur", "om", "am",
                             "yo", "bn", "fa", "id", "so", "hi", "uz", "tr", "de", "pt", "ru", "autre"],
  "champs": [
    {"code": "langueMaternelle", "carte": "langues", "type": "choix", "liste": "langues", "requis": false},
    {"code": "languesExplication", "carte": "langues", "type": "choix_multiple", "liste": "langues",
     "exclure": ["ar"], "requis": true, "min": 1},
    {"code": "niveauMemorisationDeclare", "carte": "recitation", "type": "choix", "requis": true,
     "valeurs": ["aucune", "moins_10_juz", "de_10_a_29_juz", "coran_entier"]},
    {"code": "niveauLectureTajwid", "carte": "recitation", "type": "choix", "requis": true,
     "valeurs": ["lecture_sans_regles_tajwid", "tajwid_applique", "tajwid_enseigne"]},
    {"code": "riwayat", "carte": "recitation", "type": "choix_multiple", "requis": true, "min": 1, "max": 20,
     "valeurs": ["hafs", "shuba", "warsh", "qalun", "al_bazzi", "qunbul", "ad_duri_abi_amr", "as_susi",
                 "hisham", "ibn_dhakwan", "khalaf_an_hamza", "khallad", "abu_al_harith",
                 "ad_duri_al_kisai", "ibn_wardan", "ibn_jammaz", "ruways", "rawh", "ishaq", "idris"]},
    {"code": "ijazaPresentable", "carte": "recitation", "type": "choix", "requis": true,
     "valeurs": ["oui", "pret_test", "non"]},
    {"code": "experienceDebutants", "carte": "recitation", "type": "choix", "requis": true,
     "valeurs": ["oui", "non"]},
    {"code": "disponibilitesDeclarees", "carte": "disponibilites", "type": "creneaux", "requis": true,
     "min": 1, "max": 168},
    {"code": "fuseauIana", "carte": "disponibilites", "type": "choix", "liste": "fuseaux", "requis": true},
    {"code": "classesSouhaitees", "carte": "disponibilites", "type": "choix", "requis": true,
     "valeurs": ["1", "2", "3"]},
    {"code": "debutPossible", "carte": "disponibilites", "type": "choix", "requis": true,
     "valeurs": ["immediat", "mois_prochain", "sous_3_mois", "inconnu"]},
    {"code": "publics", "carte": "publics", "type": "choix_multiple", "requis": true, "min": 1, "max": 4,
     "valeurs": ["6_9", "10_13", "14_17", "adultes"]},
    {"code": "paysResidence", "carte": "versement", "type": "choix", "liste": "pays", "requis": true},
    {"code": "paysVersement", "carte": "versement", "type": "choix", "liste": "pays", "requis": true},
    {"code": "compteBancaire", "carte": "versement", "type": "booleen", "requis": true},
    {"code": "operateurs", "carte": "versement", "type": "choix_multiple", "liste": "operateurs_confirmes",
     "dependDe": "paysVersement", "requis": false, "min": 0, "max": 10},
    {"code": "moyensAccessibles", "carte": "versement", "type": "choix_multiple", "liste": "moyens_connus",
     "requis": false, "min": 0}
  ]
}
$definition$::jsonb, true);

COMMENT ON TABLE public.candidature_questionnaires IS
  'CAND-L2A1 : questionnaires versionnes (une version courante par type) ; une version publiee ne '
  'change pas. Aucune policy : lu par questionnaire_salle_examen() et etat_dossier().';
COMMENT ON TABLE private.pays_iso_3166 IS
  'CAND-L2A1 : pays ISO 3166-1 alpha-2 de lib/core/i18n/pays_iso.dart (249 codes), liste fermee du '
  'questionnaire (paysResidence, paysVersement).';

-- ============================================================
-- 3. Moteur : regles des gestes et idempotence
-- ============================================================

-- La source permise de chaque geste (spec 4.2). Une ligne par variante : un
-- geste vaut si UNE de ses variantes correspond. auteurs : categories admises ;
-- etats null : tout etat de ces etapes ; pause : interdite (refuse pendant une
-- pause, spec 4.3), permise (refuser et retirer), requise (lever la pause) ;
-- condition : predicat ferme lu par private.candidature_condition ;
-- motif_requis : categories pour qui le motif est exige (colonne Motif de
-- 4.2) ; modele_vers : colonne du modele de message exige ; cible : valeurs
-- posees par le geste ; admis : colonnes que l'appelant peut poser (C16) ;
-- brouillon : geste du brouillon (C7 : version du document, version de la
-- candidature inchangee, seule la derniere cle gardee). Ecrite par migration
-- seulement.
CREATE TABLE private.candidature_gestes_regles (
  geste text NOT NULL CHECK (geste ~ '^[a-z][a-z_]{2,59}$'),
  variante smallint NOT NULL DEFAULT 1 CHECK (variante BETWEEN 1 AND 9),
  transition smallint NULL CHECK (transition BETWEEN 1 AND 99),
  auteurs text[] NOT NULL
    CHECK (pg_catalog.cardinality(auteurs) >= 1 AND auteurs <@ ARRAY['candidat', 'direction']::text[]),
  etapes text[] NOT NULL
    CHECK (pg_catalog.cardinality(etapes) >= 1
           AND etapes <@ ARRAY['recue', 'invitee', 'prequalification', 'verifications', 'confirmee']::text[]),
  etats text[] NULL
    CHECK (etats IS NULL OR (pg_catalog.cardinality(etats) >= 1
           AND etats <@ ARRAY['a_completer', 'en_examen', 'paiement_non_disponible', 'entretien_a_planifier',
                              'entretien_planifie', 'decision_en_attente']::text[])),
  issues text[] NOT NULL
    CHECK (pg_catalog.cardinality(issues) >= 1 AND issues <@ ARRAY['en_cours', 'refusee', 'retiree']::text[]),
  pause text NOT NULL DEFAULT 'interdite' CHECK (pause IN ('interdite', 'permise', 'requise')),
  condition text NULL CHECK (condition IN ('restreinte', 'non_restreinte', 'indisponible', 'non_indisponible',
    'paiement_a_verifier', 'paiement_a_verifier_ou_compatible', 'restreinte_paiement_a_verifier')),
  motif_requis text[] NOT NULL DEFAULT '{}'::text[] CHECK (motif_requis <@ auteurs),
  modele_vers text NULL CHECK (modele_vers IN ('pause_modele', 'issue_modele')),
  groupable boolean NOT NULL DEFAULT false,
  type_evenement text NULL CHECK (type_evenement IN ('transition', 'pause', 'reprise', 'restriction',
    'levee_restriction', 'responsable', 'controle', 'entretien', 'prevenu')),
  cible jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (pg_catalog.jsonb_typeof(cible) = 'object'),
  admis text[] NOT NULL DEFAULT '{}'::text[]
    CHECK (admis <@ ARRAY['reprise_le', 'indisponible_jusqu_au', 'responsable_id', 'pays_residence',
                          'fuseau_iana']::text[]),
  brouillon boolean NOT NULL DEFAULT false,
  PRIMARY KEY (geste, variante),
  -- Une transition journalise toujours ; seul le brouillon n'en est pas une.
  CONSTRAINT candidature_gestes_regles_evenement CHECK ((transition IS NULL) = (type_evenement IS NULL)),
  CONSTRAINT candidature_gestes_regles_brouillon CHECK (brouillon = (transition IS NULL)),
  -- Une colonne posee par la regle ne se pose pas aussi par l'appelant.
  CONSTRAINT candidature_gestes_regles_admis_hors_cible CHECK (NOT (cible ?| admis))
);

INSERT INTO private.candidature_gestes_regles
  (geste, variante, transition, auteurs, etapes, etats, issues, pause, condition, motif_requis,
   modele_vers, groupable, type_evenement, cible, admis, brouillon)
VALUES
  ('inviter', 1, 3, '{direction}', '{recue}', NULL, '{en_cours}', 'interdite', NULL, '{}',
   NULL, true, 'transition', '{"etape": "invitee"}', '{}', false),
  ('enregistrer_reponses', 1, NULL, '{candidat}', '{prequalification}', '{a_completer}', '{en_cours}',
   'interdite', NULL, '{}', NULL, false, NULL, '{}', '{}', true),
  ('envoyer_reponses', 1, 6, '{candidat}', '{prequalification}', '{a_completer}', '{en_cours}',
   'interdite', NULL, '{}', NULL, false, 'transition', '{"etat": "en_examen"}',
   '{pays_residence,fuseau_iana}', false),
  ('demander_complement', 1, 7, '{direction}', '{prequalification}', '{en_examen}', '{en_cours}',
   'interdite', NULL, '{direction}', NULL, false, 'transition', '{"etat": "a_completer"}', '{}', false),
  ('demander_complement', 2, 23, '{direction}', '{verifications}', NULL, '{en_cours}',
   'interdite', NULL, '{direction}', NULL, false, 'transition', '{}', '{}', false),
  ('admettre_verifications', 1, 10, '{direction}', '{prequalification}', '{en_examen}', '{en_cours}',
   'interdite', NULL, '{}', NULL, false, 'transition',
   '{"etape": "verifications", "etat": "entretien_a_planifier"}', '{}', false),
  ('planifier_entretien', 1, 11, '{direction}', '{verifications}', '{entretien_a_planifier}', '{en_cours}',
   'interdite', NULL, '{}', NULL, false, 'entretien', '{"etat": "entretien_planifie"}', '{}', false),
  ('consigner_entretien_non_tenu', 1, 12, '{direction}', '{verifications}', '{entretien_planifie}',
   '{en_cours}', 'interdite', NULL, '{direction}', NULL, false, 'entretien', '{"etat": "entretien_a_planifier"}', '{}', false),
  ('consigner_entretien_tenu', 1, 13, '{direction}', '{verifications}', '{entretien_planifie}', '{en_cours}',
   'interdite', NULL, '{}', NULL, false, 'entretien', '{"etat": "decision_en_attente"}', '{}', false),
  ('valider_piece', 1, 14, '{direction}', '{verifications}', '{decision_en_attente}', '{en_cours}',
   'interdite', NULL, '{}', NULL, false, 'transition', '{"etape": "confirmee", "etat": null}', '{}', false),
  ('piece_a_corriger', 1, 15, '{direction}', '{verifications}', NULL, '{en_cours}',
   'interdite', NULL, '{direction}', NULL, false, 'transition', '{}', '{}', false),
  ('refuser', 1, 16, '{direction}', '{recue,invitee,prequalification,verifications}', NULL, '{en_cours}',
   'permise', NULL, '{direction}', 'issue_modele', true, 'transition',
   '{"issue": "refusee", "en_pause": false, "reprise_le": null, "pause_modele": null}', '{}', false),
  ('retirer', 1, 17, '{candidat,direction}', '{recue,invitee,prequalification,verifications}', NULL,
   '{en_cours}', 'permise', NULL, '{direction}', NULL, false, 'transition',
   '{"issue": "retiree", "en_pause": false, "reprise_le": null, "pause_modele": null}', '{}', false),
  ('mettre_en_pause', 1, 18, '{direction}', '{recue,invitee,prequalification,verifications,confirmee}', NULL,
   '{en_cours}', 'interdite', NULL, '{direction}', 'pause_modele', true, 'pause', '{"en_pause": true}', '{reprise_le}', false),
  ('lever_pause', 1, 18, '{direction}', '{recue,invitee,prequalification,verifications,confirmee}', NULL,
   '{en_cours}', 'requise', NULL, '{}', NULL, true, 'reprise',
   '{"en_pause": false, "reprise_le": null, "pause_modele": null}', '{}', false),
  ('rouvrir', 1, 19, '{direction}', '{recue,invitee,prequalification,verifications}', NULL,
   '{refusee,retiree}', 'interdite', NULL, '{direction}', NULL, false, 'transition',
   '{"issue": "en_cours", "issue_modele": null}', '{}', false),
  ('restreindre', 1, 20, '{direction}', '{confirmee}', NULL, '{en_cours}', 'interdite', 'non_restreinte',
   '{direction}', NULL, false, 'restriction', '{"restreinte": true, "restriction_cause": "manuelle"}', '{}', false),
  ('lever_restriction', 1, 21, '{direction}', '{confirmee}', NULL, '{en_cours}', 'interdite', 'restreinte',
   '{direction}', NULL, false, 'levee_restriction', '{"restreinte": false, "restriction_cause": null}', '{}', false),
  ('noter_indisponibilite', 1, 22, '{direction}', '{confirmee}', NULL, '{en_cours}', 'interdite',
   'non_indisponible', '{}', NULL, false, 'transition', '{"indisponible": true}', '{indisponible_jusqu_au}', false),
  ('lever_indisponibilite', 1, 22, '{direction}', '{confirmee}', NULL, '{en_cours}', 'interdite',
   'indisponible', '{}', NULL, false, 'transition', '{"indisponible": false, "indisponible_jusqu_au": null}', '{}', false),
  ('confirmer_moyen_paiement', 1, 24, '{direction}', '{prequalification}', '{en_examen}', '{en_cours}',
   'interdite', 'paiement_a_verifier', '{}', NULL, false, 'controle', '{}', '{}', false),
  ('confirmer_moyen_paiement', 2, 24, '{direction}', '{confirmee}', NULL, '{en_cours}',
   'interdite', 'restreinte_paiement_a_verifier', '{}', NULL, false, 'controle', '{}', '{}', false),
  ('infirmer_moyen_paiement', 1, 25, '{direction}', '{prequalification}', '{en_examen}', '{en_cours}',
   'interdite', 'paiement_a_verifier_ou_compatible', '{direction}', NULL, false, 'controle', '{}', '{}', false),
  ('consigner_prevenu', 1, 26, '{direction}', '{recue}', NULL, '{en_cours}', 'interdite', NULL, '{}',
   NULL, true, 'prevenu', '{}', '{}', false),
  ('rattacher', 1, 27, '{direction}', '{prequalification}', '{a_completer}', '{en_cours}', 'interdite', NULL,
   '{}', NULL, false, 'transition', '{}', '{}', false),
  ('definir_responsable', 1, 28, '{direction}', '{recue,invitee,prequalification,verifications,confirmee}',
   NULL, '{en_cours}', 'interdite', NULL, '{}', NULL, false, 'responsable', '{}', '{responsable_id}', false);

COMMENT ON TABLE private.candidature_gestes_regles IS
  'CAND-L2A1 : source permise de chaque geste du module (spec consolidee 4.2), lue par le moteur. '
  'Ecrite par migration seulement.';

-- L'idempotence des gestes (C3), en ajout seul.
CREATE TABLE public.candidature_gestes (
  cle text PRIMARY KEY CHECK (pg_catalog.length(cle) BETWEEN 8 AND 200),
  candidature_id uuid NOT NULL REFERENCES public.candidatures(id) ON DELETE RESTRICT,
  geste text NOT NULL CHECK (geste ~ '^[a-z][a-z_]{2,59}$'),
  auteur_id uuid NULL REFERENCES public.profiles(id),
  resultat jsonb NOT NULL CHECK (pg_catalog.jsonb_typeof(resultat) = 'object'),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);
CREATE INDEX candidature_gestes_candidature_idx ON public.candidature_gestes (candidature_id, cree_le DESC);
CREATE TRIGGER candidature_gestes_ajout_seul
  BEFORE UPDATE OR DELETE ON public.candidature_gestes
  FOR EACH ROW EXECUTE FUNCTION private.cand_evenements_refuser_mutation();
COMMENT ON TABLE public.candidature_gestes IS
  'CAND-L2A1 : cles d idempotence des gestes reussis et leur premier resultat (C3), en ajout seul ; '
  'jamais une reponse ni un motif ; aucune policy. Conservation : CAND-Q21.';

-- La derniere cle de brouillon de chaque candidature (C3, C7) : une ligne,
-- remplacee a chaque brouillon, effacee avec la candidature. Le resultat ne
-- porte aucune reponse.
CREATE TABLE public.candidature_brouillon_cles (
  candidature_id uuid PRIMARY KEY REFERENCES public.candidatures(id) ON DELETE CASCADE,
  cle text NOT NULL UNIQUE CHECK (pg_catalog.length(cle) BETWEEN 8 AND 200),
  resultat jsonb NOT NULL CHECK (pg_catalog.jsonb_typeof(resultat) = 'object' AND NOT resultat ? 'reponses'),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);
COMMENT ON TABLE public.candidature_brouillon_cles IS
  'CAND-L2A1 : derniere cle d idempotence du brouillon de chaque candidature et son resultat, sans '
  'reponse (C3, C7) ; aucune policy.';

-- ============================================================
-- 4. Accords : cadre religieux et pedagogique, conditions de remuneration
-- ============================================================

-- Deux sortes d'accord de plus, comme teacher_conduct_code
-- (20261018160000_pe_protection_enfants.sql, section 2).
ALTER TABLE public.contract_acceptances DROP CONSTRAINT contract_acceptances_contract_kind_check;
ALTER TABLE public.contract_acceptances ADD CONSTRAINT contract_acceptances_contract_kind_check
  CHECK (contract_kind IN ('guardian_terms', 'teacher_nda', 'recording_and_control_notice',
                           'teacher_conduct_code', 'teacher_religious_framework', 'teacher_pay_conditions'));
-- Seul le cadre religieux a une version requise ; elle n'est PAS publiee ici
-- (spec 9 : apres la validation juridique et l'accord du directeur).
ALTER TABLE public.contract_required_versions DROP CONSTRAINT contract_required_versions_contract_kind_check;
ALTER TABLE public.contract_required_versions ADD CONSTRAINT contract_required_versions_contract_kind_check
  CHECK (contract_kind IN ('recording_and_control_notice', 'teacher_conduct_code',
                           'teacher_religious_framework'));

-- La part de l'enseignant par version de politique (C10), en ajout seul. Pas
-- de cle etrangere vers politiques_commerciales : des scenarios existants
-- (fac_a a fac_d, fi_br06) y retirent la v2.0.0 le temps de leur transaction ;
-- une politique publiee ne s'efface jamais (politiques_commerciales_immuable),
-- et une ligne ne s'ecrit que pour une version publiee (declencheur).
CREATE TABLE public.politique_part_enseignant (
  politique_version text PRIMARY KEY CHECK (politique_version ~ '^v[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'),
  part_enfant_pour_mille integer NOT NULL CHECK (part_enfant_pour_mille BETWEEN 0 AND 1000),
  part_adulte_pour_mille integer NOT NULL CHECK (part_adulte_pour_mille BETWEEN 0 AND 1000),
  decision_ref text NOT NULL CHECK (pg_catalog.length(pg_catalog.btrim(decision_ref)) BETWEEN 1 AND 300),
  enregistre_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);
CREATE TRIGGER politique_part_enseignant_immuable
  BEFORE UPDATE OR DELETE ON public.politique_part_enseignant
  FOR EACH ROW EXECUTE FUNCTION private.fac_politique_immuable();
CREATE FUNCTION private.politique_part_version_publiee()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.politiques_commerciales p WHERE p.version = NEW.politique_version) THEN
    RAISE EXCEPTION 'CAND-L2A1 : part de l''enseignant pour une politique non publiee : %', NEW.politique_version
      USING ERRCODE = '23503';
  END IF;
  RETURN NEW;
END;
$function$;
CREATE TRIGGER politique_part_enseignant_version_publiee
  BEFORE INSERT ON public.politique_part_enseignant
  FOR EACH ROW EXECUTE FUNCTION private.politique_part_version_publiee();
INSERT INTO public.politique_part_enseignant
  (politique_version, part_enfant_pour_mille, part_adulte_pour_mille, decision_ref)
VALUES ('v2.0.0', 470, 470,
  'DECISION-TARIFS-2026-10-18.md, decision du directeur du 19/10/2026 ; tarifs-2026-10-18.json, '
  'enseignant.part_du_prix_pour_mille');
COMMENT ON TABLE public.politique_part_enseignant IS
  'CAND-L2A1 : part de l enseignant (pour mille du prix public) par version de la politique '
  'commerciale (CAND-BR-12, C10) ; ajout seul ; aucune policy.';

-- La version requise du cadre religieux, lue par la page d'accords et par la
-- policy (une policy s'execute avec les droits de l'appelant, qui ne lit pas
-- la table). Nulle tant que le directeur ne l'a pas publiee.
CREATE FUNCTION public.cadre_religieux_version_requise()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT r.version
    FROM public.contract_required_versions r
   WHERE r.contract_kind = 'teacher_religious_framework';
$function$;

-- Le compte appelant peut-il accepter cette version du cadre (C9) ? La version
-- requise publiee, et une candidature enseignant en cours en Salle d'examen ou
-- en Salle de verification et d'entretien, au compte du role du type, en
-- attente, provisoire ou actif, non supprime, non expire.
CREATE FUNCTION public.cadre_religieux_acceptable(p_version text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(
    p_version IS NOT NULL
    AND p_version = (SELECT r.version FROM public.contract_required_versions r
                      WHERE r.contract_kind = 'teacher_religious_framework')
    AND EXISTS (
      SELECT 1
        FROM public.candidatures c
        JOIN public.candidature_types t ON t.code = c.type_code
        JOIN public.profiles p ON p.id = c.profile_id
       WHERE c.profile_id = auth.uid()
         AND c.type_code = 'enseignant'
         AND c.issue = 'en_cours'
         AND c.etape IN ('prequalification', 'verifications')
         AND p.role = t.role_compte
         AND p.deleted_at IS NULL
         AND p.account_status IN ('pending_kyc', 'provisional_active', 'active')
         AND (p.access_until IS NULL OR p.access_until > pg_catalog.now())),
    false);
$function$;

CREATE POLICY contract_acceptances_cadre_religieux_candidat
  ON public.contract_acceptances
  AS RESTRICTIVE
  FOR INSERT TO authenticated
  WITH CHECK (
    contract_kind <> 'teacher_religious_framework'
    OR coalesce(profile_id = auth.uid() AND public.cadre_religieux_acceptable(version), false)
  );

-- L'accord de remuneration ne s'ecrit que par l'envoi (C11).
CREATE POLICY contract_acceptances_conditions_remuneration_serveur
  ON public.contract_acceptances
  AS RESTRICTIVE
  FOR INSERT TO authenticated
  WITH CHECK (contract_kind <> 'teacher_pay_conditions');

-- Les accords d'un compte qui porte une candidature avant la salle 3 ne se
-- lisent que de son cote (C15) : meme regle que profiles_compte_candidat_portee
-- (CAND-L1B), dont la fonction ne vaut que pour la direction. Restrictive :
-- elle borne contract_acceptances_admin_read sans rien ouvrir.
CREATE POLICY contract_acceptances_compte_candidat_portee
  ON public.contract_acceptances
  AS RESTRICTIVE
  FOR SELECT TO authenticated, agent_ro
  USING (coalesce(NOT app_private.compte_candidat_hors_portee(profile_id), false));
COMMENT ON POLICY contract_acceptances_compte_candidat_portee ON public.contract_acceptances IS
  'CAND-L2A1 : la direction de l autre cote ne lit pas les accords d un compte qui porte une candidature '
  'avant la salle 3 (CAND-Q07, C15).';

-- ============================================================
-- 5. Aides internes (schema private, jamais appelables par un compte)
-- ============================================================

-- La politique de paie rendue au candidat (C10) : la politique en vigueur si
-- elle paie par eleve present, sinon la prochaine publiee qui le fait ; nulle
-- s'il n'y en a aucune, ou si elle n'a pas sa ligne de part de l'enseignant
-- (la part s'affiche toujours, CAND-BR-12). Aucun montant n'est rendu : ni le
-- taux par eleve present et par heure ni la devise (decision du 22/10) ; le
-- taux ne sert qu'a reconnaitre une politique qui paie par eleve present.
CREATE FUNCTION private.conditions_remuneration_applicables()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_jour date := private.fac_aujourdhui();
  v_p public.politiques_commerciales;
  v_part public.politique_part_enseignant;
BEGIN
  v_p := private.fac_politique_au(v_jour);
  IF v_p.version IS NULL OR v_p.taux_eleve_heure_enfant_mineur IS NULL
     OR v_p.taux_eleve_heure_adulte_mineur IS NULL THEN
    SELECT p.* INTO v_p
      FROM public.politiques_commerciales p
     WHERE p.date_effet > v_jour
       AND p.taux_eleve_heure_enfant_mineur IS NOT NULL
       AND p.taux_eleve_heure_adulte_mineur IS NOT NULL
     ORDER BY p.date_effet ASC
     LIMIT 1;
  END IF;
  IF v_p.version IS NULL THEN
    RETURN NULL;
  END IF;
  SELECT x.* INTO v_part FROM public.politique_part_enseignant x WHERE x.politique_version = v_p.version;
  IF v_part.politique_version IS NULL THEN
    RETURN NULL;
  END IF;
  RETURN pg_catalog.jsonb_build_object(
    'version', v_p.version,
    'dateEffet', pg_catalog.to_char(v_p.date_effet, 'YYYY-MM-DD'),
    'enVigueur', v_p.date_effet <= v_jour,
    'publics', pg_catalog.jsonb_build_array(
      pg_catalog.jsonb_build_object('public', 'enfant', 'partPourMille', v_part.part_enfant_pour_mille),
      pg_catalog.jsonb_build_object('public', 'adulte', 'partPourMille', v_part.part_adulte_pour_mille)));
END;
$function$;

-- La candidature du compte appelant, au compte valide pour un candidat (en
-- attente, provisoire ou actif, non supprime, non expire : L1-08), la plus
-- recente comme private.cand_ma_candidature() ; en cours seulement si demande.
CREATE FUNCTION private.candidature_du_titulaire(p_en_cours boolean)
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT c.id
    FROM public.candidatures c
    JOIN public.profiles p ON p.id = c.profile_id
   WHERE c.profile_id = auth.uid()
     AND p.deleted_at IS NULL
     AND p.account_status IN ('pending_kyc', 'provisional_active', 'active')
     AND (p.access_until IS NULL OR p.access_until > pg_catalog.now())
     AND (NOT coalesce(p_en_cours, false) OR c.issue = 'en_cours')
   ORDER BY c.recue_le DESC, c.id DESC
   LIMIT 1;
$function$;

-- La version courante du questionnaire d'un type.
CREATE FUNCTION private.questionnaire_courant(p_type text)
RETURNS public.candidature_questionnaires
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT q.* FROM public.candidature_questionnaires q WHERE q.type_code = p_type AND q.courant;
$function$;

-- Les fuseaux proposes : les noms IANA de forme Zone/Lieu des grandes zones,
-- jamais un alias (US/..., Etc/..., posix/...).
CREATE FUNCTION private.questionnaire_fuseau_motif()
RETURNS text
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT '^(Africa|America|Antarctica|Arctic|Asia|Atlantic|Australia|Europe|Indian|Pacific)/[A-Za-z0-9_+-]+(/[A-Za-z0-9_+-]+)?$'::text;
$function$;

CREATE FUNCTION private.questionnaire_fuseau_propose(p_nom text)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF p_nom IS NULL OR p_nom !~ private.questionnaire_fuseau_motif() THEN
    RETURN false;
  END IF;
  RETURN EXISTS (SELECT 1 FROM pg_catalog.pg_timezone_names z WHERE z.name = p_nom);
END;
$function$;

-- Les langues proposees : celles du referentiel langues_cours actives (par
-- code), puis les codes ISO 639 hors referentiel de la definition, marques
-- comme tels (spec 9). Un code deja dans le referentiel n'est jamais repete.
CREATE FUNCTION private.questionnaire_langues(p_definition jsonb)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT coalesce(pg_catalog.jsonb_agg(x.o ORDER BY x.groupe, x.rang, x.code), '[]'::jsonb)
  FROM (
    SELECT pg_catalog.jsonb_build_object('code', l.code, 'referentiel', true) AS o,
           0 AS groupe, l.ordre::bigint AS rang, l.code
      FROM public.langues_cours l
     WHERE l.actif
    UNION ALL
    SELECT pg_catalog.jsonb_build_object('code', h.code, 'referentiel', false),
           1, h.rang, h.code
      FROM pg_catalog.jsonb_array_elements_text(
             coalesce(p_definition -> 'languesHorsReferentiel', '[]'::jsonb)) WITH ORDINALITY AS h(code, rang)
     WHERE NOT EXISTS (SELECT 1 FROM public.langues_cours l WHERE l.code = h.code)
  ) x;
$function$;

-- Une valeur est-elle dans la liste fermee d'un champ ? Les operateurs : une
-- ligne mobile money a confirme du pays de versement declare (spec 5.1).
CREATE FUNCTION private.questionnaire_permis(p_definition jsonb, p_champ jsonb, p_valeur text,
                                             p_pays_versement text)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF p_valeur IS NULL THEN
    RETURN false;
  ELSIF p_champ ? 'valeurs' THEN
    RETURN (p_champ -> 'valeurs') ? p_valeur;
  ELSIF p_champ ->> 'liste' = 'langues' THEN
    -- Les codes que le champ exclut (C17) ne sont pas permis, meme saisis a la main.
    RETURN NOT coalesce((p_champ -> 'exclure') ? p_valeur, false)
           AND EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(private.questionnaire_langues(p_definition)) o
                       WHERE o ->> 'code' = p_valeur);
  ELSIF p_champ ->> 'liste' = 'pays' THEN
    RETURN EXISTS (SELECT 1 FROM private.pays_iso_3166 x WHERE x.code = p_valeur);
  ELSIF p_champ ->> 'liste' = 'fuseaux' THEN
    RETURN private.questionnaire_fuseau_propose(p_valeur);
  ELSIF p_champ ->> 'liste' = 'operateurs_confirmes' THEN
    RETURN p_pays_versement IS NOT NULL AND EXISTS (
      SELECT 1 FROM public.referentiel_paiement l
       WHERE l.pays = p_pays_versement AND l.methode = 'mobile_money' AND l.etat = 'confirme'
         AND l.operateur = p_valeur);
  ELSIF p_champ ->> 'liste' = 'moyens_connus' THEN
    -- Tous les moyens connus du catalogue de L6, confirmes ou non, quel que
    -- soit le pays (C17) : un champ informatif, que rien ne lit.
    RETURN EXISTS (SELECT 1 FROM public.referentiel_paiement_operateurs o
                    WHERE o.code = p_valeur AND o.actif);
  END IF;
  RETURN false;
END;
$function$;

-- Les options rendues a l'ecran pour un champ (listes fermees lues au
-- serveur). Les operateurs dependent du pays de versement : l'ecran les lit
-- par options_paiement_confirmees (L6) ; rien ici. Les langues d'un champ
-- sans les codes qu'il exclut (C17). Les moyens connus : code, methode et nom
-- de marque de chaque operateur actif du catalogue, sans aucun pays ni etat.
CREATE FUNCTION private.questionnaire_options(p_definition jsonb, p_champ jsonb)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF p_champ ? 'valeurs' THEN
    RETURN p_champ -> 'valeurs';
  ELSIF p_champ ->> 'liste' = 'langues' THEN
    RETURN (SELECT coalesce(pg_catalog.jsonb_agg(x.o ORDER BY x.rang), '[]'::jsonb)
              FROM pg_catalog.jsonb_array_elements(private.questionnaire_langues(p_definition))
                   WITH ORDINALITY AS x(o, rang)
             WHERE NOT coalesce((p_champ -> 'exclure') ? (x.o ->> 'code'), false));
  ELSIF p_champ ->> 'liste' = 'moyens_connus' THEN
    RETURN (SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                     'code', o.code, 'methode', o.methode, 'nom', o.nom) ORDER BY o.cree_le, o.code), '[]'::jsonb)
              FROM public.referentiel_paiement_operateurs o
             WHERE o.actif);
  ELSIF p_champ ->> 'liste' = 'pays' THEN
    RETURN (SELECT pg_catalog.jsonb_agg(x.code ORDER BY x.rang) FROM private.pays_iso_3166 x);
  ELSIF p_champ ->> 'liste' = 'fuseaux' THEN
    RETURN (SELECT pg_catalog.jsonb_agg(z.name ORDER BY z.name)
              FROM pg_catalog.pg_timezone_names z
             WHERE z.name ~ private.questionnaire_fuseau_motif());
  END IF;
  RETURN NULL;
END;
$function$;

-- Des plages de disponibilite declarees (C18) : une liste de
-- {jour, debut, fin}, jour de 1 (lundi) a 7 (ISO 8601), debut "HH:00" et fin
-- "HH:00" ou "24:00" (bornes en heures ENTIERES : c'est la maille de
-- weekly_availability, que lit l'affectation), fin apres debut (donc au moins
-- une heure par plage), au moins une plage, au plus p_max, sans que deux
-- plages d'un meme jour se chevauchent (deux plages qui se touchent, fin d'une
-- egale au debut de l'autre, ne se chevauchent pas). Aucun fuseau ici : c'est
-- celui du champ fuseauIana, le seul de la grille. Rend 'valide', 'vide',
-- 'chevauchement' (toutes les plages sont bien formees, deux se recouvrent :
-- le refus que l'examen nomme plages_qui_se_chevauchent) ou 'invalide'.
CREATE FUNCTION private.questionnaire_creneaux(p jsonb, p_max integer)
RETURNS text
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_e jsonb;
  v_n integer;
BEGIN
  IF pg_catalog.jsonb_typeof(p) IS DISTINCT FROM 'array' THEN
    RETURN 'invalide';
  END IF;
  v_n := pg_catalog.jsonb_array_length(p);
  IF v_n = 0 THEN
    RETURN 'vide';
  END IF;
  IF v_n > p_max THEN
    RETURN 'invalide';
  END IF;
  FOR v_e IN SELECT e FROM pg_catalog.jsonb_array_elements(p) AS e LOOP
    IF pg_catalog.jsonb_typeof(v_e) IS DISTINCT FROM 'object' THEN
      RETURN 'invalide';
    END IF;
    IF (SELECT pg_catalog.array_agg(k ORDER BY k) FROM pg_catalog.jsonb_object_keys(v_e) k)
       IS DISTINCT FROM ARRAY['debut', 'fin', 'jour']::text[] THEN
      RETURN 'invalide';
    END IF;
    IF pg_catalog.jsonb_typeof(v_e -> 'jour') IS DISTINCT FROM 'number'
       OR (v_e ->> 'jour') NOT IN ('1', '2', '3', '4', '5', '6', '7')
       OR pg_catalog.jsonb_typeof(v_e -> 'debut') IS DISTINCT FROM 'string'
       OR pg_catalog.jsonb_typeof(v_e -> 'fin') IS DISTINCT FROM 'string' THEN
      RETURN 'invalide';
    END IF;
    IF (v_e ->> 'debut') !~ '^([01][0-9]|2[0-3]):00$'
       OR (v_e ->> 'fin') !~ '^(([01][0-9]|2[0-3]):00|24:00)$' THEN
      RETURN 'invalide';
    END IF;
    IF pg_catalog.substr(v_e ->> 'fin', 1, 2)::integer <= pg_catalog.substr(v_e ->> 'debut', 1, 2)::integer THEN
      RETURN 'invalide';
    END IF;
  END LOOP;
  -- Deux plages du meme jour se recouvrent quand chacune commence avant que
  -- l'autre finisse. Une plage identique a une autre se recouvre elle-meme.
  IF EXISTS (
    SELECT 1
      FROM pg_catalog.jsonb_array_elements(p) WITH ORDINALITY AS a(e, i)
      JOIN pg_catalog.jsonb_array_elements(p) WITH ORDINALITY AS b(e, j)
        ON a.i < b.j
       AND a.e -> 'jour' = b.e -> 'jour'
       AND pg_catalog.substr(a.e ->> 'debut', 1, 2)::integer < pg_catalog.substr(b.e ->> 'fin', 1, 2)::integer
       AND pg_catalog.substr(b.e ->> 'debut', 1, 2)::integer < pg_catalog.substr(a.e ->> 'fin', 1, 2)::integer
  ) THEN
    RETURN 'chevauchement';
  END IF;
  RETURN 'valide';
END;
$function$;

-- Examine des reponses contre une definition : les reponses valides
-- (gardees), les champs invalides (valeur hors liste ou mal formee), les
-- champs requis manquants, les cles inconnues. Une valeur nulle vaut absente ;
-- une liste vide d'un champ requis aussi. Quand la cause d'un champ invalide
-- a un nom, il est rendu sous "motifs" (champ -> cause) ; la cle n'est rendue
-- que si elle n'est pas vide. Aujourd'hui, une seule cause nommee :
-- plages_qui_se_chevauchent (disponibilitesDeclarees, C18).
CREATE FUNCTION private.questionnaire_examiner(p_definition jsonb, p_reponses jsonb)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_champ jsonb;
  v_code text;
  v_type text;
  v_requis boolean;
  v_min integer;
  v_max integer;
  v_v jsonb;
  v_n integer;
  v_etat text;
  v_pays text;
  v_valides jsonb := '{}'::jsonb;
  v_motifs jsonb := '{}'::jsonb;
  v_invalides text[] := ARRAY[]::text[];
  v_manquants text[] := ARRAY[]::text[];
  v_inconnus text[];
BEGIN
  IF p_definition IS NULL OR p_reponses IS NULL OR pg_catalog.jsonb_typeof(p_reponses) <> 'object' THEN
    RAISE EXCEPTION 'reponses attendues : un objet' USING ERRCODE = '22023';
  END IF;
  SELECT coalesce(pg_catalog.array_agg(
           CASE WHEN k ~ '^[A-Za-z][A-Za-z0-9_]{0,59}$' THEN k ELSE '?' END ORDER BY k), ARRAY[]::text[])
    INTO v_inconnus
    FROM pg_catalog.jsonb_object_keys(p_reponses) k
   WHERE NOT EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(p_definition -> 'champs') c
                      WHERE c ->> 'code' = k);
  -- Le pays de versement declare, dont depend la liste des operateurs.
  IF pg_catalog.jsonb_typeof(p_reponses -> 'paysVersement') = 'string'
     AND EXISTS (SELECT 1 FROM private.pays_iso_3166 x WHERE x.code = p_reponses ->> 'paysVersement') THEN
    v_pays := p_reponses ->> 'paysVersement';
  END IF;
  FOR v_champ IN SELECT c FROM pg_catalog.jsonb_array_elements(p_definition -> 'champs') AS c LOOP
    v_code := v_champ ->> 'code';
    v_type := v_champ ->> 'type';
    v_requis := (v_champ ->> 'requis')::boolean;
    v_min := coalesce((v_champ ->> 'min')::integer, CASE WHEN v_requis THEN 1 ELSE 0 END);
    v_max := coalesce((v_champ ->> 'max')::integer, 999);
    v_v := p_reponses -> v_code;
    v_etat := 'invalide';
    IF v_v IS NULL OR pg_catalog.jsonb_typeof(v_v) = 'null' THEN
      v_etat := 'vide';
    ELSIF v_type = 'booleen' THEN
      IF pg_catalog.jsonb_typeof(v_v) = 'boolean' THEN
        v_etat := 'valide';
      END IF;
    ELSIF v_type = 'choix' THEN
      IF pg_catalog.jsonb_typeof(v_v) = 'string'
         AND private.questionnaire_permis(p_definition, v_champ, v_v #>> '{}', v_pays) THEN
        v_etat := 'valide';
      END IF;
    ELSIF v_type = 'choix_multiple' THEN
      IF pg_catalog.jsonb_typeof(v_v) = 'array' THEN
        v_n := pg_catalog.jsonb_array_length(v_v);
        IF v_n = 0 AND v_min > 0 THEN
          v_etat := 'vide';
        ELSIF v_n BETWEEN v_min AND v_max
              AND NOT EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(v_v) e
                              WHERE pg_catalog.jsonb_typeof(e) <> 'string') THEN
          IF (SELECT pg_catalog.count(DISTINCT e) FROM pg_catalog.jsonb_array_elements(v_v) e) = v_n
             AND NOT EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements_text(v_v) e(x)
                             WHERE NOT private.questionnaire_permis(p_definition, v_champ, e.x, v_pays)) THEN
            v_etat := 'valide';
          END IF;
        END IF;
      END IF;
    ELSIF v_type = 'creneaux' THEN
      v_etat := private.questionnaire_creneaux(v_v, v_max);
      IF v_etat = 'chevauchement' THEN
        v_motifs := v_motifs || pg_catalog.jsonb_build_object(v_code, 'plages_qui_se_chevauchent');
      END IF;
    END IF;
    IF v_etat = 'valide' THEN
      v_valides := v_valides || pg_catalog.jsonb_build_object(v_code, v_v);
    ELSIF v_etat = 'vide' THEN
      IF v_requis THEN
        v_manquants := v_manquants || v_code;
      END IF;
    ELSE
      v_invalides := v_invalides || v_code;
    END IF;
  END LOOP;
  RETURN pg_catalog.jsonb_build_object(
    'reponses', v_valides,
    'invalides', pg_catalog.to_jsonb(v_invalides),
    'manquants', pg_catalog.to_jsonb(v_manquants),
    'inconnus', pg_catalog.to_jsonb(v_inconnus))
    || CASE WHEN v_motifs = '{}'::jsonb THEN '{}'::jsonb
            ELSE pg_catalog.jsonb_build_object('motifs', v_motifs) END;
END;
$function$;

-- Le brouillon ouvert d'une candidature a une version du questionnaire (C7) :
-- le document du candidat le plus recent marque brouillon, ou rien.
CREATE FUNCTION private.questionnaire_brouillon(p_candidature uuid, p_version text)
RETURNS public.candidature_reponses
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT r.*
    FROM public.candidature_reponses r
   WHERE r.candidature_id = p_candidature AND r.source = 'candidat' AND r.brouillon
     AND r.questionnaire_version = p_version
   ORDER BY r.soumis_le DESC, r.id DESC
   LIMIT 1;
$function$;

-- Ecrit les reponses du candidat (C7) : le brouillon ouvert a cette version
-- est mis a jour, sa version plus un ; sinon un document neuf, version 1. A
-- l'envoi, le document perd la marque brouillon et recoit envoye_le. Rend le
-- document ecrit.
CREATE FUNCTION private.questionnaire_ecrire(p_candidature uuid, p_version text, p_reponses jsonb,
                                             p_envoi boolean)
RETURNS public.candidature_reponses
LANGUAGE plpgsql
VOLATILE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_r public.candidature_reponses;
  v_envoi boolean := coalesce(p_envoi, false);
BEGIN
  v_r := private.questionnaire_brouillon(p_candidature, p_version);
  IF v_r.id IS NOT NULL THEN
    UPDATE public.candidature_reponses
       SET reponses = p_reponses,
           soumis_le = pg_catalog.clock_timestamp(),
           version = v_r.version + 1,
           brouillon = NOT v_envoi,
           envoye_le = CASE WHEN v_envoi THEN pg_catalog.clock_timestamp() END
     WHERE id = v_r.id
    RETURNING * INTO v_r;
    RETURN v_r;
  END IF;
  INSERT INTO public.candidature_reponses
    (candidature_id, questionnaire_version, reponses, source, brouillon, envoye_le)
  VALUES (p_candidature, p_version, p_reponses, 'candidat', NOT v_envoi,
          CASE WHEN v_envoi THEN pg_catalog.clock_timestamp() END)
  RETURNING * INTO v_r;
  RETURN v_r;
END;
$function$;

-- Un motif normalise (L2-10) : blancs de tete et de queue retires (espace,
-- tabulation, fins de ligne, espaces Unicode et espace insecable, marque
-- d'ordre des octets) ; un motif fait de blancs vaut absent.
CREATE FUNCTION private.candidature_motif(p_motif text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT nullif(pg_catalog.regexp_replace(p_motif,
    '^[[:space:]\u0085\u00a0\u1680\u180e\u2000-\u200b\u2028\u2029\u202f\u205f\u3000\ufeff]+|[[:space:]\u0085\u00a0\u1680\u180e\u2000-\u200b\u2028\u2029\u202f\u205f\u3000\ufeff]+$',
    '', 'g'), '');
$function$;

-- Un predicat ferme de la table des regles.
CREATE FUNCTION private.candidature_condition(c public.candidatures, p_condition text)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF p_condition IS NULL THEN
    RETURN true;
  ELSIF p_condition = 'restreinte' THEN
    RETURN c.restreinte;
  ELSIF p_condition = 'non_restreinte' THEN
    RETURN NOT c.restreinte;
  ELSIF p_condition = 'indisponible' THEN
    RETURN c.indisponible;
  ELSIF p_condition = 'non_indisponible' THEN
    RETURN NOT c.indisponible;
  ELSIF p_condition = 'paiement_a_verifier' THEN
    RETURN private.paiement_etat(c.id) = 'a_verifier';
  ELSIF p_condition = 'paiement_a_verifier_ou_compatible' THEN
    RETURN private.paiement_etat(c.id) IN ('a_verifier', 'compatible');
  ELSIF p_condition = 'restreinte_paiement_a_verifier' THEN
    RETURN c.restreinte AND c.restriction_cause = 'paiement' AND private.paiement_etat(c.id) = 'a_verifier';
  END IF;
  RETURN false;
END;
$function$;

-- La variante d'un geste qui vaut pour cette candidature (la premiere), ou
-- rien. p_variante restreint a une variante ; p_ignorer_pause sert a nommer la
-- raison d'un refus.
CREATE FUNCTION private.candidature_regle(c public.candidatures, p_geste text, p_categorie text,
                                          p_variante smallint, p_ignorer_pause boolean)
RETURNS private.candidature_gestes_regles
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT r.*
    FROM private.candidature_gestes_regles r
   WHERE r.geste = p_geste
     AND (p_variante IS NULL OR r.variante = p_variante)
     AND p_categorie = ANY (r.auteurs)
     AND c.etape = ANY (r.etapes)
     AND (r.etats IS NULL OR c.etat = ANY (r.etats))
     AND c.issue = ANY (r.issues)
     AND (p_ignorer_pause
          OR CASE r.pause WHEN 'interdite' THEN NOT c.en_pause
                          WHEN 'requise' THEN c.en_pause
                          ELSE true END)
     AND private.candidature_condition(c, r.condition)
   ORDER BY r.variante
   LIMIT 1;
$function$;

-- La cle d'idempotence (C3), sous verrou consultatif pris par l'appelant :
-- nulle si neuve ; {rejoue: premier resultat} si c'est le meme geste ;
-- {erreur: cle_idempotence_reutilisee} sinon. La derniere cle de brouillon
-- d'une candidature compte aussi (C7) : son auteur est le titulaire.
CREATE FUNCTION private.candidature_idempotence_lue(p_cle text, p_candidature uuid, p_geste text,
                                                    p_auteur uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_g public.candidature_gestes;
  v_b public.candidature_brouillon_cles;
BEGIN
  SELECT g.* INTO v_g FROM public.candidature_gestes g WHERE g.cle = p_cle;
  IF v_g.cle IS NOT NULL THEN
    IF v_g.candidature_id = p_candidature AND v_g.geste = p_geste
       AND v_g.auteur_id IS NOT DISTINCT FROM p_auteur THEN
      RETURN pg_catalog.jsonb_build_object('rejoue', v_g.resultat || '{"rejoue": true}'::jsonb);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', 'cle_idempotence_reutilisee');
  END IF;
  SELECT b.* INTO v_b FROM public.candidature_brouillon_cles b WHERE b.cle = p_cle;
  IF v_b.cle IS NOT NULL THEN
    IF v_b.candidature_id = p_candidature AND EXISTS (
         SELECT 1 FROM private.candidature_gestes_regles r WHERE r.geste = p_geste AND r.brouillon)
       AND EXISTS (SELECT 1 FROM public.candidatures c
                    WHERE c.id = p_candidature AND c.profile_id IS NOT DISTINCT FROM p_auteur) THEN
      RETURN pg_catalog.jsonb_build_object('rejoue', v_b.resultat || '{"rejoue": true}'::jsonb);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', 'cle_idempotence_reutilisee');
  END IF;
  RETURN NULL;
END;
$function$;

-- Moteur, premier temps (C2) : tout ce qui se verifie avant d'ecrire. Rend
-- {ok, transition, variante}, {rejoue: premier resultat} ou {erreur: ...}.
-- Leve 22023 pour un argument invalide et 42501 pour un auteur qui n'est pas
-- la session. Seule une tentative hors portee ecrit (sa trace). Pour le
-- brouillon (C7), la version attendue est celle du document : la RPC la
-- compare apres le questionnaire, sous le verrou pris ici.
CREATE FUNCTION private.candidature_geste_ouvrir(
  p_candidature uuid,
  p_geste text,
  p_categorie text,
  p_auteur uuid,
  p_version_attendue integer,
  p_cle text,
  p_motif text DEFAULT NULL,
  p_modele text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_c public.candidatures;
  v_lecteur uuid;
  v_genre public.gender;
  v_idem jsonb;
  v_r private.candidature_gestes_regles;
  v_motif text := private.candidature_motif(p_motif);
  v_brouillon boolean;
BEGIN
  IF p_candidature IS NULL OR p_geste IS NULL OR p_categorie IS NULL OR p_version_attendue IS NULL
     OR p_cle IS NULL OR p_categorie NOT IN ('candidat', 'direction', 'systeme') THEN
    RAISE EXCEPTION 'geste invalide : candidature, geste, auteur, version attendue et cle attendus'
      USING ERRCODE = '22023';
  END IF;
  IF pg_catalog.length(p_cle) NOT BETWEEN 8 AND 200 THEN
    RAISE EXCEPTION 'cle d''idempotence invalide : 8 a 200 signes' USING ERRCODE = '22023';
  END IF;
  SELECT pg_catalog.bool_or(r.brouillon) INTO v_brouillon
    FROM private.candidature_gestes_regles r
   WHERE r.geste = p_geste AND p_categorie = ANY (r.auteurs);
  IF v_brouillon IS NULL THEN
    RAISE EXCEPTION 'geste inconnu ou auteur non admis : %', p_geste USING ERRCODE = '22023';
  END IF;
  IF pg_catalog.length(v_motif) > 2000 THEN
    RAISE EXCEPTION 'motif trop long : 2000 signes au plus' USING ERRCODE = '22023';
  END IF;
  IF p_modele IS NOT NULL AND p_modele !~ '^[a-z][a-z0-9_]{1,59}$' THEN
    RAISE EXCEPTION 'modele de message invalide : une cle attendue' USING ERRCODE = '22023';
  END IF;

  -- L'auteur : la session elle-meme ; pour la direction, active et de genre
  -- connu (C4) ; le systeme n'a pas d'auteur.
  IF p_categorie = 'systeme' THEN
    IF p_auteur IS NOT NULL THEN
      RAISE EXCEPTION 'un geste du systeme n''a pas d''auteur' USING ERRCODE = '22023';
    END IF;
  ELSIF NOT coalesce(p_auteur = auth.uid(), false) THEN
    RAISE EXCEPTION 'auteur du geste different de la session' USING ERRCODE = '42501';
  END IF;
  IF p_categorie = 'direction' THEN
    SELECT l.profile_id, l.genre INTO v_lecteur, v_genre FROM private.cand_lecteur() l;
    IF v_lecteur IS NULL THEN
      RAISE EXCEPTION 'gestes des candidatures reserves a la direction active' USING ERRCODE = '42501';
    END IF;
    IF v_genre IS NULL THEN
      RAISE EXCEPTION 'genre du lecteur inconnu : aucun geste tant qu''il n''est pas renseigne'
        USING ERRCODE = '42501';
    END IF;
  END IF;

  -- La cle, puis la ligne : deux appels concurrents se suivent.
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('candidature_geste:' || p_cle, 0));
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = p_candidature FOR UPDATE;
  IF v_c.id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'absente');
  END IF;
  IF p_categorie = 'direction' AND v_c.genre IS DISTINCT FROM v_genre THEN
    RETURN private.cand_hors_portee(v_c.id, v_lecteur, 'geste:' || p_geste);
  END IF;
  IF p_categorie = 'candidat' AND v_c.profile_id IS DISTINCT FROM p_auteur THEN
    RAISE EXCEPTION 'candidature d''un autre compte' USING ERRCODE = '42501';
  END IF;

  v_idem := private.candidature_idempotence_lue(p_cle, v_c.id, p_geste, p_auteur);
  IF v_idem IS NOT NULL THEN
    RETURN v_idem;
  END IF;
  IF NOT v_brouillon AND v_c.version <> p_version_attendue THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'conflit_candidature', 'versionCourante', v_c.version);
  END IF;

  v_r := private.candidature_regle(v_c, p_geste, p_categorie, NULL, false);
  IF v_r.geste IS NULL THEN
    RETURN pg_catalog.jsonb_build_object(
      'erreur', 'transition_interdite',
      'geste', p_geste,
      'etape', v_c.etape,
      'etat', v_c.etat,
      'issue', v_c.issue,
      'enPause', v_c.en_pause,
      'raison', CASE WHEN (private.candidature_regle(v_c, p_geste, p_categorie, NULL, true)).geste IS NOT NULL
                     THEN 'pause' ELSE 'etat' END);
  END IF;
  IF p_categorie = ANY (v_r.motif_requis) AND v_motif IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'motif_requis', 'geste', p_geste);
  END IF;
  IF v_r.modele_vers IS NOT NULL AND p_modele IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'modele_requis', 'geste', p_geste);
  END IF;
  RETURN pg_catalog.jsonb_build_object('ok', true, 'transition', v_r.transition, 'variante', v_r.variante);
END;
$function$;

-- Moteur, second temps : ecrit le nouvel etat (cible de la regle, modele, et
-- changements que la regle admet, C16), la version, la derniere activite,
-- puis, pour une transition, l'evenement (motif interne au serveur seulement,
-- changements avant et apres) et l'entree d'audit (sans motif ; sa lecture
-- est bornee par genre, C15). Le brouillon (C7) ne touche que la derniere
-- activite : ni version, ni evenement, ni audit. Leve P0001 si la regle ne
-- vaut plus : l'appelant a saute le premier temps.
CREATE FUNCTION private.candidature_geste_appliquer(
  p_candidature uuid,
  p_geste text,
  p_variante smallint,
  p_categorie text,
  p_auteur uuid,
  p_motif text DEFAULT NULL,
  p_modele text DEFAULT NULL,
  p_changements jsonb DEFAULT '{}'::jsonb,
  p_details jsonb DEFAULT '{}'::jsonb
)
RETURNS public.candidatures
LANGUAGE plpgsql
VOLATILE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_r private.candidature_gestes_regles;
  v_avant public.candidatures;
  v_apres public.candidatures;
  v_ch jsonb := coalesce(p_changements, '{}'::jsonb);
  v_details jsonb := coalesce(p_details, '{}'::jsonb);
  v_fautives text;
  v_ev bigint;
  v_motif text := private.candidature_motif(p_motif);
  v_changements jsonb := '{}'::jsonb;
  v_k text;
BEGIN
  IF pg_catalog.jsonb_typeof(v_ch) <> 'object' OR pg_catalog.jsonb_typeof(v_details) <> 'object' THEN
    RAISE EXCEPTION 'changements et details attendus : des objets' USING ERRCODE = '22023';
  END IF;
  SELECT r.* INTO v_r FROM private.candidature_gestes_regles r
   WHERE r.geste = p_geste AND r.variante = p_variante;
  IF v_r.geste IS NULL OR NOT (p_categorie = ANY (v_r.auteurs)) THEN
    RAISE EXCEPTION 'geste inconnu ou auteur non admis : %', p_geste USING ERRCODE = '22023';
  END IF;
  -- Les seules colonnes que la regle de ce geste admet (C16).
  SELECT pg_catalog.string_agg(k, ', ' ORDER BY k) INTO v_fautives
    FROM pg_catalog.jsonb_object_keys(v_ch) k
   WHERE NOT (k = ANY (v_r.admis));
  IF v_fautives IS NOT NULL THEN
    RAISE EXCEPTION 'changement non admis pour ce geste : %', v_fautives USING ERRCODE = '22023';
  END IF;

  SELECT c.* INTO v_avant FROM public.candidatures c WHERE c.id = p_candidature FOR UPDATE;
  IF v_avant.id IS NULL
     OR (private.candidature_regle(v_avant, p_geste, p_categorie, p_variante, false)).geste IS NULL
     OR (p_categorie = ANY (v_r.motif_requis) AND v_motif IS NULL)
     OR (v_r.modele_vers IS NOT NULL AND p_modele IS NULL) THEN
    RAISE EXCEPTION 'CAND-L2A1 : geste % applique hors de sa regle', p_geste USING ERRCODE = 'P0001';
  END IF;

  IF v_r.brouillon THEN
    UPDATE public.candidatures c SET derniere_activite = pg_catalog.clock_timestamp()
     WHERE c.id = p_candidature
    RETURNING c.* INTO v_apres;
    RETURN v_apres;
  END IF;

  -- Un responsable pose : membre actif de la direction, du meme cote que la
  -- candidature (4.2, ligne 28).
  IF v_ch ? 'responsable_id' AND pg_catalog.jsonb_typeof(v_ch -> 'responsable_id') <> 'null'
     AND NOT EXISTS (
       SELECT 1 FROM public.profiles p
        WHERE p.id = (v_ch ->> 'responsable_id')::uuid
          AND p.role = 'admin'::public.app_role
          AND p.deleted_at IS NULL
          AND p.account_status = 'active'::public.account_status
          AND p.gender IS NOT DISTINCT FROM v_avant.genre) THEN
    RAISE EXCEPTION 'responsable hors de la direction active du cote de la candidature' USING ERRCODE = '42501';
  END IF;

  v_ch := v_r.cible || v_ch;
  IF v_r.modele_vers IS NOT NULL THEN
    v_ch := v_ch || pg_catalog.jsonb_build_object(v_r.modele_vers, p_modele);
  END IF;

  UPDATE public.candidatures c SET
    etape = CASE WHEN v_ch ? 'etape' THEN v_ch ->> 'etape' ELSE c.etape END,
    etat = CASE WHEN v_ch ? 'etat' THEN v_ch ->> 'etat' ELSE c.etat END,
    issue = CASE WHEN v_ch ? 'issue' THEN v_ch ->> 'issue' ELSE c.issue END,
    en_pause = CASE WHEN v_ch ? 'en_pause' THEN (v_ch ->> 'en_pause')::boolean ELSE c.en_pause END,
    reprise_le = CASE WHEN v_ch ? 'reprise_le' THEN (v_ch ->> 'reprise_le')::date ELSE c.reprise_le END,
    pause_modele = CASE WHEN v_ch ? 'pause_modele' THEN v_ch ->> 'pause_modele' ELSE c.pause_modele END,
    issue_modele = CASE WHEN v_ch ? 'issue_modele' THEN v_ch ->> 'issue_modele' ELSE c.issue_modele END,
    restreinte = CASE WHEN v_ch ? 'restreinte' THEN (v_ch ->> 'restreinte')::boolean ELSE c.restreinte END,
    restriction_cause = CASE WHEN v_ch ? 'restriction_cause' THEN v_ch ->> 'restriction_cause'
                             ELSE c.restriction_cause END,
    indisponible = CASE WHEN v_ch ? 'indisponible' THEN (v_ch ->> 'indisponible')::boolean
                        ELSE c.indisponible END,
    indisponible_jusqu_au = CASE WHEN v_ch ? 'indisponible_jusqu_au' THEN (v_ch ->> 'indisponible_jusqu_au')::date
                                 ELSE c.indisponible_jusqu_au END,
    responsable_id = CASE WHEN v_ch ? 'responsable_id' THEN (v_ch ->> 'responsable_id')::uuid
                          ELSE c.responsable_id END,
    pays_residence = CASE WHEN v_ch ? 'pays_residence' THEN v_ch ->> 'pays_residence' ELSE c.pays_residence END,
    fuseau_iana = CASE WHEN v_ch ? 'fuseau_iana' THEN v_ch ->> 'fuseau_iana' ELSE c.fuseau_iana END,
    version = c.version + 1,
    derniere_activite = CASE WHEN p_categorie = 'systeme' THEN c.derniere_activite
                             ELSE pg_catalog.clock_timestamp() END
  WHERE c.id = p_candidature
  RETURNING c.* INTO v_apres;

  -- Les changements de l'appelant, avant et apres (C16).
  FOR v_k IN SELECT k FROM pg_catalog.jsonb_object_keys(coalesce(p_changements, '{}'::jsonb)) k ORDER BY k LOOP
    v_changements := v_changements || pg_catalog.jsonb_build_object(v_k, pg_catalog.jsonb_build_object(
      'avant', pg_catalog.to_jsonb(v_avant) -> v_k, 'apres', pg_catalog.to_jsonb(v_apres) -> v_k));
  END LOOP;

  IF v_r.type_evenement IS NOT NULL THEN
    INSERT INTO public.candidature_evenements
      (candidature_id, type, etape_avant, etape_apres, etat_avant, etat_apres, issue_avant, issue_apres,
       auteur_id, motif_interne, details)
    VALUES (p_candidature, v_r.type_evenement, v_avant.etape, v_apres.etape, v_avant.etat, v_apres.etat,
            v_avant.issue, v_apres.issue, p_auteur, v_motif,
            v_details || pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
              'geste', p_geste, 'transition', v_r.transition, 'auteur', p_categorie, 'modele', p_modele))
            || CASE WHEN v_changements = '{}'::jsonb THEN '{}'::jsonb
                    ELSE pg_catalog.jsonb_build_object('changements', v_changements) END)
    RETURNING id INTO v_ev;
    PERFORM public.log_sensitive_access('candidature_geste', 'candidatures', p_candidature::text,
      pg_catalog.jsonb_build_object(
        'geste', p_geste,
        'transition', v_r.transition,
        'auteur', p_categorie,
        'evenement', v_ev,
        'etapeAvant', v_avant.etape, 'etapeApres', v_apres.etape,
        'etatAvant', v_avant.etat, 'etatApres', v_apres.etat,
        'issueAvant', v_avant.issue, 'issueApres', v_apres.issue,
        'version', v_apres.version));
  END IF;
  RETURN v_apres;
END;
$function$;

-- Moteur, dernier temps : garde le resultat sous la cle (C3) et le rend. Le
-- brouillon (C7) ne garde que sa derniere cle, une ligne par candidature.
CREATE FUNCTION private.candidature_geste_conclure(p_cle text, p_candidature uuid, p_geste text,
                                                   p_auteur uuid, p_resultat jsonb)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_resultat jsonb := coalesce(p_resultat, '{}'::jsonb) - 'rejoue';
BEGIN
  IF EXISTS (SELECT 1 FROM private.candidature_gestes_regles r WHERE r.geste = p_geste AND r.brouillon) THEN
    INSERT INTO public.candidature_brouillon_cles AS b (candidature_id, cle, resultat)
    VALUES (p_candidature, p_cle, v_resultat)
    ON CONFLICT (candidature_id) DO UPDATE
      SET cle = excluded.cle, resultat = excluded.resultat, cree_le = pg_catalog.clock_timestamp();
  ELSE
    INSERT INTO public.candidature_gestes (cle, candidature_id, geste, auteur_id, resultat)
    VALUES (p_cle, p_candidature, p_geste, p_auteur, v_resultat);
  END IF;
  RETURN v_resultat || '{"rejoue": false}'::jsonb;
END;
$function$;

-- Le bloc candidature d'etat_dossier() (C12), pour le compte appelant, a
-- partir de la brique de CAND-L1. Jamais un motif interne.
CREATE FUNCTION private.candidature_etat_candidat()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_base jsonb := private.cand_ma_candidature();
  v_c public.candidatures;
  v_q public.candidature_questionnaires;
  v_doc public.candidature_reponses;
  v_ex jsonb;
  v_manquants jsonb := '[]'::jsonb;
  v_perime boolean;
  v_cadre text;
  v_cadre_ok boolean := false;
  v_cond jsonb;
  v_cond_ok boolean := false;
  v_salle_examen boolean;
  v_salle_verification boolean;
  v_bloque text[] := ARRAY[]::text[];
  v_a_completer text[] := ARRAY[]::text[];
  v_demande public.candidature_evenements;
  v_complement jsonb := '[]'::jsonb;
BEGIN
  IF NOT coalesce((v_base ->> 'candidature')::boolean, false) THEN
    RETURN v_base;
  END IF;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.reference = v_base ->> 'reference';
  v_q := private.questionnaire_courant(v_c.type_code);
  SELECT r.* INTO v_doc
    FROM public.candidature_reponses r
   WHERE r.candidature_id = v_c.id AND r.source = 'candidat'
   ORDER BY r.soumis_le DESC, r.id DESC
   LIMIT 1;
  v_perime := v_doc.id IS NOT NULL AND v_doc.questionnaire_version IS DISTINCT FROM v_q.version;
  IF v_q.version IS NOT NULL THEN
    IF v_doc.id IS NOT NULL AND NOT v_perime THEN
      v_ex := private.questionnaire_examiner(v_q.definition, v_doc.reponses);
      v_manquants := (v_ex -> 'manquants') || (v_ex -> 'invalides');
    ELSE
      SELECT coalesce(pg_catalog.jsonb_agg(x.c ->> 'code' ORDER BY x.o), '[]'::jsonb) INTO v_manquants
        FROM pg_catalog.jsonb_array_elements(v_q.definition -> 'champs') WITH ORDINALITY AS x(c, o)
       WHERE (x.c ->> 'requis')::boolean;
    END IF;
  END IF;

  v_cadre := public.cadre_religieux_version_requise();
  IF v_cadre IS NOT NULL THEN
    v_cadre_ok := EXISTS (SELECT 1 FROM public.contract_acceptances a
                           WHERE a.profile_id = v_c.profile_id
                             AND a.contract_kind = 'teacher_religious_framework'
                             AND a.version = v_cadre);
  END IF;
  v_cond := private.conditions_remuneration_applicables();
  IF v_cond IS NOT NULL THEN
    v_cond_ok := EXISTS (SELECT 1 FROM public.contract_acceptances a
                          WHERE a.profile_id = v_c.profile_id
                            AND a.contract_kind = 'teacher_pay_conditions'
                            AND a.version = v_cond ->> 'version');
  END IF;

  v_salle_examen := coalesce(v_c.etape = 'prequalification' AND v_c.etat = 'a_completer'
                             AND v_c.issue = 'en_cours', false);
  v_salle_verification := coalesce(v_c.etape = 'verifications' AND v_c.issue = 'en_cours', false);
  IF NOT v_salle_examen THEN
    v_bloque := v_bloque || 'etat'::text;
  END IF;
  IF v_c.en_pause THEN
    v_bloque := v_bloque || 'pause'::text;
  END IF;
  IF v_q.version IS NULL THEN
    v_bloque := v_bloque || 'questionnaire_absent'::text;
  ELSIF v_perime THEN
    v_bloque := v_bloque || 'questionnaire_perime'::text;
  ELSIF pg_catalog.jsonb_array_length(v_manquants) > 0 THEN
    v_bloque := v_bloque || 'questionnaire_incomplet'::text;
  END IF;
  IF v_cadre IS NULL THEN
    v_bloque := v_bloque || 'cadre_non_publie'::text;
  ELSIF NOT v_cadre_ok THEN
    v_bloque := v_bloque || 'cadre_non_accepte'::text;
  END IF;
  IF v_cond IS NULL THEN
    v_bloque := v_bloque || 'conditions_indisponibles'::text;
  END IF;
  -- Ce qui reste a completer, hors pause : en Salle d'examen, le
  -- questionnaire et le cadre religieux ; en Salle de verification et
  -- d'entretien, le cadre religieux quand une version requise neuve n'est pas
  -- encore acceptee (4.3 : re-acceptee avant la salle 3).
  IF NOT v_c.en_pause THEN
    IF v_salle_examen AND (v_perime OR pg_catalog.jsonb_array_length(v_manquants) > 0) THEN
      v_a_completer := v_a_completer || 'questionnaire'::text;
    END IF;
    IF (v_salle_examen OR v_salle_verification) AND v_cadre IS NOT NULL AND NOT v_cadre_ok THEN
      v_a_completer := v_a_completer || 'cadre_religieux'::text;
    END IF;
  END IF;

  -- Ce que la direction a demande (C12) : les codes de details.aCompleter du
  -- dernier evenement de transition qui en porte (7, 9, 23), tant que l'etape
  -- n'a pas change, que l'issue est en cours et qu'aucun envoi (transition 6)
  -- ne l'a suivi. Jamais un motif.
  SELECT e.* INTO v_demande
    FROM public.candidature_evenements e
   WHERE e.candidature_id = v_c.id AND e.type = 'transition'
     AND pg_catalog.jsonb_typeof(e.details -> 'aCompleter') = 'array'
   ORDER BY e.cree_le DESC, e.id DESC
   LIMIT 1;
  IF v_demande.id IS NOT NULL AND v_c.issue = 'en_cours'
     AND v_c.etape IS NOT DISTINCT FROM v_demande.etape_apres
     AND NOT EXISTS (SELECT 1 FROM public.candidature_evenements e
                      WHERE e.candidature_id = v_c.id AND e.type = 'transition'
                        AND e.details ->> 'transition' = '6'
                        AND (e.cree_le, e.id) > (v_demande.cree_le, v_demande.id)) THEN
    SELECT coalesce(pg_catalog.jsonb_agg(a.x ORDER BY a.o), '[]'::jsonb) INTO v_complement
      FROM pg_catalog.jsonb_array_elements(v_demande.details -> 'aCompleter') WITH ORDINALITY AS a(x, o)
     WHERE pg_catalog.jsonb_typeof(a.x) = 'string' AND (a.x #>> '{}') ~ '^[a-z][a-z0-9_]{1,59}$';
  END IF;

  RETURN v_base || pg_catalog.jsonb_build_object(
    'version', v_c.version,
    'pauseModele', CASE WHEN v_c.en_pause THEN v_c.pause_modele END,
    'refusModele', CASE WHEN v_c.issue = 'refusee' THEN v_c.issue_modele END,
    'questionnaire', pg_catalog.jsonb_build_object(
      'versionCourante', v_q.version,
      'versionReponses', v_doc.questionnaire_version,
      'perime', v_perime,
      'envoyeLe', private.cand_instant(v_doc.envoye_le),
      'manquants', v_manquants),
    'cadreReligieux', pg_catalog.jsonb_build_object('versionRequise', v_cadre, 'accepte', v_cadre_ok),
    'conditionsRemuneration', pg_catalog.jsonb_build_object(
      'disponible', v_cond IS NOT NULL, 'version', v_cond ->> 'version', 'acceptees', v_cond_ok),
    -- La dimension paiement de L6, en direct, sur la declaration envoyee
    -- (C8) : inconnu, a_verifier, compatible ou incompatible, rien d'autre.
    'paiement', private.paiement_etat(v_c.id),
    'aCompleter', pg_catalog.to_jsonb(v_a_completer),
    'complementDemande', v_complement,
    'peutEnvoyer', pg_catalog.cardinality(v_bloque) = 0,
    'envoiBloque', pg_catalog.to_jsonb(v_bloque));
END;
$function$;

-- ============================================================
-- 6. RPC du candidat (PortMaCandidature)
-- ============================================================

-- conditionsRemuneration (CAND-BR-12, C10) : la part de l'enseignant par
-- public, en pour mille, lue en base, jamais un montant (decision du 22/10) ;
-- l'acceptation du candidat pour cette version, s'il l'a donnee.
CREATE FUNCTION public.conditions_remuneration_candidat()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_id uuid := private.candidature_du_titulaire(true);
  v_cond jsonb;
  v_le timestamptz;
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL AND v_id IS NOT NULL, false) THEN
    RAISE EXCEPTION 'conditions de remuneration reservees au titulaire d''une candidature en cours'
      USING ERRCODE = '42501';
  END IF;
  v_cond := private.conditions_remuneration_applicables();
  IF v_cond IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('disponible', false);
  END IF;
  SELECT a.accepted_at INTO v_le
    FROM public.contract_acceptances a
   WHERE a.profile_id = auth.uid() AND a.contract_kind = 'teacher_pay_conditions'
     AND a.version = v_cond ->> 'version';
  RETURN v_cond || pg_catalog.jsonb_build_object('disponible', true, 'accepteesLe', private.cand_instant(v_le));
END;
$function$;

-- questionnaire : la version courante, ses champs et leurs listes fermees, le
-- dernier document du candidat (brouillon ou envoye) pour la reprise, et la
-- version du brouillon ouvert (versionAttendue du brouillon, 0 sans
-- brouillon, C7).
CREATE FUNCTION public.questionnaire_salle_examen()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_id uuid := private.candidature_du_titulaire(true);
  v_c public.candidatures;
  v_q public.candidature_questionnaires;
  v_doc public.candidature_reponses;
  v_brouillon public.candidature_reponses;
  v_champs jsonb;
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL AND v_id IS NOT NULL, false) THEN
    RAISE EXCEPTION 'questionnaire reserve au titulaire d''une candidature en cours' USING ERRCODE = '42501';
  END IF;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = v_id;
  v_q := private.questionnaire_courant(v_c.type_code);
  IF v_q.version IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('disponible', false);
  END IF;
  SELECT coalesce(pg_catalog.jsonb_agg(
           pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
             'code', x.c ->> 'code', 'carte', x.c ->> 'carte', 'type', x.c ->> 'type',
             'requis', x.c -> 'requis', 'min', x.c -> 'min', 'max', x.c -> 'max',
             'dependDe', x.c -> 'dependDe'))
           || pg_catalog.jsonb_build_object('options', private.questionnaire_options(v_q.definition, x.c))
           ORDER BY x.o), '[]'::jsonb)
    INTO v_champs
    FROM pg_catalog.jsonb_array_elements(v_q.definition -> 'champs') WITH ORDINALITY AS x(c, o);
  SELECT r.* INTO v_doc
    FROM public.candidature_reponses r
   WHERE r.candidature_id = v_c.id AND r.source = 'candidat'
   ORDER BY r.soumis_le DESC, r.id DESC
   LIMIT 1;
  v_brouillon := private.questionnaire_brouillon(v_c.id, v_q.version);
  RETURN pg_catalog.jsonb_build_object(
    'disponible', true,
    'version', v_q.version,
    'champs', v_champs,
    'candidatureVersion', v_c.version,
    'versionBrouillon', coalesce(v_brouillon.version, 0),
    'dernieresReponses', CASE WHEN v_doc.id IS NULL THEN NULL ELSE pg_catalog.jsonb_build_object(
      'questionnaireVersion', v_doc.questionnaire_version,
      'reponses', v_doc.reponses,
      'brouillon', v_doc.brouillon,
      'soumisLe', private.cand_instant(v_doc.soumis_le),
      'envoyeLe', private.cand_instant(v_doc.envoye_le),
      'perime', v_doc.questionnaire_version IS DISTINCT FROM v_q.version) END);
END;
$function$;

-- Le brouillon (C7) : reponses partielles permises, jamais une valeur hors
-- liste. versionAttendue est la version du brouillon ouvert (0 sans
-- brouillon) : la version de la candidature ne change pas. Rend la version du
-- brouillon, celle du questionnaire, les champs requis encore manquants et
-- complet ; jamais les reponses (relues par questionnaire_salle_examen()),
-- pour que le resultat garde sous la cle n'en porte aucune.
CREATE FUNCTION public.enregistrer_reponses_salle_examen(
  p_questionnaire_version text,
  p_reponses jsonb,
  p_version_attendue integer,
  p_cle_idempotence text
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_id uuid := private.candidature_du_titulaire(false);
  v_o jsonb;
  v_c public.candidatures;
  v_q public.candidature_questionnaires;
  v_ex jsonb;
  v_brouillon public.candidature_reponses;
  v_doc public.candidature_reponses;
BEGIN
  IF NOT coalesce(v_uid IS NOT NULL AND v_id IS NOT NULL, false) THEN
    RAISE EXCEPTION 'reponses reservees au titulaire d''une candidature' USING ERRCODE = '42501';
  END IF;
  IF p_questionnaire_version IS NULL OR p_reponses IS NULL
     OR pg_catalog.jsonb_typeof(p_reponses) <> 'object' THEN
    RAISE EXCEPTION 'version du questionnaire et reponses (objet) attendues' USING ERRCODE = '22023';
  END IF;
  v_o := private.candidature_geste_ouvrir(v_id, 'enregistrer_reponses', 'candidat', v_uid,
                                          p_version_attendue, p_cle_idempotence);
  IF v_o ? 'rejoue' THEN
    RETURN v_o -> 'rejoue';
  ELSIF v_o ? 'erreur' THEN
    RETURN v_o;
  END IF;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = v_id;
  v_q := private.questionnaire_courant(v_c.type_code);
  IF v_q.version IS NULL OR p_questionnaire_version IS DISTINCT FROM v_q.version THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'questionnaire_perime', 'versionCourante', v_q.version);
  END IF;
  v_brouillon := private.questionnaire_brouillon(v_id, v_q.version);
  IF coalesce(v_brouillon.version, 0) <> p_version_attendue THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'conflit_brouillon',
                                         'versionCourante', coalesce(v_brouillon.version, 0));
  END IF;
  v_ex := private.questionnaire_examiner(v_q.definition, p_reponses);
  IF pg_catalog.jsonb_array_length(v_ex -> 'invalides') > 0 OR pg_catalog.jsonb_array_length(v_ex -> 'inconnus') > 0 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'reponses_invalides',
                                         'champs', (v_ex -> 'invalides') || (v_ex -> 'inconnus'))
           || CASE WHEN v_ex ? 'motifs' THEN pg_catalog.jsonb_build_object('motifs', v_ex -> 'motifs')
                   ELSE '{}'::jsonb END;
  END IF;
  v_doc := private.questionnaire_ecrire(v_id, v_q.version, v_ex -> 'reponses', false);
  PERFORM private.candidature_geste_appliquer(v_id, 'enregistrer_reponses', (v_o ->> 'variante')::smallint,
    'candidat', v_uid);
  RETURN private.candidature_geste_conclure(p_cle_idempotence, v_id, 'enregistrer_reponses', v_uid,
    pg_catalog.jsonb_build_object(
      'versionBrouillon', v_doc.version,
      'questionnaireVersion', v_q.version,
      'manquants', v_ex -> 'manquants',
      'complet', pg_catalog.jsonb_array_length(v_ex -> 'manquants') = 0));
END;
$function$;

-- envoyerReponses, transition 6 (a_completer vers en_examen) : questionnaire
-- complet a la version courante, accord de remuneration aux conditions
-- affichees (version de la politique lue, C11), cadre religieux a la version
-- requise ; puis l'accord de remuneration enregistre (C11), le document
-- envoye, la transition (pays de residence et fuseau recopies, C13), et le
-- recalcul du paiement (C8). Rend le bloc candidature relu d'etat_dossier().
CREATE FUNCTION public.envoyer_reponses_salle_examen(
  p_questionnaire_version text,
  p_reponses jsonb,
  p_accord_remuneration boolean,
  p_version_conditions text,
  p_version_attendue integer,
  p_cle_idempotence text
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_id uuid := private.candidature_du_titulaire(false);
  v_o jsonb;
  v_c public.candidatures;
  v_q public.candidature_questionnaires;
  v_ex jsonb;
  v_cond jsonb;
  v_cadre text;
  v_doc public.candidature_reponses;
BEGIN
  IF NOT coalesce(v_uid IS NOT NULL AND v_id IS NOT NULL, false) THEN
    RAISE EXCEPTION 'envoi reserve au titulaire d''une candidature' USING ERRCODE = '42501';
  END IF;
  IF p_questionnaire_version IS NULL OR p_reponses IS NULL OR p_accord_remuneration IS NULL
     OR p_version_conditions IS NULL OR pg_catalog.jsonb_typeof(p_reponses) <> 'object' THEN
    RAISE EXCEPTION 'version du questionnaire, reponses (objet), accord et version des conditions de remuneration attendus'
      USING ERRCODE = '22023';
  END IF;
  v_o := private.candidature_geste_ouvrir(v_id, 'envoyer_reponses', 'candidat', v_uid,
                                          p_version_attendue, p_cle_idempotence);
  IF v_o ? 'rejoue' THEN
    RETURN v_o -> 'rejoue';
  ELSIF v_o ? 'erreur' THEN
    RETURN v_o;
  END IF;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = v_id;
  v_q := private.questionnaire_courant(v_c.type_code);
  IF v_q.version IS NULL OR p_questionnaire_version IS DISTINCT FROM v_q.version THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'questionnaire_perime', 'versionCourante', v_q.version);
  END IF;
  v_ex := private.questionnaire_examiner(v_q.definition, p_reponses);
  IF pg_catalog.jsonb_array_length(v_ex -> 'invalides') > 0 OR pg_catalog.jsonb_array_length(v_ex -> 'inconnus') > 0 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'reponses_invalides',
                                         'champs', (v_ex -> 'invalides') || (v_ex -> 'inconnus'))
           || CASE WHEN v_ex ? 'motifs' THEN pg_catalog.jsonb_build_object('motifs', v_ex -> 'motifs')
                   ELSE '{}'::jsonb END;
  END IF;
  IF pg_catalog.jsonb_array_length(v_ex -> 'manquants') > 0 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'reponses_incompletes', 'champs', v_ex -> 'manquants');
  END IF;
  IF NOT p_accord_remuneration THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'accord_remuneration_requis');
  END IF;
  v_cond := private.conditions_remuneration_applicables();
  IF v_cond IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'conditions_indisponibles');
  END IF;
  -- L'accord vaut pour les conditions affichees au candidat, jamais pour une
  -- politique publiee depuis (C11).
  IF p_version_conditions IS DISTINCT FROM v_cond ->> 'version' THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'conditions_perimees', 'versionCourante', v_cond ->> 'version');
  END IF;
  v_cadre := public.cadre_religieux_version_requise();
  IF v_cadre IS NULL OR NOT EXISTS (
       SELECT 1 FROM public.contract_acceptances a
        WHERE a.profile_id = v_uid AND a.contract_kind = 'teacher_religious_framework'
          AND a.version = v_cadre) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'engagement_non_accepte',
                                         'versionRequise', v_cadre, 'publie', v_cadre IS NOT NULL);
  END IF;

  INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
  VALUES (v_uid, 'teacher_pay_conditions', v_cond ->> 'version')
  ON CONFLICT (profile_id, contract_kind, version) DO NOTHING;
  v_doc := private.questionnaire_ecrire(v_id, v_q.version,
    (v_ex -> 'reponses') || pg_catalog.jsonb_build_object('accordRemuneration', true), true);
  PERFORM private.candidature_geste_appliquer(v_id, 'envoyer_reponses', (v_o ->> 'variante')::smallint,
    'candidat', v_uid, NULL, NULL,
    pg_catalog.jsonb_build_object('pays_residence', v_ex #>> '{reponses,paysResidence}',
                                  'fuseau_iana', v_ex #>> '{reponses,fuseauIana}'),
    pg_catalog.jsonb_build_object('questionnaireVersion', v_q.version, 'reponsesId', v_doc.id,
                                  'conditionsRemuneration', v_cond ->> 'version', 'cadreReligieux', v_cadre));
  PERFORM private.paiement_recalculer(v_id, 'reponses');
  RETURN private.candidature_geste_conclure(p_cle_idempotence, v_id, 'envoyer_reponses', v_uid,
    pg_catalog.jsonb_build_object('candidature', public.etat_dossier() -> 'candidature'));
END;
$function$;

-- retirer, transition 17 par le candidat (CAND-03) : depuis toute etape en
-- cours avant la salle 3, pause comprise (C5) ; canal application et date
-- traces ; un entretien planifie est seulement note (L4 l'annulera) ;
-- marqueur aNotifier pour L5. Rend le bloc candidature relu.
CREATE FUNCTION public.retrait_candidat(p_version_attendue integer, p_cle_idempotence text)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_id uuid := private.candidature_du_titulaire(false);
  v_o jsonb;
  v_c public.candidatures;
BEGIN
  IF NOT coalesce(v_uid IS NOT NULL AND v_id IS NOT NULL, false) THEN
    RAISE EXCEPTION 'retrait reserve au titulaire d''une candidature' USING ERRCODE = '42501';
  END IF;
  v_o := private.candidature_geste_ouvrir(v_id, 'retirer', 'candidat', v_uid,
                                          p_version_attendue, p_cle_idempotence);
  IF v_o ? 'rejoue' THEN
    RETURN v_o -> 'rejoue';
  ELSIF v_o ? 'erreur' THEN
    RETURN v_o;
  END IF;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = v_id;
  PERFORM private.candidature_geste_appliquer(v_id, 'retirer', (v_o ->> 'variante')::smallint,
    'candidat', v_uid, NULL, NULL, '{}'::jsonb,
    pg_catalog.jsonb_build_object(
      'canal', 'application',
      'entretienPlanifie', v_c.etat IS NOT DISTINCT FROM 'entretien_planifie',
      'pauseLevee', v_c.en_pause,
      'aNotifier', 'retrait_enregistre'));
  RETURN private.candidature_geste_conclure(p_cle_idempotence, v_id, 'retirer', v_uid,
    pg_catalog.jsonb_build_object('candidature', public.etat_dossier() -> 'candidature'));
END;
$function$;

-- ============================================================
-- 7. etat_dossier() : corps de 20261021210400 recopie, plus la candidature
-- ============================================================

CREATE OR REPLACE FUNCTION public.etat_dossier()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_profile public.profiles;
  v_doc public.kyc_documents;
  v_contrat boolean;
  v_accuse boolean;
  v_conduite boolean;
  v_usage text;
  v_suit boolean;
  v_candidature jsonb;
begin
  if auth.uid() is null then
    raise exception 'aucune session';
  end if;

  select * into v_profile
  from public.profiles p where p.id = auth.uid() and p.deleted_at is null;

  -- Aucun profil : c'est une inscription a terminer, pas un dossier a attendre.
  if v_profile.id is null then
    return jsonb_build_object('profil', false);
  end if;

  select * into v_doc
  from public.kyc_documents k
  where k.profile_id = v_profile.id and k.deleted_at is null
  order by k.created_at desc
  limit 1;

  select exists (
    select 1 from public.contract_acceptances c
    where c.profile_id = v_profile.id
      and c.contract_kind = case when v_profile.role = 'teacher'
                                 then 'teacher_nda' else 'guardian_terms' end
  ) into v_contrat;

  select exists (
    select 1 from public.contract_acceptances c
    where c.profile_id = v_profile.id
      and c.contract_kind = 'recording_and_control_notice'
  ) into v_accuse;

  -- CAND-Q15 conduite : le code de conduite n'est demande qu'a l'enseignant,
  -- a la version requise (la meme regle que la garde d'activation).
  select v_profile.role is distinct from 'teacher'::public.app_role or exists (
    select 1 from public.contract_acceptances c
    join public.contract_required_versions r
      on r.contract_kind = c.contract_kind and r.version = c.version
    where c.profile_id = v_profile.id
      and c.contract_kind = 'teacher_conduct_code'
  ) into v_conduite;

  -- L5-01 : l'usage choisi a l'inscription, et la fiche d'eleve du titulaire.
  select h.usage_inscription into v_usage
  from public.households h
  where h.id = v_profile.household_id and h.primary_guardian_id = v_profile.id;

  select exists (
    select 1 from public.student_profiles s
    where s.profile_id = v_profile.id
  ) into v_suit;

  -- CAND-L2A1 : l'etat de la candidature du compte, s'il en porte une (C12) ;
  -- jamais un motif interne.
  v_candidature := private.candidature_etat_candidat();

  return jsonb_build_object(
    'profil', true,
    'role', v_profile.role::text,
    'statut', v_profile.account_status::text,
    'piece_deposee', v_doc.id is not null,
    'piece_statut', v_doc.status::text,
    'motif_refus', v_doc.rejection_reason,
    'depose_le', v_doc.created_at,
    'contrat_signe', v_contrat,
    'accuse_signe', v_accuse,
    'code_conduite_signe', v_conduite,
    'usage', v_usage,
    'suit_des_cours', v_suit,
    'candidature', v_candidature
  );
end;
$function$;

-- ============================================================
-- 7 bis. Declaration de paiement de L6 : documents envoyes seulement (C8)
-- ============================================================

-- Corps de 20261021220100_cand_l6_referentiel_paiement.sql recopie ; seul
-- ajout, un brouillon (C7) n'est jamais la declaration. Un document ecrit
-- sans la marque (lot L6, import a venir) le reste.
CREATE OR REPLACE FUNCTION private.paiement_declaration(p_candidature uuid)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT CASE
    WHEN d.reponses ->> 'paysVersement' ~ '^[A-Z]{2}$'
         AND pg_catalog.jsonb_typeof(d.reponses -> 'compteBancaire') = 'boolean'
    THEN pg_catalog.jsonb_build_object(
      'paysVersement', d.reponses ->> 'paysVersement',
      'compteBancaire', (d.reponses ->> 'compteBancaire')::boolean,
      'operateurs', coalesce((
        SELECT pg_catalog.jsonb_agg(DISTINCT o.code ORDER BY o.code)
        FROM pg_catalog.jsonb_array_elements_text(
               CASE WHEN pg_catalog.jsonb_typeof(d.reponses -> 'operateurs') = 'array'
                    THEN d.reponses -> 'operateurs' ELSE '[]'::jsonb END) AS o(code)
        WHERE o.code ~ '^[a-z][a-z0-9_]{1,39}$'), '[]'::jsonb))
  END
  FROM (SELECT (SELECT r.reponses FROM public.candidature_reponses r
                WHERE r.candidature_id = p_candidature AND r.source = 'candidat'
                  AND NOT r.brouillon
                ORDER BY r.soumis_le DESC, r.id DESC
                LIMIT 1) AS reponses) d;
$function$;

-- ============================================================
-- 7 ter. Journal d'audit borne par genre (C15)
-- ============================================================

-- Le cote d'une ligne d'audit (female, male, deux, ou nul : aucun cote) et,
-- pour un auteur porteur d'une candidature avant la salle 3, la reference de
-- cette candidature, a rendre a la place de son nom (8.3). Voir C15. Lu ligne
-- a ligne par la policy d'audit_logs et par journal_audit ;
-- private.audit_logs_cotes en est la forme ensembliste.
CREATE FUNCTION private.journal_portee(p_table text, p_ligne text, p_acteur uuid, p_details jsonb,
                                       OUT cote text, OUT reference_acteur text)
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_genre_acteur text;
BEGIN
  IF p_acteur IS NOT NULL THEN
    SELECT c.genre::text, c.reference INTO v_genre_acteur, reference_acteur
      FROM public.candidatures c
     WHERE c.profile_id = p_acteur AND c.etape <> 'confirmee'
     ORDER BY c.recue_le DESC, c.id DESC
     LIMIT 1;
  END IF;
  -- Une ligne qui vise une candidature : son cote.
  IF p_table IN ('candidatures', 'candidature_contacts')
     AND p_ligne ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
    SELECT c.genre::text INTO cote FROM public.candidatures c WHERE c.id = p_ligne::uuid;
    IF cote IS NOT NULL THEN
      RETURN;
    END IF;
  END IF;
  -- Une ligne ecrite par un porteur de candidature avant la salle 3 : son cote.
  IF v_genre_acteur IS NOT NULL THEN
    cote := v_genre_acteur;
    RETURN;
  END IF;
  -- Une lecture de liste de CAND-L1 : le cote du lecteur, les deux sous
  -- l'exception super-admin.
  IF p_table = 'candidatures' AND p_ligne IS NULL THEN
    cote := CASE WHEN p_details ->> 'exception_active' = 'true' THEN 'deux'
                 ELSE coalesce(p_details ->> 'reader_gender', 'deux') END;
    RETURN;
  END IF;
  -- Une trace de l'exception super-admin sans candidature compte des lignes
  -- de l'autre cote.
  IF p_details ->> 'motif' = 'exception_super_admin_kyc' THEN
    cote := 'deux';
  END IF;
END;
$function$;

-- La meme regle, ensembliste, pour les comptes de journal_audit_filtres
-- (C15) : chaque ligne d'audit_logs et son cote, sans un appel de fonction
-- par ligne (une jointure de hachage sur les candidatures, un parcours du
-- journal). journal_audit, qui s'arrete a sa page, et la policy lisent
-- private.journal_portee ligne a ligne ; le scenario prouve que les deux
-- formes rendent, ligne par ligne, le meme cote et la meme reference.
CREATE VIEW private.audit_logs_cotes AS
WITH cand AS (
  SELECT c.id::text AS ligne, c.genre::text AS cote
    FROM public.candidatures c
), porteurs AS (
  SELECT DISTINCT ON (c.profile_id) c.profile_id, c.genre::text AS cote, c.reference
    FROM public.candidatures c
   WHERE c.profile_id IS NOT NULL AND c.etape <> 'confirmee'
   ORDER BY c.profile_id, c.recue_le DESC, c.id DESC
)
SELECT a.id, a.created_at, a.actor, a.actor_role, a.action, a.table_name, a.row_id, a.payload,
       coalesce(
         cv.cote,
         po.cote,
         CASE WHEN a.table_name = 'candidatures' AND a.row_id IS NULL THEN
           CASE WHEN a.payload ->> 'exception_active' = 'true' THEN 'deux'
                ELSE coalesce(a.payload ->> 'reader_gender', 'deux') END END,
         CASE WHEN a.payload ->> 'motif' = 'exception_super_admin_kyc' THEN 'deux' END) AS cote,
       po.reference AS reference_acteur
  FROM public.audit_logs a
  LEFT JOIN cand cv ON a.table_name IN ('candidatures', 'candidature_contacts') AND cv.ligne = a.row_id
  LEFT JOIN porteurs po ON po.profile_id = a.actor;
COMMENT ON VIEW private.audit_logs_cotes IS
  'CAND-L2A1 : chaque ligne d audit_logs et son cote (female, male, deux ou nul), avec la reference '
  'CAND- de son auteur porteur de candidature avant la salle 3 (C15) ; lue par journal_audit_filtres ; '
  'aucun compte ne la lit.';

-- Lecture directe d'audit_logs (C15) : une ligne a cote ne se lit que de ce
-- cote, sans l'exception super-admin (une lecture directe ne se journalise
-- pas ; l'exception passe par journal_audit()). Hors de la direction, rien
-- (audit_logs_read ne s'ouvre qu'a elle). Dans app_private, non expose, pour
-- qu'une policy l'appelle (motif de app_private.compte_candidat_hors_portee).
CREATE FUNCTION app_private.audit_ligne_dans_portee(p_table text, p_ligne text, p_acteur uuid,
                                                    p_details jsonb)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_cote text;
BEGIN
  IF coalesce(public.app_role() = 'admin'::public.app_role, false) THEN
    v_cote := (private.journal_portee(p_table, p_ligne, p_acteur, p_details)).cote;
    RETURN v_cote IS NULL OR coalesce(v_cote = (SELECT p.gender::text FROM public.profiles p
                                                 WHERE p.id = auth.uid() AND p.deleted_at IS NULL), false);
  END IF;
  RETURN false;
END;
$function$;

CREATE POLICY audit_logs_portee_candidatures
  ON public.audit_logs
  AS RESTRICTIVE
  FOR SELECT TO authenticated
  USING (coalesce(app_private.audit_ligne_dans_portee(table_name, row_id, actor, payload), false));
COMMENT ON POLICY audit_logs_portee_candidatures ON public.audit_logs IS
  'CAND-L2A1 : une ligne d audit qui vise une candidature, ou ecrite par un porteur de candidature avant '
  'la salle 3, ne se lit que du cote de la candidature (CAND-Q07, C15) ; restrictive, sans l exception '
  'super-admin, qui passe par journal_audit() et s y journalise.';

-- journal_audit() : corps de 0016_masquage_coherent_en_observation.sql
-- recopie (garde, bornes, curseur, masquage, jointure sans filtre de
-- cloture) ; ajouts de C15 : les seules lignes du cote du lecteur, la
-- reference CAND- a la place du nom d'un porteur de candidature avant la
-- salle 3, la trace de l'exception super-admin quand elle rend des lignes de
-- l'autre cote.
CREATE OR REPLACE FUNCTION public.journal_audit(p_acteur uuid DEFAULT NULL::uuid, p_action text DEFAULT NULL::text, p_depuis timestamp with time zone DEFAULT NULL::timestamp with time zone, p_limite integer DEFAULT 50, p_avant_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_avant_id bigint DEFAULT NULL::bigint)
 RETURNS TABLE(entree_id bigint, survenu_le timestamp with time zone, acteur uuid, role_acteur text, nom_acteur text, type_evenement text, table_visee text, ligne_visee text, details jsonb)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_masque boolean := public.agent_identite_masquee();
  v_genre text;
  v_super boolean;
  v_autre_cote integer := 0;
  r record;
begin
  if NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) then
    raise exception 'journal d''audit reserve a l''administration';
  end if;

  if p_limite < 1 or p_limite > 200 then
    raise exception 'limite hors bornes';
  end if;

  if (p_avant_date is null) <> (p_avant_id is null) then
    raise exception 'curseur incomplet';
  end if;

  -- CAND-L2A1 (C15) : le cote du lecteur ; un genre inconnu ne lit aucune
  -- ligne qui a un cote ; le super-admin lit les deux, journalise.
  select p.gender::text into v_genre
  from public.profiles p where p.id = auth.uid() and p.deleted_at is null;
  v_super := coalesce(public.kyc_super_admin_exception_active(), false);

  for r in
    select
      a.id, a.created_at, a.actor, a.actor_role, a.action, a.table_name, a.row_id, a.payload,
      p.immutable_id, p.first_name, p.last_name, j.cote, j.reference_acteur
    from public.audit_logs a
    left join public.profiles p on p.id = a.actor
    cross join lateral private.journal_portee(a.table_name, a.row_id, a.actor, a.payload) j
    where (p_acteur is null or a.actor = p_acteur)
      and (p_action is null or a.action = p_action)
      and (p_depuis is null or a.created_at >= p_depuis)
      and (
        p_avant_date is null
        or (a.created_at, a.id) < (p_avant_date, p_avant_id)
      )
      and (j.cote is null or v_super or j.cote = v_genre)
    order by a.created_at desc, a.id desc
    limit p_limite
  loop
    if r.cote is not null and r.cote is distinct from v_genre then
      v_autre_cote := v_autre_cote + 1;
    end if;
    entree_id := r.id;
    survenu_le := r.created_at;
    acteur := r.actor;
    role_acteur := r.actor_role;
    nom_acteur := case
      when r.reference_acteur is not null then r.reference_acteur
      when v_masque then r.immutable_id
      else coalesce(
        nullif(trim(coalesce(r.first_name, '') || ' ' || coalesce(r.last_name, '')), ''),
        r.immutable_id
      )
    end;
    type_evenement := r.action;
    table_visee := r.table_name;
    ligne_visee := r.row_id;
    details := r.payload;
    return next;
  end loop;

  if v_autre_cote > 0 then
    perform public.log_sensitive_access('candidature_exception_super_admin', 'audit_logs', null,
      jsonb_build_object('lecture', 'journal_audit', 'lignesAutreCote', v_autre_cote,
                         'motif', 'exception_super_admin_kyc'));
  end if;
  return;
end;
$function$;

-- journal_audit_filtres() : corps de 0015_administration_voit_les_personnes.sql
-- recopie (masquage, repli sur l'identifiant immuable) ; ajouts de C15 :
-- totaux, actions et acteurs comptes sur les seules lignes du cote du
-- lecteur, reference CAND- d'un porteur de candidature, trace de l'exception.
CREATE OR REPLACE FUNCTION public.journal_audit_filtres()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_resultat jsonb;
  v_masque boolean := public.agent_identite_masquee();
  v_genre text;
  v_super boolean;
  v_autre_cote integer;
begin
  if NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) then
    raise exception 'journal d''audit reserve a l''administration';
  end if;

  -- CAND-L2A1 (C15) : la meme portee que journal_audit().
  select p.gender::text into v_genre
  from public.profiles p where p.id = auth.uid() and p.deleted_at is null;
  v_super := coalesce(public.kyc_super_admin_exception_active(), false);

  with lignes as (
    select a.id, a.created_at, a.actor, a.actor_role, a.action, a.cote, a.reference_acteur
    from private.audit_logs_cotes a
    where a.cote is null or v_super or a.cote = v_genre
  )
  select jsonb_build_object(
    'total', (select count(*) from lignes),
    'premiere', (select min(x.created_at) from lignes x),
    'actions', coalesce((
      select jsonb_agg(
        jsonb_build_object('action', t.action, 'n', t.n)
        order by t.n desc, t.action asc
      )
      from (
        select a.action, count(*) as n
        from lignes a
        group by a.action
      ) t
    ), '[]'::jsonb),
    'acteurs', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', u.actor,
          'nom', u.nom,
          'identifiant', u.identifiant,
          'role', u.role,
          'n', u.n
        )
        order by u.n desc, u.nom asc
      )
      from (
        select
          a.actor,
          count(*) as n,
          (array_agg(a.actor_role order by a.created_at desc, a.id desc))[1] as role,
          max(p.immutable_id) as identifiant,
          -- Deux corrections d'un coup : le masquage, qui n'etait applique
          -- nulle part sur cet ecran malgre la banniere "prenoms masques" ;
          -- et le repli sur l'identifiant immuable, faute de quoi deux
          -- personnes portant le meme nom produisaient deux filtres
          -- visuellement identiques. CAND-L2A1 : un porteur de candidature
          -- avant la salle 3 est nomme par sa reference (8.3).
          case
            when max(a.reference_acteur) is not null then max(a.reference_acteur)
            when v_masque then coalesce(max(p.immutable_id), a.actor::text)
            else coalesce(
              nullif(trim(coalesce(max(p.first_name), '') || ' ' || coalesce(max(p.last_name), '')), ''),
              max(p.immutable_id),
              a.actor::text
            )
          end as nom
        from lignes a
        left join public.profiles p on p.id = a.actor
        where a.actor is not null
        group by a.actor
      ) u
    ), '[]'::jsonb)
  ),
  (select count(*) from lignes x where x.cote is not null and x.cote is distinct from v_genre)
  into v_resultat, v_autre_cote;

  if v_autre_cote > 0 then
    perform public.log_sensitive_access('candidature_exception_super_admin', 'audit_logs', null,
      jsonb_build_object('lecture', 'journal_audit_filtres', 'lignesAutreCote', v_autre_cote,
                         'motif', 'exception_super_admin_kyc'));
  end if;

  return v_resultat;
end;
$function$;

-- ============================================================
-- 8. Droits, empreintes F86, controle final
-- ============================================================

REVOKE ALL ON public.candidature_questionnaires, public.candidature_gestes, public.candidature_brouillon_cles,
  public.politique_part_enseignant, private.pays_iso_3166, private.candidature_gestes_regles
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
ALTER TABLE public.candidature_questionnaires ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.candidature_gestes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.candidature_brouillon_cles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.politique_part_enseignant ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.pays_iso_3166 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.candidature_gestes_regles ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON FUNCTION
  private.questionnaire_definition_valide(jsonb),
  private.questionnaire_immuable(),
  private.politique_part_version_publiee(),
  private.conditions_remuneration_applicables(),
  private.candidature_du_titulaire(boolean),
  private.questionnaire_courant(text),
  private.questionnaire_fuseau_motif(),
  private.questionnaire_fuseau_propose(text),
  private.questionnaire_langues(jsonb),
  private.questionnaire_permis(jsonb, jsonb, text, text),
  private.questionnaire_options(jsonb, jsonb),
  private.questionnaire_creneaux(jsonb, integer),
  private.questionnaire_examiner(jsonb, jsonb),
  private.questionnaire_brouillon(uuid, text),
  private.questionnaire_ecrire(uuid, text, jsonb, boolean),
  private.candidature_motif(text),
  private.candidature_condition(public.candidatures, text),
  private.candidature_regle(public.candidatures, text, text, smallint, boolean),
  private.candidature_idempotence_lue(text, uuid, text, uuid),
  private.candidature_geste_ouvrir(uuid, text, text, uuid, integer, text, text, text),
  private.candidature_geste_appliquer(uuid, text, smallint, text, uuid, text, text, jsonb, jsonb),
  private.candidature_geste_conclure(text, uuid, text, uuid, jsonb),
  private.candidature_etat_candidat(),
  private.journal_portee(text, text, uuid, jsonb)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

REVOKE ALL ON private.audit_logs_cotes FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- Le predicat de la policy d'audit_logs (C15) : authenticated seul, le role
-- que vise la policy (motif de app_private.compte_candidat_hors_portee).
ALTER FUNCTION app_private.audit_ligne_dans_portee(text, text, uuid, jsonb) OWNER TO postgres;
REVOKE ALL ON FUNCTION app_private.audit_ligne_dans_portee(text, text, uuid, jsonb)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION app_private.audit_ligne_dans_portee(text, text, uuid, jsonb) TO authenticated;
COMMENT ON FUNCTION app_private.audit_ligne_dans_portee(text, text, uuid, jsonb) IS
  'CAND-L2A1 : une ligne d audit est-elle du cote de la direction qui lit (C15) ? Sans l exception '
  'super-admin ; faux hors de la direction. Lu par la policy restrictive audit_logs_portee_candidatures.';

-- journal_audit et journal_audit_filtres, redefinis ici, suivent l'idiome
-- F86 des RPC client du lot : authenticated seul. Avant ce lot, service_role
-- y gardait EXECUTE (droits par defaut), sans usage : la garde exige la
-- direction ; agent_ro ne l'avait plus (scenario agt01, A12).
ALTER FUNCTION public.journal_audit(uuid, text, timestamptz, integer, timestamptz, bigint) OWNER TO postgres;
ALTER FUNCTION public.journal_audit_filtres() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.journal_audit(uuid, text, timestamptz, integer, timestamptz, bigint),
  public.journal_audit_filtres() FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.journal_audit(uuid, text, timestamptz, integer, timestamptz, bigint),
  public.journal_audit_filtres() TO authenticated;

DO $acl$
DECLARE
  f text;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.conditions_remuneration_candidat()',
    'public.questionnaire_salle_examen()',
    'public.enregistrer_reponses_salle_examen(text,jsonb,integer,text)',
    'public.envoyer_reponses_salle_examen(text,jsonb,boolean,text,integer,text)',
    'public.retrait_candidat(integer,text)',
    'public.cadre_religieux_version_requise()',
    'public.cadre_religieux_acceptable(text)',
    'public.etat_dossier()'
  ] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', f);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', f);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', f);
  END LOOP;
END;
$acl$;

DO $droits$
DECLARE
  v record;
BEGIN
  FOR v IN
    SELECT * FROM (VALUES
      ('public.conditions_remuneration_candidat()', 'POSITIVE_CANDIDATE_SELF',
       'Titulaire d une candidature en cours au compte valide (L1-08), sinon 42501 ; part de l enseignant par public (pour mille, jamais un montant ni la devise : decision du 22/10) lue dans politique_part_enseignant ; politique en vigueur ou prochaine publiee qui paie par eleve present, indisponible sans sa part ; son acceptation.'),
      ('public.questionnaire_salle_examen()', 'POSITIVE_CANDIDATE_SELF',
       'Titulaire d une candidature en cours au compte valide, sinon 42501 ; version courante, champs et listes fermees (langues par code, pays ISO, fuseaux IANA), son dernier document de reponses, version du brouillon ouvert.'),
      ('public.enregistrer_reponses_salle_examen(text,jsonb,integer,text)', 'POSITIVE_CANDIDATE_SELF_ENGINE',
       'Titulaire d une candidature, sinon 42501 ; moteur : version du brouillon attendue, derniere cle d idempotence, regle (a_completer, en cours, hors pause) ; valeur hors liste refusee sans ecriture ; brouillon a la version courante ; version de la candidature inchangee ; aucune reponse gardee sous la cle.'),
      ('public.envoyer_reponses_salle_examen(text,jsonb,boolean,text,integer,text)', 'POSITIVE_CANDIDATE_SELF_ENGINE',
       'Titulaire d une candidature, sinon 42501 ; transition 6 par le moteur ; questionnaire complet, accord de remuneration aux conditions affichees (version), cadre religieux a la version requise, sinon refus rendu sans ecriture ; accord de remuneration enregistre ; recalcul du paiement (L6).'),
      ('public.retrait_candidat(integer,text)', 'POSITIVE_CANDIDATE_SELF_ENGINE',
       'Titulaire d une candidature, sinon 42501 ; transition 17 par le moteur, toute etape en cours avant la salle 3, pause comprise ; canal application ; refus rendus sans ecriture.'),
      ('public.cadre_religieux_version_requise()', 'AUTHENTICATED_PUBLIC_VERSION',
       'Version requise du cadre religieux et pedagogique, nulle tant qu elle n est pas publiee ; lue par la page d accords.'),
      ('public.cadre_religieux_acceptable(text)', 'AUTHENTICATED_SELF_PREDICATE',
       'Predicat de la policy RESTRICTIVE du cadre religieux : version requise publiee et candidature enseignant en cours du compte appelant (Salle d examen ou de verification), compte valide ; ne rend qu un booleen sur soi.'),
      ('public.etat_dossier()', 'SESSION_POSITIVE',
       'Lecture du seul dossier de l appelant ; corps de 20261021210400 garde (code_conduite_signe) ; CAND-L2A1 : cle candidature (etape, etat, issue, pause par modele, questionnaire, cadre, conditions, paiement, a completer, complement demande, envoi possible), jamais un motif interne.'),
      ('public.journal_audit(uuid,text,timestamp with time zone,integer,timestamp with time zone,bigint)', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE',
       'Direction active (garde de 0016 gardee) ; CAND-L2A1 C15 : les seules lignes du cote du lecteur (candidature visee, auteur porteur de candidature avant la salle 3, lecture de liste), genre inconnu sans ligne a cote, super-admin les deux cotes journalise ; reference CAND- a la place du nom d un porteur de candidature.'),
      ('public.journal_audit_filtres()', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE',
       'Direction active (garde de 0015 gardee) ; CAND-L2A1 C15 : totaux, actions et acteurs comptes sur les seules lignes du cote du lecteur ; super-admin journalise ; reference CAND- a la place du nom d un porteur de candidature.')
    ) AS t(signature, garde, note)
  LOOP
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v.signature, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=%s; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-22. CAND-L2A1. %s Must-pass: supabase/tests/scenarios_cand_l2a1_moteur_salle_examen.sql.',
      v.signature,
      pg_catalog.md5(pg_catalog.pg_get_functiondef(v.signature::regprocedure)),
      v.garde, v.note));
  END LOOP;
END;
$droits$;

DO $postflight$
DECLARE
  v record;
  v_role text;
  v_liste text;
BEGIN
  -- Les RPC client : DEFINER, proprietaire postgres, search_path vide,
  -- volatilite attendue, empreinte F86 a jour, authenticated seul, garde
  -- positive.
  FOR v IN
    SELECT e.signature, e.volatilite, p.*
    FROM (VALUES
      ('public.conditions_remuneration_candidat()', 's'),
      ('public.questionnaire_salle_examen()', 's'),
      ('public.enregistrer_reponses_salle_examen(text,jsonb,integer,text)', 'v'),
      ('public.envoyer_reponses_salle_examen(text,jsonb,boolean,text,integer,text)', 'v'),
      ('public.retrait_candidat(integer,text)', 'v'),
      ('public.cadre_religieux_version_requise()', 's'),
      ('public.cadre_religieux_acceptable(text)', 's'),
      ('public.etat_dossier()', 's')
    ) AS e(signature, volatilite)
    LEFT JOIN pg_catalog.pg_proc p ON p.oid = pg_catalog.to_regprocedure(e.signature)
  LOOP
    IF v.oid IS NULL
       OR NOT v.prosecdef
       OR pg_catalog.pg_get_userbyid(v.proowner) <> 'postgres'
       OR NOT coalesce(v.proconfig @> ARRAY['search_path=""'], false)
       OR v.provolatile::text <> v.volatilite
       OR coalesce(pg_catalog.obj_description(v.oid, 'pg_proc'), '')
          NOT LIKE '%md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v.oid)) || '%'
       OR NOT pg_catalog.has_function_privilege('authenticated', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v.oid, 'EXECUTE')
       OR app_private.has_unsafe_role_guard(v.prosrc) THEN
      RAISE EXCEPTION 'CAND-L2A1 : DEFINER, proprietaire, search_path, volatilite, empreinte, ACL ou garde invalide : %',
        v.signature;
    END IF;
  END LOOP;
  IF pg_catalog.strpos((SELECT p.prosrc FROM pg_catalog.pg_proc p WHERE p.oid = 'public.etat_dossier()'::regprocedure),
                       'code_conduite_signe') = 0 THEN
    RAISE EXCEPTION 'CAND-L2A1 : etat_dossier() a perdu code_conduite_signe';
  END IF;

  -- Le journal (C15) : DEFINER, proprietaire postgres, search_path vide,
  -- VOLATILE (trace de l'exception), empreinte F86, authenticated seul,
  -- garde positive, portee dans le corps.
  FOR v IN
    SELECT p.*
    FROM pg_catalog.pg_proc p
    WHERE p.oid IN ('public.journal_audit(uuid,text,timestamptz,integer,timestamptz,bigint)'::regprocedure,
                    'public.journal_audit_filtres()'::regprocedure)
  LOOP
    IF NOT v.prosecdef
       OR pg_catalog.pg_get_userbyid(v.proowner) <> 'postgres'
       OR NOT coalesce(v.proconfig @> ARRAY['search_path=""'], false)
       OR v.provolatile <> 'v'
       OR coalesce(pg_catalog.obj_description(v.oid, 'pg_proc'), '')
          NOT LIKE '%md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v.oid)) || '%'
       OR NOT pg_catalog.has_function_privilege('authenticated', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v.oid, 'EXECUTE')
       OR app_private.has_unsafe_role_guard(v.prosrc)
       OR (pg_catalog.strpos(v.prosrc, 'private.journal_portee') = 0
           AND pg_catalog.strpos(v.prosrc, 'private.audit_logs_cotes') = 0) THEN
      RAISE EXCEPTION 'CAND-L2A1 : journal d audit mal forme : %', v.oid::regprocedure;
    END IF;
  END LOOP;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = 'app_private.audit_ligne_dans_portee(text,text,uuid,jsonb)'::regprocedure
                    AND p.prosecdef AND pg_catalog.pg_get_userbyid(p.proowner) = 'postgres'
                    AND coalesce(p.proconfig @> ARRAY['search_path=""'], false)
                    AND NOT app_private.has_unsafe_role_guard(p.prosrc))
     OR NOT pg_catalog.has_function_privilege('authenticated',
              'app_private.audit_ligne_dans_portee(text,text,uuid,jsonb)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'app_private.audit_ligne_dans_portee(text,text,uuid,jsonb)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', 'app_private.audit_ligne_dans_portee(text,text,uuid,jsonb)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'app_private.audit_ligne_dans_portee(text,text,uuid,jsonb)', 'EXECUTE')
     OR (SELECT pg_catalog.count(*) FROM pg_catalog.pg_policies p
          WHERE p.schemaname = 'public' AND p.cmd = 'SELECT' AND p.permissive = 'RESTRICTIVE'
            AND ((p.tablename = 'audit_logs' AND p.policyname = 'audit_logs_portee_candidatures'
                  AND p.roles = ARRAY['authenticated']::name[])
              OR (p.tablename = 'contract_acceptances' AND p.policyname = 'contract_acceptances_compte_candidat_portee'
                  AND p.roles @> ARRAY['authenticated', 'agent_ro']::name[]))) <> 2 THEN
    RAISE EXCEPTION 'CAND-L2A1 : portee du journal ou des accords absente ou mal formee';
  END IF;

  -- Les aides internes : appelables par aucun compte ; aucune aide cand_
  -- de plus (CAND-L1 en compte neuf).
  FOR v IN
    SELECT p.oid
    FROM pg_catalog.pg_proc p
    JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'private'
      AND (p.proname LIKE 'questionnaire\_%' OR p.proname LIKE 'candidature\_%'
           OR p.proname IN ('conditions_remuneration_applicables', 'politique_part_version_publiee',
                            'journal_portee'))
  LOOP
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF pg_catalog.has_function_privilege(v_role, v.oid, 'EXECUTE') THEN
        RAISE EXCEPTION 'CAND-L2A1 : aide interne % executable par %', v.oid::regprocedure, v_role;
      END IF;
    END LOOP;
  END LOOP;
  IF (SELECT pg_catalog.count(*) FROM pg_catalog.pg_proc p
      WHERE p.pronamespace = 'private'::regnamespace AND p.proname LIKE 'cand\_%') <> 9 THEN
    RAISE EXCEPTION 'CAND-L2A1 : les aides cand_ de CAND-L1 doivent rester neuf';
  END IF;

  -- Les tables : RLS active, aucun privilege client, aucune policy ; les
  -- sequences n'existent pas (cles naturelles).
  FOR v IN
    SELECT c.oid, c.relrowsecurity
    FROM pg_catalog.pg_class c
    WHERE c.oid IN ('public.candidature_questionnaires'::regclass, 'public.candidature_gestes'::regclass,
                    'public.candidature_brouillon_cles'::regclass,
                    'public.politique_part_enseignant'::regclass, 'private.pays_iso_3166'::regclass,
                    'private.candidature_gestes_regles'::regclass)
  LOOP
    IF NOT v.relrowsecurity THEN
      RAISE EXCEPTION 'CAND-L2A1 : RLS inactive sur %', v.oid::regclass;
    END IF;
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF pg_catalog.has_table_privilege(v_role, v.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER') THEN
        RAISE EXCEPTION 'CAND-L2A1 : % garde un privilege sur %', v_role, v.oid::regclass;
      END IF;
    END LOOP;
  END LOOP;
  FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
    IF pg_catalog.has_table_privilege(v_role, 'private.audit_logs_cotes', 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER') THEN
      RAISE EXCEPTION 'CAND-L2A1 : % lit la vue des cotes du journal', v_role;
    END IF;
  END LOOP;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_policies
              WHERE (schemaname = 'public'
                     AND tablename IN ('candidature_questionnaires', 'candidature_gestes', 'candidature_brouillon_cles',
                                       'politique_part_enseignant'))
                 OR (schemaname = 'private' AND tablename IN ('pays_iso_3166', 'candidature_gestes_regles'))) THEN
    RAISE EXCEPTION 'CAND-L2A1 : une policy ouvre une table du lot';
  END IF;

  -- Les accords : deux sortes de plus, aucune version requise publiee pour le
  -- cadre (spec 9), deux policies RESTRICTIVE, inventaire inchange (dix).
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_constraint c
                  WHERE c.conrelid = 'public.contract_acceptances'::regclass
                    AND c.conname = 'contract_acceptances_contract_kind_check'
                    AND pg_catalog.pg_get_constraintdef(c.oid) LIKE '%teacher_religious_framework%'
                    AND pg_catalog.pg_get_constraintdef(c.oid) LIKE '%teacher_pay_conditions%'
                    AND pg_catalog.pg_get_constraintdef(c.oid) LIKE '%teacher_conduct_code%')
     OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_constraint c
                     WHERE c.conrelid = 'public.contract_required_versions'::regclass
                       AND c.conname = 'contract_required_versions_contract_kind_check'
                       AND pg_catalog.pg_get_constraintdef(c.oid) LIKE '%teacher_religious_framework%'
                       AND pg_catalog.pg_get_constraintdef(c.oid) NOT LIKE '%teacher_pay_conditions%') THEN
    RAISE EXCEPTION 'CAND-L2A1 : sortes d accord inattendues';
  END IF;
  IF public.cadre_religieux_version_requise() IS NOT NULL THEN
    RAISE EXCEPTION 'CAND-L2A1 : la version requise du cadre religieux ne se publie pas par ce lot (spec 9)';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM pg_catalog.pg_policies p
      WHERE p.schemaname = 'public' AND p.tablename = 'contract_acceptances' AND p.cmd = 'INSERT'
        AND p.permissive = 'RESTRICTIVE'
        AND p.policyname IN ('contract_acceptances_cadre_religieux_candidat',
                             'contract_acceptances_conditions_remuneration_serveur')) <> 2 THEN
    RAISE EXCEPTION 'CAND-L2A1 : policies des accords absentes ou permissives';
  END IF;
  SELECT pg_catalog.string_agg(p.tablename || '.' || p.policyname, ', ' ORDER BY p.tablename || '.' || p.policyname)
    INTO v_liste
    FROM pg_catalog.pg_policies p
   WHERE p.schemaname = 'public'
     AND (coalesce(p.qual, '') || coalesce(p.with_check, '')) LIKE '%app_role()%'
     AND (coalesce(p.qual, '') || coalesce(p.with_check, '')) NOT LIKE '%app_account_valid%';
  IF v_liste IS DISTINCT FROM 'contract_acceptances.contract_acceptances_code_conduite_enseignant, contract_acceptances.contract_acceptances_self_insert, households.households_guardian_select, intentions_horaire.intentions_horaire_parties, kyc_documents.kyc_guardian_insert, kyc_documents.kyc_staff_self_insert, offres_horaires.offres_horaires_vitrine, profiles.profiles_compte_candidat_portee, profiles.profiles_family_select, student_reading_position.srp_foyer_lecture' THEN
    RAISE EXCEPTION 'CAND-L2A1 : inventaire des policies sans app_account_valid change : %', v_liste;
  END IF;

  -- Les pays : les 249 codes, les memes que les lignes de virement de L6.
  IF (SELECT pg_catalog.count(*) FROM private.pays_iso_3166) <> 249
     OR EXISTS (SELECT x.code FROM private.pays_iso_3166 x
                EXCEPT SELECT l.pays FROM public.referentiel_paiement l WHERE l.methode = 'virement_bancaire')
     OR EXISTS (SELECT l.pays FROM public.referentiel_paiement l WHERE l.methode = 'virement_bancaire'
                EXCEPT SELECT x.code FROM private.pays_iso_3166 x) THEN
    RAISE EXCEPTION 'CAND-L2A1 : liste des pays differente de celle de L6';
  END IF;

  -- La paie : 47 % et les taux du 19/10 dans la v2.0.0.
  IF (SELECT (x.part_enfant_pour_mille, x.part_adulte_pour_mille)
        FROM public.politique_part_enseignant x WHERE x.politique_version = 'v2.0.0')
     IS DISTINCT FROM (470, 470)
     OR (SELECT (p.taux_eleve_heure_enfant_mineur, p.taux_eleve_heure_adulte_mineur)
           FROM public.politiques_commerciales p WHERE p.version = 'v2.0.0')
     IS DISTINCT FROM (199::bigint, 157::bigint) THEN
    RAISE EXCEPTION 'CAND-L2A1 : paie de la v2.0.0 differente de la decision du 19/10';
  END IF;

  -- Le questionnaire : une version courante pour enseignant, qui porte les
  -- cles de L6 a leur type.
  IF (SELECT pg_catalog.count(*) FROM public.candidature_questionnaires q
      WHERE q.type_code = 'enseignant' AND q.courant) <> 1
     OR NOT EXISTS (
       SELECT 1 FROM public.candidature_questionnaires q
        WHERE q.courant AND q.type_code = 'enseignant'
          AND (q.definition -> 'champs') @> '[{"code": "paysVersement", "type": "choix", "liste": "pays"},
                                              {"code": "compteBancaire", "type": "booleen"},
                                              {"code": "operateurs", "type": "choix_multiple", "liste": "operateurs_confirmes"},
                                              {"code": "paysResidence", "liste": "pays"},
                                              {"code": "fuseauIana", "liste": "fuseaux"},
                                              {"code": "langueMaternelle", "liste": "langues"}]'::jsonb) THEN
    RAISE EXCEPTION 'CAND-L2A1 : questionnaire courant absent ou sans les cles de L6';
  END IF;

  -- Le questionnaire du 22/10 (C17) : langues sans plafond ni arabe de cours
  -- ni ff, memorisation et ijaza separees, tranches d'age, classes
  -- souhaitees a la place des heures, moyens accessibles informatifs.
  IF NOT EXISTS (
       SELECT 1 FROM public.candidature_questionnaires q
        WHERE q.courant AND q.type_code = 'enseignant'
          AND (q.definition -> 'champs') @> '[{"code": "langueMaternelle", "requis": false},
                                              {"code": "languesExplication", "requis": true, "min": 1, "exclure": ["ar"]},
                                              {"code": "niveauMemorisationDeclare",
                                               "valeurs": ["aucune", "moins_10_juz", "de_10_a_29_juz", "coran_entier"]},
                                              {"code": "ijazaPresentable", "valeurs": ["oui", "pret_test", "non"]},
                                              {"code": "publics", "min": 1, "valeurs": ["6_9", "10_13", "14_17", "adultes"]},
                                              {"code": "classesSouhaitees", "requis": true, "valeurs": ["1", "2", "3"]},
                                              {"code": "moyensAccessibles", "requis": false, "liste": "moyens_connus"}]'::jsonb
          AND NOT EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(q.definition -> 'champs') c
                           WHERE c ->> 'code' IN ('heuresParSemaine')
                              OR (c ->> 'code' = 'languesExplication' AND c ? 'max'))
          AND NOT ((q.definition -> 'languesHorsReferentiel') ? 'ff')
          AND (q.definition -> 'languesHorsReferentiel') @> '["man", "sus", "sw", "ha", "wo", "bm", "snk", "mnk", "ar", "autre"]'::jsonb) THEN
    RAISE EXCEPTION 'CAND-L2A1 : le questionnaire courant differe des reponses du directeur du 22/10';
  END IF;

  -- Les regles : motif exige exactement ou la colonne Motif de 4.2 dit oui ;
  -- pendant une pause, seuls lever, refuser et retirer (4.3, L2-9).
  IF (SELECT pg_catalog.string_agg(DISTINCT r.transition::text, ',' ORDER BY r.transition::text)
        FROM private.candidature_gestes_regles r WHERE 'direction' = ANY (r.motif_requis))
     IS DISTINCT FROM '12,15,16,17,18,19,20,21,23,25,7'
     OR (SELECT pg_catalog.string_agg(r.geste, ',' ORDER BY r.geste)
           FROM private.candidature_gestes_regles r WHERE r.pause <> 'interdite')
     IS DISTINCT FROM 'lever_pause,refuser,retirer'
     OR (SELECT pg_catalog.string_agg(r.geste, ',' ORDER BY r.geste)
           FROM private.candidature_gestes_regles r WHERE r.groupable)
     IS DISTINCT FROM 'consigner_prevenu,inviter,lever_pause,mettre_en_pause,refuser'
     -- Changements admis (C16) : ceux-la seulement.
     OR (SELECT pg_catalog.string_agg(r.geste || ':' || pg_catalog.array_to_string(r.admis, '+'), ',' ORDER BY r.geste)
           FROM private.candidature_gestes_regles r WHERE pg_catalog.cardinality(r.admis) > 0)
     IS DISTINCT FROM 'definir_responsable:responsable_id,envoyer_reponses:pays_residence+fuseau_iana,mettre_en_pause:reprise_le,noter_indisponibilite:indisponible_jusqu_au'
     OR (SELECT pg_catalog.string_agg(r.geste, ',') FROM private.candidature_gestes_regles r WHERE r.brouillon)
     IS DISTINCT FROM 'enregistrer_reponses' THEN
    RAISE EXCEPTION 'CAND-L2A1 : table des regles differente de la section 4.2';
  END IF;
END;
$postflight$;

COMMIT;
