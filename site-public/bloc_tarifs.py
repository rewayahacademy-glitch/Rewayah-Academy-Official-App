"""Tarifs publics du site : lecture dans la base au build, validation, mise en forme.

Module charge par build_site.py. Aucune dependance hors bibliotheque standard.
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


def esc(value: object) -> str:
    return html.escape(str(value), quote=True)


def _unique_object(pairs: list[tuple[str, object]]) -> dict[str, object]:
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"Duplicate JSON key: {key}")
        result[key] = value
    return result


# ---------------------------------------------------------------------------
# Tarifs publics
#
# Les prix viennent de la base, lus AU MOMENT DU BUILD par la seule fonction
# publique `public.tarifs_publics()` (appel POST de PostgREST, clé publiable).
# Le navigateur ne parle jamais à la base : ni URL ni clé dans le HTML produit.
# Sans variables d'environnement, ou sur toute erreur, repli sur le fichier de
# la décision `docs/current/tarifs-2026-10-18.json`, avec un message clair.
# ---------------------------------------------------------------------------

TARIFS_DECISION = ROOT.parent / "docs" / "current" / "tarifs-2026-10-18.json"
TARIFS_COPIE = ROOT / "content" / "tarifs.json"  # copie de la decision, pour un build hors du depot complet
TARIFS_FALLBACK = TARIFS_DECISION if TARIFS_DECISION.exists() else TARIFS_COPIE
TARIFS_DELAI_SECONDES = 8
TARIFS_TAILLE_MAX = 64 * 1024
NBSP = " "
NNBSP = " "

_POLITIQUE_CLES = {
    "version", "dateEffet", "devise", "horsTaxes", "ageAdulte", "tarifEnfantMineur",
    "tarifAdulteMineur", "essaiActif", "essaisMax", "remisesFoyer", "prepaiement",
    "parrainageCreditMineur", "bourse", "cumulMaxPourMille", "classes",
}


class TarifsInvalides(ValueError):
    """La réponse reçue n'a pas la forme attendue."""


def _cles_exactes(valeur: object, attendues: set[str], chemin: str, facultatives: set[str] = frozenset()) -> dict:
    if not isinstance(valeur, dict):
        raise TarifsInvalides(f"{chemin} doit être un objet")
    inconnues = set(valeur) - attendues
    if inconnues:
        raise TarifsInvalides(f"{chemin} : clés inconnues {sorted(inconnues)}")
    manquantes = attendues - set(valeur) - facultatives
    if manquantes:
        raise TarifsInvalides(f"{chemin} : clés manquantes {sorted(manquantes)}")
    return valeur


def _entier(valeur: object, chemin: str, bas: int, haut: int, nul_ok: bool = False) -> int | None:
    if valeur is None and nul_ok:
        return None
    if isinstance(valeur, bool) or not isinstance(valeur, int) or not bas <= valeur <= haut:
        raise TarifsInvalides(f"{chemin} : entier attendu entre {bas} et {haut}")
    return valeur


def _booleen(valeur: object, chemin: str) -> bool:
    if not isinstance(valeur, bool):
        raise TarifsInvalides(f"{chemin} : booléen attendu")
    return valeur


