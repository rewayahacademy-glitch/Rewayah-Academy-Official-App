// COUPE-MOTS-FOND-1 : la dette CONNUE de la garde du rendu, ecran par
// ecran. Chaque entree est un paragraphe entier que la garde a trouve coupe
// sur un ecran hors du perimetre de l'etape (fichiers d'autres lots, voir
// le « reste » du rendu de COUPE-MOTS-FOND-1) : il est exclu de la mesure,
// avec sa raison, jusqu'a sa correction. Tout AUTRE paragraphe de ces
// ecrans reste mesure : un nouveau mot coupe y fait echouer la garde.
//
// Une entree se retire quand son ecran est corrige ; la garde le prouve en
// repassant sans elle.

/// La dette, par nom d'ecran du balayage : textes entiers exclus.
const Map<String, Set<String>> detteCoupeMots = <String, Set<String>>{
  // `programmes_page.dart` : « Niveaux » dans une rangee a cote de la
  // pastille d'etat (320 px texte x2, Interface guidee).
  'Programmes (versions)': <String>{'Niveaux'},
  'admin Programmes': <String>{'Niveaux'},
  // `admin_acces_agents` : la carte « Pourra / Ne pourra pas » pose ses
  // phrases dans une colonne etroite (320 px texte x2).
  'admin Acces des agents': <String>{
    'Pourra',
    'Ne pourra pas',
    "Ouvrir l'application, naviguer, et lire tout ce que cette personne lit.",
    "Écrire quoi que ce soit, voir une pièce d'identité, un appareil, le "
        "journal d'audit, ni sortir du périmètre de cette personne.",
  },
  // `admin_configuration` (Fonctionnalites) : l'introduction a 320 px
  // texte x2, Interface guidee.
  'admin Fonctionnalites': <String>{
    'Les fonctionnalités qui changent le comportement de toute la '
        'plateforme.',
  },
  // Profil de l'enseignant : le nom a cote de l'avatar (320 px texte x2).
  'enseignant profil': <String>{'Sayyid Ibrahim'},
  // Compte du controleur : la ligne de role (Interface guidee).
  'controleur compte': <String>{
    'Observe les séances pour la qualité pédagogique',
  },
  // Accueil du tuteur : le detail de la carte vide (Interface guidee).
  'tuteur accueil': <String>{
    "La prochaine séance d'Élève A1 apparaîtra ici dès qu'elle sera "
        'programmée.',
  },
  // Compte du tuteur (`espaces_compte.dart`) : titres et details des
  // rubriques a cote de leur medaillon (320 px texte x2).
  'tuteur compte': <String>{
    'Consentements',
    'Informations personnelles',
    'Consulter mes informations',
    'Informations légales',
    'Accès et paiements',
    'Paiements et reçus',
    'Non disponible',
    'Connexion et sécurité',
    'Méthode de connexion',
    'Nom, adresse de connexion, langue et fuseau',
  },
  // Mon espace de l'adulte : l'adresse e-mail sans point de coupure
  // (Interface guidee, 320 px texte x2).
  'adulte monEspace': <String>{'mamadou.diallo@example.com'},
};
