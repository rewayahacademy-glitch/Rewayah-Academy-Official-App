"""Avis publics du site : lecture dans la base au build, validation, mise en forme.

Module charge par build_site.py, sur le modele de bloc_tarifs.py. Les avis viennent de
la seule fonction publique `public.avis_publics()` (decision du 19/10/2026), lue AU
MOMENT DU BUILD. Le navigateur ne parle jamais a la base : ni URL ni cle dans le HTML.
Sur toute erreur, repli sur content/avis.json (aucun avis). Aucune dependance hors
bibliotheque standard. Aucun balisage schema.org : on ne publie pas d'etoiles pour les
moteurs de recherche.
"""

from __future__ import annotations

import html
import json
import os
import re
import urllib.error
import urllib.request
from datetime import date
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parent
AVIS_REPLI = ROOT / "content" / "avis.json"
AVIS_DELAI_SECONDES = 8
AVIS_TAILLE_MAX = 1024 * 1024
AVIS_MAX = 200
NBSP = " "

QUALITES = {"parent": "Parent d’élève", "eleve_adulte": "Élève adulte"}
MOIS = ("janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août",
        "septembre", "octobre", "novembre", "décembre")
# Langue des pages en cours de construction (build_site) : les mentions des avis (qui parle, depuis quand, la date)
# sont ecrites dans la langue de la page ; le texte de l'avis, lui, reste tel qu'il a ete ecrit (decision du 19/10/2026).
LANGUE = "fr"
MOIS_LANGUES = {
    "fr": MOIS,
    "ar": ("يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو", "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"),
    "en": ("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"),
    "es": ("enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"),
    "pt": ("janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"),
}
TEXTES = {
    "fr": {"parent": "Parent d’élève", "eleve_adulte": "Élève adulte", "depuis": "avec nous depuis {mois}",
           "publie": "Publié le {date}", "note": "{n} sur 5", "resume": "{m} sur 5, {n} avis",
           "intro1": "{n} avis publié pour l’instant, lu par la direction avant publication et jamais retouché.",
           "intro": "{n} avis publiés pour l’instant, lus par la direction avant publication et jamais retouchés.",
           "vide": "Les premiers avis seront publiés ici bientôt, après lecture par la direction.",
           "titre": "Ce que disent nos familles", "sous_titre": "Les mots de nos élèves et de leurs parents, publiés tels qu’ils ont été écrits.",
           "moyenne": "d’après {n} avis, publiés tels qu’ils ont été écrits"},
    "ar": {"parent": "وليّ أمر طالب", "eleve_adulte": "طالب بالغ", "depuis": "معنا منذ {mois}",
           "publie": "نُشر في {date}", "note": "{n} من 5", "resume": "{m} من 5، {n} من الآراء",
           "intro1": "عدد الآراء المنشورة حتى الآن: {n}، قرأته الإدارة قبل نشره ولم يُغيَّر فيه شيء.",
           "intro": "عدد الآراء المنشورة حتى الآن: {n}، قرأتها الإدارة قبل نشرها ولم يُغيَّر فيها شيء.",
           "vide": "ستُنشر هنا الآراء الأولى قريبًا، بعد أن تقرأها الإدارة.",
           "titre": "ماذا تقول أسرنا", "sous_titre": "كلمات طلابنا وأوليائهم، تُنشر كما كُتبت.",
           "moyenne": "استنادًا إلى {n} من الآراء، تُنشر كما كُتبت"},
    "en": {"parent": "Parent of a student", "eleve_adulte": "Adult student", "depuis": "with us since {mois}",
           "publie": "Published on {date}", "note": "{n} out of 5", "resume": "{m} out of 5, {n} reviews",
           "intro1": "{n} review published so far, read by the management before publication and never edited.",
           "intro": "{n} reviews published so far, read by the management before publication and never edited.",
           "vide": "The first reviews will be published here soon, once the management has read them.",
           "titre": "What our families say", "sous_titre": "The words of our students and their parents, published exactly as they were written.",
           "moyenne": "based on {n} reviews, published exactly as they were written"},
    "es": {"parent": "Padre o madre de un alumno", "eleve_adulte": "Alumno adulto", "depuis": "con nosotros desde {mois}",
           "publie": "Publicado el {date}", "note": "{n} de 5", "resume": "{m} de 5, {n} opiniones",
           "intro1": "{n} opinión publicada por ahora, leída por la dirección antes de su publicación y nunca retocada.",
           "intro": "{n} opiniones publicadas por ahora, leídas por la dirección antes de su publicación y nunca retocadas.",
           "vide": "Las primeras opiniones se publicarán aquí pronto, después de que la dirección las lea.",
           "titre": "Lo que dicen nuestras familias", "sous_titre": "Las palabras de nuestros alumnos y de sus padres, publicadas tal como fueron escritas.",
           "moyenne": "según {n} opiniones, publicadas tal como fueron escritas"},
    "pt": {"parent": "Pai ou mãe de um aluno", "eleve_adulte": "Aluno adulto", "depuis": "connosco desde {mois}",
           "publie": "Publicado em {date}", "note": "{n} em 5", "resume": "{m} em 5, {n} opiniões",
           "intro1": "{n} opinião publicada até agora, lida pela direção antes da publicação e nunca alterada.",
           "intro": "{n} opiniões publicadas até agora, lidas pela direção antes da publicação e nunca alteradas.",
           "vide": "As primeiras opiniões serão publicadas aqui em breve, depois de lidas pela direção.",
           "titre": "O que dizem as nossas famílias", "sous_titre": "As palavras dos nossos alunos e dos seus pais, publicadas tal como foram escritas.",
           "moyenne": "com base em {n} opiniões, publicadas tal como foram escritas"},
}
_PAYS_LANGUES: dict[str, dict[str, str]] = {}