def _politique_valide(brute: object, chemin: str) -> dict:
    p = _cles_exactes(brute, _POLITIQUE_CLES, chemin)
    if not isinstance(p["version"], str) or not re.fullmatch(r"[A-Za-z0-9._-]{1,32}", p["version"]):
        raise TarifsInvalides(f"{chemin}.version invalide")
    if not isinstance(p["dateEffet"], str) or not re.fullmatch(r"\d{4}-\d{2}-\d{2}", p["dateEffet"]):
        raise TarifsInvalides(f"{chemin}.dateEffet invalide")
    try:
        date.fromisoformat(p["dateEffet"])
    except ValueError as erreur:
        raise TarifsInvalides(f"{chemin}.dateEffet invalide") from erreur
    if not isinstance(p["devise"], str) or not re.fullmatch(r"[A-Z]{3}", p["devise"]):
        raise TarifsInvalides(f"{chemin}.devise invalide")
    _booleen(p["horsTaxes"], f"{chemin}.horsTaxes")
    _entier(p["ageAdulte"], f"{chemin}.ageAdulte", 10, 30)
    _entier(p["tarifEnfantMineur"], f"{chemin}.tarifEnfantMineur", 1, 10_000_000)
    _entier(p["tarifAdulteMineur"], f"{chemin}.tarifAdulteMineur", 1, 10_000_000)
    _booleen(p["essaiActif"], f"{chemin}.essaiActif")
    _entier(p["essaisMax"], f"{chemin}.essaisMax", 0, 10)
    remises = p["remisesFoyer"]
    if not isinstance(remises, list) or len(remises) > 10:
        raise TarifsInvalides(f"{chemin}.remisesFoyer : liste de 10 éléments au plus")
    rangs = []
    for i, r in enumerate(remises):
        nom = f"{chemin}.remisesFoyer[{i}]"
        if not isinstance(r, dict) or "aPartirDuRang" not in r:
            raise TarifsInvalides(f"{nom} invalide")
        if set(r) == {"aPartirDuRang", "pourMille"}:
            _entier(r["pourMille"], f"{nom}.pourMille", 0, 1000)
        elif set(r) == {"aPartirDuRang", "montantMineur"}:
            _entier(r["montantMineur"], f"{nom}.montantMineur", -10_000_000, 0)
        else:
            raise TarifsInvalides(f"{nom} : clés inattendues {sorted(r)}")
        rangs.append(_entier(r["aPartirDuRang"], f"{nom}.aPartirDuRang", 2, 20))
    if rangs != sorted(set(rangs)):
        raise TarifsInvalides(f"{chemin}.remisesFoyer : rangs à ranger du plus petit au plus grand, sans doublon")
    if p["prepaiement"] is not None:
        pre = _cles_exactes(p["prepaiement"], {"trimestrielPourMille", "annuelPourMille"}, f"{chemin}.prepaiement")
        for cle in pre:
            _entier(pre[cle], f"{chemin}.prepaiement.{cle}", 0, 1000, nul_ok=True)
    _entier(p["parrainageCreditMineur"], f"{chemin}.parrainageCreditMineur", 0, 10_000_000, nul_ok=True)
    if p["bourse"] is not None:
        b = _cles_exactes(p["bourse"], {"pourMille", "dureeMois"}, f"{chemin}.bourse")
        _entier(b["pourMille"], f"{chemin}.bourse.pourMille", 0, 1000)
        _entier(b["dureeMois"], f"{chemin}.bourse.dureeMois", 1, 24, nul_ok=True)
    _entier(p["cumulMaxPourMille"], f"{chemin}.cumulMaxPourMille", 0, 1000, nul_ok=True)
    c = _cles_exactes(p["classes"], {"tailleEnfant", "tailleAdulte", "ouvertureMinimum"}, f"{chemin}.classes")
    for cle in c:
        _entier(c[cle], f"{chemin}.classes.{cle}", 1, 50)
    return p


def valider_tarifs(brut: object) -> dict:
    """Vérifie la réponse de `tarifs_publics()` : types, bornes, clés exactes."""
    racine = _cles_exactes(brut, {"courante", "suivante"}, "réponse")
    if racine["courante"] is None:
        raise TarifsInvalides("aucune politique en vigueur")
    resultat = {"courante": _politique_valide(racine["courante"], "courante"), "suivante": None}
    if racine["suivante"] is not None:
        resultat["suivante"] = _politique_valide(racine["suivante"], "suivante")
        if resultat["suivante"]["dateEffet"] <= resultat["courante"]["dateEffet"]:
            raise TarifsInvalides("la politique suivante doit prendre effet après la courante")
    return resultat


