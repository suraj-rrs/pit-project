# Escape Terminal — Mini-jeu UNIX (Bash)

> Un mini-jeu **100% Bash** où le joueur doit utiliser des commandes UNIX pour s'échapper d'une série de "pièces" (répertoires).

---

## Contenu du dépôt

- `escape_terminal.sh` — script principal qui configure l'environnement et lance le "maître du jeu" (game master).
- `README.md` — documentation (ci-dessous) expliquant le principe, les étapes et des indices.

> Le document ci-dessous contient à la fois le script complet (que tu peux copier dans un fichier `escape_terminal.sh` et rendre exécutable) et la documentation `.md` détaillée.

---

## Script Bash complet (`escape_terminal.sh`)

```bash
#!/usr/bin/env bash
set -euo pipefail

# Escape Terminal — version simple et pédagogique
# Usage: ./escape_terminal.sh

GAME_BASE="/tmp/escape_terminal_$RANDOM"
GAME_DIR="$GAME_BASE/game"
MASTER_PID_FILE="$GAME_BASE/.master_pid"
TIMER_START=0

cleanup() {
  echo -e "\n[GAME] Nettoyage..."
  if [[ -f "$MASTER_PID_FILE" ]]; then
    pkill -P $(cat "$MASTER_PID_FILE") 2>/dev/null || true
    rm -f "$MASTER_PID_FILE"
  fi
  # Ne supprime pas automatiquement le répertoire si on veut que l'utilisateur puisse le relire.
  # rm -rf "$GAME_BASE"
  echo "[GAME] Terminé. Le dossier de jeu est : $GAME_DIR"
}
trap cleanup EXIT

echo "[GAME] Création de l'environnement de jeu dans $GAME_DIR"
rm -rf "$GAME_BASE"
mkdir -p "$GAME_DIR"

# -- Création des pièces (répertoires)
mkdir -p "$GAME_DIR/room1"
mkdir -p "$GAME_DIR/room2/.hidden"
mkdir -p "$GAME_DIR/room3"
mkdir -p "$GAME_DIR/final"

# -- Contenu des pièces — indices / fichiers
cat > "$GAME_DIR/room1/note.txt" <<'EOF'
Bienvenue, aventurier·ère !

Ta mission : sortir de cette suite de pièces.

Indice 1 : regarde le coffre nommé chest.bin. Il contient le mot de passe encodé.
Utilise une commande pour décoder et créer un fichier \"../room2/door.key\" contenant le mot de passe.

Bon courage !
EOF

# chest.bin — base64 de la clé pour room2
echo -n "s3cr3t_key_room2" | base64 > "$GAME_DIR/room1/chest.bin"

cat > "$GAME_DIR/room1/README_HINT.txt" <<'EOF'
Si tu es bloqué·e : essaye `base64 -d chest.bin` ou `base64 --decode chest.bin`.
EOF

# room2 — on demande la création d'un fichier door.key avec le mot de passe décodé
cat > "$GAME_DIR/room2/.hidden/riddle.txt" <<'EOF'
Riddle: Je suis une commande qui cherche du texte. Mon nom commence par 'g'...
Utilise-moi pour trouver un nom dans les fichiers.
EOF

# room3 contient une archive compressée qui révèle une instruction
# Créons un fichier compressé (tar.gz) contenant un message chiffré en rot13
echo -n "Le mot de passe pour la dernière porte est: victory" | tr 'A-Za-z' 'N-ZA-Mn-za-m' > "$GAME_DIR/room3/secret_rot13.txt"
tar -czf "$GAME_DIR/room3/secret.tar.gz" -C "$GAME_DIR/room3" secret_rot13.txt
rm -f "$GAME_DIR/room3/secret_rot13.txt"

# marqueurs d'état (créés par le joueur)
# - $GAME_DIR/room2/door.key : doit contenir le mot exact 's3cr3t_key_room2'
# - $GAME_DIR/room3/door2.key : doit contenir 'victory'

EXPECTED_KEY_ROOM2="s3cr3t_key_room2"
EXPECTED_KEY_ROOM3="victory"

# Game master: surveille les actions du joueur et déverrouille les étapes
# Ce petit "maître du jeu" affiche des messages, crée des récompenses et tient le chrono.
(
  # sous-shell pour séparer le processus
  echo $$ > "$MASTER_PID_FILE"
  SECONDS=0
  progress=0
  echo "\n[GAME MASTER] Le jeu a commencé ! Va dans : $GAME_DIR et utilise ton shell (ls, cat, grep, base64, tar, tr...)"
  echo "[GAME MASTER] Astuce : tu peux ouvrir une autre session (ou un autre onglet) et taper : cd $GAME_DIR"

  while true; do
    sleep 1
    # étape 1 -> 2 : vérifie door.key
    if [[ $progress -lt 1 ]]; then
      if [[ -f "$GAME_DIR/room2/door.key" ]]; then
        val=$(tr -d '\r' < "$GAME_DIR/room2/door.key") || val=""
        if [[ "$val" == "$EXPECTED_KEY_ROOM2" ]]; then
          echo "\n[GAME MASTER] Porte vers room2 déverrouillée ! Tu peux maintenant explorer room2."
          # offrir un fichier indice dans room2
          cat > "$GAME_DIR/room2/clue_for_room2.txt" <<'EOF'
Bravo ! Pour ouvrir la salle suivante, trouve l'archive dans room3 et extrais son contenu.
Ensuite applique rot13 (commande 'tr') pour décoder, puis écris le mot dans ../room3/door2.key
EOF
          progress=1
        else
          # si le fichier existe mais mauvaise valeur, encourager
          echo -n "." # petit feedback visuel
        fi
      fi
    fi

    # étape 2 -> 3 : vérifie door2.key
    if [[ $progress -ge 1 && $progress -lt 2 ]]; then
      if [[ -f "$GAME_DIR/room3/door2.key" ]]; then
        val2=$(tr -d '\r' < "$GAME_DIR/room3/door2.key") || val2=""
        if [[ "$val2" == "$EXPECTED_KEY_ROOM3" ]]; then
          echo "\n[GAME MASTER] Superbe — la dernière porte est ouverte !"
          # créer le trésor final
          cat > "$GAME_DIR/final/treasure.txt" <<'EOF'
Félicitations ! Tu as trouvé le trésor.
Flag: ESCAPE-{you_used_unix_commands}
EOF
          echo "[GAME MASTER] Le trésor est dans $GAME_DIR/final/treasure.txt"
          progress=2
          # afficher temps
          echo "[GAME MASTER] Temps écoulé : ${SECONDS}s"
          echo "[GAME MASTER] Fin du jeu — tape Ctrl+C dans le terminal où ce script tourne pour quitter et garder l'environnement de jeu."
        else
          echo -n "."
        fi
      fi
    fi

    # si tout est fait, on attend que le joueur prenne le treasure
    if [[ $progress -ge 2 ]]; then
      sleep 3
    fi
  done
) &

# Petite pause pour laisser le maître du jeu démarrer
sleep 1

# Affichage final d'instructions initiales
cat <<EOF

=== ESCAPE TERMINAL ===

1) Ouvre un autre onglet/une autre fenêtre de terminal.
2) Va dans le dossier de jeu :
   cd $GAME_DIR
3) Utilise les commandes UNIX pour résoudre les énigmes : ls, cat, base64, grep, find, tar, tr, etc.

Objectif final : trouver le fichier $GAME_DIR/final/treasure.txt

Conseils utiles :
 - Pour décoder chest.bin : base64 --decode room1/chest.bin
 - Pour l'archive : tar -xzf room3/secret.tar.gz -C room3
 - Pour ROT13 : tr 'A-Za-z' 'N-ZA-Mn-za-m'

Amuse-toi bien !

(Appuie sur Ctrl+C dans ce terminal pour arrêter le maître du jeu — le dossier reste intact.)

EOF

# Garde le script en avant-plan (attente passive) — l'utilisateur interagit dans un autre shell
# On attend une interruption Ctrl+C pour quitter proprement
while true; do
  sleep 3600
done
```

