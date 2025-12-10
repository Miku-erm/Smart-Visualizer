# api.R

# --- 1. SET UP LIBRARIES ---
library(plumber)
library(dplyr)
library(ggplot2)
library(jsonlite)
library(readr)
library(readxl)
library(base64enc)
library(fortunes)

# --- 2. CONFIGURATION ---
PLOT_DIR <- tempdir() 

# Helper: Save plot to base64
plot_to_base64 <- function(p, filename) {
  full_path <- file.path(PLOT_DIR, paste0(filename, ".png"))
  png(full_path, width = 600, height = 400, res = 100, bg = "#1e293b") # Dark bg
  print(p)
  dev.off()
  b64_string <- base64encode(full_path)
  file.remove(full_path)
  return(paste0("data:image/png;base64,", b64_string))
}

# --- 3. PLOT GENERATION LOGIC ---
generate_plots_from_df <- function(df) {
  score <- 0
  plots_base64 <- list()
  plot_counter <- 1
  
  # Dark theme for all plots
  theme_dark_custom <- function() {
    theme_minimal() +
      theme(
        text = element_text(color = "#f8fafc"),
        axis.text = element_text(color = "#cbd5e1"),
        panel.grid.major = element_line(color = "#334155"),
        panel.grid.minor = element_line(color = "#1e293b"),
        plot.background = element_rect(fill = "#1e293b", color = NA),
        panel.background = element_rect(fill = "#1e293b", color = NA),
        legend.background = element_rect(fill = "#1e293b"),
        legend.text = element_text(color = "white")
      )
  }
  
  # Identify column types
  nums <- names(select_if(df, is.numeric))
  cats <- names(select_if(df, function(x) is.factor(x) || is.character(x)))
  
  # Helper to get column safely
  get_col <- function(col_name) df[[col_name]]
  
  # Helper to wrap plot execution
  run_plot <- function(p, name, title) {
    img <- plot_to_base64(p, name)
    # Return formatted object
    return(list(title=title, image=img))
  }

  # --- 1. Bar Plot ---
  tryCatch({
    p <- ggplot() + theme_dark_custom()
    title <- "Bar Plot"
    if (length(cats) > 0) {
      col <- cats[1]
      title <- paste("Bar Plot:", col)
      p <- ggplot(df, aes(x = .data[[col]])) + 
           geom_bar(fill = "#38bdf8") + 
           labs(title = title) + theme_dark_custom()
    } else {
      # Bin the first numeric
      col <- nums[1]
      title <- paste("Histogram:", col)
      p <- ggplot(df, aes(x = .data[[col]])) + 
           geom_histogram(fill = "#38bdf8", bins=10) + 
           labs(title = title) + theme_dark_custom()
    }
    plots_base64[[plot_counter]] <- run_plot(p, "bar", title)
    score <- score + 10
    plot_counter <- plot_counter + 1
  }, error = function(e) print(paste("Bar error:", e)))

  # --- 2. Scatter Plot ---
  tryCatch({
    p <- ggplot() + theme_dark_custom()
    if (length(nums) >= 2) {
      title <- paste("Scatter Plot:", nums[1], "vs", nums[2])
      p <- ggplot(df, aes(x = .data[[nums[1]]], y = .data[[nums[2]]])) +
           geom_point(color = "#4ade80", alpha=0.7) +
           labs(title = title) + theme_dark_custom()
      plots_base64[[plot_counter]] <- run_plot(p, "scatter", title)
      score <- score + 10
      plot_counter <- plot_counter + 1
    }
  }, error = function(e) print(paste("Scatter error:", e)))

  # --- 3. Line Plot ---
  tryCatch({
    title <- paste("Line Trend:", nums[1])
    p <- ggplot(df, aes(x = seq_along(df[[1]]), y = .data[[nums[1]]])) +
         geom_line(color = "#f472b6", linewidth=1) +
         labs(title = title) + theme_dark_custom()
    plots_base64[[plot_counter]] <- run_plot(p, "line", title)
    score <- score + 10
    plot_counter <- plot_counter + 1
  }, error = function(e) print(paste("Line error:", e)))

  # --- 4. Box Plot ---
  tryCatch({
    p <- ggplot() + theme_dark_custom()
    title <- "Box Plot"
    if (length(cats) > 0 && length(nums) > 0) {
      title <- paste("Box Plot:", nums[1], "by", cats[1])
      p <- ggplot(df, aes(x = .data[[cats[1]]], y = .data[[nums[1]]], fill = .data[[cats[1]]])) +
           geom_boxplot() + scale_fill_brewer(palette="Set3") +
           labs(title = title) + theme_dark_custom() + theme(legend.position="none")
    } else {
       title <- paste("Box Plot:", nums[1])
       p <- ggplot(df, aes(y = .data[[nums[1]]])) + geom_boxplot(fill="#fbbf24") + 
            labs(title = title) + theme_dark_custom()
    }
    plots_base64[[plot_counter]] <- run_plot(p, "box", title)
    score <- score + 10
    plot_counter <- plot_counter + 1
  }, error = function(e) print(paste("Box error:", e)))

  # --- 5. Density ---
  tryCatch({
    title <- paste("Density Plot:", nums[1])
    p <- ggplot(df, aes(x = .data[[nums[1]]])) + geom_density(fill="#818cf8", alpha=0.5) + 
         labs(title = title) + theme_dark_custom()
    plots_base64[[plot_counter]] <- run_plot(p, "density", title)
    score <- score + 10
    plot_counter <- plot_counter + 1
  }, error = function(e) {})

  # --- 6. Violin ---
   tryCatch({
    p <- ggplot() + theme_dark_custom()
    title <- "Violin Plot"
    if (length(cats) > 0 && length(nums) > 0) {
      p <- ggplot(df, aes(x = .data[[cats[1]]], y = .data[[nums[1]]], fill = .data[[cats[1]]])) +
           geom_violin() + 
           labs(title = title) + theme_dark_custom() + theme(legend.position="none")
    } else {
      p <- ggplot(df, aes(x=1, y=.data[[nums[1]]])) + geom_violin(fill="#a78bfa") + theme_dark_custom()
    }
    plots_base64[[plot_counter]] <- run_plot(p, "violin", title)
    score <- score + 10
    plot_counter <- plot_counter + 1
  }, error = function(e) {})
  
  # --- 7. Heatmap (Correlation) ---
  tryCatch({
    cormat <- cor(select_if(df, is.numeric), use="complete.obs")
    # Use reshape2::melt explicitly
    if (requireNamespace("reshape2", quietly = TRUE)) {
        melted_cormat <- reshape2::melt(cormat)
        title <- "Correlation Heatmap"
        p <- ggplot(melted_cormat, aes(Var1, Var2, fill=value)) + 
             geom_tile() + scale_fill_gradient2() + 
             labs(title=title) +
             theme_dark_custom() + theme(axis.text.x = element_text(angle = 45, hjust = 1))
        plots_base64[[plot_counter]] <- run_plot(p, "heatmap", title)
        score <- score + 10
        plot_counter <- plot_counter + 1
    }
  }, error = function(e) {})

  # --- 8. Jitter ---
  tryCatch({
      title <- "Jitter Plot"
      p <- ggplot(df, aes(x = .data[[nums[1]]], y = .data[[nums[min(2, length(nums))]]])) + 
           geom_jitter(color="#f472b6") + theme_dark_custom() + labs(title=title)
      plots_base64[[plot_counter]] <- run_plot(p, "jitter", title)
      score <- score + 10
      plot_counter <- plot_counter + 1
  }, error = function(e) {})

  # --- 9. Area ---
  tryCatch({
      title <- "Area Plot"
      p <- ggplot(df, aes(x = seq_along(df[[1]]), y = .data[[nums[1]]])) + 
           geom_area(fill="#22d3ee", alpha=0.4) + theme_dark_custom() + labs(title=title)
      plots_base64[[plot_counter]] <- run_plot(p, "area", title)
      score <- score + 10
      plot_counter <- plot_counter + 1
  }, error = function(e) {})

  # --- 10. Hex / 2D Density ---
  tryCatch({
      if(length(nums) >= 2){
         title <- "Hexbin / 2D Density"
         # Fallback to bin2d if hexbin not installed
         p <- ggplot(df, aes(x = .data[[nums[1]]], y = .data[[nums[2]]])) + 
             geom_bin2d() + theme_dark_custom() + labs(title=title)
         plots_base64[[plot_counter]] <- run_plot(p, "hex", title)
         score <- score + 10
         plot_counter <- plot_counter + 1
      }
  }, error = function(e) {})

  return(list(score=score, plots=plots_base64, summary=paste("Analyzed", nrow(df), "rows.")))
}

