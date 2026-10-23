"""Signatures Gmail de Rewayah Academy, une par alias (directeur, 23/10/2026).

  python3 -I tool/signatures_courriel/generer.py [--page <page.html>]

Ecrit docs/current/signatures/<alias>.html (le fragment a coller dans Gmail) et,
avec --page, la page de collage (apercu, bouton Copier, consignes).
Legere : une table, styles en ligne, une image (logo PNG transparent de 3 Ko,
servi par le site), polices du systeme. Mentions de la societe exigees sur les
e-mails d'une societe anglaise (Companies Act 2006) : nom, numero, lieu
d'immatriculation, siege (site-public/content/pages.json, mentions legales).
"""
import base64
import html
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parents[2]
LOGO_URL = "https://rewayahacademy.com/fr/assets/courriel-logo-violet.png"
LOGO_LOCAL = RACINE / "site-public/assets/courriel-logo-violet.png"
SITE = "https://rewayahacademy.com/fr/"
ENCRE, ATTENUE, LIEN, VIOLET = "#110E20", "#655E70", "#6538E4", "#8652E6"
POLICE = "Arial,Helvetica,sans-serif"
SOCIETE = ("Rewayah Academy Ltd · société n° 16624644 (Angleterre et pays de Galles) · "
           "71-75 Shelton Street, Londres WC2H 9JQ, Royaume-Uni")

# alias -> (service affiche, a quoi sert la boite)
SIGNATURES = {
    "contact": ("Rewayah Academy", "Questions générales, familles, partenaires"),
    "support": ("Assistance", "Accès, compte, classes"),
    "inscriptions": ("Inscriptions", "Demandes et inscriptions des élèves"),
    "invoices": ("Facturation", "Factures et paiements"),
    "recrutement": ("Recrutement", "Candidatures des enseignants"),
}


def signature(alias: str, service: str, logo: str = LOGO_URL) -> str:
    adresse = f"{alias}@rewayahacademy.com"
    e = html.escape
    return (
        f'<table cellpadding="0" cellspacing="0" border="0" style="font-family:{POLICE};color:{ENCRE};border-collapse:collapse">'
        f'<tr><td style="padding:0 0 10px"><a href="{SITE}" style="text-decoration:none">'
        f'<img src="{logo}" width="132" height="37" alt="Rewayah Academy" style="display:block;border:0;width:132px;height:37px"></a></td></tr>'
        f'<tr><td style="padding:0"><div style="width:28px;height:2px;background:{VIOLET};font-size:0;line-height:0">&nbsp;</div></td></tr>'
        f'<tr><td style="padding:8px 0 0;font-family:{POLICE};font-size:13px;line-height:18px;font-weight:bold;color:{ENCRE}">{e(service)}</td></tr>'
        f'<tr><td style="padding:2px 0 0;font-family:{POLICE};font-size:12px;line-height:18px;color:{ATTENUE}">'
        f'<a href="mailto:{adresse}" style="color:{LIEN};text-decoration:none">{adresse}</a>'
        f'&nbsp;·&nbsp;<a href="{SITE}" style="color:{LIEN};text-decoration:none">rewayahacademy.com</a></td></tr>'
        f'<tr><td style="padding:8px 0 0;font-family:{POLICE};font-size:10px;line-height:14px;color:{ATTENUE};max-width:420px">{e(SOCIETE)}</td></tr>'
        f"</table>"
    )


def texte(alias: str, service: str) -> str:
    return f"{service}\n{alias}@rewayahacademy.com · rewayahacademy.com\n{SOCIETE}"


def page(sortie: Path) -> None:
    donnee = "data:image/png;base64," + base64.b64encode(LOGO_LOCAL.read_bytes()).decode()
    cartes = []
    for alias, (service, role) in SIGNATURES.items():
        sig = signature(alias, service)
        apercu = sig.replace(f'src="{LOGO_URL}"', f'src="{LOGO_URL}" data-repli="{donnee}" onerror="this.onerror=null;this.src=this.dataset.repli"')
        cartes.append(
            f'<section class="carte" aria-labelledby="t-{alias}"><header><h2 id="t-{alias}">{alias}@rewayahacademy.com</h2>'
            f'<p>{html.escape(role)}</p></header>'
            f'<div class="apercu" id="sig-{alias}">{apercu}</div>'
            f'<template id="html-{alias}">{sig}</template>'
            f'<textarea hidden id="txt-{alias}">{html.escape(texte(alias, service))}</textarea>'
            f'<button type="button" class="copier" id="b-{alias}" data-alias="{alias}">Copier la signature</button>'
            f'<span class="etat" id="e-{alias}" role="status"></span></section>'
        )
    modele = (Path(__file__).parent / "modele.html").read_text(encoding="utf-8")
    sortie.write_text(modele.replace("<!--CARTES-->", "\n".join(cartes)), encoding="utf-8")


def main() -> None:
    dossier = RACINE / "docs/current/signatures"
    for alias, (service, _) in SIGNATURES.items():
        (dossier / f"{alias}.html").write_text(signature(alias, service) + "\n", encoding="utf-8")
    if "--page" in sys.argv:
        page(Path(sys.argv[sys.argv.index("--page") + 1]))


if __name__ == "__main__":
    main()