def _ouvrir_sans_redirection() -> "urllib.request.OpenerDirector":
    class SansRedirection(urllib.request.HTTPRedirectHandler):
        def redirect_request(self, *args, **kwargs):  # noqa: D401
            return None
    return urllib.request.build_opener(SansRedirection)


def tarifs_depuis_base(env: dict[str, str] | None = None, ouvrir=None) -> dict:
    """Appelle `public.tarifs_publics()` avec la clé publiable. Lève en cas d'échec."""
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
        f"{url}/rest/v1/rpc/tarifs_publics", data=b"{}", method="POST",
        headers={"apikey": cle, "Content-Type": "application/json", "Accept": "application/json"})
    ouvrir = ouvrir or _ouvrir_sans_redirection().open
    try:
        with ouvrir(demande, timeout=TARIFS_DELAI_SECONDES) as reponse:
            if getattr(reponse, "status", 200) != 200:
                raise ValueError(f"réponse HTTP {reponse.status}")
            corps = reponse.read(TARIFS_TAILLE_MAX + 1)
    except urllib.error.HTTPError as erreur:
        raise ValueError(f"réponse HTTP {erreur.code}") from None
    except urllib.error.URLError as erreur:
        raise ValueError(f"base injoignable ({type(erreur.reason).__name__})") from None
    if len(corps) > TARIFS_TAILLE_MAX:
        raise TarifsInvalides("réponse trop volumineuse")
    try:
        brut = json.loads(corps.decode("utf-8"), object_pairs_hook=_unique_object)
    except (UnicodeDecodeError, ValueError) as erreur:
        raise TarifsInvalides("réponse qui n'est pas du JSON valide") from erreur
    return valider_tarifs(brut)


def tarifs_depuis_fichier(chemin: Path = TARIFS_FALLBACK) -> dict:
    """Le fichier de la décision, mis dans la même forme que la réponse de la base."""
    f = json.loads(chemin.read_text(encoding="utf-8"), object_pairs_hook=_unique_object)
    remises = f["remises"]
    politique = {
        "version": f["version"],
        "dateEffet": f.get("date_effet", f["version"]),
        "devise": f["devise"],
        "horsTaxes": f["prix_hors_taxes"],
        "ageAdulte": f["formules"]["adulte"]["age_min"],
        "tarifEnfantMineur": f["formules"]["enfant"]["prix_mensuel_mineur"],
        "tarifAdulteMineur": f["formules"]["adulte"]["prix_mensuel_mineur"],
        "essaiActif": f["essai_gratuit"],
        "essaisMax": 0,
        "remisesFoyer": [{"aPartirDuRang": r["a_partir_du_rang"], "pourMille": r["pour_mille"]}
                         for r in remises["foyer"]],
        "prepaiement": {"trimestrielPourMille": remises["prepaiement"]["trimestriel_pour_mille"],
                        "annuelPourMille": remises["prepaiement"]["annuel_pour_mille"]},
        "parrainageCreditMineur": remises["parrainage_credit_mineur"],
        "bourse": {"pourMille": remises["bourse"]["pour_mille"], "dureeMois": remises["bourse"]["revue_mois"]},
        "cumulMaxPourMille": remises["cumul_max_pour_mille"],
        "classes": {"tailleEnfant": f["formules"]["enfant"]["groupe_max"],
                    "tailleAdulte": f["formules"]["adulte"]["groupe_max"],
                    "ouvertureMinimum": f["regles_publiques"]["groupe_ouvre_a_partir_de"]},
    }
    return valider_tarifs({"courante": politique, "suivante": None})


def formules_editoriales(chemin: Path = TARIFS_FALLBACK) -> dict:
    """Ce que la base ne porte pas : séances par semaine, durées, pauses, âge de départ."""
    f = json.loads(chemin.read_text(encoding="utf-8"), object_pairs_hook=_unique_object)
    return {nom: {cle: f["formules"][nom][cle]
                  for cle in ("age_min", "seances_par_semaine", "duree_minutes", "pause_minutes")}
            for nom in ("enfant", "adulte")}


