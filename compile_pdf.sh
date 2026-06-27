#!/bin/bash
# ==============================================================================
# Script de compilation LaTeX via Docker pour StockMaster
# ==============================================================================

# Arrêter le script si une commande échoue
set -e

# Dossiers et fichiers
PROJECT_DIR="/mnt/CA3C389F3C388909/projets_profil/StockMaster-ERP-Mobile/StockMaster"
BUILD_DIR="/home/anas/tmp_latex_build_stockmaster"
TEX_FILE="Rapport-StockMaster.tex"
PDF_FILE="Rapport-StockMaster.pdf"

echo "=== DEBUT DE COMPILATION LATEX (VIA DOCKER) ==="
echo "Dossier Projet : $PROJECT_DIR"
echo "Dossier Temp   : $BUILD_DIR"

# Créer le dossier temporaire si inexistant
mkdir -p "$BUILD_DIR"

# Copier le fichier tex
cp "$PROJECT_DIR/$TEX_FILE" "$BUILD_DIR/"

# Copier le diagramme de classe depuis la racine
cp "$PROJECT_DIR/diagClass.png" "$BUILD_DIR/"

# Copier les captures d'écran depuis stockmaster_docs/
echo "Copie des captures d'écran..."
cp "$PROJECT_DIR/stockmaster_docs/ForgotPA2.jpeg" "$BUILD_DIR/"
cp "$PROJECT_DIR/stockmaster_docs/Tableau_de_bord.png" "$BUILD_DIR/"
cp "$PROJECT_DIR/stockmaster_docs/Tableau_de_bord_en__bas.png" "$BUILD_DIR/"
cp "$PROJECT_DIR/stockmaster_docs/Tableau_de_bord_en_mileu.png" "$BUILD_DIR/"
cp "$PROJECT_DIR/stockmaster_docs/add_product.png" "$BUILD_DIR/"
cp "$PROJECT_DIR/stockmaster_docs/admin_setting.png" "$BUILD_DIR/"
cp "$PROJECT_DIR/stockmaster_docs/codescanner.png" "$BUILD_DIR/"
cp "$PROJECT_DIR/stockmaster_docs/edit_product.png" "$BUILD_DIR/"
cp "$PROJECT_DIR/stockmaster_docs/employee_setting.jpg" "$BUILD_DIR/"
cp "$PROJECT_DIR/stockmaster_docs/exported_as_excel.png" "$BUILD_DIR/"
cp "$PROJECT_DIR/stockmaster_docs/exported_as_pdf.png" "$BUILD_DIR/"
cp "$PROJECT_DIR/stockmaster_docs/forgotPA.jpeg" "$BUILD_DIR/"
cp "$PROJECT_DIR/stockmaster_docs/login.jpeg" "$BUILD_DIR/"
cp "$PROJECT_DIR/stockmaster_docs/logo.png" "$BUILD_DIR/"
cp "$PROJECT_DIR/stockmaster_docs/prodcut_details.png" "$BUILD_DIR/"
cp "$PROJECT_DIR/stockmaster_docs/product_list_view2.png" "$BUILD_DIR/"
cp "$PROJECT_DIR/stockmaster_docs/products_list.png" "$BUILD_DIR/"
cp "$PROJECT_DIR/stockmaster_docs/register.jpeg" "$BUILD_DIR/"
cp "$PROJECT_DIR/stockmaster_docs/transactions_history.png" "$BUILD_DIR/"

# Gérer le fichier avec le caractère spécial '&' pour éviter les soucis dans LaTeX et bash
cp "$PROJECT_DIR/stockmaster_docs/rapport&stistics.png" "$BUILD_DIR/rapport_statistics.png"

# Exécution de pdflatex (passe 1)
echo "--------------------------------------------------"
echo "Passe 1 : Compilation et création de la table des matières..."
echo "--------------------------------------------------"
docker run --rm \
  -v "$BUILD_DIR:/data" \
  -w /data \
  kjarosh/latex:2025.1-medium \
  pdflatex -interaction=nonstopmode "$TEX_FILE" || true

# Exécution de pdflatex (passe 2)
echo "--------------------------------------------------"
echo "Passe 2 : Résolution des références croisées..."
echo "--------------------------------------------------"
docker run --rm \
  -v "$BUILD_DIR:/data" \
  -w /data \
  kjarosh/latex:2025.1-medium \
  pdflatex -interaction=nonstopmode "$TEX_FILE" || true

# Déplacer le PDF généré
if [ -f "$BUILD_DIR/$PDF_FILE" ]; then
  cp "$BUILD_DIR/$PDF_FILE" "$PROJECT_DIR/"
  echo "✅ Le rapport PDF a été généré et déplacé avec succès !"
else
  echo "❌ ERREUR : Le PDF n'a pas été généré."
  exit 1
fi

# Nettoyer les fichiers temporaires
echo "Nettoyage du dossier temporaire..."
rm -rf "$BUILD_DIR"

echo "=================================================="
echo "✅ COMPILATION DOCKER LATEX REUSSIE !"
echo "Fichier de sortie : $PROJECT_DIR/$PDF_FILE"
echo "Taille du fichier : $(du -h "$PROJECT_DIR/$PDF_FILE" | cut -f1)"
echo "=================================================="
