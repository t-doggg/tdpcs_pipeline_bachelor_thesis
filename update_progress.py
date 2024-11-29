#!/usr/bin/env python3

# -------------------------------------------------------------------------------------------------
# Definiert eine Progress-Bar mit # und - als Symbole
def update_progress(progress, message=""):
    terminal_width = shutil.get_terminal_size().columns
    bar_length = terminal_width - len(message) - 12  # Berücksichtige die Länge der Nachricht und des Festtextes
    block = int(round(bar_length * progress))
    text = "\r{message} [{0}] {1:.2f}%".format("#" * block + "-" * (bar_length - block), progress * 100,
                                               message=message)
    print(text, end="\r")
# -------------------------------------------------------------------------------------------------


