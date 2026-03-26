# Hey Snowy ❄️

> **Observations des conditions de neige en ski de randonnée — vocal, anonyme et gratuit.**

![Hey Snowy Logo](assets/logo_full.png)

---

## 🎯 C'est quoi Hey Snowy ?

Hey Snowy est une application mobile open source (Android / iOS) qui permet aux randonneurs à ski de reporter les conditions de neige **mains libres**, en mouvement — sans sortir le téléphone de la poche, sans enlever les gants.

Il suffit de dire **"Hey Snowy"** → parler naturellement des conditions → dire **"Bye Bye Snowy"** (ou attendre 15 secondes). En fin de sortie, l'app transcrit les notes vocales, extrait les données structurées grâce à l'IA, et les partage anonymement avec la communauté.

Le résultat : une **base de données communautaire, temps réel et géolocalisée des conditions de neige** — construite par les skieurs, pour les skieurs.

---

## ✨ Fonctionnalités

- 🎙️ **Enregistrement vocal mains libres** — détection de mot-clé (Porcupine), aucune interaction avec l'écran
- 📍 **Snap GPS automatique** — chaque observation est géolocalisée et horodatée
- 🤖 **Transcription + extraction IA** — Whisper (Groq) transcrit la voix, Llama 3 extrait les données structurées (type de neige, épaisseur, stabilité, orientation)
- 🗺️ **Carte communautaire** — visualise toutes les observations récentes sur OpenStreetMap
- ✏️ **Édition manuelle** — corrige l'extraction IA avant ou après l'upload
- 🔒 **Anonyme par design** — pas de compte, pas de données personnelles
- 📴 **Offline-first** — enregistrement local, synchronisation au retour du réseau
- 💸 **100% gratuit** — Groq free tier, Supabase free tier, OpenStreetMap

---

## 🏔️ Catégories de neige

| Catégorie | Description |
|-----------|-------------|
| `poudre` | Neige fraîche légère, floconneuse |
| `moquette` | Neige de printemps transformée, agréable |
| `transfo` | Neige qui vient de décailler |
| `béton` | Neige regelée dure, croûte portante |
| `croûte` | Croûte de regel non portante |
| `ventée` | Neige soufflée, tassée par le vent, plaque potentielle |
| `humide` | Neige mouillée, lourde, printanière |
| `purge` | Neige ayant déjà purgé naturellement |
| `lourde` | Poudreuse ayant pris l'humidité |
| `autre` | Autre |

---

## 🛠️ Stack technique

| Couche | Technologie |
|--------|------------|
| Framework mobile | Flutter (iOS + Android) |
| Mot-clé vocal | Porcupine (Picovoice) |
| Enregistrement audio | flutter_sound |
| GPS | geolocator |
| Transcription | Whisper via Groq API (free tier) |
| Extraction IA | Llama 3.3 70B via Groq API (free tier) |
| Stockage local | SQLite (sqflite) |
| Backend communautaire | Supabase (free tier) |
| Carte | flutter_map + OpenStreetMap |

---

## 🚀 Démarrage rapide

### Prérequis

- Flutter SDK 3.x
- Android Studio (pour le build Android)
- Clés API gratuites (voir ci-dessous)

### 1. Cloner le repo

```bash
git clone https://github.com/Tinevagio/hey-snowy.git
cd hey-snowy
```

### 2. Obtenir les clés API (toutes gratuites)

| Service | Usage | Lien |
|---------|-------|------|
| **Groq** | Transcription (Whisper) + extraction IA (Llama) | [console.groq.com](https://console.groq.com) |
| **Supabase** | Base de données communautaire | [supabase.com](https://supabase.com) |
| **Picovoice** | Détection du mot-clé vocal | [console.picovoice.ai](https://console.picovoice.ai) |

### 3. Configurer les clés API

Copie les fichiers template et remplis tes clés :

```bash
cp lib/services/ai_service.template.dart lib/services/ai_service.dart
cp lib/services/transcription_service.template.dart lib/services/transcription_service.dart
cp lib/services/supabase_service.template.dart lib/services/supabase_service.dart
cp lib/services/wake_word_service.template.dart lib/services/wake_word_service.dart
```

### 4. Configurer Supabase

Exécute ce SQL dans l'éditeur SQL de ton projet Supabase :

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

### 5. Ajouter les fichiers wake word

Génère tes fichiers `.ppn` sur [console.picovoice.ai](https://console.picovoice.ai) et place-les dans `assets/` :

```
assets/
  hey_snow_android.ppn
  bye_snow_android.ppn
```

### 6. Lancer l'app

```bash
flutter pub get
flutter run
```

---

## 📱 Comment utiliser

1. **Démarrer une sortie** — appuie sur "Démarrer sortie"
2. **Enregistrer une observation** — dis ton mot-clé (ex. "Hey Snow"), parle naturellement des conditions, dis ton mot d'arrêt ou attends 15 secondes
3. **Terminer la sortie** — appuie sur "Terminer" pour lancer le traitement (transcription + extraction IA + upload communautaire)
4. **Consulter** — visualise tes observations dans la liste ou sur la carte
5. **Corriger** — appuie sur une observation pour corriger l'extraction IA si besoin

---

## 🌍 Données communautaires

Toutes les observations sont :
- **Anonymes** — pas d'identifiant utilisateur, pas de compte requis
- **Publiques** — visibles par tous les utilisateurs sur la carte communautaire
- **Opt-out** — désactive "Partager avec la communauté" avant de terminer la sortie

---

## 🤝 Contribuer

Les contributions sont les bienvenues ! Quelques idées :

- 🌐 Ajouter d'autres langues (italien, allemand, espagnol...)
- 📊 Intégrer les bulletins avalanche
- 🗺️ Enregistrement de la trace GPX
- 🤖 Améliorer le prompt d'extraction IA
- 📱 Build et tests iOS

Ouvre une issue avant de soumettre une PR pour qu'on puisse discuter de l'approche.

---

## 🔮 Roadmap

- [ ] Support iOS
- [ ] Export trace GPX
- [ ] Intégration bulletins avalanche sur la carte
- [ ] Intégration données météo
- [ ] Modèle ML entraîné sur les données communautaires
- [ ] Dashboard web de visualisation des données

---

## 📄 Licence

Licence MIT — voir [LICENSE](LICENSE) pour les détails.

---

## 🙏 Remerciements

- [Picovoice Porcupine](https://picovoice.ai/) pour la détection de mot-clé offline
- [Groq](https://groq.com/) pour l'inférence IA ultra-rapide et gratuite
- [Supabase](https://supabase.com/) pour le backend communautaire gratuit
- [OpenStreetMap](https://www.openstreetmap.org/) pour les données cartographiques
- [flutter_map](https://pub.dev/packages/flutter_map) pour le widget de carte Flutter

---

*Construit avec ❄️ par des randonneurs à ski, pour des randonneurs à ski.*
