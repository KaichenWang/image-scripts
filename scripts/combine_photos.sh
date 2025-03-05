#!/bin/bash

# Place this combine_photos.sh file in the same folder as images and run:
# chmod +x combine_photos.sh
# ./combine_photos.sh

files=(*.jpg)
num_files=${#files[@]}

for ((i=0; i<num_files; i+=2)); do
    if [ $((i+1)) -lt $num_files ]; then
        left="${files[i]}"
        right="${files[i+1]}"
        output="combined_$(basename "$left" .jpg)_$(basename "$right" .jpg).jpg"

        # Get dimensions of the first image
        dimensions=$(identify -format "%wx%h" "$left")
        width=$(echo $dimensions | cut -d'x' -f1)
        height=$(echo $dimensions | cut -d'x' -f2)

        # Calculate new width to maintain 3:2 aspect ratio
        new_width=$((height * 3 / 2))

        # Resize both images to half the new width
        half_width=$((new_width / 2))
        convert "$left" -resize "${half_width}x$height^" -gravity center -extent "${half_width}x$height" "left_resized.jpg"
        convert "$right" -resize "${half_width}x$height^" -gravity center -extent "${half_width}x$height" "right_resized.jpg"

        # Combine them side by side
        convert +append "left_resized.jpg" "right_resized.jpg" "$output"

        # Clean up temporary files
        rm "left_resized.jpg" "right_resized.jpg"

        echo "Created: $output"
    fi
done
