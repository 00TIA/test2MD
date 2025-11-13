# grafica.md — Schermata B: **Aggiungi Recensione** (Infantino · iOS 26)

Documento di specifica **UI/UX** per la seconda schermata dell’app **Infantino**. Questo file è vincolante per l’implementazione del modulo **ReviewEditor**.

---

## 1) Obiettivo & Vincoli
- **Obiettivo:** consentire all’utente di inserire una nuova recensione completa e valida con il minimo attrito.
- **Device/OS:** solo **iOS 26**.
- **Framework:** **SwiftUI** con pattern **Liquid Glass**.
- **Persistenza:** salvataggio locale via **SwiftData** (gestito dallo strato app).
- **Accessibilità:** pieno supporto **Dynamic Type**, **VoiceOver**, **Rotor**, contrasti **WCAG AA**.
- **Localizzazione:** **it-IT** (obbligatoria), **en** (opzionale). Nessun testo hard-coded nel codice.

---

## 2) Struttura & Layout
- **Contenitore:** `NavigationStack` → vista scrollabile verticale (performance-ready per Dynamic Type XL+).
- **Sezioni in ordine visivo e di focus:**
  1. **Box Valutazione (stelle 1–5)**
  2. **Box Titolo recensione**
  3. **Box Descrizione del locale**
  4. **Box Esperienza**
  5. **Bottone Invia** (sticky-safe: sempre raggiungibile, ma non fixed; v. note sotto)
- **Spaziatura verticale:** 12pt tra campi; 20–24pt tra blocchi principali.
- **Margini orizzontali:** 20pt (iPhone), 28pt (iPad/large). Rispetto delle **safe areas**.
- **Scroll to error/first invalid:** allo **tap su Invia** o **onSubmit** del campo, la vista scorre dolcemente al primo errore.
- **Comportamento tastiera:** i campi TextEditor usano **toolbar** con pulsante *Fine*; spaziatura automatica per evitare overlap.

### 2.1 Liquid Glass & Materiali
- Card/box con **materiale traslucido** (Liquid Glass) coerente con lo **stile iOS 26**.
- **Angoli poco rotondi**: raggio **12–14pt** per contenitori e controlli (no 24pt).
- **Ombre** soffuse, solo per separazione dal background (no drop shadow pesanti).
- **Colori**: usare esclusivamente la **palette Blu Oltreoceano** (Primary) e **Bianco Ottico** (Background/Surface). Definire token semantici:
  - `color.primary` → Blu Oltreoceano
  - `color.onPrimary` → Bianco Ottico
  - `color.background` → Bianco Ottico
  - `color.surfaceGlass` → Bianco Ottico con materiale Liquid Glass
  - `color.onSurface` → Blu Oltreoceano (tint/testo)
- Evitare colori aggiuntivi e gradienti: **stile minimal**.

---

## 3) Componenti

### 3.1 Box Valutazione (Star Rating 1–5)
- **Elemento:** righe di **5 stelle** interattive (icona SF Symbol *star.fill / star*).
- **Hit target:** ≥ 44×44pt per stella; padding orizzontale 4–8pt.
- **Interazione:** tap diretto imposta il valore; ripetere tap sulla stessa stella conferma; **press & drag** opzionale per *scrub*.
- **Feedback:** **haptics** leggeri su cambio valore; micro-animazione *spring* (0.2–0.25) sulla stella selezionata.
- **Label accessibili:** annunciare "Valutazione: X su 5"; supportare increment/decrement via **Rotor**.
- **Stato errore:** se non selezionato → messaggio inline (vedi 4.2) e bordo accentato.

### 3.2 Box Titolo recensione
- **Campo:** `TextField` singola riga.
- **Placeholder:** es. "Titolo della recensione".
- **Vincoli:** 3–80 caratteri (contatore caratteri in tempo reale, lato destro, *secondary text*).
- **Validazione istantanea:**
  - < 3 char → errore inline;
  - > 80 char → blocco input oltre limite (hard cap) + breve haptic di *warning*.
- **Accessibilità:** label esplicita, hint VO ("Inserisci il titolo della recensione").