---

## README.md (documentation d'accompagnement)

```markdown
# Escape Terminal — Guide utilisateur

## But du jeu
Tu es enfermé·e dans une suite de répertoires. Pour avancer, utilise les commandes UNIX classiques (ls, cat, grep, find, base64, tar, tr, etc.) pour trouver et décoder des indices. Le but final est de trouver le fichier `final/treasure.txt`.

## Prérequis
- Un système GNU/Linux (ou équivalent) avec Bash.
- Commandes standard : `ls`, `cat`, `grep`, `find`, `base64`, `tar`, `tr`, `chmod`, `touch`.
- Aucun privilège spécial (sudo) n'est requis.

## Lancer le jeu
1. Rends le script exécutable :

```bash
chmod +x escape_terminal.sh
```

2. Lance-le :

```bash
./escape_terminal.sh
```

Le script va créer un dossier de jeu dans `/tmp/escape_terminal_<RANDOM>/game` et démarrer un "maître du jeu" qui surveille les actions.

## Règles et progression
1. **Room 1** : lis `room1/note.txt`. Tu y trouveras un fichier `chest.bin` qui est encodé en base64. Décoder `chest.bin` te fournit la clé attendue pour débloquer la `room2`.

   Exemple :
   ```bash
   base64 --decode room1/chest.bin
   # puis écrire le contenu dans room2/door.key
   base64 --decode room1/chest.bin > room2/door.key
   ```

2. **Room 2** : une fois la clé correctement écrite dans `room2/door.key`, le maître du jeu crée un indice `room2/clue_for_room2.txt`. Cet indice t'indique d'aller dans `room3` et d'extraire une archive.

3. **Room 3** : extrais `room3/secret.tar.gz`, applique `tr 'A-Za-z' 'N-ZA-Mn-za-m'` (rot13) pour obtenir le mot final `victory`. Écris ce mot dans `room3/door2.key`.

   Exemple :
   ```bash
   tar -xzf room3/secret.tar.gz -C room3
   tr 'A-Za-z' 'N-ZA-Mn-za-m' < room3/secret_rot13.txt > room3/door2.key
   ```

4. **Final** : quand la valeur est correcte, le maître du jeu crée `final/treasure.txt` qui contient le flag/texte de victoire.

## Commandes utiles
- `ls -la` : lister fichiers (incluant fichiers cachés)
- `cat fichier` : afficher le contenu
- `base64 --decode fichier` ou `base64 -d fichier` : décoder base64
- `tar -xzf archive.tar.gz` : extraire une archive
- `tr 'A-Za-z' 'N-ZA-Mn-za-m'` : appliquer rot13
- `grep`, `find` : rechercher des indices

## Indices / astuces
- N'oublie pas de regarder les fichiers cachés (`ls -la`, `ls -laR`) et les sous-répertoires.
- Tu peux ouvrir une autre fenêtre de terminal pour travailler pendant que le maître du jeu tourne.
- Le maître du jeu te donnera des messages / indices au fur et à mesure.

## Améliorations possibles (pour toi)
- Ajouter un chronomètre et stocker les meilleurs temps.
- Générer des clés aléatoires à chaque lancement pour renforcer la rejouabilité.
- Ajouter des mini-énigmes plus complexes (stéganographie dans une image, puzzles sur les permissions, casse-têtes sur les propriétaires, etc.).

## Nettoyage
Le script imprime l'emplacement du dossier jeu (`/tmp/escape_terminal_<RANDOM>/game`) lors de la fin. Supprime-le si tu veux nettoyer :

```bash
rm -rf /tmp/escape_terminal_<RANDOM>
```

---

Amuse-toi bien ! Si tu veux, je peux :
- te fournir une version plus compliquée (plus d'étapes, énigmes réseau fictives),
- ajouter un système de score/leaderboard,
- te proposer des variantes pédagogiques (permissions, ownership, réseaux de pipes...),
- t'aider à transformer le jeu pour qu'il tourne dans un conteneur Docker pour plus d'isolement.
```

---

## Notes finales
- Le script et la doc ci-dessus sont conçus pour être pédagogiques et faciles à étendre.
- Copier-coller le bloc `escape_terminal.sh` dans un fichier, rends-le exécutable, puis lance-le.

Bonne création — dis-moi si tu veux que j'ajoute :
- de la génération aléatoire des clés,
- un chronomètre et un système de meilleurs temps,
- une difficulté "hardcore" avec permissions et propriétaires différents.

