# TODO — FROUFROU FIGHTERS

Priorité absolue : **un premier combat réellement jouable** entre deux personnages
(déplacements, attaques, collisions, dégâts, victoire). → **Atteint**, contre une IA à 3 difficultés.

Légende : `[x]` fait et testé · `[ ]` à faire

---

## Phase 1 — Initialisation et configuration ✅

- [x] Arborescence, `project.godot` généré par `tools/configure_project.gd`
- [x] 1920×1080 `canvas_items` / `expand`, paysage, rendu Compatibility, ETC2/ASTC, 60 ticks
- [x] Actions logiques + liaisons clavier (codes physiques) et manette
- [x] Couches de collision nommées, bus audio, GDScript typé imposé
- [x] `boot.tscn`, `ProjectConfigCheck`, framework de tests headless, docs

## Phase 2 — Scènes et architecture ✅

- [x] `main_menu.tscn`, `character_select.tscn`, `fight_scene.tscn`, `fighter.tscn`, `abidjan_stage.tscn`,
      `results.tscn` (+ `fight_hud.tscn`)
- [x] Autoload `SceneRouter` : navigation avec fondu, blocage des clics, gestion des scènes introuvables
- [x] Autoload `GameSession` : sélection des combattants et résultat transmis entre écrans
- [x] Le boot enchaîne vers le menu principal
- [x] Thème UI global généré depuis `UIPalette` (`UIThemeBuilder`)
- [x] `SafeAreaContainer` : marges de sécurité sur mobile (encoches, coins arrondis)
- [x] Sélection générée depuis `FighterRegistry` (ajouter un combattant = l'ajouter au roster)

## Phase 3 — Combattants temporaires ✅

- [x] `FighterData` (identité, visuel, stats, boîtes, 7 attaques) avec validation
- [x] `MoveData` / `HitboxData` configurables dans l'inspecteur
- [x] K.BLAZE (rapide, acrobatique) et AMAZONE (technique, puissante) : `data/fighters/` + `data/moves/`
- [x] 24 poses SVG générées (`tools/generate_placeholder_sprites.gd`), recolorées par shader de palette
- [x] Animations temporaires : idle, walk, jump, crouch, punch, kick, crouch_punch, low_kick, air_punch,
      air_kick, block, crouch_block, hit, knockdown, getup, dodge, throw, special, ultimate, victory, defeat

## Phase 4 — Déplacements et animations ✅

- [x] `Fighter` (CharacterBody2D) piloté frame par frame, cinématique déterministe
- [x] Machine à états : IDLE, WALK, JUMP, CROUCH, ATTACK, BLOCK, HITSTUN, BLOCKSTUN, KNOCKDOWN, GETUP,
      DODGE, VICTORY, DEFEAT
- [x] `FighterController` abstrait : `PlayerController`, `ScriptedController`, mannequin
- [x] `InputBuffer` : tolérance de 6 frames, détection Poing+Pied
- [x] Orientation automatique, boîtes de poussée, écart maximal, murs
- [x] Esquive avec invulnérabilité
- [x] Flash d'impact (AnimationPlayer), gel d'animation pendant le hitstop

## Phase 5 — Hitboxes et dégâts ✅

- [x] Hitbox / Hurtbox indépendantes (Area2D), actives uniquement pendant les frames actives
- [x] Un seul impact par attaque et par cible (multi-coups explicites via `max_hits`)
- [x] Dégâts, hitstun, blockstun, gel d'impact, pushback (transféré à l'attaquant dos au mur)
- [x] Garde debout / accroupie, attaques basses et sautées, garde « arrière »
- [x] Projections imparables (+ projection depuis une attaque légère à 1-3 frames)
- [x] Chutes, relevé invulnérable, KO → DEFEAT
- [x] Gain de jauge (attaquant et défenseur), annulations (léger → lourd)
- [x] Échanges (trades) équitables : détection des deux côtés avant application

## Réalisé en avance (prévu Phases 9-10)

- [x] `FightManager` : intro, manches, timer 99 s, KO, double KO, temps écoulé, 2 manches gagnantes,
      plafond de 5 manches, résultat, poses de victoire / défaite, passage aux résultats
