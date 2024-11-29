#!/usr/bin/env python3

# Diese Funktion soll den Output der GTDB-Tk-Funktion bereinigen, um den Nutzer eine einfachere
def process_gtdbtk_output(gtdbtk_output_dir):
    # Ein leeres Wörterbuch erstellen, um die Anzahl jedes Stammes zu zählen
    stamm_count = {}

    # Pfad zur TSV-Datei unter Verwendung von gtdbtk_output_dir
    tsv_paths = [
        os.path.join(gtdbtk_output_dir, 'gtdbtk.bac120.summary.tsv'),
        os.path.join(gtdbtk_output_dir, 'gtdbtk.ar53.summary.tsv')
    ]

    # Für jede TSV-Datei im Verzeichnis iterieren
    for tsv_path in tsv_paths:
        # Öffnen der TSV-Datei im Lesemodus
        with open(tsv_path, 'r') as file_tsv_gtdbtk:
            # CSV-Reader-Objekt erstellen
            tsv_reader_gtdbtk = csv.reader(file_tsv_gtdbtk, delimiter='\t')
            # Die erste Zeile überspringen (Überschriften)
            next(tsv_reader_gtdbtk)
            # Für jede Zeile in der Datei iterieren
            for row_in_gtdbtk in tsv_reader_gtdbtk:
                # Den letzten Abschnitt (Stamm) aus der zweiten Spalte extrahieren
                stamm_gtdbtk = row_in_gtdbtk[1].split(';')[-1].strip()
                # Wenn der Stamm bereits im Wörterbuch vorhanden ist,
                # erhöhen Sie den Zähler um 1, sonst initialisieren Sie ihn mit 1
                if stamm_gtdbtk in stamm_count:
                    stamm_count[stamm_gtdbtk] += 1
                else:
                    stamm_count[stamm_gtdbtk] = 1

    # Ergebnisse in eine CSV-Datei speichern
    results_csv_path = os.path.join(gtdbtk_output_dir, 'ergebnisse.csv')
    with open(results_csv_path, 'w', newline='') as csvfile_gtdbtk:
        # CSV-Schreibobjekt erstellen
        csv_writer_gtdbtk = csv.writer(csvfile_gtdbtk)
        # Überschrift schreiben
        csv_writer_gtdbtk.writerow(['Stamm', 'Count'])
        # Datenzeilen schreiben
        for stamm_gtdbtk, count_gtdbtk in stamm_count.items():
            csv_writer_gtdbtk.writerow([stamm_gtdbtk, count_gtdbtk])
