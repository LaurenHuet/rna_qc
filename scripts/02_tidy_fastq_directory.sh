#!/bin/bash


# Run this inside the fastq directory
for file in OG*; do
  # Extract OG number without trailing letter (e.g., OG123G → OG123)
  base=$(echo "$file" | grep -oE '^OG[0-9]+')

  # Skip if base is empty
  [ -z "$base" ] && continue

  # Create the OG directory and 'rna' subfolder
  mkdir -p "$base/rna"

  # Move all files matching the OG number (regardless of trailing letter) into 'rna'
  mv "${base}"* "$base/rna/" 2>/dev/null
done