def encarts_publics(chemin: Path = TARIFS_FALLBACK) -> dict:
    """Les textes que la décision du 18/10 (consigne 3) fait publier tels quels sur les cours, les familles et le recrutement.
    Seule la typographie change : une espace insécable avant « $ » et « % », pour qu'un montant ne se coupe pas."""
    f = json.loads(chemin.read_text(encoding="utf-8"), object_pairs_hook=_unique_object)
    return {cle: re.sub(r"(\d) ([$%])", "\\1\u00a0\\2", texte) for cle, texte in f["site_public"].items()}


def encarts_suivis(politique: dict) -> dict:
    """Les encarts tels quels quand la politique affichée est celle de la décision. Si la base publie d'autres
    valeurs (prix, âge adulte, tailles de classe), les mêmes phrases reprennent celles de la base, paie comprise :
    le site ne montre jamais deux prix pour la même formule."""
    textes = encarts_publics()
    fichier = politique_affichee(tarifs_depuis_fichier())
    cles = ("tarifEnfantMineur", "tarifAdulteMineur", "ageAdulte", "devise")
    if all(politique[k] == fichier[k] for k in cles) and politique["classes"] == fichier["classes"]:
        return textes
    part = json.loads(TARIFS_FALLBACK.read_text(encoding="utf-8"))["enseignant"]["part_du_prix_pour_mille"]

    def valeurs(q: dict) -> list[str]:
        c, age = q["classes"], q["ageAdulte"]
        paie_enfant = round(q["tarifEnfantMineur"] * part["enfant"] * c["tailleEnfant"] / 100_000)
        paie_adulte = round(q["tarifAdulteMineur"] * part["adulte"] * c["tailleAdulte"] / 100_000)
        dollars = lambda n: fmt_montant(n * 100, q["devise"])
        return [fmt_montant(q["tarifEnfantMineur"], q["devise"]), fmt_montant(q["tarifAdulteMineur"], q["devise"]),
                f"{AGE_ENFANT_MIN} à {age - 1} ans", f"à partir de {age} ans",
                f"de {c['ouvertureMinimum']} à {c['tailleEnfant']} élèves",
                f"de {c['ouvertureMinimum']} à {c['tailleAdulte']} personnes",
                f"classes de {c['ouvertureMinimum']} à {c['tailleAdulte']} élèves",
                dollars(paie_enfant), dollars(paie_adulte), dollars(round(3 * paie_adulte))]

    anciennes, nouvelles = valeurs(fichier), valeurs(politique)
    suivis = {}
    for cle, texte in textes.items():
        # En deux temps, par des jetons, pour qu'une nouvelle valeur ne soit jamais remplacée à son tour.
        for i, ancienne in enumerate(anciennes):
            texte = re.sub(rf"(?<![\d,]){re.escape(ancienne)}", f"\x00{i}\x00", texte)
        for i, nouvelle in enumerate(nouvelles):
            texte = texte.replace(f"\x00{i}\x00", nouvelle)
        suivis[cle] = texte
    return suivis


def charger_tarifs(env: dict[str, str] | None = None, ouvrir=None, journal=print) -> tuple[dict, str]:
    """Base d'abord, fichier de la décision sinon. Rend (tarifs, origine)."""
    try:
        tarifs = tarifs_depuis_base(env, ouvrir)
        journal("Tarifs : lus dans la base (public.tarifs_publics), version "
                f"{tarifs['courante']['version']}.")
        return tarifs, "base"
    except LookupError as erreur:
        raison = f"{erreur}"
    except (TarifsInvalides, ValueError, OSError) as erreur:
        raison = f"{erreur}"
    journal(f"Tarifs : repli sur le fichier de la décision, {TARIFS_FALLBACK.name} ({raison}).")
    return tarifs_depuis_fichier(), "fichier"


# --- Mise en forme -------------------------------------------------------

