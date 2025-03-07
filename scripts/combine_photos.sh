#!/bin/bash

# Set default number of images to combine (2) or use command line argument
images_per_row=${1:-2}

files=(*.jpg)
num_files=${#files[@]}

for ((i=0; i<num_files; i+=images_per_row)); do
    # Check if we have enough files for this row
    remaining=$((num_files - i))
    if [ $remaining -lt $images_per_row ]; then
        echo "Skipping last $remaining file(s) as they are not enough to make a complete row."
        break
    fi
    
    # Build output filename and prepare file list
    output="combined"
    image_files=""
    resized_files=""
    
    for ((j=0; j<images_per_row; j++)); do
        current_file="${files[i+j]}"
        output="${output}_$(basename "$current_file" .jpg)"
        image_files="$image_files \"$current_file\""
        resized_files="$resized_files \"resized_$j.jpg\""
    done
    output="${output}.jpg"
    
    # Get dimensions of the first image
    dimensions=$(identify -format "%wx%h" "${files[i]}")
    width=$(echo $dimensions | cut -d'x' -f1)
    height=$(echo $dimensions | cut -d'x' -f2)
    
    # Calculate new width to maintain 3:2 aspect ratio for the combined image
    new_width=$((height * 3 / 2))
    
    # Calculate width for each individual image
    single_width=$((new_width / images_per_row))
    
    # Resize all images for this row
    for ((j=0; j<images_per_row; j++)); do
        current_file="${files[i+j]}"
        convert "$current_file" -resize "${single_width}x$height^" -gravity center -extent "${single_width}x$height" "resized_$j.jpg"
    done
    
    # Combine all resized images side by side
    convert +append resized_*.jpg "$output"
    
    # Clean up temporary files
    rm resized_*.jpg
    
    echo "Created: $output"
done