# image-scripts
Shell scripts to batch process images

## Scripts

### add_timestamp.sh

#### Description

Adds a timestamp of when the image was created to the bottom right corner. Applied in batch to all images in directory.

#### Usage

- Place this add_timestamp.sh file in the same folder as images and run:
```
chmod +x add_timestamp.sh
./add_timestamp.sh
```

#### Options

- `-d, --delete`: Delete original files after successful timestamping
- `-b, --before DATE`: Skip images with timestamps on or after DATE (format: DD-MM-YYYY)
- `-h, --help`: Show help message

#### Examples

```bash
# Process images, keep originals
./add_timestamp.sh

# Process images, delete originals after success
./add_timestamp.sh -d

# Skip images on or after June 15, 2023
./add_timestamp.sh -b 15-06-2023

# Delete originals and skip images on or after January 1, 2024
./add_timestamp.sh -d -b 01-01-2024
```

### combine_photos.sh

#### Description

Combines two images into one. Applied in batch to all images in directory (every 2 photos are combined).

#### Usage

- Place this combine_photos.sh file in the same folder as images and run:
```
chmod +x combine_photos.sh
./combine_photos.sh
```

##### Multiple images

Pass a number as argument. Example: combining 3 photos:
```
./combine_photos.sh 3
```
