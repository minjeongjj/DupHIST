#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  cat("Usage: Rscript midpoint_root.R <input.nwk> <output.nwk>\n")
  quit(status = 1)
}

input_file <- args[1]
output_file <- args[2]

suppressPackageStartupMessages({
  library(ape)
  library(phytools)
})

if (!file.exists(input_file)) {
  stop(paste("Error: Input file not found ->", input_file))
}

tree <- read.tree(input_file)

rooted_tree <- midpoint_root(tree)

write.tree(rooted_tree, file = output_file)
