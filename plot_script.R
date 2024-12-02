# TDPCS-Analysis - Enhanced Version
# Debugging ist noch im Code enthalten. User bekommt nochmals Feedback zum übergebenem Pfad.

# Lade die benötigten Pakete
library("shiny")
library("RColorBrewer")
library("shinythemes")
library("plotly")
library("DT")

# Liest die Argumente aus, welche aus der Long Pipeline übergeben werden
args <- commandArgs(trailingOnly = TRUE)

# Argument 1: Pfad zur CSV-Datei
csv_path <- args[1]

# Argument 2: Pfad zur FASTQ-Datei (wird benötigt um FQ-Stats anzuzeigen und Count-SChwelle nach Total Reads zu skalieren)
fastq_path <- args[2]

# Debugging: Überprüfe, ob die korrekten Pfade übergeben wurden
# print(paste("CSV Path:", csv_path))
# print(paste("FASTQ Path:", fastq_path))

# CSV-Datei einlesen als Dataframe
data <- read.csv(csv_path)

# Funktion zum Lesen der FASTQ-Datei, erstellt leere Liste für Reads, Schleife durch die FQ Datei, sep, durch @ und speichert.
read_fastq <- function(file_path) {
  con <- file(file_path, "r")
  reads <- list()
  while (length(line <- readLines(con, n = 1, warn = FALSE)) > 0) {
    if (substr(line, 1, 1) == "@") {
      seq_id <- line
      seq <- readLines(con, n = 1, warn = FALSE)
      plus <- readLines(con, n = 1, warn = FALSE)
      qscore <- readLines(con, n = 1, warn = FALSE)
      reads[[length(reads) + 1]] <- list(seq_id = seq_id, seq = seq, qscore = qscore)
    }
  }
  close(con)
  return(reads)
}

# Lese die FQ-Daten ein durch vorher definierte Funktion und gebe Path
fastq_data <- read_fastq(fastq_path)

# Extrahiere die Read-Größen und Q-Scores 
# Berechnet Länge nchar der Seqzenz seq
read_sizes <- sapply(fastq_data, function(read) nchar(read$seq))
# Berechnet Q-Score, read$qscore ist Qualitätsbewertung in ASCII, utf8ToInt wandelt jeden ASCII-Zeichenwert in einen numerischen Wert,
# - 33 wird der Offset entfernt, um den phred-Qualitätswert zu berechnen (Standard in FASTQ-Dateien)
q_scores <- unlist(lapply(fastq_data, function(read) utf8ToInt(read$qscore) - 33))

# Berechne zusätzliche statistische Werte
read_median <- median(data$Count)
read_mean <- round(mean(data$Count), 2)
total_reads <- sum(data$Count)

