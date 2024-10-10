#!/bin/bash
# USAGE INSTRUCTIONS
# To run this script, you need to have the following tools installed:
# - pngquant
# - optipng
# - jpegoptim
# - optimizt
# You can install them using the following commands
# On Debian/Ubuntu:
# sudo apt-get install pngquant optipng jpegoptim
# On CentOS/RHEL/Almalinux:
# sudo yum install pngquant optipng jpegoptim
# npm install -g optimizt
# 
# You can run this script with the following command:
# bash imageOptimizer.sh /path/to/directory
# You can also run this script with the following options:
# --verbose: Display a progress bar with time estimation
# --sleep <duration>: Set the sleep duration between image optimizations (default is 0.75 second)
# Example:
# bash imageOptimizer.sh --verbose --sleep 2 /path/to/directory

# TESTED on UBUNTU and ALMALINUX with 1.2Gb of images
# pngquant, optipng, optimizt yeld different results, so it's a good idea to run all of them
#

# Default values
DIR="."
VERBOSE=false
# It's more important to have a good sleep duration than a fast script, specially on shared web hosting
# If in the first run there's too many images to process, we recommend to run this script on a local machine instead of of production server, then upload the images
# Compressing images can be a very CPU intensive task, so it's better to have a good sleep duration to avoid overloading the server
#  IT's also a good idea to schedule a cron job to run this script during off-peak hours
SLEEP_DURATION=0.75


# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose)
            VERBOSE=true
            shift
            ;;
        --sleep)
            SLEEP_DURATION="$2"
            shift 2
            ;;
        *)
            DIR="$1"
            shift
            ;;
    esac
done

# Do not remove the imageOptimization.log file, it's used to track processed files and avoid processing them again
LOG="$DIR/imageOptimization.log"
ERROR_LOG="$DIR/imageOptimization_errors.log"

# Image counter and how many were optimized
TOTAL=0
OPTIMIZED=0

# Associative array to track processed files
declare -A processed_files

# Capture the start time
script_start_time=$(date +%s)

# Function to display a progress bar with time estimation
show_progress() {
    local current=$1
    local total=$2
    # If total is 0, then abort to avoid division by zero
    if [ $total -eq 0 ]; then
        return
    fi
    local elapsed=$3
    local width=$(tput cols)
    local bar_width=$((width - 50)) # Adjust for percentage and time display
    local progress=$((current * bar_width / total))
    local remaining=$((bar_width - progress))
    local avg_time=$(awk "BEGIN {print $elapsed / $current}")
    local remaining_time=$(awk "BEGIN {print ($total - $current) * $avg_time}")
    local remaining_time_formatted=$(printf "%02d:%02d" $(awk "BEGIN {print int($remaining_time/60)}") $(awk "BEGIN {print int($remaining_time%60)}"))

    printf "\r["
    printf "%0.s#" $(seq 1 $progress)
    printf "%0.s " $(seq 1 $remaining)
    printf "] %d/%d (ETA: %s)" $current $total $remaining_time_formatted
}

# Function to optimize images
optimize_images() {
    local cmd=$1
    local ext=$2
    local options=$3

    if command -v "$cmd" &> /dev/null
    then
        echo "$cmd found"
        if [ -f "$LOG" ]; then
            mapfile -t files < <(find "$DIR" -type f -newer "$LOG" -iname "*.$ext")
        else
            mapfile -t files < <(find "$DIR" -type f -iname "*.$ext")
        fi

        local file_count=${#files[@]}
        local current_file=0
        local start_time=$(date +%s)

        for file in "${files[@]}"; do
            if [ ! -f "$file" ]; then
                echo "File not found: $file" >> "$ERROR_LOG"
                continue
            fi

            original_size=$(stat -c%s "$file" 2>>"$ERROR_LOG")
            if [ $? -ne 0 ]; then
                echo "Error getting size of $file" >> "$ERROR_LOG"
                continue
            fi

            "$cmd" $options "$file" 2>>"$ERROR_LOG"
            if [ $? -ne 0 ]; then
                echo "Error processing $file with $cmd" >> "$ERROR_LOG"
                continue
            fi

            new_size=$(stat -c%s "$file" 2>>"$ERROR_LOG")
            if [ $? -ne 0 ]; then
                echo "Error getting new size of $file" >> "$ERROR_LOG"
                continue
            fi

            if [ -z "${processed_files[$file]}" ]; then
                processed_files["$file"]=1
                TOTAL=$((TOTAL + 1))
                if [ $new_size -lt $original_size ]; then
                    OPTIMIZED=$((OPTIMIZED + 1))
                fi
            fi
            current_file=$((current_file + 1))
            elapsed_time=$(( $(date +%s) - $start_time ))

            # Update progress bar every 5 files if verbose is enabled
            if $VERBOSE && (( current_file % 5 == 0 )); then
                show_progress $current_file $file_count $elapsed_time
            fi

            # Introduce a small delay to reduce CPU load
            sleep "$SLEEP_DURATION"
        done
        # Ensure the progress bar is updated at the end if verbose is enabled
        if $VERBOSE; then
            show_progress $current_file $file_count $elapsed_time
            echo
        fi
    else
        echo "$cmd not found"
    fi
}

# Optimize PNG files with pngquant
optimize_images "pngquant" "png" "--skip-if-larger --quality 75-85 --force --ext .png"

# Optimize PNG files with optipng
optimize_images "optipng" "png" "-quiet"

# Optimize JPEG files with jpegoptim, lossless optimization
# optimize_images "jpegoptim" "jpg" "--strip-all"
# optimize_images "jpegoptim" "jpeg" "--strip-all"

# Optimize images with optimizt, lossy optimization
# Run this to squeeze another 0 to 3% of compression for PNG files. After running pngquant and optipng might not be worth it
# optimize_images "optimizt" "png" "" 
optimize_images "optimizt" "jpg" ""
optimize_images "optimizt" "jpeg" ""

# Print and save the results
echo "Total images processed: $TOTAL" | tee -a "$LOG"
echo "Total images optimized: $OPTIMIZED" | tee -a "$LOG"

# Calculate and display the total elapsed time
script_end_time=$(date +%s)
total_elapsed_time=$((script_end_time - script_start_time))
total_elapsed_time_formatted=$(printf "%02d:%02d:%02d" $((total_elapsed_time/3600)) $((total_elapsed_time%3600/60)) $((total_elapsed_time%60)))
echo "Total elapsed time: $total_elapsed_time_formatted" | tee -a "$LOG"

# Update the flag file
touch "$LOG"