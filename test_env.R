
# Test R environment
lib_path <- file.path(getwd(), "R_libs")
.libPaths(c(lib_path, .libPaths()))

tryCatch({
    library(plumber)
    print("✅ Plumber loaded successfully!")
    library(ggplot2)
    print("✅ ggplot2 loaded successfully!")
}, error = function(e) {
    print(paste("❌ Error loading packages:", e$message))
    quit(status=1)
})