- [x] HUD de base : noms, barres de vie (alerte santé basse), timer, manches, jauge, annonces
- [x] Caméra : suivi, zoom progressif, limites de l'arène, secousse sur impacts lourds
- [x] Écran de résultats : victoire / défaite / égalité, score, revanche, changement de combattant, menu

## Phase 6 — Combos et attaques spéciales ✅

- [x] Compteur de combos (`ComboTracker` + HUD « N COUPS · dégâts »)
- [x] Magnan Rush (K.BLAZE, 3 coups, chute au dernier) ; Royal Counter (AMAZONE, contre + Riposte Royale)
- [x] Ultimes à jauge pleine (Bas + Spécial), invulnérabilité de démarrage, annonces HUD
- [x] Annulations léger → lourd → spécial / ultime (données `cancel_into`)
- [x] Mode assisté (`AssistedInput`) : chaîne automatique au Poing, raccourci ultime ; choix à la sélection
- [x] Correctif moteur : le recul (pushback) ne glisse plus pendant tout le hitstun
- [x] Personnalisation des touches (écran d'options, Phase 10)

## Phase 7 — IA ✅

- [x] `AIController` (étend `FighterController`) : Facile / Normal / Difficile, profils en données
      (`data/ai/*.tres`, `AIProfile`)
- [x] Perception retardée (`AIPerception`) : l'IA ne voit que l'état visible de l'adversaire, avec un temps
      de réaction (22 / 12 / 6 frames) ; test prouvant qu'elle ignore les commandes futures du joueur
- [x] Garde selon la hauteur d'attaque, garde préventive, esquive, Royal Counter en réaction
- [x] Punition des récupérations, combos (léger → lourd → spécial / ultime), ultimes stratégiques
- [x] Gestion de distance (recul, approche, saut), projections contre un adversaire en garde
- [x] Adversaire IA dans `fight_scene.gd` ; choix de la difficulté à l'écran de sélection
- [x] Correctif moteur : « Bas + Spécial » est mémorisé dans le tampon (ultime bufferisée pendant un gel)
- [x] Mémoriser la difficulté choisie (sauvegarde, Phase 10)

## Phase 8 — Arène Abidjan : Le Plateau Électrique ✅

- [x] 6 plans `Parallax2D` (ciel, arrière-plan, plan médian, boulevard, rue, premier plan) + plan de
      combat stable à vitesse 1 ; profondeur par vitesses, brume et premier plan
- [x] Tours du Plateau (fenêtres allumées, feux d'antenne clignotants), silhouette pyramidale sur l'horizon
- [x] Échangeur avec circulation dans les deux sens, taxis orange, lampadaires
- [x] Rue commerçante : maquis, alloco, garba, attiéké, pharmacie, coiffure… ; auvents orange / blanc / vert,
      enseignes néon qui grésillent
- [x] Câbles électriques, trottoir, chaussée, reflets des néons dans les flaques
- [x] Public en silhouettes au premier plan
- [x] Décor réactif : le public se lève, les néons grésillent, étincelles sur KO et ultimes
- [x] `StageData` + `StageRegistry` (`data/stages/abidjan_plateau.tres`), chargement par le combat
- [x] Tout est dessiné par code (`@tool`, visible dans l'éditeur), une seule fois ; ~1,7 ms CPU / GPU par frame sur PC
- [ ] Illustrations peintes à la main (DA définitive) en remplacement du décor procédural
- [ ] Ambiance sonore de la ville (klaxons, foule, musique de maquis) — assets audio
- [ ] Mesure de performance sur appareil mobile de référence (Phase 11)

## Phase 9 — HUD et commandes tactiles ✅

- [x] Portraits des combattants (illustration `FighterData.portrait`, sinon tête du sprite de test recolorée)
- [x] Jauge spéciale sous la barre de vie : le bas de l'écran est libre pour les pouces
- [x] `TouchJoystick` flottant (seuils de jeu de combat : saut plus exigeant que l'accroupi)
- [x] `TouchActionButton` : Poing, Pied, Spécial, Garde, Esquive — mêmes actions logiques que clavier / manette
- [x] Multi-touch (un doigt par commande) ; Poing + Pied tactiles = projection
- [x] Zone de sécurité, affichage AUTO (mobile, navigateur mobile) / `-- --touch` sur ordinateur
- [x] Relâchement de toutes les commandes en fin de manche et en quittant le combat
- [x] Modes Classique / Assisté valables au tactile (badge « MODE ASSISTÉ »)
- [x] Correctif : l'affichage AUTO ne se fie plus à `is_touchscreen_available()` (vrai sur PC avec l'émulation)
- [x] Affichage forcé des commandes tactiles (options, Phase 10) — taille / opacité / position : à faire
- [ ] Test sur appareil réel (Phase 11 : nécessite export Android / iOS)

## Phase 10 — Menus et sauvegarde ✅

- [x] Menu pause (`PauseMenu`) : reprendre, recommencer, options, menu principal ; Échap / P / Start /
      bouton tactile « II » ; pause automatique quand l'application passe en arrière-plan
- [x] Écran d'options (`OptionsPanel`, 4 onglets) depuis le menu principal et depuis la pause
- [x] Volumes Général / Musique / Effets / Voix appliqués aux bus audio
- [x] Difficulté, mode de commandes, affichage tactile réglables et mémorisés
- [x] Personnalisation clavier + manette (`ControlsRemapPanel`), sans doublon, réinitialisable ;
      libellés selon la disposition réelle du clavier (AZERTY…)
- [x] Sauvegarde locale versionnée (`SaveManager`) : réglages, touches, combattants débloqués,
      victoires par difficulté, statistiques ; fusion avec les défauts, écriture atomique et groupée,
      fichier corrompu mis de côté
- [x] Statistiques enregistrées à chaque fin de match ; bilan sur l'écran de résultats
- [x] Les tests utilisent leur propre fichier de sauvegarde (jamais celui du joueur)
- [ ] Style des onglets et des curseurs dans le thème (actuellement thème Godot par défaut)
- [ ] Réglages tactiles avancés : taille, opacité, position des boutons
- [ ] Déblocage de nouveaux combattants (mécanique prête : `SaveManager.unlock_fighter`)

## Phase 11 — Tests, corrections, optimisation ✅ (sauf validation sur appareil)

- [x] Préréglages d'export Android et iOS (`export_presets.cfg`), validés par Godot : seuls manquent les
      modèles d'export 4.7.2, le JDK et le SDK Android (et Xcode pour iOS)
- [x] Filtres d'export : `tests/*` et `tools/*` exclus — vérifié dans le `.pck` exporté (~575 Ko)
- [x] Icônes générées depuis le logo : Android 192 + adaptative 432, App Store 1024 opaque
- [x] Banc de performance (`tools/benchmark_combat.gd`) : 0,08 ms / frame de simulation, aucun pic > 4 ms
- [x] Test : la simulation ne crée aucun objet pendant 1 800 frames de combat entre deux IA
- [x] Vérification de fuite : les objets restants ne croissent pas avec la durée (10 s = 4 min)
- [x] Passe qualité : 26 catégories d'avertissements GDScript, zéro avertissement
- [x] Finitions : onglets et curseurs dans le thème, noms de touches spéciales en français
- [ ] Identifiant d'application définitif (remplacer `com.froufrou.fighters`)
- [ ] Installer modèles d'export + JDK + SDK Android, exporter l'APK, tester sur un téléphone de référence
      (60 FPS, mémoire, tactile réel, zones de sécurité, mise en arrière-plan)
- [ ] Clé de signature release Android ; projet Xcode signé pour iOS (Mac requis)
- [ ] Pooling des effets visuels (à prévoir quand des particules / effets d'impact seront ajoutés)

## Plus tard

- [ ] Police d'interface sous licence libre adaptée à la DA
- [ ] Mode versus local 2 joueurs (liaisons par périphérique)
- [ ] Illustrations définitives des combattants et de l'arène (remplacent les SVG ; `FighterData` inchangé)
