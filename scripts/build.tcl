# build.tcl

# 1. Prüfen, ob ein Argument (der Modulname) übergeben wurde
if { $argc != 1 } {
    puts "Fehler: Bitte genau ein Top-Modul als Argument übergeben."
    puts "Verwendung: vivado -mode batch -source build.tcl -tclargs <top_modul_name>"
    exit 1
}

# Den übergebenen Namen aus der Liste der Argumente auslesen
set top_module [lindex $argv 0]

# Ziel-FPGA definieren (passe den Part an dein Board an!)
set part_num "xc7a35tcpg236-1" 

puts "=== Starte Build für Top-Modul: $top_module ==="

# 2. Dateien einlesen
read_verilog [glob -nocomplain ../src/*.sv]

# --- NEU: Eigener IP-Repository Ordner ---
# 2a. Pfad zum IP-Repo setzen (Passe '../mein_ip_repo' an deinen echten Ordner an!)
set_property ip_repo_paths ../ip_repo [current_project]

# 2b. Vivado anweisen, den Ordner nach IPs zu durchsuchen
update_ip_catalog
# -----------------------------------------

# --- IP-Cores sicher einlesen ---
# Wir speichern die gefundenen Dateien in einer Variable
set ip_files [glob -nocomplain ../ip/*.xci ../ip/*/*.xci]

# Prüfen, ob die Liste der Dateien NICHT leer ist (Länge > 0)
if { [llength $ip_files] > 0 } {
    puts "INFO: Folgende IPs gefunden: $ip_files"
    read_ip $ip_files
    generate_target all [get_ips]
    synth_ip [get_ips]
} else {
    puts "INFO: Keine .xci Dateien gefunden. Überspringe IP-Schritt."
}
# ---------------------------------

# 2d. Generiere die Output-Produkte für alle gefundenen IPs
generate_target all [get_ips]

# 2e. Synthetisiere die IPs ("Out-of-context")
synth_ip [get_ips]
# ----------------------------------------------


# 3. Synthese (jetzt mit der dynamischen Variablen!)
synth_design -top $top_module -part $part_num

# 4. Platzierung & Routing (Implementation)
opt_design
place_design
route_design

# 5. Bitstream generieren (Wir benennen die Datei direkt nach dem Modul!)
write_bitstream -force ../${top_module}.bit

# 6. Reports generieren
report_timing_summary -file ../${top_module}_timing_summary.rpt
report_utilization -file ../${top_module}_utilization.rpt

puts "=== Build für $top_module erfolgreich abgeschlossen! ==="