def _tx(cle: str, **valeurs) -> str:
    return TEXTES.get(LANGUE, TEXTES["fr"])[cle].format(**valeurs)


def nom_pays(code: str) -> str:
    """Le nom du pays dans la langue de la page (content/pays.json, tire des noms CLDR d'Unicode)."""
    if LANGUE == "fr":
        return PAYS.get(code, code)
    if not _PAYS_LANGUES:
        fichier = ROOT / "content" / "pays.json"
        _PAYS_LANGUES.update(json.loads(fichier.read_text(encoding="utf-8")) if fichier.exists() else {})
    return _PAYS_LANGUES.get(LANGUE, {}).get(code) or PAYS.get(code, code)


_CLES_AVIS = {"nom", "qualite", "pays", "depuis", "note", "titre", "texte", "publie_le"}


def esc(value: object) -> str:
    return html.escape(str(value), quote=True)


def _unique_object(pairs: list[tuple[str, object]]) -> dict[str, object]:
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"Duplicate JSON key: {key}")
        result[key] = value
    return result


class AvisInvalides(ValueError):
    """La réponse reçue n'a pas la forme attendue."""


def _chaine(valeur: object, chemin: str, bas: int, haut: int) -> str:
    if not isinstance(valeur, str) or len(valeur) > haut or len(valeur.strip()) < bas:
        raise AvisInvalides(f"{chemin} : texte de {bas} à {haut} caractères attendu")
    return valeur


def _date_iso(valeur: object, chemin: str) -> date:
    if not isinstance(valeur, str) or not re.match(r"\d{4}-\d{2}-\d{2}", valeur):
        raise AvisInvalides(f"{chemin} : date ISO attendue")
    try:
        return date.fromisoformat(valeur[:10])
    except ValueError as erreur:
        raise AvisInvalides(f"{chemin} : date invalide") from erreur


