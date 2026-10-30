"""La page du directeur pour le lot B (admission et onboarding, 29/10/2026).

  python3 -I tool/page_migrations/page_lot_b.py --sortie <page.html>

Une seule liste, dans l'ordre (consigne du pilote du 29/10) : les reglages de
Supabase, les trois migrations de la production, la ligne des scenarios dans
ci.yml, la demande de fusion et son apercu, la fusion, puis la preuve. Chaque
geste a sa coche ; ce qui se colle a son bouton Copier. Meme gabarit que la
phase 2 (`modele_phase2.html`).

Faits qui fixent l'ordre (lus le 29/10) :
- `deploy.yml` n'applique AUCUNE migration a la fusion (declencheur manuel,
  desactive par defaut) ; il deploie les fonctions Edge, dont le modele
  d'e-mail « demande recue ». Les migrations se collent donc a la main, une
  fois.
- L'apercu d'une demande de fusion est construit avec le meme `SUPABASE_URL`
  que la production : il lit la base de production. Les migrations passent
  donc AVANT l'apercu.
- L'application en ligne aujourd'hui appelle `inscrire_titulaire` avec six
  arguments nommes ; la version a sept arguments (le dernier a une valeur par
  defaut) les accepte. Coller les migrations avant la fusion ne casse rien.
"""
import argparse
import json
import pathlib
import re
import sys

RACINE = pathlib.Path(__file__).resolve().parents[2]
ICI = pathlib.Path(__file__).resolve().parent
PROD = 'gggmtelinlpseweouyav'
TABLEAU = f'https://supabase.com/dashboard/project/{PROD}'
DEPOT = 'https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App'
BRANCHE = 'claude/admiring-brown-r6ai72-admission-b'
EFFACEMENT = re.compile(r'\b(delete from|drop |truncate)\b', re.IGNORECASE)

sys.path.insert(0, str(ICI.parent))
from envelopper_pour_editeur_sql import envelopper  # noqa: E402

MIGRATIONS = [
    ('20261029120000_admission_lot_b_famille_en_attente.sql',
     'Une famille et un élève adulte naissent en attente, avec leur demande et l’e-mail « demande reçue ».'),
    ('20261029150000_admission_lot_b_apprenants.sql',
     'La demande garde ses apprenants : prénom, âge, genre et réponses de chaque enfant.'),
    ('20261029180000_langues_cours_publiques.sql',
     'La liste des langues de cours se lit avant la création du compte, et rien d’autre.'),
]

SCENARIOS = [
    ('Scenarios admission lot B (famille et eleve adulte en attente)', 'scenarios_admission_lot_b.sql'),
    ('Scenarios admission lot B (apprenants de la demande)', 'scenarios_admission_lot_b_apprenants.sql'),
    ('Scenarios langues de cours publiques (lot B)', 'scenarios_langues_cours_publiques.sql'),
]


