#!/usr/bin/Rscript
# 
# This file will compute the blurryness index of an image
# 

suppressPackageStartupMessages( require(spatialwarnings) )
suppressPackageStartupMessages( require(plyr) )
suppressPackageStartupMessages( require(ggplot2) )


args <- commandArgs(trailingOnly = TRUE)
if ( length(args) < 3 ) { 
  stop("Bad command line. Usage: blurry.R <image_dir> <input_fps> <output_fps>")
} else { 
  imgdir <- args[1]
  input_fps <- as.numeric(args[2])
  output_fps <- as.numeric(args[3])
}

# Create folder with filtered images 
newf <- paste0(gsub("/$", "", imgdir), "_filtered")
if ( ! dir.exists(newf) ) { 
  dir.create(newf)
}

all_images <- dir(imgdir, pattern = "*.png", full = TRUE)

# If we do not reduce fps, then bail
if ( output_fps >= input_fps ) { 
  cat("Output FPS is above or below input FPS, nothing to do.\n")
  
  # Copy the selected images into filtered folder 
  invisible( file.copy(all_images, newf))
  
  # Print status 
  msg <- paste0("Copied ", length(all_images), " images into ", newf, "\n")
  cat(msg)
  q()
}


# Compute Moran lag-1 autocorrelation on all images
cat("Scanning images...\n")
all_blurs <- ldply(seq_along(all_images), function(imgn) { 
  imgf <- all_images[imgn]
  img <- tryNULL(png::readPNG(imgf))
  img <- img[seq(1, dim(img)[1], by = 2), seq(1, dim(img)[2], by = 2), ]
  
  if ( is.null(img) ) { 
    cat("Could not read", imgf, "\n")
    return({ 
      data.frame(imgf = imgf, 
      imgtime = imgn*(1/input_fps), 
      moran = NA)
    })
  }
  moran_base <- raw_cg_moran(img[ , ,1], 1)
  data.frame(imgf = imgf, 
             imgtime = imgn*(1/input_fps), 
             moran   = moran_base)
  
}, .progress = "time")

all_blurs <- subset(all_blurs, ! is.na(moran))

# Make debug plot in 
pl <- ggplot(all_blurs) + 
  geom_line(aes(x = imgtime, y = moran)) 

ggsave(pl, file = paste0(imgdir, "_blur.pdf"), 
       width = 16, height = 5)

# Scan images and select the one with the lowest moran correlation for each 
# second
imgtime <- with(all_blurs, seq(min(imgtime), max(imgtime), by = output_fps))
to_keep <- ldply(imgtime, function(imt) { 
  d <- subset(all_blurs, imgtime >= imt & imgtime < (imt+output_fps) )
  if ( nrow(d) == 0 ) { 
    return( NULL )
  }
  data.frame(kept_imgf = subset(d, moran == min(moran))[ ,"imgf"])
})

# Copy the selected images into filtered folder 
invisible( file.copy(to_keep[ ,"kept_imgf"], newf))

# Print status 
msg <- paste0("Copied ", nrow(to_keep), " images into ", newf, "\n")
cat(msg)

