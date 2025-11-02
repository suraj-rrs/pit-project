#!/bin/bash
# Script : start_jedi.sh
# Objectif : créer trois fichiers texte (rouge, bleu, vert)

# Affiche un message
echo "Quelle couleur de sabre laser choisis-tu"

# Crée les fichiers
touch rouge.txt bleu.txt vert.txt

# Vérifie si tout s’est bien passé
if [[ -f rouge.txt && -f bleu.txt && -f vert.txt ]]; then
    echo "rouge.txt, bleu.txt, vert.txt"
else
    echo "❌ Erreur : les fichiers n'ont pas pu être créés."
fi