def _avis_valide(brut: object, chemin: str) -> dict:
    if not isinstance(brut, dict):
        raise AvisInvalides(f"{chemin} doit être un objet")
    if set(brut) != _CLES_AVIS:
        raise AvisInvalides(f"{chemin} : clés différentes de {sorted(_CLES_AVIS)}")
    _chaine(brut["nom"], f"{chemin}.nom", 2, 60)
    if brut["qualite"] not in QUALITES:
        raise AvisInvalides(f"{chemin}.qualite invalide")
    if not isinstance(brut["pays"], str) or not re.fullmatch(r"[A-Z]{2}", brut["pays"]):
        raise AvisInvalides(f"{chemin}.pays invalide")
    depuis = _date_iso(brut["depuis"], f"{chemin}.depuis")
    if depuis.day != 1 or depuis.year < 2015:
        raise AvisInvalides(f"{chemin}.depuis : premier du mois, 2015 ou après")
    n = brut["note"]
    if isinstance(n, bool) or not isinstance(n, int) or not 1 <= n <= 5:
        raise AvisInvalides(f"{chemin}.note : entier de 1 à 5 attendu")
    if brut["titre"] is not None:
        _chaine(brut["titre"], f"{chemin}.titre", 0, 80)
    _chaine(brut["texte"], f"{chemin}.texte", 20, 1500)
    _date_iso(brut["publie_le"], f"{chemin}.publie_le")
    return brut


def valider_avis(brut: object) -> dict:
    """Vérifie la réponse de `avis_publics()` : types, bornes, clés exactes."""
    if not isinstance(brut, dict) or set(brut) != {"nombre", "moyenne_dixiemes", "avis"}:
        raise AvisInvalides("réponse : clés attendues nombre, moyenne_dixiemes, avis")
    nombre, moyenne, liste = brut["nombre"], brut["moyenne_dixiemes"], brut["avis"]
    if isinstance(nombre, bool) or not isinstance(nombre, int) or nombre < 0:
        raise AvisInvalides("nombre : entier positif attendu")
    if not isinstance(liste, list) or len(liste) > AVIS_MAX or len(liste) > nombre:
        raise AvisInvalides(f"avis : liste de {AVIS_MAX} éléments au plus, pas plus que nombre")
    if nombre == 0:
        if moyenne is not None or liste:
            raise AvisInvalides("sans avis, la moyenne est nulle et la liste vide")
    elif isinstance(moyenne, bool) or not isinstance(moyenne, int) or not 10 <= moyenne <= 50:
        raise AvisInvalides("moyenne_dixiemes : entier de 10 à 50 attendu")
    for i, a in enumerate(liste):
        _avis_valide(a, f"avis[{i}]")
    return brut


def _ouvrir_sans_redirection() -> "urllib.request.OpenerDirector":
    class SansRedirection(urllib.request.HTTPRedirectHandler):
        def redirect_request(self, *args, **kwargs):  # noqa: D401
            return None
    return urllib.request.build_opener(SansRedirection)


def avis_depuis_base(env: dict[str, str] | None = None, ouvrir=None) -> dict:
    """Appelle `public.avis_publics()` avec la clé publiable. Lève en cas d'échec."""
    env = os.environ if env is None else env
    url = (env.get("SUPABASE_URL") or "").strip().rstrip("/")
    cle = (env.get("SUPABASE_PUBLISHABLE_KEY") or env.get("SUPABASE_ANON_KEY") or "").strip()
    if not url or not cle:
        raise LookupError("variables SUPABASE_URL et SUPABASE_PUBLISHABLE_KEY (ou SUPABASE_ANON_KEY) absentes")
    analyse = urlparse(url)
    local = analyse.hostname in ("localhost", "127.0.0.1")
    if not analyse.netloc or analyse.scheme not in ("https", "http") or (analyse.scheme == "http" and not local):
        raise ValueError("SUPABASE_URL doit être une adresse https")
    demande = urllib.request.Request(
        f"{url}/rest/v1/rpc/avis_publics", data=b"{}", method="POST",
        headers={"apikey": cle, "Content-Type": "application/json", "Accept": "application/json"})
    ouvrir = ouvrir or _ouvrir_sans_redirection().open
    try:
        with ouvrir(demande, timeout=AVIS_DELAI_SECONDES) as reponse:
            if getattr(reponse, "status", 200) != 200:
                raise ValueError(f"réponse HTTP {reponse.status}")
            corps = reponse.read(AVIS_TAILLE_MAX + 1)
    except urllib.error.HTTPError as erreur:
        raise ValueError(f"réponse HTTP {erreur.code}") from None
    except urllib.error.URLError as erreur:
        raise ValueError(f"base injoignable ({type(erreur.reason).__name__})") from None
    if len(corps) > AVIS_TAILLE_MAX:
        raise AvisInvalides("réponse trop volumineuse")
    try:
        brut = json.loads(corps.decode("utf-8"), object_pairs_hook=_unique_object)
    except (UnicodeDecodeError, ValueError) as erreur:
        raise AvisInvalides("réponse qui n'est pas du JSON valide") from erreur
    return valider_avis(brut)