SYMBOLES = {"USD": "$", "EUR": "€", "GBP": "£"}
NOMS_DEVISES = {"USD": "dollars américains", "EUR": "euros", "GBP": "livres sterling"}
MOIS = ("janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août",
        "septembre", "octobre", "novembre", "décembre")


def fmt_montant(mineur: int, devise: str) -> str:
    dollars, cents = divmod(abs(mineur), 100)
    texte = f"{dollars:,}".replace(",", NNBSP) + (f",{cents:02d}" if cents else "")
    return f"{'-' if mineur < 0 else ''}{texte}{NBSP}{SYMBOLES.get(devise, devise)}"


def fmt_pour_mille(pour_mille: int) -> str:
    entier, reste = divmod(pour_mille, 10)
    return f"{entier}{',' + str(reste) if reste else ''}{NBSP}%"


def fmt_date(iso: str) -> str:
    d = date.fromisoformat(iso)
    return f"{'1er' if d.day == 1 else d.day} {MOIS[d.month - 1]} {d.year}"


def fmt_rang(n: int) -> str:
    return "1er" if n == 1 else f"{n}e"


def prix_apres_remise(prix: int, rang: int, remises: list[dict]) -> int:
    """Prix d'une place au rang donné dans le foyer (arrondi au centime, demi vers le haut)."""
    applicable = None
    for r in remises:
        if rang >= r["aPartirDuRang"]:
            applicable = r
    if applicable is None:
        return prix
    if "pourMille" in applicable:
        return (prix * (1000 - applicable["pourMille"]) + 500) // 1000
    return max(0, prix + applicable["montantMineur"])


def lignes_remises_rang(politique: dict) -> list[tuple[str, str]]:
    """Les lignes « membre du foyer / remise » : la première sans remise, puis une par palier."""
    remises = politique["remisesFoyer"]
    if not remises:
        return [("Tous les membres", "Aucune")]
    lignes = []
    premier = remises[0]["aPartirDuRang"]
    lignes.append(("1er membre" if premier == 2 else f"1er au {fmt_rang(premier - 1)} membre", "Aucune"))
    for i, r in enumerate(remises):
        suivant = remises[i + 1]["aPartirDuRang"] if i + 1 < len(remises) else None
        rang = r["aPartirDuRang"]
        if suivant is None:
            etiquette = f"{fmt_rang(rang)} membre et suivants"
        elif suivant == rang + 1:
            etiquette = f"{fmt_rang(rang)} membre"
        else:
            etiquette = f"{fmt_rang(rang)} au {fmt_rang(suivant - 1)} membre"
        if "pourMille" in r:
            valeur = fmt_pour_mille(r["pourMille"])
        else:
            valeur = fmt_montant(-r["montantMineur"], politique["devise"]) + " en moins"
        lignes.append((etiquette, valeur))
    return lignes


def famille_enfants(politique: dict) -> list[tuple[int, int]]:
    """Total mensuel pour 1, 2, 3... enfants (jusqu'au palier le plus haut, plus un)."""
    remises = politique["remisesFoyer"]
    haut = max(3, (remises[-1]["aPartirDuRang"] + 1) if remises else 3)
    total, lignes = 0, []
    for n in range(1, haut + 1):
        total += prix_apres_remise(politique["tarifEnfantMineur"], n, remises)
        lignes.append((n, total))
    return lignes


def politique_affichee(tarifs: dict) -> dict:
    """La politique que le site met en avant : la suivante si elle est déjà publiée."""
    return tarifs["suivante"] or tarifs["courante"]


