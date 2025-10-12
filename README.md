# junk raft rumble

# 🌊 Junk Raft Rumble - Game Design Document

## 📋 Document Information

**Version:** 1.0  
**Date:** Octobre 2025  
**Studio:** [Nom du Studio]  
**Plateforme:** PC / Mobile  
**Engine:** Godot 4.5  
**Genre:** Tower Defense / Strategy / Action

---

## 🎯 Vision du Jeu

### Concept Principal
**Junk Raft Rumble** est un tower defense innovant où le joueur construit et défend son île flottante composée de radeaux de fortune, tout en contrôlant activement la vitesse de collision contre l'île ennemie via un système de swipe. Le joueur doit équilibrer placement stratégique de tours et timing des impacts pour détruire l'adversaire.

### Pitch en une phrase
*"Construis ton île de combat, place tes défenses, et swipe pour contrôler l'impact final dans ce tower defense où le timing est aussi crucial que la stratégie."*

### Inspirations
- **Tower Defense:** Bloons TD, Kingdom Rush
- **Systèmes de swipe:** Fruit Ninja, Cut the Rope
- **Progression:** Idle games, RPG incrémentaux
- **Thème:** Waterworld, Mad Max sur l'eau

---

## 🎮 Gameplay Core

### Boucle de Gameplay Principale

```
1. PRÉPARATION (Éditeur de Tours)
   ↓
2. APPROCHE (Les îles se rapprochent)
   ↓
3. COMBAT (Swipe pour contrôler la vitesse)
   ↓
4. COLLISION (Impact calculé selon la vitesse)
   ↓
5. RÉSULTAT (Victoire/Défaite + XP)
   ↓
6. AMÉLIORATION (Skills, nouvelles tours)
   ↓
Retour à 1
```

### Mécaniques Principales

#### 1. Construction d'Île (Pré-combat)
- **Grille isométrique 8x8** pour placer les tours
- **Système de drag & drop** pour positionner
- **Budget limité:** Chaque tour coûte de l'or
- **Sauvegarde automatique** du layout
- **Maximum 64 tours** (une par case)

#### 2. Système de Tours
**Tours disponibles:**
- 🔴 **Tour Rouge** (Basique): Équilibrée, bon début
- 🔵 **Canon**: AOE, dégâts de zone
- 🧊 **Glace**: Ralentit les ennemis
- ⚡ **Foudre**: Chaîne entre plusieurs cibles
- 🎯 **Sniper**: Longue portée, gros dégâts
- 🔫 **Mitrailleuse**: Tir rapide
- 💀 **Poison**: Dégâts sur la durée
- 💥 **Bombe**: Explosion massive
- 🔥 **Laser**: Dégâts continus

**Statistiques des tours:**
- Dégâts (Damage)
- Vitesse d'attaque (Attack Speed)
- Portée (Range)
- Points de vie (Health)
- Effets spéciaux (Slow, Poison, AOE, etc.)

#### 3. Système de Combat (Phase de Bataille)

**Mouvement des îles:**
- Les îles avancent l'une vers l'autre sur des rails fixes
- Vitesse de base: 50-75 unités/seconde
- Les tours attaquent automatiquement

**Système de Swipe:**
- **Swipe DROITE (→)**: Accélère l'île du joueur
  - Augmente la vitesse jusqu'à 250 unités/sec
  - Coûte du carburant
  - Plus de vitesse = plus de dégâts à l'impact
  
- **Swipe GAUCHE (←)**: Freine/recule
  - Réduit la vitesse jusqu'à -50 unités/sec
  - Coûte du carburant
  - Permet d'économiser du carburant

**Système de Carburant:**
- Barre de carburant: 0-100
- Chaque swipe coûte 15-20 carburant
- Recharge automatique: 5-8 carburant/sec
- Si carburant vide: impossible de swiper

**Collision:**
```
Dégâts d'impact = Dégâts de base + (Vitesse - Vitesse de base) × Multiplicateur

Exemple:
- Vitesse de base: 50
- Vitesse actuelle: 200
- Dégâts de base: 10
- Multiplicateur: 2.0
→ Dégâts = 10 + (200-50) × 2.0 = 310 dégâts!
```

#### 4. Conditions de Victoire/Défaite
- **Victoire**: Détruire toutes les tuiles ennemies (64 → 0)
- **Défaite**: Toutes ses tuiles sont détruites (64 → 0)
- Chaque tuile a 3 HP
- Les projectiles et collisions réduisent les HP des tuiles

