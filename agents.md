# AI Agents – SwiftUI (iOS 26) – “Infantino” Local Reviews

Documento operativo per sviluppo AI‑first dell’app **Infantino**: mostra recensioni locali e permette all’utente di aggiungere una recensione con **titolo**, **classificazione a stelle**, **descrizione del locale** ed **esperienza**. Target esclusivo **iOS 26**.

---

## 0) Obiettivi & Scope
- **Piattaforma:** iOS 26 (solo device che supportano iOS 26).
- **UI:** SwiftUI con pattern e stile **Liquid Glass** introdotti in iOS 26 (tab bar dinamica, in‑place alerts, context menu verticali, search in basso quando usata).
- **Dominio:** recensioni locali (ristoranti, bar, parchi, musei, ecc.).
- **MVP (2 schermate):**
  - **Schermata Principale (Home – Ristorante):**
    - Titolo attività in alto: **infantino**.
    - Sotto il titolo: **immagine del ristorante** affiancata a **descrizione**, **tabella orari** e **numero di telefono**.
    - Sezione **Recensioni del locale**: elenco di box con **stelle**, **titolo recensione**, **utente**, **data**, **corpo**.
    - **Bottone “+”** flottante in basso per aggiungere una recensione → apre la seconda schermata.
  - **Seconda Schermata (Aggiungi Recensione):** form con **Titolo**, **Stelle (1–5)**, **Descrizione locale**, **Esperienza**; salvataggio locale.
    - **UI/UX vincolata a `grafica.md`**: layout e stili della seconda schermata devono rispettare le specifiche grafiche contenute nel file `grafica.md` (box rating, box titolo, box corpo, bottone di invio).
- **Qualità minima:** build pulita, 0 errori lint, **copertura test ≥ 70%** sui moduli dell’MVP, accessibilità base (Dynamic Type, VoiceOver), localizzazione **it-IT** (en opzionale).

**Non‑goal (MVP):** autenticazione remota, sincronizzazione cloud, mappe avanzate, moderazione automatica, condivisione social.

---

## 1) Linee Guida iOS 26 (Design System)
- **Liquid Glass:** usare materiali traslucidi per barre, card e pannelli (`.background(.liquidGlass)` o equivalente). Evitare sfondi opachi.
- **Controlli dinamici:** micro‑animazioni a molla su press/hover/focus. Niente animazioni invasive.
- **Tab Bar Dinamica:** si ritrae allo scroll down e riappare allo scroll up.
- **Ricerca in basso:** search affordance a fondo schermo nelle viste elenco (se/quando presente).
- **In‑place Alerts:** conferme/azioni che si espandono dal controllo che le ha originate (no modali centrati, salvo casi eccezionali).
- **Context Menu verticali espansi** per comandi contestuali (modifica, elimina, condividi).
- **Icone & Widget:** palette compatibile con look **Tinted** e **Clear**. Non fissare colori hard‑coded.

**Accessibilità:** supporto Dynamic Type, label per immagini/icon, contrasto WCAG AA, rotori VoiceOver, action semantiche.

**Localizzazione:** chiavi `Localizable.strings` it (obbligatorio) + en (opzionale). Evitare testo hard‑coded nel codice.

---

## 2) Architettura & Struttura Repo
- **Architettura:** MVVM + NavigationStack, dipendenze via initializer injection, nessun singleton globale non giustificato.
- **Persistenza:** **SwiftData** per storage locale; migrazione semplice v1→v2.
- **Struttura cartelle:**
```
/App/
  /Sources/
    App.swift
    /DesignSystem/
    /Shared/
    /Features/
      /Home/               # schermata principale con header ristorante + lista recensioni
      /ReviewEditor/       # form aggiunta/modifica recensione
/Models/
/Storage/
/Tests/
/Scripts/
/.github/
```

---

## 3) Modello Dati (SwiftData)
**Entity: Review**
- `id: UUID`
- `title: String` (obbligatorio, 3–80 caratteri)
- `rating: Int` (1–5)
- `placeDescription: String` (descrizione locale, 10–500 caratteri)
- `experience: String` (esperienza personale, 10–1000 caratteri)
- `userName: String` (nome visualizzato dell’autore)
- `reviewDate: Date` (data della recensione)
- `createdAt: Date`
- `updatedAt: Date`

**Entity: Restaurant (statico per MVP)**
- `name: String` = "infantino"
- `heroImage: Data` (o asset locale)
- `description: String`
- `phoneNumber: String`
- `openingHours: [OpeningHour]` dove `OpeningHour { weekday: Int, open: String, close: String }`

**Regole di validazione**
- Titolo non vuoto; rating 1–5; testi con limiti indicati; `userName` non vuoto; `reviewDate` default = `Date()` alla creazione; trimming whitespace; rifiuto contenuti vietati (offensivi/PII nei log: **vietato loggare PII**).

---