def note_date_effet(tarifs: dict, aujourdhui: date) -> str:
    """Phrase sur la date d'effet quand la politique affichée n'est pas encore en vigueur."""
    p = politique_affichee(tarifs)
    if date.fromisoformat(p["dateEffet"]) <= aujourdhui:
        return ""
    texte = f"Ces tarifs s'appliquent à partir du {fmt_date(p['dateEffet'])}."
    if tarifs["suivante"] is not None:
        c = tarifs["courante"]
        texte += (f" Jusqu'à cette date : {fmt_montant(c['tarifEnfantMineur'], c['devise'])} par mois"
                  f" pour un enfant et {fmt_montant(c['tarifAdulteMineur'], c['devise'])} pour un adulte,"
                  " hors taxes.")
    return texte


def _tableau(legende: str, colonnes: tuple[str, str], lignes: list[tuple[str, str]]) -> str:
    corps = "".join(f'<tr><th scope="row">{esc(a)}</th><td>{esc(b)}</td></tr>' for a, b in lignes)
    return (f'<table class="price-table"><caption>{esc(legende)}</caption><thead><tr>'
            f'<th scope="col">{esc(colonnes[0])}</th><th scope="col">{esc(colonnes[1])}</th></tr></thead>'
            f'<tbody>{corps}</tbody></table>')


def lignes_grille(politique: dict) -> list[tuple[str, str]]:
    age = politique["ageAdulte"]
    return [(f"Enfants et adolescents, {AGE_ENFANT_MIN} à {age - 1} ans",
             fmt_montant(politique["tarifEnfantMineur"], politique["devise"])),
            (f"Adultes, {age} ans et plus", fmt_montant(politique["tarifAdulteMineur"], politique["devise"]))]


AGE_ENFANT_MIN = formules_editoriales()["enfant"]["age_min"]


