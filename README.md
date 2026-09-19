<div align="center">

<img src="assets/images/logo-pagellasanremo.png" alt="Logo Pagella Sanremo" width="120" />

# Pagella Sanremo

**Dai i voti alle esibizioni del Festival di Sanremo 2026, serata per serata.<br/>Confronta la tua classifica con la community e con i tuoi amici.**

[![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%5E3.5-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Backend-Supabase-3FCF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![Riverpod](https://img.shields.io/badge/State-Riverpod-5B21B6)](https://riverpod.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![CI](https://github.com/peppeneglia/pagella_sanremo/actions/workflows/ci.yml/badge.svg)](https://github.com/peppeneglia/pagella_sanremo/actions/workflows/ci.yml)

</div>

---

## ✨ Cosa fa

Pagella Sanremo è un'app mobile con cui votare, in tempo reale, i 30 artisti in gara al Festival.
Per ogni esibizione assegni un voto da **1 a 10** (anche mezzi punti) in tre categorie:

| 🎤 Canto | ✍️ Testo | 👗 Look |
|:--:|:--:|:--:|

L'app calcola la media, costruisce la tua classifica personale e, se hai un account, la confronta con quella di tutta la community e dei gruppi che crei con gli amici.

### Funzionalità

- **🗳️ Votazione per serata** — cinque serate con la scaletta corretta: tutti gli artisti nella prima e nella finale, metà nella seconda e terza, la serata cover con ospite e brano diverso.
- **🏆 La mia classifica** — ordinabile per totale, singola categoria o *Canto + Testo*, con podio 🥇🥈🥉.
- **🌍 Classifica community** — medie aggregate di tutti gli utenti registrati, con aggiornamento automatico ogni minuto e pull-to-refresh.
- **👥 Gruppi** — crea un gruppo con nome ed emoji, invita gli amici con un **codice a 6 caratteri**, guarda la classifica del gruppo e i voti di ogni membro artista per artista.
- **🕶️ Modalità anonima** — puoi votare senza account: i voti restano sul dispositivo. Se poi ti registri, vengono migrati automaticamente sul tuo profilo.
- **☁️ Sincronizzazione offline-first** — i voti si salvano subito in locale e vengono inviati al backend in background, con merge al login.
- **🔐 Account e privacy** — registrazione via email, eliminazione completa dell'account dall'app, informativa privacy integrata.

---

## 🏗️ Architettura

Struttura **feature-first** con separazione tra modelli, servizi, provider e UI. Lo stato è gestito con [Riverpod](https://riverpod.dev), il backend è [Supabase](https://supabase.com) (Auth + Postgres), la persistenza locale usa `shared_preferences`.

```
lib/
├── main.dart                         # bootstrap: Supabase, tema, orientamento
├── config/
│   ├── supabase_config.dart          # credenziali lette da --dart-define
│   └── theme/app_theme.dart          # colori e ThemeData
└── features/
    ├── auth/                         # welcome, login/registrazione, profilo, privacy
    │   ├── presentation/screens/
    │   └── providers/                # authState, anonymousMode, isLoggedIn
    ├── core/
    │   ├── presentation/screens/     # MainScaffold con bottom navigation
    │   └── providers/                # packageInfo
    ├── voting/
    │   ├── data/artists_data.dart    # i 30 artisti e la scaletta della serata cover
    │   ├── models/artist.dart
    │   ├── providers/                # date, artisti per serata, VotesNotifier
    │   ├── services/                 # sync dei voti con Supabase
    │   ├── presentation/screens/     # pagina di voto
    │   └── widgets/                  # VotingRow, DateButton
    ├── rankings/
    │   ├── providers/                # classifica personale e community
    │   ├── services/                 # lettura vista community_rankings
    │   └── presentation/screens/
    └── groups/
        ├── models/group.dart
        ├── providers/
        ├── services/group_service.dart
        └── presentation/screens/
```

### Flusso dei voti

```
VotingRow ──onChanged──▶ VotesNotifier ──▶ state (in memoria)
                              │
                              ├──▶ SharedPreferences   (sempre, immediato)
                              └──▶ Supabase `votes`    (solo con account, fire-and-forget)

Login ──▶ cache locale ⊕ voti remoti ──merge──▶ state ──▶ push dei voti mancanti
       └─▶ migrazione dei voti anonimi sull'account
```

---

## 🚀 Avvio rapido

### Requisiti

- [Flutter](https://docs.flutter.dev/get-started/install) 3.41 o superiore (Dart ≥ 3.5)
- Un progetto [Supabase](https://supabase.com) (vedi [Backend](#️-backend-supabase))
- Android Studio / Xcode per gli emulatori

### Installazione

```sh
git clone https://github.com/peppeneglia/pagella_sanremo.git
cd pagella_sanremo
flutter pub get
```

### Configurazione

Le credenziali Supabase **non sono nel repository**: vengono passate a compile-time.
Copia il file di esempio e inserisci URL e chiave *anon* del tuo progetto:

```sh
cp env.example.json env.json
```

```json
{
  "SUPABASE_URL": "https://<project-ref>.supabase.co",
  "SUPABASE_ANON_KEY": "<anon-key>"
}
```

`env.json` è già in `.gitignore`. Se avvii senza configurazione, l'app si ferma subito con un messaggio esplicito.

### Esecuzione

```sh
flutter run --dart-define-from-file=env.json
```

---

## 🗄️ Backend (Supabase)

Lo schema del database non è versionato in questo repository. Il client si aspetta le seguenti entità, tutte protette da **Row Level Security** in modo che ogni utente possa leggere e scrivere solo i propri dati (e leggere quelli dei membri dei propri gruppi).

<details>
<summary><strong>Tabelle, viste e funzioni attese dal client</strong></summary>

<br/>

**`profiles`** — profilo pubblico dell'utente (`id` = `auth.users.id`)

| colonna | tipo | note |
|---|---|---|
| `id` | uuid | PK, FK → `auth.users` |
| `username` | text | mostrato nei gruppi |
| `email` | text | fallback se manca lo username |

**`votes`** — un record per utente × artista × serata

| colonna | tipo | note |
|---|---|---|
| `user_id` | uuid | FK → `auth.users` |
| `artist_name` | text | chiave dell'artista (vedi `artists_data.dart`) |
| `date` | text | es. `MAR 24` |
| `canto`, `testo`, `look` | numeric | 1–10 a passi di 0.5, nullable |
| `updated_at` | timestamptz | |
| | | **UNIQUE** (`user_id`, `artist_name`, `date`) |

**`groups`**

| colonna | tipo | note |
|---|---|---|
| `id` | uuid | PK |
| `name` | text | |
| `emoji` | text | |
| `code` | text | **UNIQUE**, 6 caratteri (senza `I L O 0 1`) |
| `owner_id` | uuid | FK → `auth.users` |
| `created_at` | timestamptz | |

**`group_members`**

| colonna | tipo | note |
|---|---|---|
| `id` | uuid | PK |
| `group_id` | uuid | FK → `groups` **ON DELETE CASCADE** |
| `user_id` | uuid | FK → `auth.users` |
| `joined_at` | timestamptz | |

**Vista `community_rankings`** — medie per `artist_name` e `date`: `avg_canto`, `avg_testo`, `avg_look`, `avg_total`, `total_voters`.

**Funzione RPC `delete_user_account()`** — `security definer`: elimina voti, iscrizioni ai gruppi, profilo e l'utente `auth` che la invoca.

</details>

---

## 📦 Build di rilascio

```sh
# Android (App Bundle per il Play Store)
flutter build appbundle --dart-define-from-file=env.json

# iOS
flutter build ipa --dart-define-from-file=env.json
```

Per firmare la build Android crea `android/key.properties` (ignorato da git):

```properties
storeFile=/percorso/upload-keystore.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

Senza questo file la release viene firmata con la chiave di debug, così il progetto si compila anche senza il keystore.

---

## 🧪 Qualità del codice

```sh
dart format lib test          # formattazione
flutter analyze --fatal-infos # lint (flutter_lints + regole in analysis_options.yaml)
flutter test                  # test unitari
```

Gli stessi controlli girano in CI su ogni push e pull request (`.github/workflows/ci.yml`).

I test coprono la logica pura che non richiede il backend: distribuzione degli artisti per serata, calcolo e ordinamento delle classifiche, modelli dei gruppi.

---

## 🔒 Privacy

L'app raccoglie solo email, username, voti e appartenenza ai gruppi. In modalità anonima nessun dato lascia il dispositivo. L'informativa completa è consultabile dalla pagina *Profilo → Privacy Policy*.

---

## 📄 Licenza

Distribuito con licenza **MIT**. Vedi [LICENSE](LICENSE).

<div align="center">
<sub>Sviluppato da <a href="https://github.com/peppeneglia">Peppe Neglia</a> · Non affiliato a RAI o al Festival di Sanremo</sub>
</div>
