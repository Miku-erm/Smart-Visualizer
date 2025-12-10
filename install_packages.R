
# Install required packages to a local project directory
lib_path <- file.path(getwd(), "R_libs")
if (!dir.exists(lib_path)) {
  dir.create(lib_path)
}
.libPaths(c(lib_path, .libPaths()))

required_packages <- c(
  "plumber",
  "dplyr",
  "ggplot2",
  "jsonlite",
  "readr",
  "readxl",
  "base64enc",
  "fortunes",
  "reshape2",
  "titanic"
)

options(repos = c(CRAN = "https://cloud.r-project.org"))

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message(paste("Installing", pkg, "to", lib_path, "..."))
    install.packages(pkg, lib = lib_path)
  } else {
    message(paste(pkg, "is already installed."))
  }
}
message("All packages checked/installed.")