# UI (Ausgabemaske für TDPCS-Long)
ui <- fluidPage(
  # Setzt ein Design-Theme und Color Scheme für Ausgabemaske
  theme = shinytheme("cerulean"), 

  # Titel der Anwendung
  titlePanel("TDPCS-Analysis - Enhanced Version"),

  # Hauptlayout: Seitenleiste (Eingaben) und Hauptbereich (Ausgaben)
  sidebarLayout(
    sidebarPanel(
      # Abschnitt für User-Einstellungen. Fenster links welches mit Buttons usw. Auswertemöglichkeiten gibt
      h4("Analyse-Einstellungen"),

      # Auswahl Diagrammtyp - erstmal nur Balken-, Kuchen-Chart und Histgramm. 
      # ToDo: Stacked Balken oder eine Art Flussdiagramm die die Herkunft zeigt (Bakterienstamm etc.)
      radioButtons("plot_type", "Plot-Typ:",
                   choices = c("Balkendiagramm" = "bar", "Kuchen-Chart" = "pie", "Histogramm" = "histogram"),
                   selected = "bar"),

      # Auswahl der Sortierchoices
      selectInput("sort_by", "Sortieren nach:", choices = c("Stamm", "Count")),

      # Schieberegler zur Einstellung des Count-Schwellenwerts (Prozent)
      sliderInput("count_threshold", "Count-Schwellenwert (%):", 
                  min = 0.1, max = 5, value = 1, step = 0.05, post = "%"),

      # Checkbox, um menschliche Reads aus den Daten zu entfernen 
      checkboxInput("remove_human", "Human entfernen", value = FALSE),

      # Dropdown-Menü zum Filtern nach einem spezifischen Stamm
      # Kann raus
      selectInput("filter_stem", "Nach Stamm filtern:", 
                  choices = c("Alle", unique(data$Stamm))),

      # Datei-Upload-Element für Datenexport
      fileInput("file", "Daten exportieren", accept = c('.csv')),

      # Button, um Daten zu exportieren
      actionButton("export_button", "Exportieren"),

      # Auswahl der Skalierung der X-Achse
      radioButtons("x_axis_scale", "X-Achsen-Skalierung:",
                   choices = c("1kb" = "1kb", "2kb" = "2kb", "5kb" = "5kb", "Bis zum größten Read" = "max"),
                   selected = "max"),

      # Abschnitt für die Anzeige FQ-Metriken die zuvor extrahiert/berechnet wurden
      tags$h4("Statistische Daten"),
      textOutput("read_median"), # Median der Read-Länge
      textOutput("read_mean"),   # Mittelwert der Read-Länge
      textOutput("total_reads"), # Gesamtanzahl der Reads

      # Horizontale Linie zur Trennung der Eingabeelemente vom Ausgabefeld der Ausgabemaske
      hr(),

      # Button, um die Daten zu aktualisieren
      # NN, nur für dev nötig
      actionButton("refresh_button", "Daten aktualisieren")
    ),

    mainPanel(
      # Hauptbereich mit verschiedenen Tabs
      tabsetPanel(
        # Tab für die grafische Darstellung des Plots
        tabPanel("Plot", plotlyOutput("plot", height = "600px")),

        # Tab für die tabellarische Datenansicht (zum extrahieren später mal)
        tabPanel("Data View", DTOutput("data_view")),

        # Tab für das Histogramm der Read-Größen
        tabPanel("Histogramm Read-Größe", plotlyOutput("original_read_distribution", height = "600px")),

        # Tab für die Verteilung der Qualitäts-Scores
        tabPanel("Q-Score-Verteilung", plotlyOutput("qscore_distribution", height = "600px")),

        # Tab für eine textuelle Zusammenfassung der Daten
        tabPanel("Zusammenfassung", verbatimTextOutput("summary_output"))
      )
    )
  )
)

