#!/usr/bin/python3
import os
import sys
import cv2

def resize_images(directory, new_size):
    # Create a new folder called "originals"
    originals_folder = os.path.join(directory, 'originals')
    os.makedirs(originals_folder, exist_ok=True)

    # Move original images to "originals" folder
    for filename in os.listdir(directory):
        if filename.lower().endswith(('.png', '.jpg', '.jpeg')):
            original_path = os.path.join(directory, filename)
            new_path = os.path.join(originals_folder, filename)
            os.rename(original_path, new_path)

    # Resize images in the current directory
    for filename in os.listdir(directory):
        if filename.lower().endswith(('.png', '.jpg', '.jpeg')):
            image_path = os.path.join(directory, filename)
            image = cv2.imread(image_path)
            resized_image = cv2.resize(image, new_size, interpolation=cv2.INTER_AREA)
            cv2.imwrite(image_path, resized_image)

# Usage: python script.py <directory> <new_width> <new_height>
if __name__ == '__main__':
    directory = sys.argv[1]
    new_width = int(sys.argv[2])
    new_height = int(sys.argv[3])
    new_size = (new_width, new_height)
    resize_images(directory, new_size)

# Usage: python script.py <directory> <new_width> <new_height>
if __name__ == '__main__':
    directory = sys.argv[1]
    new_width = int(sys.argv[2])
    new_height = int(sys.argv[3])
    new_size = (new_width, new_height)
    resize_images(directory, new_size)