# --- 4. ENDPOINTS ---

#* Handle CORS
#* @filter cors
function(res) {
  res$setHeader("Access-Control-Allow-Origin", "*")
  res$setHeader("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
  res$setHeader("Access-Control-Allow-Headers", "Content-Type")
  plumber::forward()
}

#* Upload and Analyze
#* @post /upload
#* @parser multi
#* @serializer unboxedJSON
function(req, res) {
  tryCatch({
    if (is.null(req$body$dataset)) {
        return(list(error="No file uploaded"))
    }
    
    val <- req$body$dataset
    print(paste("DEBUG: Keys in val:", paste(names(val), collapse=", ")))
    print(paste("DEBUG: Class of val:", class(val)))
    if (!is.null(val$content)) {
        print(paste("DEBUG: Content length:", length(val$content)))
        print(paste("DEBUG: Content class:", class(val$content)))
    } else {
        print("DEBUG: val$content is NULL")
    }

    filename <- val$filename
    
    # Save temp with correct extension for identification
    ext <- tools::file_ext(filename)
    tmp <- tempfile(fileext = paste0(".", ext))
    
    if (!is.null(val$content)) {
        # It's binary (or perceived as such)
        writeBin(val$content, tmp)
    } else if (!is.null(val$value)) {
        # It's text. Plumber might have parsed it.
        # If it's a character vector, we write it as text.
        content_text <- val$value
        if (is.character(content_text)) {
            if (length(content_text) > 1) {
                # If parsed into multiple lines, collapse them
                content_text <- paste(content_text, collapse = "\n")
            }
            writeLines(content_text, tmp)
        } else {
             # Fallback if it's somehow not character but not null?
             # Try forcing to raw if possible, or error out safely
             tryCatch({
                writeBin(as.raw(content_text), tmp)
             }, error = function(e) {
                stop(paste("Unknown content type in val$value:", class(content_text)))
             })
        }
    } else {
        stop("File content is missing from request body (neither content nor value found).")
    }
    
    if (tolower(ext) %in% c("xlsx", "xls")) {
        df <- readxl::read_excel(tmp)
    } else {
        df <- read_csv(tmp, show_col_types = FALSE)
    }
    
    # Generate
    result <- generate_plots_from_df(df)
    return(result)
    
  }, error = function(e) {
    return(list(error = paste("Server Error:", e)))
  })
}

#* Default Titanic Plot (Legacy/Fallback)
#* @get /plot
#* @serializer unboxedJSON
function() {
    # ... existing logic or call generic ...
    if (requireNamespace("titanic", quietly = TRUE)) {
        data("titanic_train", package = "titanic")
        return(generate_plots_from_df(titanic_train))
    }
    return(list(error="Titanic pkg not found"))
}