# Server-Funktion um die  Logik der Shiny-App zu steuern
server <- function(input, output, session) {
  
  # Berechne die statistischen Werte basierend auf read_sizes
  read_median <- median(read_sizes, na.rm = TRUE)
  read_mean <- round(mean(read_sizes, na.rm = TRUE), 2)
  total_reads <- length(read_sizes)
  
  # Setze die statistischen Werte in die UI-Elemente
  output$read_median <- renderText({ paste("Read Median:", read_median) })
  output$read_mean <- renderText({ paste("Read Durchschnitt:", read_mean) })
  output$total_reads <- renderText({ paste("Gesamtanzahl der Reads:", total_reads) })
  
  # Funktion die die Filter des Nutzers anwendet die Daten basierend
  filtered_data <- reactive({
    threshold_value <- (input$count_threshold / 100) * total_reads # Schwellenwert berechnen
    filtered <- data[data$Count > threshold_value, ] # Daten nach Count filtern
    if (input$remove_human) {
      filtered <- filtered[filtered$Stamm != "Human", ] # "Human"-Einträge entfernen
    }
    if (input$filter_stem != "Alle") {
      filtered <- filtered[grepl(input$filter_stem, filtered$Stamm), ] # NN as saied. Nach spezifischem Stamm filtern
    }
    return(filtered) # Gefilterte Daten zurückgeben
  })
  
  # Rendere das Diagramm basierend auf User Input und geg. Daten
  output$plot <- renderPlotly({
    filtered_data <- filtered_data()
    if (input$plot_type == "bar") {
      if (input$sort_by == "Stamm") {
        filtered_data <- filtered_data[order(filtered_data$Stamm), ]
      } else {
        filtered_data <- filtered_data[order(filtered_data$Count), ]
      }
      
      # Balkendiagramm erstellen
      plot_ly(
        x = ~filtered_data$Stamm,
        y = ~filtered_data$Count,
        type = "bar",
        marker = list(color = brewer.pal(n = length(filtered_data$Stamm), name = "Set3"))
      ) %>% layout(title = "Balkendiagramm", xaxis = list(title = "Stamm"), yaxis = list(title = "Count"))
    } else if (input$plot_type == "pie") {
      # Counts pro Stamm als porzentuale Verteilung und erstelle ein Kuchendiagramm
      agg_data <- aggregate(Count ~ Stamm, data = filtered_data, FUN = sum)
      filtered_data <- agg_data[agg_data$Count > (input$count_threshold / 100) * total_reads, ]
      filtered_data <- filtered_data[order(filtered_data$Count, decreasing = TRUE), ]
      # Kuchendiagramm erstellen
      plot_ly(
        labels = ~filtered_data$Stamm,
        values = ~filtered_data$Count,
        type = "pie",
        marker = list(colors = brewer.pal(n = length(filtered_data$Stamm), name = "Set3"))
      ) %>% layout(title = "Kuchen-Chart")
    } else if (input$plot_type == "histogram") {
      # Histogramm der Counts erstellen
      plot_ly(
        x = ~filtered_data$Count,
        type = "histogram",
        marker = list(color = "skyblue")
      ) %>% layout(title = "Histogramm der Counts", xaxis = list(title = "Count"), yaxis = list(title = "Frequency"))
    }
  })
  
  # Erstelle Grafik für das Histogramm der Original-Read-Größen
  output$original_read_distribution <- renderPlotly({
    xlim <- switch(input$x_axis_scale,
                   "1kb" = 1000,
                   "2kb" = 2000,
                   "5kb" = 5000,
                   "max" = max(read_sizes, na.rm = TRUE)) # X-Achsen-Skalierung auswählen
    
    plot_data <- read_sizes[read_sizes <= xlim] # Daten innerhalb der X-Grenzen auswählen
    plot_ly(
      x = ~plot_data,
      type = "histogram",
      marker = list(color = "lightgreen")
    ) %>% layout(title = "Histogramm der Original-Read-Verteilung", xaxis = list(title = "Read Größe"), yaxis = list(title = "Häufigkeit"))
  })
  
  # Erstelle Grafik für das Histogramm der Qualitäts-Scores
  output$qscore_distribution <- renderPlotly({
    plot_ly(
      x = ~q_scores,
      type = "histogram",
      marker = list(color = "salmon")
    ) %>% layout(title = "Histogramm der Q-Score-Verteilung", xaxis = list(title = "Q-Score"), yaxis = list(title = "Häufigkeit"))
  })
  
  # Zeige eine Text-Zusammenfassung der gefilterten Daten
  output$summary_output <- renderPrint({
    summary(filtered_data())
  })
  
  # Observe Export-Button (weil falls er geklickt wird) und exportiere die gefilterten Daten als CSV
  observeEvent(input$export_button, {
    if (!is.null(input$file)) {
      export_path <- paste0(dirname(input$file$datapath), "/", sub("\\..*", "", input$file$name))
      
      # Exportieren der Daten
      write.csv(filtered_data(), paste0(export_path, ".csv")) # Gefilterte Daten exportieren
    }
  })
  
  # Observe Refresh-Button (weil falls er geklickt wird) und lade die Sitzung neu
  observeEvent(input$refresh_button, {
    session$reload()
  })
}

# Shiny-App starten
shinyApp(
  ui = ui,
  server = server,
  options = list(port = 4010)
)
