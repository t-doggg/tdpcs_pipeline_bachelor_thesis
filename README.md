# tdpcs_pipeline_bachelor_thesis
Die TDPCS-Pipelines sind Analyse-Pipelines, die es ermöglichen, aus metagenomischen Proben spezifische Bakterien zu identifizieren. Diese Pipelines wurde im Rahmen der Bachelorarbeit von Timo Dinse entwickelt.

Nutzung

Die TDPCS-Pipelines kann mit folgendem Befehl ausgeführt werden:
```bash
./base -h
```

Dieser Befehl zeigt eine Hilfsübersicht mit allen verfügbaren Befehlen und Parametern.

```plaintext
Analyse Requirements: Führt die Analyse mit den angegebenen Optionen aus:
   - `-i EINGABEDATEI`  
     Die Eingabedatei im FASTQ-Format.
   - `-o AUSGABEVERZEICHNIS`  
     Das Ausgabeverzeichnis für die Ergebnisse.
   - `-x REFERENZDATEI`  
     Die Referenzdatei im FASTA-Format.
   - `-d DATENBANK_PFAD`  
     Der Pfad zur NCBI-Datenbank.
   - `-t THREADS` (optional)  
     Anzahl der Threads für die Analyse.
   - `-m MODE`  
     Modus: `fs`, `fl`, `ll` oder `ls` (Standard: `fs`).
```

Zeigt aktuellste Versionsnummer der TDPCS-Pipelines an:
```bash
./base -v
```

Beispiel für die Analyse

Ein typischer Analysebefehl sieht wie folgt aus:
```bash
tdpcs analyse -i /path/to/infq -o /path/to/outfolder -x /path/to/hostsequence -d /path/to/blastdatabase -t Threads -m MODE
```


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
```

 	2.	Long in Loop:
```bash
  tdpcs analyse -i /data/sample.fastq -o /results -x /host/host_sequence.fasta -d /blast/db/core_nt -t 16 -m ll
```


Funktionsweise

Die TDPCS-Short Pipeline funktioniert wiefolgt::

	1.	Host-Filterung: Entfernt Host-Zell-Sequenzen aus den Reads.
 	2. 	Extraktion: Filtert alle Reads, welche nicht dem Referenzgenom zugeordnet werden können.
	3.	De-novo Assembly: Erstellt ein de-novo Assembly der gefilterten Reads.
	4.	Bin Refinement: Verfeinert die Bins für genauere Analysen.
	5.	Klassifizierung: Die Klassifizierung erfolgt über GTDB-Tk.

Durch die TDPCS-Short-Pipeline wird folgende Ordnerstruktur erstellt.

```plaintext
├── 00-InputData  
│   ├── RawData  
├── 01-CleanedReads  
│   ├── FilteredData  
├── 02-DeNovo  
│   ├── Assemblies  
├── 03-Bin  
│   ├── Binning  
│   ├── Bin-Refinement  
├── 04-Classification  
│   ├── Klassifizierung von GTDB-Tk  
│   ├── Ausgabe-Datei der Ergebnisse als TSV-File (ungefiltert)  
├── 05-Results  
│   ├── Ausgabe-Datei der Ergebnisse als CSV-File (gefiltert)  
├────────────────────────  
```

 Die TDPCS-Long Pipeline funktioniert wiefolgt::

	1.	Host-Filterung: Entfernt Host-Zell-Sequenzen aus den Reads.
 	2. 	Extraktion: Filtert alle Reads, welche nicht dem Referenzgenom zugeordnet werden können.
	3.	Klassifizierung: Die Klassifizierung erfolgt über BLASTn.

Durch die TDPCS-Long-Pipeline wird folgende Ordnerstruktur erstellt.

```plaintext
├── 00-InputData  
│   ├── RawData  
├── 01-CleanedReads  
│   ├── FilteredData  
├── 02-Classification  
│   ├── Klassifizierung von BLASTn  
│   ├── Ausgabe-Datei der Ergebnisse als TSV-File (ungefiltert)  
├── 03-Results  
│   ├── Ausgabe-Datei der Ergebnisse als CSV-File (gefiltert)  
├── 04-R-Skript  
│   ├── Übergabe an R-Skript zur Auswertung durch Plots  
├────────────────────────  
```
