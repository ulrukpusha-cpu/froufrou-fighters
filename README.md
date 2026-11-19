# FROUFROU FIGHTERS

Jeu de combat arcade 2.5D ancré dans l'Afrique de l'Ouest contemporaine.
Direction artistique : *Afro Urban Hand-Drawn Fighting Art*. Cible : Android et iOS, en paysage, 60 FPS.

> **État : prototype, Phases 1 à 11 terminées** (export mobile prêt, à valider sur appareil). Un combat complet est jouable contre une **IA à trois
> difficultés** : boot → menu → sélection (combattant, difficulté de l'IA, commandes Classique / Assisté)
> → combat en 2 manches gagnantes (déplacements, sauts, attaques, garde, projections, esquive, combos,
> attaques spéciales, ultimes, contre, KO, timer) → résultats. Suivi détaillé : [TODO.md](TODO.md).

## Arène : Abidjan — Le Plateau Électrique

Le quartier des affaires d'Abidjan à la tombée de la nuit, en **6 plans de parallaxe** (`Parallax2D`) :

| Plan | Défilement | Contenu |
|---|---|---|
| Ciel | 0,05 | Dégradé violet → orange, étoiles, lune |
| Arrière-plan | 0,15 | Tours lointaines dans la brume, silhouette pyramidale sur l'horizon |
| Plan médian | 0,4 | Tours du Plateau, fenêtres allumées, feux d'antenne qui clignotent |
| Boulevard | 0,7 | Échangeur, taxis orange et voitures dans les deux sens, lampadaires |
| Rue | 0,88 | Maquis, alloco, garba, pharmacie, coiffure… : vitrines, auvents orange / blanc / vert, enseignes néon, câbles électriques |
| **Plan de combat** | **1** | Trottoir, bordure, chaussée, reflets des néons dans les flaques |
| Premier plan | 1,3 | Public en silhouettes, grands lampadaires (devant les combattants) |

- Les combattants se battent sur un **plan 2D stable**. La profondeur vient des vitesses de défilement,
  de la brume sur les plans lointains et du public au premier plan.
- Le **décor réagit** aux coups qui portent : le public se lève et lève les bras, les néons
  grésillent, et les câbles crachent des étincelles sur les KO et les ultimes
  (`Stage.react_to_impact`, groupe `stage_reactive`).
- **Léger pour le mobile** : tout est dessiné par code (`@tool`, visible dans l'éditeur) une seule fois,
  avec des graines fixes. Seuls le trafic, le public et les clignotements s'animent, sans allocation.
  Mesure sur PC (Movie Maker, combat IA contre IA) : environ 1,7 ms CPU et 1,7 ms GPU par frame.
- L'arène est décrite par `data/stages/abidjan_plateau.tres` (`StageData`) et chargée via `StageRegistry`.

## Intelligence artificielle

| Difficulté | Réaction | Comportement |
|---|---|---|
| **FACILE** | 22 frames | Attaques occasionnelles, garde rare, ne gère pas la distance. |
| **NORMAL** | 12 frames | Gère la distance, attaques variées, garde préventive, quelques punitions et combos. |
| **DIFFICILE** | 6 frames | Pare à la réaction, punit les récupérations, combos quasi systématiques, ultime placée en combo ou en punition, Royal Counter en réaction, projette les adversaires en garde. |

- L'IA perçoit l'adversaire **avec un retard** (son temps de réaction) et **uniquement par ce qui est
  visible** (position, posture, attaque en cours) : jamais ses commandes ni son contrôleur. Un test le
  vérifie : deux scénarios dont seules les commandes futures du joueur diffèrent donnent des décisions
  identiques jusqu'à l'instant où la différence devient visible.
- Elle produit des commandes comme un joueur : le moteur ne fait aucune différence.
- Chaque difficulté est un fichier `data/ai/*.tres` (`AIProfile`) : réaction, agressivité, garde,
  punition, combos, ultimes, contre, esquive, distance. Générateur aléatoire à graine : reproductible.

---

## Prérequis

| Outil | Version | Remarque |
|---|---|---|
| Godot Engine | **4.7.2 stable** (build standard, pas .NET) | Le projet est en GDScript. |
| Modèles d'export | 4.7.2 | Seulement pour produire un APK/IPA. |
| Android SDK / Xcode | — | Seulement pour l'export mobile. |

## Installation

1. Copier le dossier `FROUFROU_FIGHTERS/`.
2. Ouvrir Godot 4.7.2 → **Importer** → `FROUFROU_FIGHTERS/project.godot`.
3. Au premier lancement, Godot importe les ressources (dossier `.godot/`, ignoré par git).

En PowerShell, définir d'abord le chemin de Godot (version console) :

```powershell
$godot = "C:\chemin\vers\Godot_v4.7.2-stable_win64_console.exe"
```

Puis, depuis le dossier `FROUFROU_FIGHTERS` :

```powershell
& $godot --headless --path . --import
```

## Lancement

- **Éditeur** : ouvrir le projet puis `F5` (scène principale : `scenes/boot/boot.tscn`).
- **Ligne de commande** (depuis `FROUFROU_FIGHTERS`) :

```powershell
& $godot --path .
```

- **Directement en combat** (K.BLAZE contre AMAZONE par défaut) :

```powershell
& $godot --path . res://scenes/combat/fight_scene.tscn
```

- **Avec les commandes tactiles sur ordinateur** (la souris joue le rôle du doigt) :

```powershell
& $godot --path . -- --touch
```

## Commandes

Toutes les entrées passent par une **couche unique d'actions logiques** (`InputActions`) : clavier, manette
Bluetooth et commandes tactiles déclenchent les mêmes actions. Les touches utilisent des **codes
physiques** : la disposition est identique en AZERTY et en QWERTY.

**Commandes tactiles** (affichées automatiquement sur Android / iOS / navigateur mobile ; sur ordinateur
avec `-- --touch`) :

- **Joystick flottant** dans la moitié gauche : le pouce posé devient le centre. Le saut demande un geste
  vers le haut plus franc que l'accroupi, pour éviter les sauts involontaires.
- **Boutons** en bas à droite : POING, PIED, SPÉCIAL, GARDE, ESQUIVE. Multi-touch : on peut avancer,
  garder et frapper en même temps ; POING + PIED ensemble = projection.
- Placement dans la **zone de sécurité** (encoches, coins arrondis) ; le HUD reste en haut de l'écran.
- Toutes les commandes tenues sont relâchées en fin de manche et en quittant le combat.
- Le mode Assisté s'applique aussi au tactile (rappel « MODE ASSISTÉ » à l'écran).

| Action | Clavier QWERTY (AZERTY) | Manette (Xbox) |
|---|---|---|
| Gauche / Droite | A (Q) / D, ← / → | Croix, stick gauche |
| Saut | W (Z), ↑ | Croix haut, stick gauche |
| Accroupi | S, ↓ | Croix bas, stick gauche |
| Poing (attaque légère) | J | X |
| Pied (attaque lourde) | K | A |
| Spécial | L | B |
| Garde | I | RB |
| Esquive | O | Y, LB |
| Pause | Échap, P | Start |

**Techniques**

| Technique | Commande |
|---|---|
| Garde haute / basse | Maintenir Garde (ou maintenir l'**arrière**) ; ajouter Bas pour la garde basse |
| Attaques accroupies (basses) | Bas + Poing / Pied — se parent uniquement en garde basse |
| Attaques sautées | Poing / Pied en l'air — se parent uniquement debout |
| Projection (imparable) | Poing + Pied ensemble, au corps à corps |
| Esquive (invulnérable) | Esquive : retrait rapide vers l'arrière |
| Attaque spéciale | Spécial |
| Attaque ultime | Bas + Spécial, jauge pleine (3 niveaux) — invulnérable au démarrage |
| Combo | Poing → Pied → Spécial, chaque coup lancé pendant que le précédent touche (annulation) |

**Spécialités**

| Combattant | Spécial | Ultime |
|---|---|---|
| K.BLAZE | **Magnan Rush** : ruée en 3 coups, chute au dernier impact | **Colonne Magnan** : ruée en 5 coups |
| AMAZONE | **Royal Counter** : posture de contre ; une frappe reçue est annulée, l'attaquant est sonné et subit la *Riposte Royale*. Les projections et les ultimes passent. | **Charge des Agojie** : charge dévastatrice |

**Modes de commandes** (bouton « COMMANDES » de l'écran de sélection)

- **Classique** : commandes ci-dessus.
- **Assisté** : marteler Poing enchaîne automatiquement léger → lourd → spécial dès que le coup
  précédent touche (dans le vide, Poing reste un Poing) ; Spécial seul lance l'ultime dès que la jauge est
  pleine. Le moteur est le même : seule la traduction des commandes change (`AssistedInput`).

Le HUD affiche les portraits, la vie, la jauge (« ULTIME PRÊTE »), le timer, les manches, le compteur
de combos (« 4 COUPS · 195 ») et annonce ultimes et contres.

## Pause, options et sauvegarde

- **Pause** : Échap / P / Start / bouton tactile « II » → Reprendre, Recommencer, Options, Menu principal.
  Le combat se met aussi en pause tout seul quand l'application passe en arrière-plan (appel,
  notification). Pendant la pause, simulation, IA et commandes tactiles sont figées.
- **Options** (menu principal ou pause), en 4 onglets :
  - **Audio** : volumes Général, Musique, Effets, Voix (bus audio ; les sons arrivent avec les assets) ;
  - **Jeu** : difficulté de l'IA, mode Classique / Assisté, affichage des commandes tactiles
    (Auto / Toujours / Jamais) ;
  - **Commandes** : personnalisation clavier et manette (cliquer, puis appuyer sur la touche ; Échap
    annule). Une touche reprise par une action est retirée de l'ancienne : jamais de doublon.
    Bouton « Réinitialiser les commandes » ;
  - **Statistiques** : combats, victoires / défaites / égalités, manches, meilleur combo, victoires
    par difficulté, bilan par combattant.
- **Sauvegarde locale** (`SaveManager`, fichier `user://save.json` ; sous Windows :
  `%APPDATA%\FroufrouFighters\save.json`) : réglages, commandes personnalisées, combattants débloqués,
  progression et statistiques.
  - Structure **versionnée** et évolutive : clés manquantes complétées, types invalides remplacés,
    clés inconnues conservées, point d'entrée de migration.
  - Écriture **atomique** (fichier temporaire puis renommage) et groupée (un curseur qu'on fait
    glisser n'écrit pas en boucle) ; écriture immédiate à la fermeture ou à la mise en arrière-plan.
  - Un fichier illisible est mis de côté (`save.json.corrupt`) et le jeu repart des valeurs par défaut.
  - Les tests utilisent un fichier séparé : ils ne touchent jamais la sauvegarde du joueur.

## Tests

Framework de tests maison, sans dépendance externe : **103 tests** (configuration, entrées, composants de
combat, combats simulés frame par frame, spéciaux, ultimes, contre, combos, mode assisté, IA (difficultés,
absence de triche), commandes tactiles (multi-touch), sauvegarde, options, touches, pause, arène (parallaxe,
décor réactif), performance (aucune allocation en combat), déroulement d'un match, HUD, menus, navigation).

```powershell
& $godot --headless --path . --script res://tests/run_tests.gd
```

- Code de sortie `0` si tout passe, `1` sinon (utilisable en CI).
- Trois messages sont **attendus** et annoncés juste avant : deux `ERROR` (scène manquante) et un
  `WARNING` (sauvegarde corrompue mise de côté).
- Les tests utilisent leur propre fichier de sauvegarde : ils ne touchent jamais celle du joueur.
- Les tests sont les méthodes `test_*` de `tests/unit/` et `tests/integration/`, qui étendent `TestCase`.
  `CombatBench` (`tests/framework/`) monte une arène et deux combattants pilotés par `ScriptedController`.

## Outils

| Outil | Rôle |
|---|---|
| `tools/configure_project.gd` | Génère `project.godot`, le thème UI et les bus audio à partir des constantes du code. |
| `tools/generate_placeholder_sprites.gd` | Génère les 24 poses SVG de test et leur `SpriteFrames`. |
| `tools/generate_app_icons.gd` | Génère les icônes Android (192, adaptative 432) et iOS / App Store (1024, opaque). |
| `tools/benchmark_combat.gd` | Banc de performance : chargement, coût CPU par frame, pics, objets créés en combat. |

```powershell
& $godot --headless --path . --script res://tools/configure_project.gd
```

À relancer après toute modification de `GameConstants`, `InputActions`, `PhysicsLayers`, `UIPalette` ou
`UIThemeBuilder`. Au démarrage, `ProjectConfigCheck` signale tout écart entre le code et `project.godot`.

```powershell
& $godot --headless --path . --script res://tools/benchmark_combat.gd
```

Mesures sur le PC de développement (2 min de jeu, IA difficile contre IA difficile) :

| Mesure | Résultat |
|---|---|
| Chargement de la scène de combat | ~0,4 s |
| Simulation par frame | 0,08 ms en moyenne, 0,35 ms au 99ᵉ centile (budget : 16,7 ms) |
| Objets créés pendant le combat | **0** (simulation) ; ~40 objets d'interface créés une seule fois |
| Rendu (Movie Maker, arène complète) | ~1,7 ms CPU, ~1,7 ms GPU par frame |
| Paquet de données Android (`.pck`) | ~575 Ko, sans les tests ni les outils |

Ces chiffres sont à confirmer sur un téléphone de référence (voir ci-dessous).

## Export mobile (Android, iOS)

Les préréglages sont dans `export_presets.cfg` (paysage, plein écran immersif, icônes, ARMv7 + ARM64 ;
les dossiers `tests/` et `tools/` sont exclus). Godot les valide : seuls manquent les outils ci-dessous.

**À faire une fois, avant le premier export :**

1. **Identifiant de l'application** : remplacer `com.froufrou.fighters` (valeur provisoire) par un
   identifiant à toi, dans `export_presets.cfg` (`package/unique_name` et `application/bundle_identifier`)
   ou dans l'éditeur (Projet > Exporter).
2. **Modèles d'export Godot 4.7.2** : dans l'éditeur, *Éditeur > Gérer les modèles d'exportation >
   Télécharger et installer*.
3. **Android** : installer un **JDK** (OpenJDK) et le **SDK Android** (via Android Studio ou les outils en
   ligne de commande), aux versions indiquées par la documentation Godot « Exporting for Android ». Puis,
   dans *Éditeur > Paramètres de l'éditeur > Export > Android*, renseigner le chemin du JDK et du SDK.
   Godot crée seul la clé de débogage ; pour publier, créer une clé de release (`keytool`) et la
   renseigner dans le préréglage (mot de passe à saisir par toi, il n'est jamais stocké dans le dépôt).
4. **iOS** : nécessite un **Mac avec Xcode** et un compte Apple Developer. Renseigner l'**App Store Team
   ID** dans le préréglage iOS ; Godot exporte un projet Xcode, que l'on compile et signe dans Xcode.

**Exporter et installer sur un téléphone Android** (débogage USB activé), depuis `FROUFROU_FIGHTERS` :

```powershell
& $godot --headless --path . --export-debug "Android" build/android/froufrou_fighters.apk
```

```powershell
adb install -r build/android/froufrou_fighters.apk
```

**Mesurer les performances sur l'appareil** : dans l'éditeur, *Débogage > Déploiement avec débogage à
distance*, lancer sur le téléphone (bouton Android de la barre d'outils), puis *Débogueur > Profileur* et
*Moniteurs* (FPS, temps de frame, mémoire, objets). Objectif : 60 FPS stables pendant un combat.

## Configuration du projet

| Domaine | Valeur | Raison |
|---|---|---|
| Résolution de référence | 1920 × 1080, stretch `canvas_items` / `expand` | Une base d'UI ; les écrans plus larges voient plus de décor. |
| Orientation | Paysage (capteur) | Retournement automatique de l'appareil. |
| Rendu | Compatibility (OpenGL ES 3) partout | Meilleure couverture 2D sur Android/iOS d'entrée de gamme. |
| Simulation | 60 ticks, FPS max 60 | La logique de combat est comptée en frames fixes. |
| Textures | Compression ETC2/ASTC | Requise pour l'export mobile. |
| Tactile | La souris émule le tactile | Tester les commandes tactiles sur PC. |
| GDScript | `untyped_declaration` = **Erreur** | Le typage est imposé par le moteur. |
| Autoloads | `GameSession`, `SceneRouter`, `SaveManager` | Seuls états devant survivre aux changements de scène. |
| Thème | `assets/ui/ff_theme.tres` (généré) | Toutes les couleurs viennent de `UIPalette`. |
| Bus audio | Master → Music, SFX, Voice | Réglages de volume séparés. |

## Architecture

```
FROUFROU_FIGHTERS/
├── assets/
│   ├── fighters/placeholder/   # 24 poses SVG + placeholder_frames.tres (générés)
│   └── ui/ff_theme.tres        # thème global (généré)
├── data/
│   ├── ai/                     # easy.tres, normal.tres, hard.tres (AIProfile)
│   ├── fighters/               # k_blaze.tres, amazone.tres (FighterData)
│   ├── moves/<combattant>/     # MoveData de chaque combattant (normaux, spéciaux, ultimes)
│   └── stages/                 # abidjan_plateau.tres (StageData)
├── scenes/
│   ├── boot/boot.tscn
│   ├── menus/                  # main_menu, character_select, results, options_menu, options_panel,
│   │                           # pause_menu
│   ├── combat/                 # fight_scene, fight_hud, touch_controls
│   ├── characters/fighter.tscn # combattant générique
│   └── stages/abidjan_stage.tscn # arène en 6 plans de parallaxe
├── scripts/
│   ├── systems/                # constantes, entrées, couches, boot, autoloads (GameSession,
│   │                           # SceneRouter, SaveManager), vérification de config
│   ├── combat/                 # MoveData, HitboxData, MoveRunner, Hitbox, Hurtbox, CombatSimulation,
│   │                           # FightManager, FightCamera, Stage, MatchResult, fight_scene
│   ├── fighters/               # Fighter, FighterData, états, contrôleurs, InputFrame, InputBuffer, visuel
│   ├── ui/                     # palette, thème, SafeAreaContainer, menus, cartes, HUD, portraits,
│   │                           # TouchControls, TouchJoystick, TouchActionButton, OptionsPanel,
│   │                           # ControlsRemapPanel, PauseMenu
│   ├── ai/                     # AIController, AIProfile, AIPerception, AISnapshot
│   └── stages/                 # StageData, StageRegistry, décor : NightSky, CityLayer, TrafficLane, Taxi,
│                               # ShopRow, NeonSign, PowerLines, StreetGround, StreetLamp, Crowd
├── shaders/fighter_palette.gdshader
├── tests/                      # framework/, unit/, integration/, fixtures/
└── tools/
```

> Les dossiers `scripts/ai` et `scripts/ui` sont en minuscules (convention snake_case de Godot, et Android est
> sensible à la casse).

### Moteur de combat

```
FightManager (unique horloge, _physics_process)          ← manches, timer, KO, résultat
  └─ CombatSimulation.step()                             ← ordre fixe, identique pour J1 et J2
       ├─ Fighter.simulate_frame() ×2
       │    ├─ FighterController.poll() → InputFrame      ← joueur, IA (perception retardée), script
       │    ├─ InputBuffer (tolérance 6 frames, Poing+Pied)
       │    ├─ FighterStateMachine (13 états)
       │    ├─ MoveRunner (startup / active / recovery, registre d'impacts, annulations)
       │    └─ cinématique à pas fixe, Hurtbox, pool de 3 Hitbox
       ├─ séparation des boîtes de poussée + écart maximal (cadre caméra)
       ├─ résolution des impacts : détection pour les deux, PUIS application (échanges équitables)
       │    └─ posture de contre (MoveData.counter_window) → riposte au lieu de l'impact
       └─ ComboTracker : compte les impacts sur un adversaire qui n'a pas récupéré
```

- **Déterminisme** : tout est compté en frames à 60 Hz, la cinématique est calculée à la main (pas de
  `move_and_slide`, qui dépend du pas physique réel). Les tests rejouent un combat à l'identique.
- **Données** : une attaque est un `MoveData` (dégâts, startup / active / recovery, hitstun, blockstun,
  gel d'impact, pushback, niveau haut / bas / sauté, chute, multi-coups, jauge, annulations, hitboxes).
  Un combattant est un `FighterData`. Rien de propre à un personnage n'est codé dans le moteur.
- **Hitbox / Hurtbox** : `Area2D` + `CollisionShape2D`, actives uniquement pendant les frames définies ;
  détection par intersection de rectangles exacte à la frame ; une attaque ne touche une cible qu'une fois
  (sauf multi-coups explicites). Visualisation : *Débogage > Formes de collision visibles*.
- **Garde** : debout pare MID et sauté ; accroupi pare MID et bas ; projections imparables ; dos au mur,
  c'est l'attaquant qui recule.
- **États** : IDLE, WALK, JUMP, CROUCH, ATTACK, BLOCK, HITSTUN, BLOCKSTUN, KNOCKDOWN, GETUP, DODGE,
  VICTORY, DEFEAT.
- **Visuel** : un seul jeu de sprites de test, recoloré par combattant via `fighter_palette.gdshader`
  (R = tenue, G = peau, B = accessoires) ; flash d'impact par `AnimationPlayer`.
- **Caméra** : suit le milieu des combattants, zoom progressif selon la distance, limites de l'arène,
  secousse sur impacts lourds.

### Principes

- **Source unique de vérité** : règles, résolution, couches, actions et couleurs sont des constantes typées.
- **Séparation des responsabilités** : scènes = assemblage, scripts = logique, `data/` = équilibrage.
- **Signaux** entre systèmes : le HUD n'interroge jamais le combat, il écoute `FightManager` et `Fighter`.
- **Erreurs de chargement gérées** : registre des combattants avec validation, scènes vérifiées, retour au menu.
- **Mobile** : aucune allocation par frame en combat (objets d'entrée, tampons et hitboxes réutilisés).

## Couches de collision 2D

| N° | Nom | Usage |
|---|---|---|
| 1 | `stage_bounds` | Réservée aux éléments physiques du décor ; les limites de combat sont des données de `Stage` |
| 2 | `fighter_body` | Boîte de poussée des combattants |
| 3 | `hitbox` | Zones offensives |
| 4 | `hurtbox` | Zones vulnérables |

## Conventions de code

- GDScript **typé** partout, `snake_case` pour fichiers et fonctions, `PascalCase` pour `class_name`,
  constantes en `MAJUSCULES`, commentaires `##` en français.
- Indentation par tabulations (`.editorconfig`), fins de ligne LF (`.gitattributes`).