def rendre_tarifs_section(nom: str, tarifs: dict, aujourdhui: date) -> str:
    """Le corps d'une section de la page /fr/tarifs construite à partir des données."""
    p = politique_affichee(tarifs)
    devise = p["devise"]
    if nom == "grille":
        hors_taxes = "hors taxes" if p["horsTaxes"] else "taxes comprises"
        html_ = _tableau(f"Par élève et par mois, {hors_taxes}", ("Formule", "Prix par mois"), lignes_grille(p))
        # Les monnaies du paiement sont celles de la décision (mentions_sous_la_grille), pas « votre monnaie ».
        notes = [f"Prix en {NOMS_DEVISES.get(devise, devise)}, {hors_taxes}. La taxe de votre pays et le montant"
                 " en euros, livres ou dollars canadiens s’affichent au paiement."]
        date_note = note_date_effet(tarifs, aujourdhui)
        if date_note:
            notes.insert(0, date_note)
        return html_ + "".join(f'<p class="price-note">{esc(n)}</p>' for n in notes)
    if nom == "remises":
        parties = [_tableau("Remise selon le rang dans le foyer", ("Rang d’inscription", "Remise"),
                            lignes_remises_rang(p))]
        points = []
        pre = p["prepaiement"]
        if pre and pre["trimestrielPourMille"]:
            points.append(f"Paiement au trimestre : {fmt_pour_mille(pre['trimestrielPourMille'])} de remise.")
        if pre and pre["annuelPourMille"]:
            points.append(f"Paiement à l'année : {fmt_pour_mille(pre['annuelPourMille'])} de remise.")
        if p["parrainageCreditMineur"]:
            credit = fmt_montant(p["parrainageCreditMineur"], devise)
            points.append(f"Parrainage : {credit} de crédit pour vous et pour la famille parrainée,"
                          " après son premier mois.")
        if p["bourse"] and p["bourse"]["pourMille"]:
            duree = f", revue tous les {p['bourse']['dureeMois']} mois" if p["bourse"]["dureeMois"] else ""
            points.append(f"Bourse : {fmt_pour_mille(p['bourse']['pourMille'])} de remise pour les familles en difficulté"
                          f" et les personnes récemment converties, sur demande écrite{duree}."
                          " Les places sont limitées et la bourse ne se cumule avec aucune autre remise.")
        if p["cumulMaxPourMille"]:
            points.append(f"Les remises du foyer, du prépaiement et du parrainage ne dépassent jamais"
                          f" {fmt_pour_mille(p['cumulMaxPourMille'])} du prix.")
        liste = ('<ul class="fact-list">' + "".join(f"<li><strong>{esc(t)}</strong></li>" for t in points) + "</ul>"
                 if points else "")
        return parties[0] + liste
    if nom == "famille":
        lignes = [(f"{n} enfant{'s' if n > 1 else ''}", fmt_montant(total, devise))
                  for n, total in famille_enfants(p)]
        return (_tableau("Total par mois pour une famille d’enfants", ("Inscrits", "Total par mois"), lignes)
                + '<p class="price-note">Le rang suit l’ordre d’inscription dans le foyer. Montants hors taxes.</p>')
    if nom == "classes":
        formules = formules_editoriales()
        c = p["classes"]

        def ligne(public: str, cle: str, taille: int) -> tuple[str, str]:
            f = formules[cle]
            pause = f" dont {f['pause_minutes']} min de pause" if f["pause_minutes"] else ""
            duree = f["duree_minutes"]
            heures = f"{duree // 60} h" + (f" {duree % 60}" if duree % 60 else "") if duree >= 60 else f"{duree} min"
            return public, (f"{f['seances_par_semaine']} séances par semaine, {heures}{pause}, "
                            f"de {c['ouvertureMinimum']} à {taille} élèves")
        lignes = [ligne("Enfants et adolescents", "enfant", c["tailleEnfant"]),
                  ligne("Adultes", "adulte", c["tailleAdulte"])]
        return (_tableau("Une classe, un enseignant attitré, une heure fixe", ("Public", "Organisation"), lignes)
                + f'<p class="price-note">Une classe ouvre dès {c["ouvertureMinimum"]} inscrits. Avant cela, vous êtes'
                  ' en liste d’attente et rien n’est facturé.</p>')
    if nom == "fiches-eleves":
        e = encarts_suivis(p)

        # Les phrases de l'encart, sans en changer un mot, posees une par ligne pour se lire d'un coup d'oeil.
        def lignes(texte: str) -> str:
            phrases = re.split(r"(?<=\.) (?=[A-ZÀ-Ý0-9])", texte)
            return '<ul class="fiche__lignes">' + "".join(f"<li>{esc(ph)}</li>" for ph in phrases) + "</ul>"
        return ('<div class="fiches">'
                f'<article class="fiche"><h3>Enfants et\u00a0adolescents</h3>{lignes(e["encart_enfant"])}</article>'
                f'<article class="fiche"><h3>Adultes</h3>{lignes(e["encart_adulte"])}</article></div>')
    if nom == "fiche-enseignant":
        return f'<div class="fiches"><article class="fiche"><p>{esc(encarts_suivis(p)["encart_enseignant"])}</p></article></div>'
    raise ValueError(f"Section générée inconnue : {nom}")


# --- Simulateur ------------------------------------------------------------
# Les seules valeurs que le navigateur connait viennent d'ici. Le calcul de
# reference est en JavaScript (styles/site.js) ; calcul_reference() en Python
# sert aux tests, qui comparent les deux sur les memes cas.

MOIS_TRIMESTRE = 3   # un trimestre paye d'avance
MOIS_ANNEE = 12      # une annee payee d'avance
UNITE_MINEURE = 100  # centimes dans une unite de la devise
ECHELLE = 1000       # les pourcentages sont en pour mille
POURCENT = 100       # un pourcentage entier
ELEVES_MAX = 10      # nombre d'eleves propose au simulateur


