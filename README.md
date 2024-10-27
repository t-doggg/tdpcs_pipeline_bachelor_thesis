# tdpcs_pipeline_bachelor_thesis
Die TDPCS-Pipeline ist eine Analyse-Pipeline, die es ermöglicht, aus metagenomischen Proben spezifische Bakterien zu identifizieren. Diese Pipeline wurde im Rahmen der Bachelorarbeit von Timo Dinse entwickelt.

Funktionsweise

Die Pipeline verarbeitet die Proben in mehreren Schritten:

	1.	Host-Filterung: Entfernt Host-Zell-Sequenzen aus den Reads.
	2.	De-novo Assembly: Erstellt ein de-novo Assembly der gefilterten Reads.
	3.	Bin Refinement: Verfeinert die Bins für genauere Analysen.
	4.	Klassifizierung: Die Klassifizierung erfolgt in zwei Varianten:
	•	Fast-Track: Klassifizierung über GTDB-Tk.
	•	Detailed-Track: Nach der Host-Filterung werden alle Sequenzen >400 bp extrahiert und mittels einer lokalen BLAST-Suche weiter analysiert.

Installation

Voraussetzungen

Für die Nutzung der TDPCS-Pipeline müssen folgende Programme installiert sein:

	1.	Minimap3: Download und Installation erforderlich, um Sequenzen zuzuordnen.
	2.	NanoPhase Minimap Environment: Installiere die Umgebung gemäß den Anweisungen im NanoPhase GitHub Repository.
	3.	BLAST Search Tool: Lade das Tool und die core_nt Datenbank herunter und installiere sie gemäß den offiziellen Anweisungen.

Repository herunterladen

	1.	Klone oder lade das TDPCS-Repository von GitHub herunter:
```bash
 git clone https://github.com/username/TDPCS.git

 	2.	Navigiere ins Verzeichnis:
```bash
  cd TDPCS


Systempfad festlegen

Um die Pipeline bequem mit dem Befehl tdpcs auszuführen, sollte das tdpcs/shell/base-Verzeichnis in den Systempfad aufgenommen werden. Dies kann durch folgenden Befehl erreicht werden:
```bash
export PATH="/home/USER/tdpcs/shell/base:$PATH"

	Hinweis: Ersetze USER durch deinen Benutzernamen.

Nutzung

Die TDPCS-Pipeline kann mit folgendem Befehl ausgeführt werden:
```bash
tdpcs -h

Dieser Befehl zeigt eine Hilfsübersicht mit allen verfügbaren Befehlen und Parametern.

Beispiel für die Analyse

Ein typischer Analysebefehl sieht wie folgt aus:
```bash
tdpcs analyse -i /path/to/infq -o /path/to/outfolder -x /path/to/hostsequence -d /path/to/blastdatabase -t Threads -m MODE


	•	-i: Pfad zur Eingabedatei im FastQ-Format
	•	-o: Ausgabeverzeichnis für die Analyseergebnisse
	•	-x: Pfad zur Host-Sequenz, die aus den Reads entfernt werden soll
	•	-d: Pfad zur BLAST-Datenbank
	•	-t: Anzahl der Threads, die für die Analyse verwendet werden sollen
	•	-m: Modus der Pipeline-Ausführung

Modi

Die TDPCS-Pipeline bietet verschiedene Ausführungsmodi, die Geschwindigkeit und Detaillierungsgrad steuern:

	•	fs: Fast and Single Run – Schnelle Einzelanalyse
	•	fl: Fast in Loop – Schnelle Mehrfachanalyse in einer Schleife
	•	ls: Long in Single Run – Detaillierte Einzelanalyse
	•	ll: Long in Loop – Detaillierte Mehrfachanalyse in einer Schleife

Beispiele

	1.	Fast and Single Run:
```bash
 tdpcs analyse -i /data/sample.fastq -o /results -x /host/host_sequence.fasta -d /blast/db/core_nt -t 8 -m fs


 	2.	Long in Loop:
```bash
  tdpcs analyse -i /data/sample.fastq -o /results -x /host/host_sequence.fasta -d /blast/db/core_nt -t 16 -m ll

