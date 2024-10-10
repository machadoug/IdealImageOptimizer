# Image Optimizer Script

## Description

The `imageOptimizer.sh` script optimizes image files in a specified directory using various tools. It supports PNG, JPEG, and other formats, and can display a progress bar and control sleep duration between optimizations to reduce CPU load. This script helps reduce image file sizes, improving website performance and reducing bandwidth usage.

## Prerequisites

Ensure the following tools are installed:

- `pngquant`
- `optipng`
- `jpegoptim`
- `optimizt`

Install them using these commands:

### On Debian/Ubuntu:
```bash
sudo apt-get install pngquant optipng jpegoptim
npm install -g optimizt
```

### On CentOS/RHEL/Almalinux:
```bash
sudo yum install pngquant optipng jpegoptim
npm install -g optimizt
```

### Cloning the Repository

Clone the repository from GitHub:
```bash
git clone https://github.com/machadoug/IdealImageOptimizer.git
cd IdealImageOptimizer
```

## Usage

Run the script with:
```bash
bash imageOptimizer.sh /path/to/directory
```

Options:
- `--verbose`: Display a progress bar with time estimation.
- `--sleep <duration>`: Set sleep duration between optimizations (default is 0.75 seconds).

#### Example:
```bash
bash imageOptimizer.sh --verbose --sleep 2 /path/to/directory
```

### Script Details

#### Default Values
- `DIR="."`: Directory to optimize images in (default is the current directory).
- `VERBOSE=false`: Display a progress bar (default is false).
- `SLEEP_DURATION=0.75`: Sleep duration between optimizations (default is 0.75 seconds).

#### Log Files
- `imageOptimization.log`: Tracks processed files to avoid reprocessing.
- `imageOptimization_errors.log`: Logs errors encountered during optimization.

## License

This script is provided as-is without any warranty. Use at your own risk. See LICENSE for details.

