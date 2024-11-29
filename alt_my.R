# TDCS Analyse

# Lade die benötigten Pakete
library("shiny")
library("RColorBrewer")

# Lies den Pfad zur Ausgabedatei und zur FASTQ-Datei aus den Befehlszeilenargumenten ein
args <- commandArgs(trailingOnly = TRUE)
#csv_path <- args[1]
csv_path <- "/home/drk/testoutputs/test/05-Results/extrakt.csv"
#fastq_path <- args[2]
fastq_path <- "/home/drk/AP4_BA_Timo/rawdata/AP4.1.2_Vollblut_RelativeTests/fastq_pass/merged11.fastq"

# Jetzt kannst du den Pfad verwenden, um die Datei einzulesen
data <- read.csv(csv_path)

# Funktion zum Lesen der FASTQ-Datei
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

# Lese die FASTQ-Daten ein
fastq_data <- read_fastq(fastq_path)

# Extrahiere die Read-Größen und Q-Scores
read_sizes <- sapply(fastq_data, function(read) nchar(read$seq))
q_scores <- unlist(lapply(fastq_data, function(read) utf8ToInt(read$qscore) - 33))

# Berechne zusätzliche statistische Werte
read_median <- median(data$Count)
read_mean <- mean(data$Count)
total_reads <- sum(data$Count)