def avis_depuis_fichier(chemin: Path = AVIS_REPLI) -> dict:
    return valider_avis(json.loads(chemin.read_text(encoding="utf-8"), object_pairs_hook=_unique_object))


def charger_avis(env: dict[str, str] | None = None, ouvrir=None, journal=print) -> tuple[dict, str]:
    """Base d'abord, content/avis.json (aucun avis) sinon. Rend (avis, origine)."""
    try:
        avis = avis_depuis_base(env, ouvrir)
        journal(f"Avis : lus dans la base (public.avis_publics), {avis['nombre']} avis publiés.")
        return avis, "base"
    except (LookupError, AvisInvalides, ValueError, OSError) as erreur:
        raison = f"{erreur}"
    journal(f"Avis : repli sur {AVIS_REPLI.name}, aucun avis affiché ({raison}).")
    return avis_depuis_fichier(), "fichier"


# --- Mise en forme -------------------------------------------------------

PAYS = {
    "AD": "Andorre", "AE": "Émirats arabes unis", "AF": "Afghanistan", "AG": "Antigua-et-Barbuda",
    "AI": "Anguilla", "AL": "Albanie", "AM": "Arménie", "AO": "Angola", "AQ": "Antarctique",
    "AR": "Argentine", "AS": "Samoa américaines", "AT": "Autriche", "AU": "Australie", "AW": "Aruba",
    "AX": "Îles Åland", "AZ": "Azerbaïdjan", "BA": "Bosnie-Herzégovine", "BB": "Barbade",
    "BD": "Bangladesh", "BE": "Belgique", "BF": "Burkina Faso", "BG": "Bulgarie", "BH": "Bahreïn",
    "BI": "Burundi", "BJ": "Bénin", "BL": "Saint-Barthélemy", "BM": "Bermudes", "BN": "Brunéi",
    "BO": "Bolivie", "BQ": "Pays-Bas caribéens", "BR": "Brésil", "BS": "Bahamas", "BT": "Bhoutan",
    "BV": "Île Bouvet", "BW": "Botswana", "BY": "Biélorussie", "BZ": "Belize", "CA": "Canada",
    "CC": "Îles Cocos", "CD": "République démocratique du Congo", "CF": "République centrafricaine",
    "CG": "Congo", "CH": "Suisse", "CI": "Côte d’Ivoire", "CK": "Îles Cook", "CL": "Chili",
    "CM": "Cameroun", "CN": "Chine", "CO": "Colombie", "CR": "Costa Rica", "CU": "Cuba",
    "CV": "Cap-Vert", "CW": "Curaçao", "CX": "Île Christmas", "CY": "Chypre", "CZ": "Tchéquie",
    "DE": "Allemagne", "DJ": "Djibouti", "DK": "Danemark", "DM": "Dominique", "DO": "République dominicaine",
    "DZ": "Algérie", "EC": "Équateur", "EE": "Estonie", "EG": "Égypte", "EH": "Sahara occidental",
    "ER": "Érythrée", "ES": "Espagne", "ET": "Éthiopie", "FI": "Finlande", "FJ": "Fidji",
    "FK": "Îles Malouines", "FM": "Micronésie", "FO": "Îles Féroé", "FR": "France", "GA": "Gabon",
    "GB": "Royaume-Uni", "GD": "Grenade", "GE": "Géorgie", "GF": "Guyane française", "GG": "Guernesey",
    "GH": "Ghana", "GI": "Gibraltar", "GL": "Groenland", "GM": "Gambie", "GN": "Guinée",
    "GP": "Guadeloupe", "GQ": "Guinée équatoriale", "GR": "Grèce", "GS": "Géorgie du Sud-et-les Îles Sandwich du Sud",
    "GT": "Guatemala", "GU": "Guam", "GW": "Guinée-Bissau", "GY": "Guyana", "HK": "Hong Kong",
    "HM": "Îles Heard-et-MacDonald", "HN": "Honduras", "HR": "Croatie", "HT": "Haïti", "HU": "Hongrie",
    "ID": "Indonésie", "IE": "Irlande", "IL": "Israël", "IM": "Île de Man", "IN": "Inde",
    "IO": "Territoire britannique de l’océan Indien", "IQ": "Irak", "IR": "Iran", "IS": "Islande",
    "IT": "Italie", "JE": "Jersey", "JM": "Jamaïque", "JO": "Jordanie", "JP": "Japon", "KE": "Kenya",
    "KG": "Kirghizistan", "KH": "Cambodge", "KI": "Kiribati", "KM": "Comores", "KN": "Saint-Christophe-et-Niévès",
    "KP": "Corée du Nord", "KR": "Corée du Sud", "KW": "Koweït", "KY": "Îles Caïmans", "KZ": "Kazakhstan",
    "LA": "Laos", "LB": "Liban", "LC": "Sainte-Lucie", "LI": "Liechtenstein", "LK": "Sri Lanka",
    "LR": "Libéria", "LS": "Lesotho", "LT": "Lituanie", "LU": "Luxembourg", "LV": "Lettonie",
    "LY": "Libye", "MA": "Maroc", "MC": "Monaco", "MD": "Moldavie", "ME": "Monténégro",
    "MF": "Saint-Martin", "MG": "Madagascar", "MH": "Îles Marshall", "MK": "Macédoine du Nord",
    "ML": "Mali", "MM": "Birmanie", "MN": "Mongolie", "MO": "Macao", "MP": "Îles Mariannes du Nord",
    "MQ": "Martinique", "MR": "Mauritanie", "MS": "Montserrat", "MT": "Malte", "MU": "Maurice",
    "MV": "Maldives", "MW": "Malawi", "MX": "Mexique", "MY": "Malaisie", "MZ": "Mozambique",
    "NA": "Namibie", "NC": "Nouvelle-Calédonie", "NE": "Niger", "NF": "Île Norfolk", "NG": "Nigéria",
    "NI": "Nicaragua", "NL": "Pays-Bas", "NO": "Norvège", "NP": "Népal", "NR": "Nauru", "NU": "Niue",
    "NZ": "Nouvelle-Zélande", "OM": "Oman", "PA": "Panama", "PE": "Pérou", "PF": "Polynésie française",
    "PG": "Papouasie-Nouvelle-Guinée", "PH": "Philippines", "PK": "Pakistan", "PL": "Pologne",
    "PM": "Saint-Pierre-et-Miquelon", "PN": "Îles Pitcairn", "PR": "Porto Rico", "PS": "Palestine",
    "PT": "Portugal", "PW": "Palaos", "PY": "Paraguay", "QA": "Qatar", "RE": "La Réunion",
    "RO": "Roumanie", "RS": "Serbie", "RU": "Russie", "RW": "Rwanda", "SA": "Arabie saoudite",
    "SB": "Îles Salomon", "SC": "Seychelles", "SD": "Soudan", "SE": "Suède", "SG": "Singapour",
    "SH": "Sainte-Hélène", "SI": "Slovénie", "SJ": "Svalbard et Jan Mayen", "SK": "Slovaquie",
    "SL": "Sierra Leone", "SM": "Saint-Marin", "SN": "Sénégal", "SO": "Somalie", "SR": "Suriname",
    "SS": "Soudan du Sud", "ST": "Sao Tomé-et-Principe", "SV": "Salvador", "SX": "Saint-Martin (partie néerlandaise)",
    "SY": "Syrie", "SZ": "Eswatini", "TC": "Îles Turques-et-Caïques", "TD": "Tchad",
    "TF": "Terres australes françaises", "TG": "Togo", "TH": "Thaïlande", "TJ": "Tadjikistan",
    "TK": "Tokelau", "TL": "Timor oriental", "TM": "Turkménistan", "TN": "Tunisie", "TO": "Tonga",
    "TR": "Turquie", "TT": "Trinité-et-Tobago", "TV": "Tuvalu", "TW": "Taïwan", "TZ": "Tanzanie",
    "UA": "Ukraine", "UG": "Ouganda", "UM": "Îles mineures éloignées des États-Unis", "US": "États-Unis",
    "UY": "Uruguay", "UZ": "Ouzbékistan", "VA": "Vatican", "VC": "Saint-Vincent-et-les-Grenadines",
    "VE": "Venezuela", "VG": "Îles Vierges britanniques", "VI": "Îles Vierges des États-Unis",
    "VN": "Viêt Nam", "VU": "Vanuatu", "WF": "Wallis-et-Futuna", "WS": "Samoa", "XK": "Kosovo",
    "YE": "Yémen", "YT": "Mayotte", "ZA": "Afrique du Sud", "ZM": "Zambie", "ZW": "Zimbabwe",
}


