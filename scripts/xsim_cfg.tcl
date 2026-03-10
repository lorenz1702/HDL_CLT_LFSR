# xsim_cfg.tcl

# 1. Eine VCD-Datei erstellen und öffnen
open_vcd waves.vcd

# 2. Dem Simulator sagen, welche Signale er in die VCD-Datei schreiben soll.
# Das '/*' bedeutet: Nimm das Top-Level-Modul und alle Untermodule (rekursiv).
log_vcd [get_objects -r /*]

# 3. Simulation unendlich lange laufen lassen (bis $finish in der Testbench kommt)
run all

# 4. VCD-Datei sicher schließen und speichern
close_vcd

# 5. Simulator beenden
quit