---

## 🎓 Progression & Méta-jeu

### Système de Niveaux

**Expérience (XP):**
- Gagné uniquement en **VICTOIRE** (50 XP par bataille gagnée)
- Pas d'XP en défaite (encourage à rejouer)
- Formule de progression exponentielle:

```
Niveaux 1-10:   XP = 100 × 1.1^(niveau-1)
Niveaux 11-30:  XP = 100 × 1.12^(niveau-1)
Niveaux 31-60:  XP = 100 × 1.14^(niveau-1)
Niveaux 61-99:  XP = 100 × 1.16^(niveau-1)
```

**Niveau maximum:** 99

### Système de Compétences

**Points de compétence:**
- 1 point par niveau gagné
- 3 compétences disponibles, toutes au niveau max 99

**Compétences:**

1. **⚔️ PUISSANCE**
   - Bonus: +5% de dégâts par niveau
   - Affecte: Toutes les tours
   - Niveau 99 = +495% dégâts

2. **⚡ CADENCE**
   - Bonus: +5% vitesse d'attaque par niveau
   - Affecte: Toutes les tours
   - Niveau 99 = +495% vitesse d'attaque

3. **🛡️ RÉSISTANCE**
   - Bonus: +10 HP par niveau
   - Affecte: Toutes les tours
   - Niveau 99 = +990 HP par tour

**Calculs:**
```gdscript
Dégâts réels = Dégâts de base × (1 + niveau_puissance × 0.05)
Vitesse réelle = Vitesse de base / (1 + niveau_cadence × 0.05)
HP réels = HP de base + (niveau_résistance × 10)
```

### Profil Joueur

**Informations affichées:**
- Nom du joueur (modifiable)
- Niveau actuel
- Barre d'XP vers niveau suivant
- Avatar (personnalisable)
- Points de compétence disponibles
- Statistiques:
  - Batailles totales
  - Victoires
  - Défaites
  - Ratio victoire/défaite

**Sauvegarde:**
- Fichier: `user://player_data.save`
- Persistance entre sessions
- Format: Dictionary Godot serialisé

---

## 🎨 Direction Artistique

### Style Visuel
- **Perspective:** Isométrique (vue 3/4)
- **Thème:** Post-apocalyptique aquatique
- **Couleurs:** Teintes bleues/vertes (océan), rouille, métal
- **Aesthetic:** Bricolage, recyclage, Mad Max maritime

### Assets Graphiques
**Actuels (Kenney Tower Defense Pack):**
- Tuiles isométriques
- Tours stylisées
- Projectiles simples

**Style des effets:**
- Particules pour explosions
- Fumée lors des impacts
- Eau animée avec shader
- Effets de status (poison vert, glace bleue, etc.)

### Interface Utilisateur

**Écran de jeu:**
- Profil joueur (coin supérieur gauche)
- Informations de combat (centre)
- Barres de carburant et vitesse (pendant le combat)

