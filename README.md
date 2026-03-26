# Hey Snowy ❄️

> **Crowdsourced snow conditions reporting for backcountry skiers — fully voice-driven, anonymous, and free.**

![Hey Snowy Logo](assets/logo_full.png)

---

## 🎯 What is Hey Snowy?

Hey Snowy is an open-source mobile app (Android / iOS) that lets backcountry skiers report snow conditions **hands-free**, while moving — no need to take off gloves or stop skiing.

Just say **"Hey Snow"** → speak naturally about the snow → say **"Bye Snow"** (or wait 15 seconds). At the end of your tour, the app transcribes your voice notes, extracts structured snow data using AI, and shares it anonymously with the community.

The result: a **crowdsourced, real-time, geolocated snow conditions database** — built by skiers, for skiers.

---

## ✨ Features

- 🎙️ **Hands-free voice logging** — wake word detection (Porcupine), no screen interaction needed
- 📍 **GPS snap** — each observation is automatically geolocated and timestamped
- 🤖 **AI transcription + extraction** — Whisper (Groq) transcribes your voice, Llama 3 extracts structured data (snow type, depth, stability, aspect)
- 🗺️ **Community map** — see all recent observations on an OpenStreetMap map
- ✏️ **Manual edit** — correct AI extraction before or after upload
- 🔒 **Anonymous by design** — no user account, no personal data
- 📴 **Offline-first** — records locally, syncs when back in range
- 💸 **100% free** — Groq free tier, Supabase free tier, OpenStreetMap

---

## 🏔️ Snow categories

| Category | Description |
|----------|-------------|
| `poudre` | Fresh light powder |
| `moquette` | Spring transformed snow, pleasant |
| `transfo` | Recently softened after freeze/thaw |
| `béton` | Hard frozen snow, icy |
| `croûte` | Non-supporting breakable crust |
| `ventée` | Wind-packed snow, potential slab |
| `humide` | Wet heavy spring snow |
| `purge` | Already naturally purged |
| `lourde` | Heavy powder, lost lightness |
| `autre` | Other |

---

## 🛠️ Tech stack

| Layer | Technology |
|-------|-----------|
| Mobile framework | Flutter (iOS + Android) |
| Wake word | Porcupine (Picovoice) |
| Audio recording | flutter_sound |
| GPS | geolocator |
| Transcription | Whisper via Groq API (free tier) |
| AI extraction | Llama 3.3 70B via Groq API (free tier) |
| Local storage | SQLite (sqflite) |
| Community backend | Supabase (free tier) |
| Map | flutter_map + OpenStreetMap |

---

## 🚀 Getting started

### Prerequisites

- Flutter SDK 3.x
- Android Studio (for Android build)
- Free API keys (see below)

### 1. Clone the repo

```bash
git clone https://github.com/Tinevagio/hey-snowy.git
cd hey-snowy
```

### 2. Get API keys (all free)

| Service | Purpose | Link |
|---------|---------|------|
| **Groq** | Transcription (Whisper) + AI extraction (Llama) | [console.groq.com](https://console.groq.com) |
| **Supabase** | Community database | [supabase.com](https://supabase.com) |
| **Picovoice** | Wake word detection | [console.picovoice.ai](https://console.picovoice.ai) |

### 3. Configure API keys

Copy the template files and fill in your keys:

```bash
cp lib/services/ai_service.template.dart lib/services/ai_service.dart
cp lib/services/transcription_service.template.dart lib/services/transcription_service.dart
cp lib/services/supabase_service.template.dart lib/services/supabase_service.dart
cp lib/services/wake_word_service.template.dart lib/services/wake_word_service.dart
```

### 4. Set up Supabase

Run this SQL in your Supabase SQL editor:

```sql
create table observations (
  id text primary key,
  lat double precision not null,
  lon double precision not null,
  altitude_m double precision,
  timestamp timestamptz not null,
  snow_type text,
  depth_cm integer,
  stability_score integer,
  aspect text,
  raw_notes text,
  created_at timestamptz default now()
);

alter table observations enable row level security;
create policy "Public read" on observations for select using (true);
create policy "Public insert" on observations for insert with check (true);
create policy "Public update" on observations for update using (true);
create policy "Public delete" on observations for delete using (true);
```

### 5. Add wake word files

Generate your wake word `.ppn` files on [console.picovoice.ai](https://console.picovoice.ai) and place them in `assets/`:

```
assets/
  hey_snow_android.ppn
  bye_snow_android.ppn
```

### 6. Run

```bash
flutter pub get
flutter run
```

---

## 📱 How to use

1. **Start a tour** — tap "Démarrer sortie"
2. **Record an observation** — say your wake word (e.g. "Hey Snow"), speak naturally about the snow conditions, say your stop word or wait 15 seconds
3. **End the tour** — tap "Terminer" to trigger batch processing (transcription + AI extraction + community upload)
4. **Review** — check your observations in the list view or on the map
5. **Edit** — tap any observation to correct AI extraction if needed

---

## 🌍 Community data

All observations are:
- **Anonymous** — no user ID, no account required
- **Public** — visible to all users on the community map
- **Opt-out** — toggle "Partager avec la communauté" before ending your tour

---

## 🤝 Contributing

Contributions are very welcome! Here are some ideas:

- 🌐 Add more languages (Italian, German, Spanish...)
- 📊 Add avalanche bulletin integration
- 🗺️ Add GPX track recording
- 🤖 Improve the AI extraction prompt
- 📱 iOS build and testing

Please open an issue before submitting a PR so we can discuss the approach.

---

## 🔮 Roadmap

- [ ] iOS support
- [ ] GPX track export
- [ ] Avalanche bulletin overlay on map
- [ ] Weather data integration
- [ ] ML model trained on community data
- [ ] Web dashboard for data visualization

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgements

- [Picovoice Porcupine](https://picovoice.ai/) for offline wake word detection
- [Groq](https://groq.com/) for blazing fast free AI inference
- [Supabase](https://supabase.com/) for the free community backend
- [OpenStreetMap](https://www.openstreetmap.org/) contributors for map data
- [flutter_map](https://pub.dev/packages/flutter_map) for the Flutter map widget

---

*Built with ❄️ by backcountry skiers, for backcountry skiers.*
