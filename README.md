# panoscripts

Scripts to create panoramas from videos or photos taken along a transect. 

This is a set of scripts that will make a panorama from a video (or a set of 
pictures) taken along a linear transect. Note that these scripts are unsuitable 
for images taken from a single position by rotating the camera around its axes. 

# Usage

The panorama can then be opened in Hugin for last touches and final 
assembly. The workflow is the following: 

1. Split the video file into frames. This is done using `vidsplit` and specifying 
how many frames per second are wanted: 

``` 
visplit <input_video> <output_fps>
```

2. The previous script will produce a folder (with the same name as the video). 
The images can then be filtered using `blurry.R`, which will try to keep the 
best (with highest amount of fine details) for every time period defined by 
`<output_fps>`: 

```
./blurry.R <image_dir> <input_fps> <output_fps>
```

In the example above, `<image_dir>` is the folder where all the images 
from `vidsplit` are located, `<input_fps>` is the number of frames per seconds 
for images in this folder, and `<output_fps>` is the output frame per seconds. 

For example, if there is five images per seconds as input, and one is wanted 
as output, then `blurry.R` will keep one image out of those five (the sharpest).

The images are put in a folder whose name as the `_filtered` suffix. 

3. Once the images are all filtered and ready for assembly, `mkpano.sh` can 
be used. This script will assemble the images into a panorama file (hugin 
file), and align the images. The output file name of the hugin project file 
is `project_<input_dir>`. `mkpano.sh` can be called by calling it with the 
input folder as argument: 

```
mkpano.sh <input_folder>
```

# Links & Resources

These tools are part of the [http://indecostab.eu/](INDECOSTAB project). 
INDECOSTAB has received funding from the European Union’s Horizon 2020 research 
and innovation programme under the Marie Skłodowska-Curie grant agreement 
No 896159. 

