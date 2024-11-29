#!/bin/bash

# Versionsnummer definieren
VERSION="0.09a"

INFQ="$2"
OUTDIR="$4"
REFHUM="$6"
DATABASE_PATH="$8"
THREADS="${10}"

### Pipeline Code

## Definition der Ausgaben:
datetime.task(){ Date=$(date "+%Y-%m-%d %H:%M:%S"); echo "[$Date] TASK:"; }
datetime.info(){ Date=$(date "+%Y-%m-%d %H:%M:%S"); echo "[$Date] INFO:"; }
datetime.warning(){ Date=$(date "+%Y-%m-%d %H:%M:%S"); echo "[$Date] WARNING:"; }
datetime.error(){ Date=$(date "+%Y-%m-%d %H:%M:%S"); echo "[$Date] ERROR:"; }
datetime.skip(){ Date=$(date "+%Y-%m-%d %H:%M:%S"); echo "[$Date] SKIP:"; }
datetime.done(){ Date=$(date "+%Y-%m-%d %H:%M:%S"); echo "[$Date] DONE:"; }

echo "  _______ _____  _____   _____  _____ "
echo " |__   __|  __ \|  __ \ / ____|/ ____|"
echo "    | |  | |  | | |__) | |    | (___  "
echo "    | |  | |  | |  ___/| |     \___ \ "
echo "    | |  | |__| | |    | |____ ____) |"
echo "    |_|  |_____/|_|     \_____|_____/ "


# Start der Pipeline im Loop Run.
echo ""
echo "$(datetime.done) LOOP Mode"

# Prüfen, ob OUTDIR definiert ist
if [ -z "$OUTDIR" ]; then
    echo "$(datetime.error) OUTDIR ist nicht definiert. Beende die Pipeline."
    exit 1
fi

# Prüfen, ob OUTDIR bereits vorhanden ist
if [ -d "$OUTDIR" ]; then
    echo "$(datetime.warning) Der Ordner $OUTDIR ist bereits vorhanden. Möchten Sie fortfahren? (Ja/Nein)"
    read -r response
    case $response in
        Ja|ja|J|j|Yes|yes|Y|y )
            echo "$(datetime.info) Starte Analyse-Pipeline SINGLE-RUN (BETA-MODE) bei letzter Analyse-Position"
            ;;
        *)
            echo "$(datetime.warning) Pipeline wird beendet."
            exit 1
            ;;
    esac
else
    # Erstellen des OUTPUT-Verzeichnisses, falls es nicht existiert
    echo "$(datetime.info) Erstelle das Verzeichnis $OUTDIR"
    mkdir -p "$OUTDIR"
fi

