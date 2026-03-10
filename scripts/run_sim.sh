#!/bin/bash

# 1. Prüfen, ob ein Argument (der Modulname) übergeben wurde
if [ -z "$1" ]; then
    echo "Fehler: Kein Top-Modul angegeben!"
    echo "Verwendung: ./run_sim.sh <testbench_top_modul>"
    exit 1
fi

# Das erste Argument in einer Variablen speichern (für bessere Lesbarkeit)
TOP_MODULE=$1
SNAPSHOT="${TOP_MODULE}_snapshot"

echo "=== Starte Simulation für: $TOP_MODULE ==="

# 2. Kompilieren
echo "Kompiliere..."
xvlog -sv ../src/*.sv ../sim/*.sv

# 3. Ausarbeiten (mit der dynamischen Variablen)
echo "Elaboriere..."
xelab -debug typical -top $TOP_MODULE -snapshot $SNAPSHOT

# 4. Simulieren (mit dem dynamischen Snapshot-Namen)
echo "Simuliere..."
xsim $SNAPSHOT -tclbatch xsim_cfg.tcl

echo "=== Simulation beendet ==="