**Palette de couleurs UI:**
- Primaire: Bleu océan (#2E8BC0)
- Secondaire: Vert militaire (#4A7C59)
- Accent: Orange rouille (#D97536)
- Fond: Gris foncé (#1A1A1F)

---

## 🔊 Audio Design

### Musique
**Menu principal:** Ambiance calme, océanique
**Combat:** Rythme intense, industriel
**Victoire:** Fanfare triomphante
**Défaite:** Thème mélancolique

### Effets Sonores

**Interface:**
- Clic de bouton
- Placement de tour
- Level up
- Amélioration de compétence

**Combat:**
- Tirs de tours (varie par type)
- Impacts de projectiles
- Explosion
- Collision d'îles
- Swipe (whoosh)
- Alerte carburant vide

**Ambiance:**
- Vagues
- Vent
- Grincements de métal

---

## 🏗️ Architecture Technique

### Structure du Projet

```
res://
├── assets/
│   ├── textures/
│   ├── sounds/
│   └── fonts/
├── scenes/
│   ├── main/ (menus)
│   ├── gameplay/ (battlefield, editor)
│   ├── islands/ (tiles)
│   ├── towers/
│   ├── projectiles/
│   ├── effects/
│   └── ui/
├── scripts/
│   ├── autoload/ (singletons)
│   ├── core/ (base classes)
│   ├── gameplay/
│   ├── towers/
│   ├── projectiles/
│   └── ui/
└── shaders/
```

### Singletons (Autoload)

1. **Game.gd**
   - Ressources globales (or, santé)
   - État du jeu
   - Signaux globaux

2. **PlayerData.gd**
   - Profil du joueur
   - Niveau et XP
   - Compétences
   - Statistiques

3. **TowerDataManager.gd**
   - Layout des tours (8x8)
   - Sauvegarde/chargement
   - Gestion de la grille

### Classes de Base

**BaseTower** (scripts/core/base_tower.gd)
- Gestion du ciblage
- Système d'attaque
- Gestion de la santé
- Application des bonus de compétences

**BaseProjectile** (scripts/core/base_projectile.gd)
- Types de mouvement (homing, direct, ballistic, beam)
- Système de collision
- Effets spéciaux (AOE, poison, slow)
- Piercing

**JunkRaft** (scripts/core/junk_raft.gd)
- Système de swipe
- Gestion du carburant
- Calcul de vitesse et inertie
- Dégâts d'impact

### Systèmes Principaux

**StatusEffects** (autoload)
- Poison (DOT)
- Burn (DOT)
- Slow (ralentissement)
- Stun (étourdissement)
- Shield (absorption)
- Buffs de dégâts/vitesse

---

## 📱 Plateformes & Contrôles

### PC
**Souris:**
- Clic gauche: Sélection, placement
- Clic droit: Annulation
- Molette: Zoom (futur)

**Clavier (debug):**
- Flèche droite: Swipe accélération
- Flèche gauche: Swipe freinage
- Flèche haut: Ajout carburant
- Échap: Pause/Menu

### Mobile (futur)
**Tactile:**
- Tap: Sélection
- Drag: Placement de tour
- Swipe horizontal: Contrôle de vitesse
- Pinch: Zoom

---

## 🎯 Métriques & Balancing

### Économie

**Or (Gold):**
- Départ: 100 or
- Coût tour de base: 10 or
- Tours avancées: 20-50 or
- Gain par victoire: 50-100 or (futur)

### Tours - Statistiques de Base

| Tour | Dégâts | Vitesse | Portée | HP | Coût | Spécial |
|------|--------|---------|--------|-----|------|---------|
| Rouge | 5 | 3.0s | 400 | 10 | 10 | Aucun |
| Canon | 8 | 4.0s | 450 | 15 | 25 | AOE 100px |
| Glace | 3 | 2.5s | 400 | 10 | 20 | Slow 50% |
| Foudre | 6 | 2.0s | 350 | 10 | 30 | Chain 3x |
| Sniper | 20 | 5.0s | 800 | 8 | 40 | Longue portée |
| Mitrailleuse | 2 | 0.5s | 350 | 10 | 25 | Tir rapide |
| Poison | 2 | 3.0s | 380 | 10 | 20 | DOT 1/sec |
| Bombe | 15 | 6.0s | 400 | 20 | 50 | AOE 150px |
| Laser | 1 | 0.1s | 500 | 12 | 35 | Continu |

### Tuiles

**Statistiques:**
- HP de base: 3
- Nombre total: 64 (8×8)
- Collision entre tuiles: 1 dégât
- Pas de régénération

### Progression

**Courbe de difficulté:**
- Combat 1-5: Tutoriel, facile
- Combat 6-15: Difficulté croissante
- Combat 16-30: Défi modéré
- Combat 31-50: Difficile
- Combat 51+: Très difficile

**Temps de jeu estimé:**
- Une bataille: 2-5 minutes
- Atteindre niveau 10: 1-2 heures
- Atteindre niveau 50: 10-15 heures
- Atteindre niveau 99: 50+ heures

---

## 🚀 Roadmap de Développement

### Phase 1: Core Gameplay ✅ (ACTUEL)
- [x] Système de grille isométrique
- [x] Placement de tours
- [x] Système de combat de base
- [x] Projectiles et collisions
- [x] Système de swipe
- [x] Gestion du carburant
- [x] Système de niveaux et XP
- [x] Système de compétences

### Phase 2: Contenu & Polish 🔄 (EN COURS)
- [ ] 9 types de tours fonctionnels
- [ ] Effets visuels améliorés
- [ ] Sons et musiques
- [ ] Tutoriel intégré
- [ ] Système d'or et économie
- [ ] Sauvegarde automatique

### Phase 3: Extension 📋 (PLANIFIÉ)
- [ ] Mode histoire (campagne)
- [ ] Nouveaux types d'ennemis
- [ ] Boss battles
- [ ] Défis quotidiens
- [ ] Achievements
- [ ] Système de crafting

### Phase 4: Multijoueur 🔮 (FUTUR)
- [ ] PvP asynchrone
- [ ] Classements
- [ ] Replays
- [ ] Système de clans
- [ ] Tournois

### Phase 5: Monétisation 💰 (TRÈS FUTUR)
- [ ] Version free-to-play
- [ ] Cosmétiques (skins de tours)
- [ ] Battle pass
- [ ] Publicités (opt-in pour bonus)

---

## 🎮 Scénarios de Gameplay

### Exemple de Partie Typique

**Début:**
1. Joueur niveau 15, 500 or disponible
2. Entre dans l'éditeur de tours
3. Place stratégiquement:
   - 4 Tours Sniper en arrière (longue portée)
   - 6 Tours Canon au centre (AOE)
   - 4 Tours Glace devant (ralentissement)
4. Sauvegarde et lance la bataille

**Pendant le Combat:**
1. Les îles commencent à avancer (vitesse 50)
2. Les tours attaquent automatiquement
3. Joueur observe le carburant et la vitesse
4. À 200m de distance: swipe droite → accélère à 150
5. À 100m: swipe gauche → ralentit à 80 (économie)
6. À 50m: swipe droite × 2 → boost à 220!
7. COLLISION! Dégâts massifs infligés

**Résultat:**
- Victoire!
- +50 XP
- Level up! Niveau 16
- +1 point de compétence
- Met le point dans "Puissance"

### Stratégies Avancées

**Build "Sniper Spam":**
- 64 Tours Sniper (longue portée)
- Détruit l'ennemi avant contact
- Lent mais efficace

**Build "Speed Demon":**
- Tours défensives minimales
- Focus sur l'impact (swipe constant)
- Risqué mais rapide

**Build "Poison Cloud":**
- Tours Poison + Canon
- DOT + AOE = zone mortelle
- Contrôle du terrain

**Build "Ice Wall":**
- Tours Glace en première ligne
- Ralentit pour maximiser DPS
- Défense solide

---

## 📊 KPIs & Métriques de Succès

### Métriques Clés
- **Rétention J1:** >40%
- **Rétention J7:** >20%
- **Temps de session moyen:** 15-20 min
- **Batailles par session:** 3-5
- **Taux de victoire:** 60-70%

### Engagement
- **Niveau moyen atteint:** 25+
- **Compétences dépensées:** 80%+ des points disponibles
- **Tours différentes utilisées:** 5+/9
- **Layouts sauvegardés:** 3+ différents

---

## 🐛 Bugs Connus & Limitations

### Bugs Connus
- [ ] Collision detection parfois imprécise
- [ ] Projectiles peuvent traverser les tuiles
- [ ] UI peut se superposer en cas de spam
- [ ] Performance baisse avec 60+ tours actives

### Limitations Techniques
- Pas de multijoueur temps réel (architecture)
- Limite de 64 tours (grille 8×8 fixe)
- Pas de sauvegarde cloud (local uniquement)
- Pas de support manette (pour l'instant)

---

## 📖 Glossaire

**AOE (Area of Effect):** Dégâts de zone  
**DOT (Damage Over Time):** Dégâts sur la durée  
**DPS (Damage Per Second):** Dégâts par seconde  
**HP (Health Points):** Points de vie  
**XP (Experience Points):** Points d'expérience  
**Swipe:** Geste de glissement pour contrôler  
**Layout:** Disposition des tours sur la grille  
**Junk Raft:** Radeau de fortune/île flottante  

---

## 🙏 Crédits

**Game Design:** [Votre nom]  
**Programming:** [Votre nom]  
**Art Assets:** Kenney (kenney.nl)  
**Engine:** Godot Engine 4.5  
**Inspirations:** Bloons TD, Kingdom Rush, Clash Royale

---

## 📞 Contact & Feedback

**Email:** [votre.email@example.com]  
**Discord:** [Lien serveur]  
**GitHub:** [Lien repo]  
**Itch.io:** [Lien page]

---

*Document vivant - Dernière mise à jour: Octobre 2025*