def fmt_moyenne(dixiemes: int) -> str:
    entier, reste = divmod(dixiemes, 10)
    return f"{entier}{'.' if LANGUE in ('en', 'ar') else ','}{reste}"


def fmt_resume(avis: dict) -> str:
    """« 4,8 sur 5, 37 avis » ; vide s'il n'y a aucun avis."""
    if not avis["nombre"]:
        return ""
    n = avis["nombre"]
    return _tx("resume", m=fmt_moyenne(avis['moyenne_dixiemes']), n=n)


def fmt_mois(iso: str) -> str:
    d = date.fromisoformat(iso[:10])
    mois = MOIS_LANGUES.get(LANGUE, MOIS)[d.month - 1]
    return f"{mois} de {d.year}" if LANGUE in ("es", "pt") else f"{mois} {d.year}"


def fmt_date(iso: str) -> str:
    d = date.fromisoformat(iso[:10])
    if LANGUE == "fr":
        return f"{'1er' if d.day == 1 else d.day} {MOIS[d.month - 1]} {d.year}"
    mois = MOIS_LANGUES.get(LANGUE, MOIS)[d.month - 1]
    return f"{d.day} de {mois} de {d.year}" if LANGUE in ("es", "pt") else f"{d.day} {mois} {d.year}"


# Seuils d'honnetete (directeur, 03/11/2026 : « 5,0 sur 5, 2 avis » n'est pas vendeur). Une moyenne sur deux ou trois avis
# ne prouve rien : elle ne s'affiche qu'a partir de AVIS_MOYENNE_MIN avis ; avant, la page dit combien d'avis sont publies,
# sans note chiffree. L'apercu des pages (accueil, cours, familles, tarifs) ne s'affiche qu'a partir de AVIS_APERCU_MIN avis
# publies, pour ne jamais montrer une vitrine de preuve sociale plus grande que la preuve. Les trois plus recents sont
# montres (jamais les mieux notes : on ne choisit pas). Une seule ligne a changer pour decider autrement.
AVIS_MOYENNE_MIN = 5
AVIS_APERCU_MIN = 1   # directeur, 06/11/2026 : les avis se voient, un apercu des le premier
AVIS_APERCU_MAX = 3