### 3.3 Box Descrizione del locale
- **Campo:** `TextEditor` multilinea.
- **Placeholder:** "Descrivi il locale (ambiente, servizi, posizione...)".
- **Vincoli:** 10–500 caratteri (contatore in basso a destra).
- **UI:** altezza minima 120–140pt, auto-grow fino a ~240pt poi scroll interno.
- **Validazione:** < 10 char → errore inline; > 500 → hard cap.

### 3.4 Box Esperienza (corpo della recensione)
- **Campo:** `TextEditor` multilinea per l’esperienza personale.
- **Placeholder:** "Racconta la tua esperienza".
- **Vincoli:** 10–1000 caratteri; contatore visibile.
- **UI:** altezza minima 160–180pt; auto-grow fino a ~300pt poi scroll interno.
- **Accessibilità:** *grouped*; annuncio VO del contatore quando resta ≤ 50 caratteri al limite.

### 3.5 Bottone **Invia**
- **Posizione:** al termine del form, dopo i box; segue lo scroll (no floating). Spaziatura top 24pt.
- **Aspetto (stile Liquid Glass, angoli poco rotondi 12–14pt):**
  - **CTA primaria (Invia):** **sfondo Blu Oltreoceano** (`color.primary`), testo e icone **Bianco Ottico** (`color.onPrimary`).
  - **Bottoni secondari/terziari (es. Riprova, Annulla):** **sfondo Bianco Ottico** (`color.background`) con bordo soft in tinta `color.primary` al 15–20% di opacità; testo `color.primary`.
- **Stati:**
  - **Disabled:** finché un campo è invalido o vuoto.
  - **Enabled:** haptic *impact light* al tap.
  - **Loading:** mostra **ActivityIndicator** inline a sinistra del label.
  - **Successo/Errore:** usare **In‑place Attached Alert** (vedi 4.3) ancorata al bottone.
- **Interazione:** disabilitazione immediata in loading; debounce 600ms.

---

## 4) Stati, Errori & Messaggistica

### 4.1 Regole di validazione (riassunto)
- **Valutazione:** 1–5 (obbligatoria).
- **Titolo:** 3–80 caratteri.
- **Descrizione locale:** 10–500 caratteri.
- **Esperienza:** 10–1000 caratteri.

### 4.2 Messaggi inline
- Posizionati **sotto** al campo, testo **footnote** con icona *exclamationmark.circle*.
- Esempi (localizzati):
  - Valutazione: "Seleziona un numero di stelle da 1 a 5."
  - Titolo: "Il titolo deve avere almeno 3 caratteri."
  - Descrizione: "Aggiungi almeno 10 caratteri."
  - Esperienza: "Racconta qualcosa in più (minimo 10 caratteri)."

### 4.3 Alert in‑place (Attached)
- Su **successo**: pannello che si espande dal bottone *Invia* con testo: "Recensione salvata" + icona *checkmark.circle*. Autodismiss 1.8s, annuncio VO *Success*
- Su **errore**: pannello dal bottone con "Errore di salvataggio" + *xmark.octagon*; persiste finché non chiuso o risolto. Focus al primo campo invalido.

---

## 5) Stile, Tipografia & Icone
- **Tipografia:** **font di sistema** San Francisco; supporto **Dynamic Type** fino a XXL. Titoli campi: `callout`/`subheadline`; contenuti: `body`/`subheadline`.
- **Palette colori:**
  - **Primary:** Blu Oltreoceano (per CTA, testi marcati, icone attive).
  - **Background/Surface:** Bianco Ottico (per sfondi e bottoni non primari) con trattamento **Liquid Glass** dove previsto.
  - **Contrasto:** mantenere ≥ AA.
- **Bottoni:** stile **Liquid Glass** con **angoli poco rotondi (12–14pt)**; **CTA blu**, altri **bianchi** come da §3.5.
- **Icone:** **SF Symbols** coerenti (*star*, *star.fill*, *exclamationmark.circle*, *checkmark.circle*). Usare tinta `color.primary`.
- **Stile generale:** **minimal**, niente gradienti decorativi, nessun colore fuori palette.

---

