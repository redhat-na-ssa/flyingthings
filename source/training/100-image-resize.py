#!/opt/app-root/bin/python
import os
import sys
import cv2

def resize_images(source_dir, dest_dir, max_width):
    try:
        os.makedirs(dest_dir, exist_ok=True)

        for filename in os.listdir(source_dir):
            source_path = os.path.join(source_dir, filename)
            dest_path = os.path.join(dest_dir, filename)

            # Read the image using OpenCV
            img = cv2.imread(source_path)

            # Get the current width and height of the image
            height, width = img.shape[:2]

            # Calculate the new height based on the aspect ratio
            new_width = max_width
            new_height = int(height * (max_width / width))

            # Resize the image while maintaining the aspect ratio
            resized_img = cv2.resize(img, (new_width, new_height), interpolation=cv2.INTER_AREA)

            # Save the resized image to the destination directory
            cv2.imwrite(dest_path, resized_img)

        print("Images have been resized and saved to the destination directory.")
    except Exception as e:
        print("Error:", e)

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python resize_images.py <source_dir> <dest_dir> <max_width>")
        sys.exit(1)

    source_directory = sys.argv[1]
    destination_directory = sys.argv[2]
    max_width = int(sys.argv[3])

    resize_images(source_directory, destination_directory, max_width)
