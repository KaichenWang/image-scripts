#!/bin/bash

# Usage function
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Add timestamp overlay to images in the current directory"
    echo ""
    echo "OPTIONS:"
    echo "  -d, --delete    Delete original files after successful timestamping"
    echo "  -b, --before DATE  Skip images with timestamps on or after DATE (format: DD-MM-YYYY)"
    echo "  -h, --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                          # Process images, keep originals"
    echo "  $0 -d                       # Process images, delete originals after success"
    echo "  $0 --delete                 # Same as -d"
    echo "  $0 -b 15-06-2023            # Skip images on or after June 15, 2023"
    echo "  $0 -d -b 01-01-2024         # Delete originals, skip images on or after Jan 1, 2024"
}

# Parse command line arguments
DELETE_ORIGINAL=false
BEFORE_DATE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--delete)
            DELETE_ORIGINAL=true
            shift
            ;;
        -b|--before)
            if [[ -z "$2" ]]; then
                echo "Error: -b/--before requires a date argument (DD-MM-YYYY)"
                usage
                exit 1
            fi
            BEFORE_DATE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate date format if provided
if [[ -n "$BEFORE_DATE" ]]; then
    if [[ ! "$BEFORE_DATE" =~ ^[0-9]{2}-[0-9]{2}-[0-9]{4}$ ]]; then
        echo "Error: Invalid date format. Expected DD-MM-YYYY, got: $BEFORE_DATE"
        usage
        exit 1
    fi
    
    # Validate the date is actually valid
    if ! date -jf "%d-%m-%Y" "$BEFORE_DATE" "+%d-%m-%Y" >/dev/null 2>&1; then
        echo "Error: Invalid date: $BEFORE_DATE"
        exit 1
    fi
fi

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
if [ "$DELETE_ORIGINAL" = true ]; then
    echo "⚠️  DELETE MODE: Original files will be deleted after successful processing"
fi
if [ -n "$BEFORE_DATE" ]; then
    echo "📅  DATE FILTER: Skipping images with timestamps on or after $BEFORE_DATE"
fi
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
    
    # Check date filter if specified
    if [ -n "$BEFORE_DATE" ]; then
        # Convert image date to DD-MM-YYYY format for comparison
        image_date=$(date -jf "%Y-%m-%d %H:%M:%S %z" "$creation_date_raw" "+%d-%m-%Y")
        
        # Convert both dates to epoch time for comparison
        image_epoch=$(date -jf "%d-%m-%Y" "$image_date" "+%s")
        before_epoch=$(date -jf "%d-%m-%Y" "$BEFORE_DATE" "+%s")
        
        # Skip if image date is on or after the before date
        if [ "$image_epoch" -ge "$before_epoch" ]; then
            echo "📅[Skipped]: $pic (date: $image_date, on or after $BEFORE_DATE)"
            ((skipped_count++))
            continue
        fi
    fi
    
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
        
        # Delete original file if requested
        if [ "$DELETE_ORIGINAL" = true ]; then
            if rm "$pic"; then
                echo "  [Deleted]: $pic"
            else
                echo "  ⚠️[Warning]: Failed to delete original file: $pic"
            fi
        fi
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