#!/usr/bin/Rscript 
# File that will compute overlaps between images 
# 

suppressPackageStartupMessages( require(spatialwarnings) )
suppressPackageStartupMessages( require(plyr) )
suppressPackageStartupMessages( require(ggplot2) )

args <- commandArgs(trailingOnly = TRUE)
if ( length(args) < 3 ) { 
  stop("Bad command line. Usage: overlaps.R <project> <output_dir> [<overlap_threshold>]")
} else { 
  input_proj <- args[1]
  outdir <- args[2]
  ovlp_thresh <- ifelse(length(args) == 3, 0.7, args[4])
}

# Create folder with filtered images 
if ( ! dir.exists(outdir) ) { 
  dir.create(outdir)
}

# Read project and parse control points
pto <- readLines(input_proj)
ptoc <- pto[grep("^c", pto)]
ctp <- ldply(ptoc, function(l) { 
  info <- strsplit(l, " ")[[1]]
  data.frame(img1 = as.integer(gsub("n", "", info[2])), 
             img2 = as.integer(gsub("N", "", info[3])), 
             x1   = as.numeric(gsub("x", "", info[4])), 
             y1   = as.numeric(gsub("y", "", info[5])), 
             x2   = as.numeric(gsub("X", "", info[6])), 
             y2   = as.numeric(gsub("Y", "", info[7])))
})

# Read images and add that to the control point information 
ptoi <- pto[grep("^i", pto)]
imgs <- ldply(seq_along(ptoi), function(n) { 
  info <- strsplit(ptoi[n], " ")[[1]]
  name <- gsub("^n", "", tail(info, 1))
  name <- gsub("\"|\\\\", "", name)
  width  <- as.numeric(gsub("w", "", info[2]))
  height <- as.numeric(gsub("h", "", info[3]))
  data.frame(imgn = n-1, name = name, width = width, height = height)
})

# Merge the information 
ctp <- ddply(ctp, ~ img1 + img2, function(df) { 
  im1 <- subset(imgs, df[1,"img1"] == imgn)
  df[ ,"w1"] <- im1[ ,"width"]
  df[ ,"h1"] <- im1[ ,"height"]
  df[ ,"n1"] <- im1[ ,"name"]
  im2 <- subset(imgs, df[1,"img2"] == imgn)
  df[ ,"w2"] <- im2[ ,"width"]
  df[ ,"h2"] <- im2[ ,"height"]
  df[ ,"n2"] <- im2[ ,"name"]
  return( df )
})

# Compute image overlaps 
get_ovlp <- function(xs, ys, w, h) { 
  area_cp <- (max(xs) - min(xs)) * (max(ys)- min(ys))
  area_cp / (w * h)
}
ovlp <- ddply(ctp, ~ img1 + img2, function(df) { 
  with(df, { 
    data.frame(img1 = img1[1], img2 = img2[1], n1 = n1[1], n2 = n2[1], 
               ovlp = with(df, get_ovlp(x1, y1, w1[1], h1[1])))
  })
})

# Remove images that are dead ends 
# ovlp <- subset(ovlp, img2 %in% img1 | img2 == max(img2))

# Here we find the furthest image with overlap above the threshold
curimg <- min(ovlp[ ,"img1"])
imgseq <- matrix(, nrow = 0, ncol = 2)
while ( curimg < max(ovlp[ ,"img2"]) ) { 
  nextimgs <- subset(ovlp, img1 == curimg)
  nextimg <- with(nextimgs, img2[which.min(abs(ovlp - 0.3))])
  imgseq <- rbind(imgseq, c(curimg, nextimg))
  curimg <- nextimg
}

# Get images to remove 
ovlp[ ,"to_remove"] <- with(ovlp, ! img1 %in% as.vector(imgseq))

imgseq <- as.data.frame(imgseq)
names(imgseq) <- c("img1", "img2")

pl <- ggplot(ovlp) + 
  geom_raster(aes(x = img1, y = img2, fill = ovlp)) + 
#   geom_vline(aes(xintercept = img1), 
#              color = "black", 
#              data = subset(ovlp, to_remove)) + 
  geom_point(aes(x = img1, y = img2), color = "black", data = imgseq) + 
  geom_line(aes(x = img1, y = img2), color = "black", data = imgseq) + 
  scale_fill_fermenter(palette = "RdBu", 
                       breaks = c(-Inf, 0, 0.6, 0.7, 0.8, 0.9, Inf)) + 
  coord_fixed() + 
  labs(x = "Image number #1", 
       y = "Image number #2", 
       caption = paste0("Overlap report (", input_dir, ")"))
ggsave(pl, file = paste0("overlap_analysis.pdf"), 
       width = 7, height = 7)

# Get the list of images that we want to remove
bad_imgs <- with(ovlp, unique(n1[to_remove]))
kept_imgs <- with(ovlp, unique(n1[! n1 %in% bad_imgs]))

invisible( file.copy(kept_imgs, outdir) )