# Etoile de 24 x 24 (trace a cinq branches), peinte par le CSS avec un jeton : aucune couleur dans le balisage.
_ETOILE = ('<svg class="etoile {etat}" viewBox="0 0 24 24" aria-hidden="true" focusable="false">'
           '<polygon points="12,2 15.09,8.26 22,9.27 17,14.14 18.18,21.02 12,17.77 5.82,21.02 7,14.14 2,9.27 8.91,8.26"/></svg>')


def _etoiles_svg(pleines: int) -> str:
    return "".join(_ETOILE.format(etat="etoile--pleine" if i < pleines else "etoile--vide") for i in range(5))


def etoiles(note: int) -> str:
    """Cinq etoiles dessinees ; le texte « N sur 5 » reste lu par les lecteurs d'ecran (role=img)."""
    return f'<span class="avis-note" role="img" aria-label="{esc(_tx('note', n=note))}">{_etoiles_svg(note)}</span>'


def _initiale(nom: str) -> str:
    for caractere in nom.strip():
        if caractere.isalpha():
            return caractere.upper()
    return "·"


def _un_avis(a: dict) -> str:
    """Une carte d'avis : les etoiles, le titre, la citation (jamais retouchee), puis qui parle."""
    pays = nom_pays(a["pays"])
    titre = f"<h3>{esc(a['titre'])}</h3>" if a["titre"] else ""
    texte = esc(a["texte"].replace("\r\n", "\n").replace("\r", "\n")).replace("\n", "<br>")
    return (f'<article class="avis-carte"><span class="avis-guillemet" aria-hidden="true">“</span>{etoiles(a["note"])}{titre}'
            f'<blockquote class="avis-texte"><p>{texte}</p></blockquote>'
            f'<footer class="avis-auteur"><span class="avis-initiale" aria-hidden="true">{esc(_initiale(a["nom"]))}</span>'
            f'<div><strong>{esc(a["nom"])}</strong>'
            f'<span>{esc(pays)} · {esc(_tx(a["qualite"]))}{"، " if LANGUE == "ar" else ", "}{esc(_tx("depuis", mois=fmt_mois(a["depuis"])))}</span>'
            f'<span class="avis-date">{esc(_tx("publie", date=fmt_date(a["publie_le"])))}</span></div></footer></article>')


