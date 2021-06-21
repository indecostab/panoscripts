#!/usr/bin/Rscript --no-init-file
# 
# This file will choose control points used in a Hugin file
# 

args <- commandArgs(trailingOnly = TRUE)
if ( length(args) < 3 && ! args[2] %in% c("scan", "all") ) { 
  stop("Bad command line. Usage: use_ctrplts.R <proj> <img1> <img2>")
} else { 
  proj <- args[1]
  imgi <- args[2]
  imgj <- args[3]
}

projtxt <- readLines(proj)

clines_file <- paste0(proj, ".clines")
if ( imgi == "scan" ) { 
  cat("Scanning control points...")
  sub <- grepl("^(#|)c", projtxt)
  writeLines(projtxt[sub], 
             con = clines_file)
  cat(paste0(" ", sum(sub), " pairs written.\n"))
  q()
}

# Remove all clines 
projtxt <- projtxt[!grepl("^(#|)c", projtxt) ]

# Read all contol points
cpoints <- readLines(clines_file)

for ( i in seq_along(cpoints) ) { 
#   cat(projtxt[i], "\n")
  if ( grepl("^(#|)c", cpoints[i]) ) { 
    
    imgi_txt <- strsplit(cpoints[i], " ")[[1]]
    if ( ( imgi_txt[2] == paste0("n", imgi) && 
           imgi_txt[3] == paste0("N", imgj) ) || 
         imgi == "all" ) { 
      # Make sure there is no slash at the end, we want to keep this 
      imgi_txt[1] <- gsub("^#", "", imgi_txt[1])
    } else { 
      # Comment this line, we don't want it, if it's not already the case
      imgi_txt[1] <- gsub("^(#+|)", "#", imgi_txt[1])
    }
    cpoints[i] <- paste(imgi_txt, collapse = " ")
  }
}

# Add cpoints back into the file 
nctrl <- which(grepl("^# control points", projtxt))
projtxt <- c(projtxt[seq(1, nctrl)], 
             cpoints, 
             projtxt[seq(nctrl+1, length(projtxt))])

writeLines(projtxt, con = proj)