## 6) Accessibilità (dettaglio)
- **Ordine di focus:** Valutazione → Titolo → Descrizione → Esperienza → Invia.
- **VO Labels:**
  - Rating: "Valutazione stelle"; value: "X su 5"; `adjustable` con increment/decrement.
  - Titolo/Descrizione/Esperienza: label esplicite + hint.
  - Invia: "Invia recensione"; hint "Salva in locale".
- **Annunci:** su successo: "Recensione salvata" (polite). Su errore: "Compila i campi richiesti" (assertive).
- **Tap target:** ≥ 44pt.

---

## 7) Localizzazione (chiavi suggerite)
```text
"review.rating.label" = "Valutazione";
"review.title.placeholder" = "Titolo della recensione";
"review.place.placeholder" = "Descrivi il locale (ambiente, servizi, posizione...)";
"review.experience.placeholder" = "Racconta la tua esperienza";
"review.submit" = "Invia";
"review.saved" = "Recensione salvata";
"review.save_error" = "Errore di salvataggio";
"error.rating.required" = "Seleziona un numero di stelle da 1 a 5.";
"error.title.too_short" = "Il titolo deve avere almeno 3 caratteri.";
"error.place.too_short" = "Aggiungi almeno 10 caratteri.";
"error.experience.too_short" = "Racconta qualcosa in più (minimo 10 caratteri).";
```

---

## 8) Micro‑animazioni
- **Stelle:** scala 0.9→1.0 con molla leggera su selezione.
- **Errori:** lieve *shake* orizzontale del box (≤ 6pt) all’errore di submit.
- **Alert in‑place:** fade/expand dal bottone con durata ~220ms.

---

## 9) Esempi di UI (snippet SwiftUI a scopo illustrativo)
> Nota: gli snippet sono indicativi; l’implementazione finale seguirà i componenti del Design System.

```swift
struct ReviewEditorView: View {
    @State private var rating: Int = 0
    @State private var title: String = ""
    @State private var place: String = ""
    @State private var experience: String = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                StarRatingView(rating: $rating)
                    .accessibilityLabel("Valutazione stelle")
                LabeledField("Titolo", text: $title, placeholder: "Titolo della recensione", limit: 80)
                LabeledTextEditor("Descrizione del locale", text: $place, min: 10, max: 500)
                LabeledTextEditor("Esperienza", text: $experience, min: 10, max: 1000)
                PrimaryButton(title: "Invia", isLoading: isSubmitting, action: submit)
                    .disabled(!isFormValid)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .attachedAlert(isPresented: $showSuccess, title: "Recensione salvata")
        .navigationTitle("Aggiungi recensione")
    }

    private var isFormValid: Bool {
        rating >= 1 && rating <= 5 && title.count >= 3 && place.count >= 10 && experience.count >= 10
    }

    private func submit() { /* ... */ }
}
```

---

## 10) Edge Cases & Regole
- **Perdita focus/tastiera:** mantenere posizione scroll; nessun salto improvviso.
- **Debounce input:** contatori/validazione non devono bloccare typing (debounce 100–150ms).
- **Limiti duri (hard cap):** impedire input oltre massimo, preservando caret.
- **Retry salvataggio:** su errore mostrare alert in‑place + opzione *Riprova*.
- **Privacy:** non loggare contenuti dei campi; masking in eventuali errori.

---

## 11) Checklist di Accettazione (UI)
- [ ] Layout conforme (ordine, spaziature, materiali Liquid Glass).
- [ ] Validazioni live e su submit; messaggi inline.
- [ ] Button states (disabled/loading/success/error) + alert in‑place.
- [ ] Accessibilità (Dynamic Type, VO, Rotor, target ≥ 44pt).
- [ ] Localizzazione it-IT completa; placeholder/label non hard-coded.
- [ ] Nessun overlap tastiera; toolbar *Fine* attiva in editor.
- [ ] Micro-animazioni presenti e sobrie.

---

## 12) Note di Implementazione
- Usare componenti del **Design System**: `StarRatingView`, `AttachedAlert`, `PrimaryButton`, `LabeledTextEditor`/`LabeledField`.
- Seguire **SwiftLint/SwiftFormat**; anteprime SwiftUI devono compilare.
- Test ViewModel: validazione, limiti, stati bottone, form reset su successo.