def _entete_page(avis: dict) -> str:
    """Au-dessus des cartes : la note moyenne en grand (a partir de AVIS_MOYENNE_MIN avis), sinon une phrase vraie."""
    n = avis["nombre"]
    if n >= AVIS_MOYENNE_MIN:
        moyenne = avis["moyenne_dixiemes"]
        return (f'<div class="avis-moyenne" role="group" aria-label="{esc(fmt_resume(avis))}">'
                f'<p class="avis-moyenne__note" aria-hidden="true"><span class="avis-moyenne__chiffre">{esc(fmt_moyenne(moyenne))}</span>'
                f'<span class="avis-note">{_etoiles_svg(int(round(moyenne / 10)))}</span></p>'
                f'<p class="avis-moyenne__texte" aria-hidden="true">{esc(_tx("moyenne", n=n))}</p></div>')
    return f'<p class="avis-intro">{esc(_tx("intro" if n > 1 else "intro1", n=n))}</p>'


def rendre_avis_section(nom: str, avis: dict) -> str:
    """Le corps d'une section générée de la page /fr/avis."""
    if nom != "liste":
        raise ValueError(f"Section générée inconnue : {nom}")
    # data-avis-liste : avis.js y remet la liste a jour, sans mise en production (directeur, 06/11/2026).
    if not avis["nombre"]:
        return f'<div class="avis-liste" data-avis-liste><p>{esc(_tx("vide"))}</p></div>'
    return ('<div class="avis-liste" data-avis-liste>' + _entete_page(avis) + '<div class="avis-grille">'
            + "".join(_un_avis(a) for a in avis["avis"]) + "</div></div>")


def rendre_avis_apercu(avis: dict, lien_html: str) -> str:
    """L'apercu des pages du site : les trois avis les plus recents. Vide tant qu'il y a moins de AVIS_APERCU_MIN avis publies."""
    # Sous le seuil, la section est la, cachee : avis.js la montre des qu'un avis est publie, sans mise en production.
    assez = avis["nombre"] >= AVIS_APERCU_MIN and len(avis["avis"]) >= AVIS_APERCU_MIN
    cartes = "".join(_un_avis(a) for a in avis["avis"][:AVIS_APERCU_MAX]) if assez else ""
    return (f'<section class="avis-apercu" id="avis-apercu" aria-labelledby="avis-apercu-titre" data-avis-apercu{"" if assez else " hidden"}>'
            f'<div class="avis-apercu__tete" data-revele><h2 id="avis-apercu-titre">{esc(_tx("titre"))}</h2>'
            f'<p>{esc(_tx("sous_titre"))}</p></div>'
            f'<div class="avis-grille" data-revele-enfants>{cartes}</div>'
            f'<p class="avis-apercu__lien" data-revele>{lien_html}</p></section>')


