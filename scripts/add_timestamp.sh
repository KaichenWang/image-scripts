#!/bin/bash

# Valid file extensions
image_extensions="jpg|jpeg|png|gif|bmp|tiff|webp|heic|HEIC"

# Counters
success_count=0
skipped_count=0
failed_count=0

# Reference dimensions for a 12MP image
reference_width=4242
reference_height=2828

# Reference positioning and font size for a 12MP image
base_x_year=275
base_x_apos=340
base_x_month=415
base_x_day=530
base_y=200
base_pointsize=100
base_offset=2

echo "================ Start ================"
for pic in *.*; do
    if [[ ! "$pic" =~ .*\.(${image_extensions})$ ]]; then
        echo "⚠️[Skipped]: non-image file: $pic"
        ((skipped_count++))
        continue
    fi

    # Get image creation date
    creation_date_raw=$(mdls -raw -name kMDItemContentCreationDate "$pic")
    year=$(date -jf "%Y-%m-%d %H:%M:%S %z" "$creation_date_raw" "+%y")
    month=$(date -jf "%Y-%m-%d %H:%M:%S %z" "$creation_date_raw" "+%m")
    day=$(date -jf "%Y-%m-%d %H:%M:%S %z" "$creation_date_raw" "+%d")
    
    # Get image dimensions
    dimensions=$(identify -format "%wx%h" "$pic")
    width=$(echo $dimensions | cut -d'x' -f1)
    height=$(echo $dimensions | cut -d'x' -f2)
    
    # Determine if image is landscape or portrait
    is_portrait=false
    if [ $width -lt $height ]; then
        is_portrait=true
        # For portraits, we'll use the width as reference for scaling
        scaling_factor=$(echo "scale=3; $width / $reference_height" | bc)
    else
        # For landscapes, we'll use the height as reference for scaling
        scaling_factor=$(echo "scale=3; $height / $reference_height" | bc)
    fi
    
    # Scale values based on image dimensions and convert to integers
    x_year=$(echo "$base_x_year * $scaling_factor" | bc | awk '{print int($1+0.5)}')
    x_apos=$(echo "$base_x_apos * $scaling_factor" | bc | awk '{print int($1+0.5)}')
    x_month=$(echo "$base_x_month * $scaling_factor" | bc | awk '{print int($1+0.5)}')
    x_day=$(echo "$base_x_day * $scaling_factor" | bc | awk '{print int($1+0.5)}')
    y=$(echo "$base_y * $scaling_factor" | bc | awk '{print int($1+0.5)}')
    pointsize=$(echo "$base_pointsize * $scaling_factor" | bc | awk '{print int($1+0.5)}')
    offset=$(echo "$base_offset * $scaling_factor" | bc | awk '{print int($1+0.5)}')
    
    # Ensure minimum values
    [ $pointsize -lt 20 ] && pointsize=20
    [ $offset -lt 1 ] && offset=1
    
    # Calculate offset positions
    x_year_offset=$((x_year + offset))
    x_apos_offset=$((x_apos + offset))
    x_month_offset=$((x_month + offset))
    x_day_offset=$((x_day + offset))
    y_offset=$((y + offset))
    
    # Conversion options
    convert_opts=(
        -font 7-Segment
        -pointsize $pointsize
        -gravity SouthEast
        -fill 'rgba(54, 8, 1, 0.3)'
        -annotate +$x_year+$y "$year"
        -annotate +$x_apos+$y "'"
        -annotate +$x_month+$y "$month"
        -annotate +$x_day+$y "$day"
        -fill 'rgba(206, 81, 62, 0.9)'
        -annotate +$x_year_offset+$y_offset "$year"
        -annotate +$x_apos_offset+$y_offset "'"
        -annotate +$x_month_offset+$y_offset "$month"
        -annotate +$x_day_offset+$y_offset "$day"
    )
    
    # Apply rotation for portrait orientation
    if $is_portrait; then
        convert_opts=(
            -rotate 90
            "${convert_opts[@]}"
            -rotate "-90"
        )
    fi
    
    # Apply the conversion
    output_file="${pic%.*}_dated.jpg"
    if convert "$pic" "${convert_opts[@]}" "$output_file"; then
        echo "[Success]: $pic -> $output_file"
        ((success_count++))
    else
        echo "❌[Failed]: $pic"
        ((failed_count++))
    fi
done

echo "================ Summary ================"
echo "Success: $success_count"
echo "Skipped: $skipped_count"
echo "Failed: $failed_count"
echo "================ Finished ================"