def etapes() -> list[dict]:
    e: list[dict] = []

    def ajoute(section: str, titre: str, html: str, copie: str | None = None, genre: str = 'texte') -> None:
        e.append({'section': section, 'titre': titre, 'html': html, 'copie': copie, 'genre': genre})

    s = '1. Les réglages de Supabase'
    ajoute(s, 'Confirmer l’adresse e-mail',
           f'<p>Ouvrez <a href="{TABLEAU}/auth/providers" target="_blank" rel="noopener">Authentication, Sign In / '
           'Providers</a>, ligne <strong>Email</strong>. Activez <strong>Confirm email</strong>, puis « Save ». '
           'Une personne qui s’inscrit doit d’abord ouvrir le lien reçu.</p>')
    ajoute(s, 'Le modèle d’e-mail « demande reçue »',
           '<p>Rien à coller : ce modèle est dans le code de l’application et part tout seul avec la fusion '
           '(étape 4). Cochez simplement.</p>')

    s = '2. La base de production : coller les trois migrations, dans l’ordre'
    ajoute(s, 'Regarder la sauvegarde du jour',
           f'<p>Ouvrez <a href="{TABLEAU}/database/backups/scheduled" target="_blank" rel="noopener">les sauvegardes '
           'de la production</a>. Il doit y en avoir une d’aujourd’hui ou d’hier. S’il n’y en a aucune, écrivez-le-moi '
           'avant de continuer.</p>')
    for i, (nom, quoi) in enumerate(MIGRATIONS, 1):
        sql = (RACINE / 'supabase' / 'migrations' / nom).read_text()
        effacement = (' Une fenêtre « destructive operation » peut apparaître : cliquez sur <strong>Run this '
                      'query</strong>, c’est prévu (une ancienne version d’une fonction est remplacée).'
                      if EFFACEMENT.search(sql) else '')
        # Enveloppe contre les fins de ligne de Windows (regle du 23/10).
        texte = envelopper(sql, pathlib.Path(nom).stem, i, len(MIGRATIONS))
        ajoute(s, f'Migration {i} sur {len(MIGRATIONS)}',
               f'<p>{quoi}</p><p class="tech">{nom} · {round(len(sql.encode()) / 1024)} Ko</p><p>Copiez, collez dans '
               f'<a href="{TABLEAU}/sql/new" target="_blank" rel="noopener">l’éditeur SQL de la production</a> '
               '(<kbd>Ctrl</kbd>+<kbd>A</kbd> puis <kbd>Ctrl</kbd>+<kbd>V</kbd>), <strong>Run</strong>, attendez '
               f'« Success ».{effacement} Chaque migration se colle une seule fois : la fusion ne les rejoue pas. Si '
               'un message dit « already exists », elle était déjà là : rien n’est cassé, passez à la suivante.</p>',
               texte, 'sql')

    s = '3. Les contrôles automatiques : trois lignes à ajouter'
    bloc = ''.join(
        f'\n      - name: {titre}\n        shell: bash\n'
        f'        run: psql -h postgres -U postgres -v ON_ERROR_STOP=1 -f supabase/tests/{fichier}\n'
        for titre, fichier in SCENARIOS)
    ajoute(s, 'Ajouter les scénarios du lot B dans ci.yml',
           f'<p>Ouvrez <a href="{DEPOT}/edit/{BRANCHE}/.github/workflows/ci.yml" target="_blank" rel="noopener">le '
           'fichier ci.yml de la branche</a>. Cherchez (<kbd>Ctrl</kbd>+<kbd>F</kbd>) la ligne '
           '<code>scenarios_notifications_classes.sql</code>. Placez le curseur à la fin de cette ligne, appuyez sur '
           '<kbd>Entrée</kbd>, puis collez le texte copié ici. En haut à droite : « Commit changes… », laissez « Commit '
           'directly to the claude/admiring-brown-r6ai72-admission-b branch », puis « Commit changes ».</p>',
           bloc, 'texte')

    s = '4. Mettre l’application en ligne'
    ajoute(s, 'Ouvrir la demande de fusion',
           f'<p>Ouvrez <a href="{DEPOT}/compare/main...{BRANCHE}?expand=1" target="_blank" rel="noopener">la '
           'comparaison</a>, titre « Admission lot B : inscription avant le compte, demande en attente », puis '
           '« Create pull request ».</p>')
    ajoute(s, 'Regarder l’aperçu',
           '<p>Quelques minutes après, un commentaire de la demande de fusion donne l’adresse de l’aperçu. Ouvrez-la '
           'sur votre téléphone, touchez « Créer un compte » : la question « Pour qui créez-vous ce compte ? » doit '
           's’afficher. Attention : l’aperçu utilise la base de production.</p>')
    ajoute(s, 'Fusionner',
           '<p>Quand les contrôles sont verts, bouton <strong>Merge pull request</strong> puis « Confirm merge ». '
           'Jamais « Close pull request ». L’application et le modèle d’e-mail partent tout seuls.</p>')

    s = '5. La preuve, sur votre téléphone'
    ajoute(s, 'S’inscrire comme famille test',
           '<p>Avec une adresse e-mail de test : « Créer un compte », « J’inscris mon enfant », puis les questions '
           '(prénom, âge, « Une fille », niveau, « Non », langue du cours, objectif, « Le soir »). Neuf écrans. '
           'Saisissez l’adresse, ouvrez le lien reçu, donnez nom et genre, « Envoyer ma demande ».</p>')
    ajoute(s, 'Voir la page d’attente',
           '<p>La page dit « Votre demande est en cours » et « Votre demande porte sur : (prénom), (âge) ans ».</p>')
    ajoute(s, 'Recevoir l’e-mail « demande reçue »',
           '<p>Dans la boîte de l’adresse de test : un e-mail « Votre demande est bien reçue » arrive dans les '
           'minutes qui suivent.</p>')
    ajoute(s, 'Recommencer avec « Je m’inscris pour moi »',
           '<p>Avec une deuxième adresse de test : cinq écrans avant l’adresse, puis la même page d’attente '
           '(« Votre demande porte sur : Vous ») et le même e-mail.</p>')
    ajoute(s, 'Me prévenir',
           '<p>Écrivez « lot B prouvé », ou ce qui n’a pas marché, avec une capture.</p>')
    return e


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument('--sortie', required=True)
    a = p.parse_args()
    donnees = etapes()
    modele = (ICI / 'modele_phase2.html').read_text()
    for avant, apres in (
        ('<title>Mise en production Rewayah</title>', '<title>Lot B en ligne</title>'),
        ('<h1>Mettre Rewayah en production</h1>', '<h1>Mettre le lot B en ligne</h1>'),
        ('Comptez environ une heure et demie, surtout pour les 15 lots.',
         'Comptez environ trente minutes, preuve comprise.'),
        ('const CLE = "rewayah-phase2-2026-10-23";', 'const CLE = "rewayah-lot-b-2026-10-29";'),
    ):
        if avant not in modele:
            raise SystemExit(f'gabarit change : {avant}')
        modele = modele.replace(avant, apres)
    page = modele.replace('__NOMBRE__', str(len(donnees))).replace(
        '__DONNEES__', json.dumps(donnees, ensure_ascii=False).replace('</', '<\\/'))
    pathlib.Path(a.sortie).write_text(page)
    print(f'{a.sortie} : {len(donnees)} gestes, {len(page.encode()) // 1024} Ko')


if __name__ == '__main__':
    main()
