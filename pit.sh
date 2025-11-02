#!/upsr/bin/env bash
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