# UI
# UI
ui <- fluidPage(
  titlePanel("DTCS-Analytics"),
  tags$style(
    HTML("
      .sidebar {
        position: -webkit-sticky;
        position: sticky;
        top: 0;
        z-index: 1000;
        background-color: #f8f9fa;
        padding: 10px;
        border-radius: 5px;
      }
      .main-panel {
        margin-left: 320px; /* width of sidebar + some margin */
      }
    ")
  ),
  div(class = "sidebar", 
      sidebarPanel(
        radioButtons("plot_type", "Plot-Typ:",
                     choices = c("Balkendiagramm" = "bar", "Kuchen-Chart" = "pie", "Histogramm" = "histogram"),
                     selected = "bar"),
        selectInput("sort_by", "Sortieren nach:", choices = c("Stamm", "Count")),
        sliderInput("count_threshold", "Count-Schwellenwert:", min = 1, max = max(data$Count), value = 1),
        checkboxInput("remove_unclassified", "Unclassified entfernen", value = FALSE),
        selectInput("filter_stem", "Nach Stamm filtern:", choices = c("Alle", unique(data$Stamm))),
        fileInput("file", "Daten exportieren", accept = c('.csv')),
        actionButton("export_button", "Exportieren"),
        radioButtons("x_axis_scale", "X-Achsen-Skalierung:",
                     choices = c("Bis 5kb" = "5kb", "Bis 10kb" = "10kb", "Bis zum größten Read" = "max"),
                     selected = "max"),
        tags$h3("Statistische Daten"),
        textOutput("read_median"),
        textOutput("read_mean"),
        textOutput("total_reads")
      )
  ),
  div(class = "main-panel", 
      mainPanel(
        plotOutput("plot", height = "600px", width = "100%"),
        tags$div(style="height: 20px;"), # Weißer Raum zwischen den Plots
        tableOutput("data_view"),
        plotOutput("histogram", height = "600px", width = "100%"),
        plotOutput("original_read_distribution", height = "600px", width = "100%"),
        plotOutput("qscore_distribution", height = "600px", width = "100%")
      )
  )
)




# Server
server <- function(input, output) {
  
  # Berechne die statistischen Werte basierend auf read_sizes
  read_median <- median(read_sizes, na.rm = TRUE)
  read_mean <- mean(read_sizes, na.rm = TRUE)
  total_reads <- length(read_sizes)
  
  # Setze die statistischen Werte in die UI-Elemente
  output$read_median <- renderText({ paste("Read Median:", read_median) })
  output$read_mean <- renderText({ paste("Read Durchschnitt:", read_mean) })
  output$total_reads <- renderText({ paste("Gesamtanzahl der Reads:", total_reads) })
  
  filtered_data <- reactive({
    filtered <- data[data$Count > input$count_threshold, ]
    if (input$remove_unclassified) {
      filtered <- filtered[filtered$Stamm != "Unclassified", ]
    }
    if (input$filter_stem != "Alle") {
      filtered <- filtered[grepl(input$filter_stem, filtered$Stamm), ]
    }
    return(filtered)
  })
  
  output$data_view <- renderTable({
    filtered_data()
  }, rownames = FALSE) # rownames = FALSE entfernt die Zeilennummern in der Tabelle
  
  
  output$plot <- renderPlot({
    if (input$plot_type == "bar") {
      filtered_data <- filtered_data()
      if (input$sort_by == "Stamm") {
        filtered_data <- filtered_data[order(filtered_data$Stamm), ]
      } else {
        filtered_data <- filtered_data[order(filtered_data$Count), ]
      }
      
      # Farbpalette auswählen
      colors <- brewer.pal(n = length(filtered_data$Stamm), name = "Set3")
      
      barplot(filtered_data$Count, names.arg = filtered_data$Stamm,
              main = "Balkendiagramm", xlab = "", ylab = "Count",
              las = 1, cex.names = 1, col = colors)
      mtext("Stamm", side = 1, line = 30, cex = 1.2) 
    } else if (input$plot_type == "pie") {
      agg_data <- aggregate(Count ~ Stamm, data = filtered_data(), FUN = sum)
      filtered_data <- agg_data[agg_data$Count > input$count_threshold, ]
      filtered_data <- filtered_data[order(filtered_data$Count, decreasing = TRUE), ]
      
      # Farbpalette auswählen
      colors <- brewer.pal(n = length(filtered_data$Stamm), name = "Set3")
      
      pie(filtered_data$Count, labels = filtered_data$Stamm,
          main = "Kuchen-Chart", cex.main = 1.2, col = colors)
    } else if (input$plot_type == "histogram") {
      hist(filtered_data()$Count, main = "Histogramm der Counts",
           xlab = "Count", ylab = "Frequency", col = "skyblue")
    }
  })
  
  output$original_read_distribution <- renderPlot({
    xlim <- switch(input$x_axis_scale,
                   "5kb" = c(0, 5000),
                   "10kb" = c(0, 10000),
                   "max" = c(0, max(read_sizes, na.rm = TRUE)))
    
    plot_data <- read_sizes
    if (input$x_axis_scale != "max") {
      plot_data <- plot_data[plot_data <= xlim[2]]
    }
    
    hist(plot_data, main = "Histogramm der Original-Read-Verteilung",
         xlab = "Read Größe", ylab = "Häufigkeit", xlim = xlim, col = "lightgreen")
  })
  
  output$qscore_distribution <- renderPlot({
    hist(q_scores, main = "Histogramm der Q-Score-Verteilung",
         xlab = "Q-Score", ylab = "Häufigkeit", col = "salmon")
  })
  
  observeEvent(input$export_button, {
    if (!is.null(input$file)) {
      export_path <- paste0(dirname(input$file$datapath), "/", sub("\\..*", "", input$file$name))
      
      # Exportieren der Daten
      write.csv(filtered_data(), paste0(export_path, ".csv"))
      
      # Exportieren des Plots basierend auf dem ausgewählten Plot-Typ
      if (input$plot_type == "bar") {
        png(paste0(export_path, "_barplot.png"), width = 800, height = 600)
        barplot(filtered_data()$Count, names.arg = filtered_data()$Stamm,
                main = "Balkendiagramm", xlab = "", ylab = "Count",
                las = 1, cex.names = 1)
        dev.off()
      } else if (input$plot_type == "pie") {
        png(paste0(export_path, "_piechart.png"), width = 800, height = 600)
        agg_data <- aggregate(Count ~ Stamm, data = filtered_data(), FUN = sum)
        filtered_data <- agg_data[agg_data$Count > input$count_threshold, ]
        filtered_data <- filtered_data[order(filtered_data$Count, decreasing = TRUE), ]
        pie(filtered_data$Count, labels = filtered_data$Stamm,
            main = "Kuchen-Chart", cex.main = 1.2)
        dev.off()
      } else if (input$plot_type == "histogram") {
        png(paste0(export_path, "_histogram.png"), width = 800, height = 600)
        hist(filtered_data()$Count, main = "Histogramm der Counts",
             xlab = "Count", ylab = "Frequency")
        dev.off()
      }
    }
  })
}

# Shiny-App starten
shinyApp(
  ui = ui,
  server = server,
  options = list(port = 4010)
)