## 4) IA dell’Informazione & Navigazione
- **Schermata A – Home (Ristorante “infantino”)**
  - **Header**: titolo grande "infantino".
  - **Sezione Ristorante**: layout orizzontale con **immagine** a sinistra e, a destra, **descrizione**, **tabella orari** (sette righe, lun–dom) e **numero di telefono** (tappable → azione chiamata con conferma in‑place).
  - **Sezione Recensioni**: lista di **ReviewCard** con stelle, titolo, utente, data, corpo (anteprima multilinea, espandibile).
  - **FAB “+”** flottante in basso a destra (Liquid Glass) che apre la **Schermata B**.
- **Schermata B – Aggiungi Recensione**
  - **Riferimento UI/UX:** attenersi a `grafica.md`.
  - **Sezioni obbligatorie:**
    - **Box Valutazione (stelle 1–5)** con feedback tattile e label accessibili.
    - **Box Titolo recensione** (TextField con limite caratteri e validazione istantanea).
    - **Box Corpo/Esperienza** (TextEditor multilinea con contatore caratteri e placeholder descrittivo della sezione *Esperienza*).
    - **Bottone Invia** sotto ai campi (stato disabilitato finché il form non è valido; mostra **alert in‑place** su esito).
  - **Validazione:** titolo ≥3 char; rating 1–5; corpo ≥10 char. Errori mostrati in‑place sotto il campo.

**Navigazione:** NavigationStack; transizione push da A → B; dismissal su successo con feedback tattile.

---

## 5) Agenti (ruoli, input, output, tool, policy)

### 5.1 Product Spec Agent
- **Missione:** trasformare richieste in PRD conciso per feature.
- **Input:** issue/idea.
- **Output:** `/Design/<feature>/SPEC.md` (scopo, user stories, criteri accettazione, non‑goal). Max 2 pagine.
- **Tool:** file‑ops.

### 5.2 UX/UI Agent (iOS 26)
- **Missione:** definire flussi, gerarchie, stati vuoti/errori, accessibilità; snippet SwiftUI preview minimal.
- **Vincoli iOS 26:** Liquid Glass, tab bar dinamica, search in basso, alert in‑place, context menu verticali.
- **Output:** `/Design/<feature>/UX.md` + wireframe testuali + palette.
- **Nota:** la **Seconda Schermata** deve rispettare `grafica.md` (box rating, box titolo, box corpo, bottone invia).

### 5.3 SwiftUI Codegen Agent
- **Missione:** implementare feature MVVM + SwiftData, senza storyboard.
- **Output:** codice in `/Features/<feature>/…` + aggiornamento `App.swift` e DesignSystem.
- **Check obbligatori:** build Release/Debug, nessun warning, anteprime compilabili.
- **Stile:** SwiftFormat + SwiftLint.

### 5.4 Test Agent
- **Missione:** test unitari ViewModel/validazione + test UI leggeri (snapshot opzionali).
- **Output:** `/Tests/<feature>Tests/…` con **copertura ≥ 70%**.

### 5.5 Security/Compliance Agent
- **Missione:** privacy, permessi, licenze; no PII nei log.
- **Blocca PR se:** nuovi permessi non usati, log sensibili, dipendenze senza licenza.

### 5.6 Release Agent
- **Missione:** versioning semantico, changelog, tag, build archivio; TestFlight (quando attivo).
- **Output:** `CHANGELOG.md`, bump versione, tag.

---

## 6) Workflow

### W1 – Nuova Feature
1) **Trigger:** issue/idea.
2) **Spec:** Product Spec Agent → `SPEC.md`.
3) **UX:** UX/UI Agent → `UX.md` + snippet preview.
4) **Code:** SwiftUI Codegen Agent → implementazione.
5) **Static checks:** `swiftformat` `swiftlint`.
6) **Test:** Test Agent → test verdi (≥70%).
7) **Security:** Security Agent → audit.
8) **PR:** apri PR con checklist e screenshot/gif.
9) **Review:** 1 approvazione umana.
10) **Merge:** `main`.

### W2 – Release
1) **Trigger:** tag `release/*` o merge in `main`.
2) **Build Archive:** `xcodebuild` archivio Release.
3) **Distribuzione:** `fastlane beta` (se configurato).

---

## 7) MVP: Criteri di Accettazione
- ✅ **Due schermate** implementate: Home e Aggiungi Recensione.
- ✅ Home mostra **titolo “infantino”**, **immagine ristorante**, **descrizione**, **tabella orari**, **numero di telefono tappabile** con conferma in‑place.
- ✅ Home elenca recensioni in **box** con **stelle**, **titolo**, **utente**, **data**, **corpo**.
- ✅ **Bottone “+”** in basso che apre la schermata di inserimento.
- ✅ Schermata **Aggiungi Recensione** conforme a **`grafica.md`** con: **box valutazione**, **box titolo**, **box corpo**, **bottone Invia**; validazione (titolo ≥3, corpo ≥10, rating 1–5) e salvataggio locale SwiftData.
- ✅ UI iOS 26 (Liquid Glass, alert in‑place, menu contestuali dove opportuni).
- ✅ Accessibilità (Dynamic Type, VoiceOver labels) e localizzazione **it-IT**.
- ✅ Test verdi; copertura ≥70%; lint/format puliti.