# Schleife zum Ausführen der Pipeline
while true; do

    echo "$(datetime.task) Starte den nächsten Pipeline-Durchlauf."

    # Erstellen einer globalen Log-Datei (falls nicht bereits vorhanden)
    G_LOG_FILE="$OUTDIR/global_file.log"
    mkdir -p "$(dirname "$G_LOG_FILE")"


	### Erstellt Output-Verzeichnis mit dem ersten Ausgabeordner 00-InputData - Ordner enthält die Input Fastq Datei, damit in dem OUTDIR alle Daten kombiniert enthalten sind.
	# Prüfe, ob der Ausgabeordner bereits existiert
	if [ -d "$OUTDIR" ]; then
		# Wenn der Ausgabeordner existiert, entferne ihn und vermerke es im Terminal und Log
		echo "$(datetime.warning) Entferne vorhandenen Ausgabeordner $OUTDIR"
		rm -r "$OUTDIR"
	fi
		
		# Erstellen des OUTPUT Verzeichnisses
	mkdir $OUTDIR
		#### Kopieren der Input Datei in das Output Verzeichnis zur Dokumentation
	mkdir $OUTDIR/00-InputData

	# Ausgabe des Startzeitpunkts in die Protokolldatei
	echo "" 
	echo "" 
	echo "$(datetime.task) Starte Analyse-Pipeline LOOP-RUN (BETA-MODE)" 
	echo "$(datetime.task) Starte Analyse-Pipeline LOOP-RUN (BETA-MODE)" >> "$G_LOG_FILE"

	#-------------------------------------------------------------------------------------------------------------------------------------
	# Überprüfen, ob die Datei $INFQ existiert
	if [ ! -f "$INFQ" ]; then
		echo "$(datetime.error) Die Datei $INFQ existiert nicht. Das Skript wird abgebrochen."
		exit 1
	fi

	# Wenn der Ordner $OUTDIR/01-CleanedReads bereits existiert, dann überspringe
	if [ -d "$OUTDIR/01-CleanedReads" ]; then
		echo "$(datetime.skip) Kopieren der Input Datei in das Output Verzeichnis zur Dokumentation wird uebersprungen" >> "$G_LOG_FILE"
		echo "$(datetime.skip) Kopieren der Input Datei in das Output Verzeichnis zur Dokumentation wird uebersprungen" 
	else	    	
		#### Kopieren der Input Datei in das Output Verzeichnis zur Dokumentation
		mkdir $OUTDIR/00-InputData

		# Ausgabe des Startzeitpunkts in die Protokolldatei
		echo "$(datetime.task) Starte Analyse-Pipeline BETA-Mode" 
		echo "$(datetime.task) Starte Analyse-Pipeline BETA-Mode" >> "$G_LOG_FILE"

		# Kopiere Input Fastq in OutDIR
		echo "$(datetime.task) Kopiere die Input-Fastq Datei in das Ausgabeverzeichnis" >> "$G_LOG_FILE"
		cp "$INFQ" "$OUTDIR/00-InputData"
		echo "$(datetime.done) $INFQ in $OUTDIR/00-InputData erfolgreich kopiert" >> "$G_LOG_FILE"
		echo "$(datetime.done) ------------------------------------------------------------------------------------------------------------------------" >> "$G_LOG_FILE"
	fi
	#-------------------------------------------------------------------------------------------------------------------------------------

	# Wenn der Ordner $OUTDIR/02-De_Novo_Assembly bereits existiert, dann überspringe
	if [ -d "$OUTDIR/02-De_Novo_Assembly" ]; then
		echo "$(datetime.warning) ------------------------------------------------------------------------------------------------------------------------" >> "$G_LOG_FILE"
		echo "$(datetime.warning) Alignment gegen Human Referenzgenom wird uebersprungen" >> "$G_LOG_FILE"
		echo "$(datetime.skip) Alignment gegen Human Referenzgenom wird uebersprungen" 
	else
		#### Alignment gegen Human Referenzgenom
		# Definiere den Pfad zur Protokolldatei
		ALIGN_LOG="$OUTDIR/01-CleanedReads/align_to_human_ref.log"

		# Erstelle das Verzeichnis, falls es nicht vorhanden ist
		mkdir -p "$(dirname "$ALIGN_LOG")"

		# Überprüfe, ob alle erforderlichen Variablen gesetzt sind
		if [ -z "$OUTDIR" ] || [ -z "$THREADS" ] || [ -z "$REFHUM" ]; then
			echo "$(datetime.error) Erforderliche Variablen fehlen."
			exit 1
		fi

		# Ausgabe des Startzeitpunkts in die Protokolldatei
		echo "$(datetime.task) Starte Minimap2-Alignment gegen $REFHUM" >> "$ALIGN_LOG"
		echo "$(datetime.task) Starte Alignment gegen $REFHUM" >> "$G_LOG_FILE"

		# align to ref
		mkdir -p "$OUTDIR/01-CleanedReads"
		minimap2 -ax map-ont -t "$THREADS" "$REFHUM" "$OUTDIR/00-InputData"/*fastq -o "$OUTDIR/01-CleanedReads/align_to_ref.sam"

		# Samtools erstellt aus Sam-File eine Bam-File
		samtools view -bS $OUTDIR/01-CleanedReads/align_to_ref.sam > $OUTDIR/01-CleanedReads/align_to_ref.bam

		# Ausgabe, dass der Vorgang abgeschlossen ist und Protokoll in die Datei schreiben
		echo "$(datetime.done) Alignment zu $REFHUM abgeschlossen. Ausgabedaten in $OUTDIR/01-CleanedReads" | tee -a "$ALIGN_LOG"
		echo "$(datetime.done) Alignment gegen $REFHUM abgeschlossen" >> "$G_LOG_FILE"
		echo "$(datetime.done) ------------------------------------------------------------------------------------------------------------------------" >> "$G_LOG_FILE"
		#-------------------------------------------------------------------------------------------------------------------------------------
		#### Extraktion der unaligned Reads aus der Bam-Datei
		# Definiere den Pfad zur Protokolldatei
		UNALIGNED_LOG="$OUTDIR/01-CleanedReads/extract_unaligned_reads.log"

		# Erstelle das Verzeichnis, falls es nicht vorhanden ist
		mkdir -p "$(dirname "$UNALIGNED_LOG")"

		# Überprüfe, ob alle erforderlichen Variablen gesetzt sind
		if [ -z "$OUTDIR" ]; then
			echo "$(datetime.error) Erforderliche Variablen fehlen."
			exit 1
		fi

		# Ausgabe des Startzeitpunkts in die Protokolldatei
		echo "$(datetime.task) Starte Extrahieren nicht alignierter Reads" >> "$UNALIGNED_LOG"
		echo "$(datetime.task) Starte Extrahieren nicht alignierter Reads" >> "$G_LOG_FILE"

		# Funktion zum Extrahieren nicht alignierter Reads
		extract_unaligned_reads() {
			aligned_bam="$1"
			unaligned_fastq="${aligned_bam%.bam}_unaligned.fastq"

			# Extrahiere nicht alignierte Reads und schreibe sie in eine FASTQ-Datei
			samtools view -f 4 -u "$aligned_bam" | samtools fastq - > "$unaligned_fastq"

			echo "$unaligned_fastq"
		}

		# Aufruf der Funktion zum Extrahieren nicht alignierter Reads
		aligned_bam="$OUTDIR/01-CleanedReads/align_to_ref.bam"
		unaligned_fastq=$(extract_unaligned_reads "$aligned_bam")

		# Ausgabe, dass der Vorgang abgeschlossen ist und Protokoll in die Datei schreiben
		echo "$(datetime.done) Extrahieren nicht alignierter Reads abgeschlossen. Ausgabedaten in $OUTDIR/03-UnalignedReads" | tee -a "$UNALIGNED_LOG"
		echo "$(datetime.done) Extrahieren nicht alignierter Reads abgeschlossen" >> "$G_LOG_FILE"

		# Funktion zur Umwandlung von FASTQ in FASTA
		convert_fastq_to_fasta() {
			unaligned_fastq="$1"
			unaligned_fasta="${unaligned_fastq%.fastq}.fa"

			# FASTQ zu FASTA konvertieren: Überspringe jede zweite Zeile nach dem Header und Quality-Werte
			awk 'NR%4==1 {print ">"substr($0,2)} NR%4==2 {print}' "$unaligned_fastq" > "$unaligned_fasta"

			echo "$unaligned_fasta"
		}

		# Aufruf der Funktion zur Umwandlung von FASTQ in FASTA
		unaligned_fasta=$(convert_fastq_to_fasta "$unaligned_fastq")

		# Ausgabe des Ergebnisses in die Protokolldatei
		echo "$(datetime.task) Umgewandelte FASTQ-Datei in FASTA: $unaligned_fasta" >> "$UNALIGNED_LOG"
		echo "$(datetime.task) Umgewandelte FASTQ-Datei in FASTA: $unaligned_fasta" >> "$G_LOG_FILE"

		echo "$(datetime.done) ------------------------------------------------------------------------------------------------------------------------" >> "$G_LOG_FILE"
		echo "$(datetime.done)  ___ ___  ____  ____   ____  ___ ___   ____  ____       ___     ___   ____     ___ "
		echo "$(datetime.done) |   |   ||    ||    \ |    ||   |   | /    ||    \     |   \   /   \ |    \   /  _]"
		echo "$(datetime.done) | _   _ | |  | |  _  | |  | | _   _ ||  o  ||  o  )    |    \ |     ||  _  | /  [_ "
		echo "$(datetime.done) |  \_/  | |  | |  |  | |  | |  \_/  ||     ||   _/     |  D  ||  O  ||  |  ||    _]"
		echo "$(datetime.done) |   |   | |  | |  |  | |  | |   |   ||  _  ||  |       |     ||     ||  |  ||   [_ "
		echo "$(datetime.done) |   |   | |  | |  |  | |  | |   |   ||  |  ||  |       |     ||     ||  |  ||     |"
		echo "$(datetime.done) |___|___||____||__|__||____||___|___||__|__||__|       |_____| \___/ |__|__||_____|"

	fi
	#-------------------------------------------------------------------------------------------------------------------------------------

	# Wenn der Ordner $OUTDIR/03-Bins bereits existiert, dann überspringe
	if [ -d "$OUTDIR/03-Bins" ]; then
		echo "$(datetime.warning) ------------------------------------------------------------------------------------------------------------------------" >> "$G_LOG_FILE"
		echo "$(datetime.skip) DeNovo Assembly wird uebersprungen" >> "$G_LOG_FILE"
			echo "$(datetime.skip) DeNovo Assembly wird uebersprungen" 
	else
			### DeNovo Assembly
			# Definiere den Pfad zur Protokolldatei
		FLYE_LOG="$OUTDIR/02-De_Novo_Assembly/de_novo_assembly.log"

		# Erstelle das Verzeichnis, falls es nicht vorhanden ist
		mkdir -p "$(dirname "$ALIGN_LOG")"

		# Überprüfe, ob alle erforderlichen Variablen gesetzt sind
		if [ -z "$OUTDIR" ] || [ -z "$THREADS" ] || [ -z "$REFHUM" ]; then
			echo "$(datetime.error) Erforderliche Variablen fehlen."
			exit 1
		fi
		

		# Erstelle das Verzeichnis, falls es nicht vorhanden ist
		mkdir -p "$(dirname "$FLYE_LOG")"

		# Überprüfe, ob alle erforderlichen Variablen gesetzt sind
		if [ -z "$OUTDIR" ] || [ -z "$THREADS" ]; then
			echo "$(datetime.error) Erforderliche Variablen fehlen."
			exit 1
		fi

		# Ausgabe des Startzeitpunkts in die Protokolldatei
		echo "$(datetime.task) Starte De-Novo-Assembly" >> "$FLYE_LOG"
		echo "$(datetime.task) Starte De-Novo-Assembly" >> "$G_LOG_FILE"

		# Assembly mit Flye durchführen
		mkdir -p "$OUTDIR/02-De_Novo_Assembly"
		flye --meta --nano-hq "$OUTDIR/01-CleanedReads/align_to_ref_unaligned.fastq" -t "$THREADS" -o "$OUTDIR/02-De_Novo_Assembly/Flye"

		# Ausgabe, dass der Vorgang abgeschlossen ist und Protokoll in die Datei schreiben
		echo "$(datetime.done) De-Novo-Assembly abgeschlossen. Ausgabedaten in $OUTDIR/02-De_Novo_Assembly/Flye" | tee -a "$FLYE_LOG"
		echo "$(datetime.done) De-Novo-Assembly abgeschlossen. Ausgabedaten in $OUTDIR/02-De_Novo_Assembly/Flye" >> "$G_LOG_FILE"
		echo "$(datetime.done) ------------------------------------------------------------------------------------------------------------------------" >> "$G_LOG_FILE"
		echo "$(datetime.done)  _____  _      __ __    ___      ___     ___   ____     ___ "
		echo "$(datetime.done) |     || |    |  |  |  /  _]    |   \   /   \ |    \   /  _]"
		echo "$(datetime.done) |   __|| |    |  |  | /  [_     |    \ |     ||  _  | /  [_ "
		echo "$(datetime.done) |  |_  | |___ |  ~  ||    _]    |  D  ||  O  ||  |  ||    _]"
		echo "$(datetime.done) |   _] |     ||___, ||   [_     |     ||     ||  |  ||   [_ "
		echo "$(datetime.done) |  |   |     ||     ||     |    |     ||     ||  |  ||     |"
		echo "$(datetime.done) |__|   |_____||____/ |_____|    |_____| \___/ |__|__||_____|"
	fi
	#-------------------------------------------------------------------------------------------------------------------------------------

	# Wenn der Ordner $OUTDIR/04-Classify bereits existiert, dann überspringe
	if [ -d "$OUTDIR/04-Classify" ]; then
		echo "$(datetime.warning) ------------------------------------------------------------------------------------------------------------------------" >> "$G_LOG_FILE"
		echo "$(datetime.skip) Binning mit Metawrap & Binning-Verfeinerung mit Metawrap wird uebersprungen" >> "$G_LOG_FILE"
			echo "$(datetime.skip) Binning mit Metawrap & Binning-Verfeinerung mit Metawrap wird uebersprungen" 
	else
			### Binning mit Metawrap
		# Definiere den Pfad zur Protokolldatei
		BINNING_LOG="$OUTDIR/03-Bins/binning.log"

		# Erstelle das Verzeichnis, falls es nicht vorhanden ist
		mkdir -p "$(dirname "$BINNING_LOG")"

		# Überprüfe, ob alle erforderlichen Variablen gesetzt sind
		if [ -z "$OUTDIR" ] || [ -z "$THREADS" ]; then
			echo "$(datetime.error) Erforderliche Variablen fehlen."
			exit 1
		fi

		# Ausgabe des Startzeitpunkts in die Protokolldatei
		echo "$(datetime.task) Starte Binning mit Metawrap" >> "$BINNING_LOG"
		echo "$(datetime.task) Starte Binning mit Metawrap" >> "$G_LOG_FILE"

		# Metawrap Binning
		mkdir -p "$OUTDIR/03-Bins"
		mkdir -p "$OUTDIR/03-Bins/Binning"

		# Binning mit Metawrap
		metawrap binning -t "$THREADS" -a "$OUTDIR/02-De_Novo_Assembly/Flye/assembly.fasta" -o "$OUTDIR/03-Bins/Binning" --metabat2 --maxbin2 --single-end "$OUTDIR/00-InputData/"*fastq

		# Ausgabe, dass der Vorgang abgeschlossen ist und Protokoll in die Datei schreiben
		echo "$(datetime.done) Binning mit Metawrap abgeschlossen. Ausgabedaten in $OUTDIR/03-Bins/Binning" | tee -a "$BINNING_LOG"
		echo "$(datetime.done) Binning mit Metawrap abgeschlossen" >> "$G_LOG_FILE"
		echo "$(datetime.done) ------------------------------------------------------------------------------------------------------------------------" >> "$G_LOG_FILE"
		
		### Binning-Verfeinerung mit Metawrap

		# Definiere den Pfad zur Protokolldatei
		BIN_REFINEMENT_LOG="$OUTDIR/03-Bins/bin_refinement.log"

		# Erstelle das Verzeichnis, falls es nicht vorhanden ist
		mkdir -p "$(dirname "$BIN_REFINEMENT_LOG")"

		# Ausgabe des Startzeitpunkts in die Protokolldatei
		echo "$(datetime.task) Starte Binning-Verfeinerung mit Metawrap" >> "$BIN_REFINEMENT_LOG"
		echo "$(datetime.task) Starte Binning-Verfeinerung mit Metawrap" >> "$G_LOG_FILE"

		# Metawrap Binning-Verfeinerung
		mkdir -p "$OUTDIR/03-Bins/Bin_Refinement"

		# Binning-Verfeinerung mit Metawrap
		metawrap bin_refinement -t "$THREADS" -A "$OUTDIR/03-Bins/Binning/metabat2_bins" -B "$OUTDIR/03-Bins/Binning/maxbin2_bins" -o "$OUTDIR/03-Bins/Bin_Refinement" --skip-checkm

		# Ausgabe, dass der Vorgang abgeschlossen ist und Protokoll in die Datei schreiben
		echo "$(datetime.done) Binning-Verfeinerung mit Metawrap abgeschlossen. Ausgabedaten in $OUTDIR/03-Bins/Bin_Refinement" | tee -a "$BIN_REFINEMENT_LOG"
		echo "$(datetime.done) Binning-Verfeinerung mit Metawrap abgeschlossen" >> "$G_LOG_FILE"
		echo "$(datetime.done) ------------------------------------------------------------------------------------------------------------------------" >> "$G_LOG_FILE"

		# Ausgabe, dass der Vorgang abgeschlossen ist und Protokoll in die Datei schreiben für die Split-Funktion
		echo "$(datetime.done) Split-Funktion abgeschlossen." | tee -a "$SPLIT_LOG"
		echo "$(datetime.done) Split-Funktion abgeschlossen" >> "$G_LOG_FILE"
		echo "$(datetime.done) ------------------------------------------------------------------------------" >> "$G_LOG_FILE"
		echo "$(datetime.done)  ___ ___    ___ ______   ____  __    __  ____    ____  ____       ___     ___   ____     ___ "
		echo "$(datetime.done) |   |   |  /  _]      | /    ||  |__|  ||    \  /    ||    \     |   \   /   \ |    \   /  _]"
		echo "$(datetime.done) | _   _ | /  [_|      ||  o  ||  |  |  ||  D  )|  o  ||  o  )    |    \ |     ||  _  | /  [_ "
		echo "$(datetime.done) |  \_/  ||    _]_|  |_||     ||  |  |  ||    / |     ||   _/     |  D  ||  O  ||  |  ||    _]"
		echo "$(datetime.done) |   |   ||   [_  |  |  |  _  ||        ||    \ |  _  ||  |       |     ||     ||  |  ||   [_ "
		echo "$(datetime.done) |   |   ||     | |  |  |  |  | \      / |  .  \|  |  ||  |       |     ||     ||  |  ||     |"
		echo "$(datetime.done) |___|___||_____| |__|  |__|__|  \_/\_/  |__|\_||__|__||__|       |_____| \___/ |__|__||_____|"
	fi
	#-------------------------------------------------------------------------------------------------------------------------------------

	### Klassifizierung mit GTDB-Tk
	# Prüfe, ob der Ausgabeordner bereits existiert
	if [ -d "$OUTDIR/04-Classify" ]; then
		# Wenn der Ausgabeordner existiert, entferne ihn und vermerke es im Terminal und Log
		echo "$(datetime.warning) Entferne vorhandenen Ausgabeordner $OUTDIR/04-Classify" >> "$G_LOG_FILE"
		echo "$(datetime.warning) Entferne vorhandenen Ausgabeordner $OUTDIR/04-Classify"
		echo "$(datetime.warning) Entferne vorhandenen Ausgabeordner $OUTDIR/05-Results" >> "$G_LOG_FILE"
		echo "$(datetime.warning) Entferne vorhandenen Ausgabeordner $OUTDIR/05-Results"
		rm -r "$OUTDIR/04-Classify"
		rm -r "$OUTDIR/05-Results"
	fi

	classify_gtdbtk(){
		# Definiere den Pfad zur Protokolldatei
		CLASSIFY_LOG="$OUTDIR/04-Classify/classify_with_gtdbtk.log"

		# Erstelle das Verzeichnis, falls es nicht vorhanden ist
		mkdir -p "$(dirname "$CLASSIFY_LOG")"

		# Ausgabe des Startzeitpunkts in die Protokolldatei
		echo "$(datetime.task) Starte Klassifizierung mit GTDB-Tk" >> "$CLASSIFY_LOG"
		echo "$(datetime.task) Starte Klassifizierung mit GTDB-Tk" >> "$G_LOG_FILE"

		# classify mit GTDB-Tk
		mkdir -p "$OUTDIR/04-Classify"
		mkdir -p "$OUTDIR/04-Classify/GTDBTK"
		gtdbtk classify_wf --genome_dir "$OUTDIR/03-Bins/Bin_Refinement/work_files/binsM" --out_dir "$OUTDIR/04-Classify/GTDBTK" --cpus "$THREADS" --extension fa --skip_ani_screen --min_perc_aa 0.5

		# Ausgabe, dass der Vorgang abgeschlossen ist und Protokoll in die Datei schreiben
		echo "$(datetime.done) Klassifizierung mit GTDB-Tk abgeschlossen. Ausgabedaten in $OUTDIR/04-Classify/GTDBTK" >> "$CLASSIFY_LOG"
		echo "$(datetime.done) Klassifizierung mit GTDB-Tk abgeschlossen" >> "$G_LOG_FILE"
		echo "$(datetime.done) ------------------------------------------------------------------------------------------------------------------------" >> "$G_LOG_FILE"
	}

	# Aufruf der Funktion zum Klassifizieren
	classify_gtdbtk

	# Funktion zur Verarbeitung des GTDB-Tk-Ausgangs aufrufen
	process_gtdbtk_output() {
		# Ausgabe des Startzeitpunkts in die Protokolldatei
		echo "$(datetime.task) Starte Aufbereitung der GTDB-Tk Ergebnisse" >> "$CLASSIFY_LOG"
		echo "$(datetime.task) Starte Aufbereitung der GTDB-Tk Ergebnisse" >> "$G_LOG_FILE"

		gtdbtk_output_dir="$1"

		# Ein leeres Array erstellen, um die Anzahl jedes Stammes zu zählen
		declare -A stamm_count

		# Pfad zur TSV-Datei unter Verwendung von gtdbtk_output_dir
		tsv_paths=("$gtdbtk_output_dir"/gtdbtk*.summary.tsv)

		# Erstelle das Verzeichnis für die Ergebnisdatei, falls es nicht vorhanden ist
		results_dir="$OUTDIR/05-Results"
		mkdir -p "$results_dir"

		# CSV-Datei erstellen
		results_csv_path="$results_dir/ergebnisse.csv"
		# Header in die CSV-Datei schreiben
		echo "Stamm,Count" > "$results_csv_path"

		# Für jede TSV-Datei im Verzeichnis iterieren
		for tsv_path in "${tsv_paths[@]}"; do
			# Überprüfe, ob die TSV-Datei vorhanden ist
			if [ -f "$tsv_path" ]; then
				# CSV-Datei bearbeiten
				awk 'NR>1 { print $2 }' FS='\t' OFS=',' "$tsv_path" | sort | uniq -c | awk '{ print $2","$1 }' >>"$results_csv_path"

				echo "Verarbeitung von $tsv_path abgeschlossen."
			else
				echo "Die Datei $tsv_path existiert nicht."
			fi
		done

		# Ausgabe, dass der Vorgang abgeschlossen ist und Protokoll in die Datei schreiben
		echo "$(datetime.done) Aufbereitung GTDB-Tk abgeschlossen. Ausgabedaten in $OUTDIR/05-Results/ergebnisse.csv" | tee -a "$CLASSIFY_LOG"
		echo "$(datetime.done) Aufbereitung GTDB-Tk abgeschlossen" >> "$G_LOG_FILE"
		echo "$(datetime.done) ------------------------------------------------------------------------------------------------------------------------" >> "$G_LOG_FILE"
	}

	# Aufruf der Funktion zur Verarbeitung des GTDB-Tk-Ausgangs
	process_gtdbtk_output "$OUTDIR/04-Classify/GTDBTK"
	#-------------------------------------------------------------------------------------------------------------------------------------

	### Klassifizierung mit BLASTn
	# Definiere den Pfad zur Protokolldatei für BLASTn
	BLASTN_LOG="$OUTDIR/05-Results/blastn.log"

	# Erstelle das Verzeichnis, falls es nicht vorhanden ist
	mkdir -p "$(dirname "$BLASTN_LOG")"

	# Ausgabe des Startzeitpunkts in die Protokolldatei für BLASTn
	echo "$(datetime.task) Starte BLASTn"
	echo "$(datetime.task) Starte BLASTn" >> "$BLASTN_LOG"
	echo "$(datetime.task) Starte BLASTn" >> "$G_LOG_FILE"
	echo "$(datetime.task) Suche nach Fasta in $OUTDIR/01-CleanedReads/align_to_ref_unaligned.fa" >> "$BLASTN_LOG"


	# Funktion zur Ausführung von BLASTn aufrufen
	run_blastn() {

		# Ausgabe-TSV-Dateipfad festlegen
		ncbi_unbinned_dir="$OUTDIR/05-Results/out_ncbi.tsv"


		# Befehl für Blastn vorbereiten
		blastn -task megablast -db "$DATABASE_PATH" -num_threads "$THREADS" -outfmt '6 qseqid sacc stitle ssciname nident qlen' -max_target_seqs 1 -max_hsps 1 -query "$OUTDIR/01-CleanedReads/align_to_ref_unaligned.fa" > "$ncbi_unbinned_dir"


		# Ausgabe, dass der Vorgang abgeschlossen ist und Protokoll in die Datei schreiben für BLASTn
		echo "$(datetime.done) BLASTn abgeschlossen." | tee -a "$BLASTN_LOG"
		echo "$(datetime.done) BLASTn abgeschlossen" >> "$G_LOG_FILE"
		echo "$(datetime.done) ------------------------------------------------------------------------------------------------------------------------" >> "$G_LOG_FILE"

		# Korrekter Pfad zur TSV-Datei zurückgeben
		echo "$ncbi_unbinned_dir"
	}

	# Aufruf der Funktion
	run_blastn "$OUTDIR/01-CleanedReads/align_to_ref_unaligned.fa"
	#-------------------------------------------------------------------------------------------------------------------------------------

	# Ausgabe von BLAST neu anordnen
	# Verzeichnis, in dem sich die TSV-RAW-Datei befindet
	NCBI_RAW="$ncbi_unbinned_dir"

	# Verzeichnis, in dem sich die TSV-MODIFIED-Datei befinden wird
	NCBI_RESTRUCTURED="$OUTDIR/05-Results/res_ncbi.tsv"

	# Pfad zum Verzeichnis des R-Skripts (Übergeordnetes Verzeichnis)
	R_SCRIPT_DIR="/home/drk/tdcs/R"

	# Rufe das R-Skript auf und übergebe den Pfad zur Ausgabedatei
	Rscript "$R_SCRIPT_DIR/restructure_raw_to_genus.R" "$NCBI_RAW" "$NCBI_RESTRUCTURED"
	
	#-------------------------------------------------------------------------------------------------------------------------------------
	# Eingabedatei
	EINGABEDATEI="$NCBI_RESTRUCTURED"
	extract_output() {
		# Ausgabedatei im CSV-Format
		AUSGABEDATEI="$OUTDIR/05-Results/res_ncbi.csv"

		# Trennzeichen für die TSV-Datei
		TRENNZEICHEN=$'\t'

		# Leere Ausgabedatei erstellen
		touch $AUSGABEDATEI

		# Header in die Ausgabedatei schreiben (CSV-Format)
		echo "Stamm,Count" > $AUSGABEDATEI

		# Ergebnisdatei zeilenweise verarbeiten (ohne Header)
		tail -n +2 "$EINGABEDATEI" | while IFS=$'\t' read -r GENUS TOTAL_COUNT; do
			# Ersetze alle Kommas in den Feldern durch Punkte
			GENUS=$(echo "$GENUS" | sed 's/,/./g')
			TOTAL_COUNT=$(echo "$TOTAL_COUNT" | sed 's/,/./g')
			
			# Genus und Zählwert in die Ausgabedatei schreiben (im CSV-Format)
			echo "$GENUS,$TOTAL_COUNT" >> $AUSGABEDATEI
		done
	}

	# Aufruf der Funktion zur Extraktion des NCBI-Output
	extract_output

	#-------------------------------------------------------------------------------------------------------------------------------------
	# Starte Shiny App zur Datenauswertung

	# Shiny App zur Datenauswertung
	shiny_gui() {
		# Verzeichnis, in dem sich die CSV-Datei befindet
		TSV_DIR="$OUTDIR/05-Results"

		# Pfad zur CSV-Datei
		TSV_FILE="$TSV_DIR/res_ncbi.csv"

		# Pfad zum Verzeichnis des R-Skripts (Übergeordnetes Verzeichnis)
		R_SCRIPT_DIR="/home/drk/tdcs/R"

		# Definiere den Pfad zur Protokolldatei für BLASTn
		RSCRIPT_LOG="$OUTDIR/05-Results/r_plots.log"

		# Erstelle das Verzeichnis, falls es nicht vorhanden ist
		mkdir -p "$(dirname "$RSCRIPT_LOG")"

		# Ausgabe des Startzeitpunkts in die Protokolldatei für BLASTn
		echo "$(datetime.task) Starte R-Skript" >> "$RSCRIPT_LOG"

		# Übergabe der Werte an das R-Skript.
		# Setze den Pfad zur Ausgabedatei als Umgebungsvariable
		export TSV_PATH="$TSV_FILE"
		export FASTQ_PATH="$INFQ"

		# R-Skript aufrufen
		Rscript "$R_SCRIPT_DIR/plot_script.R" "$TSV_PATH" "$FASTQ_PATH" &

		# Warte eine kurze Zeit, um sicherzustellen, dass die Shiny-App gestartet wurde
		sleep 2

		# Öffne den Webbrowser mit der Shiny-App
		xdg-open "http://127.0.0.1:4010"

		# Ausgabe, dass der Vorgang abgeschlossen ist und Protokoll in die Datei schreiben für BLASTn
		echo "$(datetime.done) Übergabe an R-Skript abgeschlossen." | tee -a "$RSCRIPT_LOG"
		echo "$(datetime.done) Übergabe an R-Skript abgeschlossen." | tee -a "$G_LOG_FILE"

	}

	# Warte eine kurze Zeit, um sicherzustellen, dass die Shiny-App gestartet wurde
	sleep 20 

	# Aufruf der Funktion Shiny GUI
	shiny_gui

	sleep 120

done