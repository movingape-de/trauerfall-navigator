# Website für App Store Connect

Apple verlangt für die Freigabe zwei erreichbare URLs: eine
Datenschutzrichtlinie und eine Support-Seite. Beide liegen hier fertig.

```
index.html        Start und Support
datenschutz.html  Datenschutzerklärung
impressum.html    Impressum
stil.css          Gestaltung, Farbwelt wie in der App
```

Anbieterangaben, Kontakt und Datum sind eingetragen; es stehen keine
Platzhalter mehr offen.

## Veröffentlichen über GitHub Pages

1. Den Inhalt dieses Ordners in einen Zweig `gh-pages` legen oder in einen
   Ordner `docs/` im Hauptzweig.
2. Im Repository unter *Settings → Pages* die Quelle auswählen.
3. Nach wenigen Minuten sind die Seiten erreichbar unter
   `https://movingape-de.github.io/trauerfall-navigator/`

Kürzester Weg:

```bash
git subtree push --prefix AppStore/website origin gh-pages
```

Danach in App Store Connect eintragen:

| Feld | URL |
|---|---|
| Datenschutzrichtlinie | `…/datenschutz.html` |
| Support-URL | `…/` |
