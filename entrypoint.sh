#!/bin/bash

set -e

mkdir -p $HOME/.config
cp -r /home/kicad/.config/kicad $HOME/.config/

erc_violation=0 # ERC exit code
drc_violation=0 # DRC exit code

IFS=';'

# Run ERC if requested
if [[ -n $INPUT_KICAD_SCH ]] && [[ $INPUT_SCH_ERC = "true" ]]
then
for file in $INPUT_KICAD_SCH; do
  kicad-cli sch erc \
    --output "$(dirname $file)/$INPUT_SCH_ERC_FILE" \
    --format $INPUT_REPORT_FORMAT \
    --exit-code-violations \
    "$file"
  erc_violation=$?
done
fi

# Export schematic PDF if requested
if [[ -n $INPUT_KICAD_SCH ]] && [[ $INPUT_SCH_PDF = "true" ]]
then
for file in $INPUT_KICAD_SCH; do
  kicad-cli sch export pdf \
    --output "$(dirname $file)/$INPUT_SCH_PDF_FILE" \
    "$file"
done
fi

# Export schematic BOM if requested
if [[ -n $INPUT_KICAD_SCH ]] && [[ $INPUT_SCH_BOM = "true" ]]
then
for file in $INPUT_KICAD_SCH; do
  kicad-cli sch export bom \
    --output "$(dirname $file)/$INPUT_SCH_BOM_FILE" \
    --preset "$INPUT_SCH_BOM_PRESET" \
    --format-preset "$INPUT_SCH_BOM_FORMAT_PRESET" \
    "$file"
done
fi

# Run DRC if requested
if [[ -n $INPUT_KICAD_PCB ]] && [[ $INPUT_PCB_DRC = "true" ]]
then
for file in $INPUT_KICAD_PCB; do
  kicad-cli pcb drc \
    --output "$(dirname $file)/$INPUT_PCB_DRC_FILE" \
    --format $INPUT_REPORT_FORMAT \
    --exit-code-violations \
    "$file"
  drc_violation=$?
done
fi

# Export Gerbers if requested
if [[ -n $INPUT_KICAD_PCB ]] && [[ $INPUT_PCB_GERBERS = "true" ]]
then
for file in $INPUT_KICAD_PCB; do
  GERBERS_DIR=$(mktemp -d)
  kicad-cli pcb export gerbers \
    --output "$GERBERS_DIR/" \
    "$file"
  kicad-cli pcb export drill \
    --output "$GERBERS_DIR/" \
    "$file"
  zip -j \
    "$(dirname $file)/$INPUT_PCB_GERBERS_FILE" \
    "$GERBERS_DIR"/*
done
fi

if [[ -n $INPUT_KICAD_PCB ]] && [[ $INPUT_PCB_IMAGE = "true" ]]
then
for file in $INPUT_KICAD_PCB; do
  directory=$(dirname $file)
  mkdir -p "$directory/$INPUT_PCB_IMAGE_PATH"
  kicad-cli pcb render --side top \
    --output "$directory/$INPUT_PCB_IMAGE_PATH/top.png" \
    "$file"
  kicad-cli pcb render --side bottom \
    --output "$directory/$INPUT_PCB_IMAGE_PATH/bottom.png" \
    "$file"
done
fi

if [[ -n $INPUT_KICAD_PCB ]] && [[ $INPUT_PCB_MODEL = "true" ]]
then
for file in $INPUT_KICAD_PCB; do
  kicad-cli pcb export step $INPUT_PCB_MODEL_FLAGS \
    --output "$(dirname $file)/$INPUT_PCB_MODEL_FILE" \
    "$file"
done
fi

# Return non-zero exit code for ERC or DRC violations
if [[ $erc_violation -gt 0 ]] || [[ $drc_violation -gt 0 ]]
then
  exit 1
else
  exit 0
fi