---

## 8) Design System (componenti chiave)
- **RestaurantHeader**: titolo, immagine, descrizione, tabella orari (sette righe), pulsante telefono (tappable → conferma in‑place).
- **ReviewCard**: card Liquid Glass con stelle (StarRatingView read‑only), titolo, utente, data, corpo (line‑limit con toggle “Altro”).
- **StarRatingView**: selezione 1–5 (editabile nel form); accessibile (increment/decrement via Rotor); haptics leggeri.
- **FloatingPlusButton (FAB)**: bottone “+” flottante in basso a destra con ombra vetrosa; apre editor.
- **AttachedAlert**: conferme e messaggi contestuali (salvato, eliminato, errore validazione).

**Temi:** supporto **Tinted Light**, **Tinted Dark**, **Clear Glass**; preferenza utente in Impostazioni (opzionale in MVP).

---

## 9) Telemetria, Privacy & Permessi
- **Permessi iOS:** nessuno nel MVP (niente posizione/foto). Se in futuro si aggiungono foto o geolocalizzazione → testi privacy in `Info.plist` localizzati.
- **Log:** no dati sensibili (titoli/testi utente non nel log in chiaro). Redazione stringhe lunghe.
- **Licenze:** elenco in `/THIRD_PARTY_LICENSES.md`.

---

## 10) Tooling & Comandi
```bash
# Format & Lint
swiftformat . --swiftversion 5.10
swiftlint

# Build & Test
xcodebuild -scheme Infantino -destination 'platform=iOS Simulator,name=iPhone 16' build
xcodebuild -scheme Infantino -destination 'platform=iOS Simulator,name=iPhone 16' test

# Versioning (esempio)
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString 1.0.0" App/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion 1" App/Info.plist

# Release (se configurato)
bundle exec fastlane beta
```

---

## 11) Prompt di Sistema per Agenti

**Product Spec Agent – system**
> Crea SPEC.md conciso (max 2 pagine) per app a **2 schermate**: Home (header ristorante + lista recensioni) e Aggiungi Recensione (form). Includi user stories e criteri.

**UX/UI Agent – system (iOS 26)**
> Disegna la Home con: titolo “infantino”; sezione ristorante con immagine + descrizione + tabella orari + telefono (tappable); sezione recensioni con ReviewCard; FAB “+” in basso a destra. **Seconda schermata**: attenersi a `grafica.md`: **Box Valutazione**, **Box Titolo**, **Box Corpo**, **Bottone Invia**. Usa Liquid Glass, micro‑animazioni, accessibilità. Fornisci snippet preview.

**SwiftUI Codegen Agent – system**
> Genera moduli `/Features/Home` e `/Features/ReviewEditor`. Modello SwiftData Review { id, title, rating(1–5), placeDescription, experience, userName, reviewDate, createdAt, updatedAt }. **ReviewEditor** deve implementare i componenti previsti da `grafica.md`: Box Valutazione, Box Titolo (TextField), Box Corpo/Esperienza (TextEditor), Bottone Invia (disabilitato finché non valido). Aggiungi validazione in tempo reale e alert in‑place su esito. Rispetta SwiftLint/SwiftFormat.

**Test Agent – system**
> Test ViewModel: validazione form, creazione Review con date e userName, ordinamento per data, formattazione stelle. Snapshot opzionali per ReviewCard. Copertura ≥70%.

**Security/Compliance Agent – system**
> Verifica assenza permessi superflui; nessun log PII; licenze terze parti. Blocca PR se violazioni.

**Release Agent – system**
> Versioning semantico, CHANGELOG, tag git, archivio Release. Escludi dati utente dall’artefatto.

---

## 12) Checklist PR (incollare nella descrizione)
- [ ] Ho eseguito `swiftformat` e `swiftlint`.
- [ ] Test locali verdi (copertura ≥70%).
- [ ] UI conforme a iOS 26 (Liquid Glass, alert in‑place, FAB, accessibilità).
- [ ] Localizzazione aggiornata (it-IT; en opzionale).
- [ ] Nessun nuovo permesso iOS non usato.
- [ ] Screenshot e GIF inclusi.

---

## 13) Roadmap MVP → v1
- [ ] Impostare `.swiftlint.yml` e `.swiftformat`.
- [ ] Implementare **Models/Review** + storage **SwiftData**.
- [ ] **Home**: header ristorante + lista recensioni + FAB.
- [ ] **ReviewEditor**: box valutazione, titolo, corpo, bottone invia (secondo `grafica.md`).
- [ ] **Settings** (opzionale post‑MVP): tema e export JSON.
- [ ] Test unitari (validazione + ViewModel) ≥70%.
- [ ] CI GitHub Actions (build, lint, test).
- [ ] Preparazione release 1.0.0.

---

> Questo file è la **fonte di verità** per gli agenti AI e per la CI del progetto Infantino (iOS 26). Aggiornalo quando evolvono requisiti o linee guida di piattaforma.