def donnees_simulateur_dict(tarifs: dict) -> dict:
    p = politique_affichee(tarifs)
    pre = p["prepaiement"] or {}
    return {
        "devise": p["devise"],
        "symbole": SYMBOLES.get(p["devise"], p["devise"]),
        "horsTaxes": p["horsTaxes"],
        "essaiActif": p["essaiActif"],
        "ageEnfantMin": AGE_ENFANT_MIN,
        "ageAdulte": p["ageAdulte"],
        "enfant": p["tarifEnfantMineur"],
        "adulte": p["tarifAdulteMineur"],
        "remises": p["remisesFoyer"],
        "prepaiement": {
            "trimestre": {"pourMille": pre.get("trimestrielPourMille"), "mois": MOIS_TRIMESTRE},
            "annee": {"pourMille": pre.get("annuelPourMille"), "mois": MOIS_ANNEE},
        },
        "parrainageCredit": p["parrainageCreditMineur"],
        "bourse": ({"pourMille": p["bourse"]["pourMille"]} if p["bourse"] and p["bourse"]["pourMille"] else None),
        "cumulMax": p["cumulMaxPourMille"],
        "echelle": ECHELLE,
        "pourcent": POURCENT,
        "unite": UNITE_MINEURE,
        "elevesMax": ELEVES_MAX,
    }


def donnees_simulateur(tarifs: dict) -> str:
    """JSON a poser dans la page. Le « < » est echappe pour ne jamais fermer la balise."""
    texte = json.dumps(donnees_simulateur_dict(tarifs), ensure_ascii=False, separators=(",", ":"))
    return texte.replace("<", "\\u003c").replace(">", "\\u003e").replace("&", "\\u0026")


def _prix_rang(prix: int, rang: int, remises: list[dict], echelle: int) -> int:
    applicable = None
    for r in remises:
        if rang >= r["aPartirDuRang"]:
            applicable = r
    if applicable is None:
        return prix
    if "pourMille" in applicable:
        return (prix * (echelle - applicable["pourMille"]) + echelle // 2) // echelle
    return max(0, prix + applicable["montantMineur"])


def calcul_reference(d: dict, eleves: list[dict], paiement: str = "mensuel", parrainage: bool = False) -> dict:
    """Calcul de reference en entiers (unite mineure), meme regle que le JavaScript.

    eleves : liste ordonnee (ordre d'inscription) de {"age": int, "bourse": bool}.
    paiement : "mensuel", "trimestre" ou "annee".
    """
    e = d["echelle"]
    pre = d["prepaiement"].get(paiement) if paiement != "mensuel" else None
    n = pre["mois"] if pre else 1
    lignes, marge, total = [], 0, 0
    for rang, el in enumerate(eleves, 1):
        tarif = d["enfant"] if el["age"] < d["ageAdulte"] else d["adulte"]
        base = tarif * n
        if el["bourse"] and d["bourse"]:
            remise = ((tarif * d["bourse"]["pourMille"] + e // 2) // e) * n
            lignes.append({"base": base, "foyer": 0, "prepaiement": 0, "bourse": remise, "plafond": 0,
                           "total": base - remise})
            total += base - remise
            continue
        foyer = (tarif - _prix_rang(tarif, rang, d["remises"], e)) * n
        prep = (base * pre["pourMille"] + e // 2) // e if pre and pre["pourMille"] else 0
        remise = foyer + prep
        plafond_max = base * d["cumulMax"] // e if d["cumulMax"] is not None else None
        ajust = 0
        if plafond_max is not None and remise > plafond_max:
            ajust = remise - plafond_max
            remise = plafond_max
        du = base - remise
        if n > 1:
            du = ((du + d["unite"] // 2) // d["unite"]) * d["unite"]
        lignes.append({"base": base, "foyer": foyer, "prepaiement": prep, "bourse": 0, "plafond": ajust,
                       "total": du})
        total += du
        if plafond_max is not None:
            marge += max(0, plafond_max - remise)
    credit = 0
    if parrainage and d["parrainageCredit"] and any(not (x["bourse"] and d["bourse"]) for x in eleves):
        credit = d["parrainageCredit"] if d["cumulMax"] is None else min(d["parrainageCredit"], marge)
    premier = total - credit
    return {"mois": n, "lignes": lignes, "credit": credit, "totalPeriode": premier,
            "totalSansCredit": total}