# --- Avis en direct (directeur, 06/11/2026) -----------------------------------------------------------------------
# La page porte la liste lue a la construction ; styles/avis.js la remet a jour depuis la base, dans le navigateur.
# Ce que la page recoit : l'adresse de la seule fonction publique avis_publics() et la cle PUBLIABLE de Supabase (faite
# pour etre publique, deja dans l'application). Jamais une autre cle : une cle secrete (sb_secret_, ou un jeton dont le
# role n'est pas « anon ») est refusee et la page reste sans mise a jour en direct.

def _role_jeton(cle: str) -> str | None:
    import base64
    morceaux = cle.split(".")
    if len(morceaux) != 3:
        return None
    try:
        charge = json.loads(base64.urlsafe_b64decode(morceaux[1] + "=" * (-len(morceaux[1]) % 4)).decode("utf-8"))
    except (ValueError, UnicodeDecodeError):
        return None
    return charge.get("role") if isinstance(charge, dict) else None


def cle_publiable(cle: str) -> bool:
    """Vrai seulement pour une cle faite pour le public : sb_publishable_..., ou l'ancien jeton de role « anon »."""
    if not isinstance(cle, str) or not re.fullmatch(r"[A-Za-z0-9._\-]{20,600}", cle):
        return False
    if cle.startswith("sb_publishable_"):
        return True
    if cle.startswith("sb_"):
        return False
    return _role_jeton(cle) == "anon"


def source_directe(env: dict[str, str] | None = None) -> dict | None:
    """L'adresse et la cle que la page peut porter, ou None (variables absentes, adresse non https, cle non publiable)."""
    env = os.environ if env is None else env
    url = (env.get("SUPABASE_URL") or "").strip().rstrip("/")
    cle = (env.get("SUPABASE_PUBLISHABLE_KEY") or env.get("SUPABASE_ANON_KEY") or "").strip()
    analyse = urlparse(url)
    if analyse.scheme != "https" or not analyse.hostname or analyse.path or analyse.query or not cle_publiable(cle):
        return None
    return {"url": f"https://{analyse.netloc}/rest/v1/rpc/avis_publics", "cle": cle}


def signature(avis: dict) -> str:
    """Meme calcul que signature() de avis.js : si la base rend la meme liste, la page n'est pas retouchee."""
    return f"{avis['nombre']}|" + "|".join(f"{a['publie_le'][:10]}~{a['nom']}~{len(a['texte'])}" for a in avis["avis"])


def bloc_direct(avis: dict, source: dict | None, assets: str) -> str:
    """Les reglages d'avis.js pour la langue des pages en construction, puis le script. Vide sans source."""
    if not source:
        return ""
    if LANGUE == "fr":
        pays = PAYS
    else:
        if not _PAYS_LANGUES:
            nom_pays("FR")
        pays = _PAYS_LANGUES.get(LANGUE, {})
    reglages = {"url": source["url"], "cle": source["cle"], "langue": LANGUE, "textes": TEXTES.get(LANGUE, TEXTES["fr"]),
                "mois": list(MOIS_LANGUES.get(LANGUE, MOIS)), "pays": pays, "signature": signature(avis),
                "seuils": {"moyenne": AVIS_MOYENNE_MIN, "apercu": AVIS_APERCU_MIN, "apercu_max": AVIS_APERCU_MAX}}
    donnees = json.dumps(reglages, ensure_ascii=False, separators=(",", ":")).replace("<", "\\u003c")
    return (f'<script type="application/json" id="avis-direct">{donnees}</script>'
            f'<script src="{assets}/avis.js" defer></script>')
