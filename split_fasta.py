#!/usr/bin/env python3

def split_fasta(refined_bins_dir):
    unbinned_fasta_path = os.path.join(refined_bins_dir, 'binsA', 'bin.unbinned.fa')
    with open(unbinned_fasta_path, 'r') as f:
        current_contig = None
        current_sequence = ''
        for line in f:
            if line.startswith('>'):
                # Neue Contig gefunden
                if current_contig:
                    # Schreibe aktuelle Contig in Datei
                    with open(os.path.join(refined_bins_dir, 'binsA',
                                           f'{current_contig}.fa'), 'w') as contig_file:
                        contig_file.write(current_sequence)
                current_contig = line.strip()[1:]
                current_sequence = line
            else:
                current_sequence += line

    return unbinned_fasta_path
