#!/bin/bash
# ============================================
#  FILE ORGANIZER - A beginner shell project
#  Usage: bash organize.sh [folder]
#  If no folder is given, it uses the current one
# ============================================

# ---------- 1. SETUP ----------

# Use the first argument ($1) as the target folder.
# If nothing is passed, use "." which means current folder.
TARGET="${1:-.}"

# Check if the folder actually exists. If not, print an error and exit.
if [ ! -d "$TARGET" ]; then
  echo "Error: '$TARGET' is not a valid folder."
  exit 1   # exit with code 1 = something went wrong
fi

echo ""
echo "📁 Organizing files in: $TARGET"
echo "--------------------------------"

# ---------- 2. CREATE DESTINATION FOLDERS ----------

# We'll sort files into these folders.
# mkdir -p means: create the folder (and don't complain if it already exists).
mkdir -p "$TARGET/Images"
mkdir -p "$TARGET/Videos"
mkdir -p "$TARGET/Documents"
mkdir -p "$TARGET/Music"
mkdir -p "$TARGET/Archives"
mkdir -p "$TARGET/Others"

# ---------- 3. COUNTERS ----------

# We'll count how many files we move for each category.
# Variables start at 0.
images=0
videos=0
docs=0
music=0
archives=0
others=0

# ---------- 4. LOOP THROUGH FILES ----------

# "for file in ..." loops over every item in the folder.
# The * means "everything". We use -maxdepth 1 so we don't go into subfolders.
for file in "$TARGET"/*; do

  # Skip if the item is a folder (we only want files)
  if [ -d "$file" ]; then
    continue   # "continue" jumps to the next loop iteration
  fi

  # Get just the filename without the folder path
  filename=$(basename "$file")

  # Get the file extension (the part after the last dot), lowercased
  # ${filename##*.} strips everything before the last dot
  ext="${filename##*.}"
  ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')   # convert to lowercase

  # ---------- 5. DECIDE WHERE TO MOVE THE FILE ----------

  # "case" is like a switch statement — matches the extension to a category
  case "$ext" in

    # Image formats
    jpg|jpeg|png|gif|bmp|svg|webp)
      mv "$file" "$TARGET/Images/"
      images=$((images + 1))   # increase counter by 1
      echo "  🖼️  Moved to Images:    $filename"
      ;;

    # Video formats
    mp4|mkv|avi|mov|wmv|flv|webm)
      mv "$file" "$TARGET/Videos/"
      videos=$((videos + 1))
      echo "  🎬 Moved to Videos:    $filename"
      ;;

    # Document formats
    pdf|doc|docx|txt|xls|xlsx|ppt|pptx|csv|odt)
      mv "$file" "$TARGET/Documents/"
      docs=$((docs + 1))
      echo "  📄 Moved to Documents: $filename"
      ;;

    # Music formats
    mp3|wav|aac|flac|ogg|m4a)
      mv "$file" "$TARGET/Music/"
      music=$((music + 1))
      echo "  🎵 Moved to Music:     $filename"
      ;;

    # Archive/compressed 
