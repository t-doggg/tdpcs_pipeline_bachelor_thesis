# Load necessary libraries
library(dplyr)
library(stringr)

# Get command-line arguments
args <- commandArgs(trailingOnly = TRUE)

# Check if the required arguments are provided
if (length(args) < 2) {
  stop("Please provide both the input file and output file paths as arguments.")
}

# Assign the input and output file paths from the arguments
input_file <- args[1]
output_file <- args[2]

# Function to process the bacteria counts from the input file
process_bacteria_counts_file <- function(input_file, temp_output_file) {
  
  # Step 1: Read the TSV file without headers
  data <- read.delim(input_file, header = FALSE, sep = "\t", stringsAsFactors = FALSE)
  
  # Step 2: Extract the third column (assuming this is where the bacteria names are stored)
  bacteria_column <- data[[3]]  # Extract the third column directly
  
  # Step 3: Remove "[" and "]" from the bacteria names
  bacteria_column_clean <- str_replace_all(bacteria_column, "\\[|\\]", "")
  
  # Step 4: Extract the first two words from each entry in the cleaned bacteria column
  bacteria_names <- sapply(strsplit(bacteria_column_clean, " "), function(x) paste(x[1:2], collapse = " "))
  
  # Step 5: Count the occurrences of each unique bacterium name
  bacteria_counts <- bacteria_names %>%
    table() %>%
    as.data.frame()
  
  # Step 6: Rename the columns for clarity
  colnames(bacteria_counts) <- c("Bacteria", "Count")
  
  # Step 7: Write the result to the temporary TSV file
  write.table(bacteria_counts, file = temp_output_file, sep = "\t", row.names = FALSE, col.names = TRUE, quote = FALSE)
  
  print(paste("Bacteria counts have been saved to the temporary file:", temp_output_file))
}

# Function to process the genus counts from the temporary file
process_genus_counts <- function(temp_output_file, output_file) {
  # Step 1: Read the TSV file with bacteria names and counts
  data <- read.delim(temp_output_file, header = TRUE, sep = "\t", stringsAsFactors = FALSE)
  
  # Step 2: Extract the first word (genus) from the "Bacteria" column
  genus_names <- sapply(strsplit(data$Bacteria, " "), function(x) x[1])
  
  # Step 3: Combine genus names and their corresponding counts
  genus_data <- data.frame(Genus = genus_names, Count = data$Count)
  
  # Step 4: Sum the counts for each unique genus
  genus_counts <- genus_data %>%
    group_by(Genus) %>%
    summarise(Total_Count = sum(Count))  # Summing counts for the same genus
  
  # Step 5: Write the result to the final output TSV file
  write.table(genus_counts, file = output_file, sep = "\t", row.names = FALSE, col.names = TRUE, quote = FALSE)
  
  print(paste("Genus counts have been saved to", output_file))
}

# Run the functions in sequence
process_bacteria_counts_file(input_file, temp_output_file)   # Step 1: Process bacteria counts to temp file
process_genus_counts(temp_output_file, output_file)          # Step 2: Process genus counts to final output file

# Delete the temporary file
file.remove(temp_output_file)
print("Temporary file has been deleted.")