#!/usr/bin/python3
import os
import sys
import cv2


def resize_images(directory, new_width, new_height):
    # Resize images in the specified directory
    for filename in os.listdir(directory):
        if filename.lower().endswith(('.png', '.jpg', '.jpeg')):
            # print("resizing: ", str(filename))
            try:
                image_path = os.path.join(directory, filename)
                image = cv2.imread(image_path)
                resized_image = cv2.resize(image, (new_width, new_height), interpolation=cv2.INTER_AREA)
                cv2.imwrite(image_path, resized_image)
            except Exception as e:
                print("Error: ", str(filename))
                print(str(e))

# Usage: python script.py <directory> <new_width> <new_height>
if __name__ == '__main__':
    directory = sys.argv[1]
    new_width = int(sys.argv[2])
    new_height = int(sys.argv[3])
    resize_images(directory, new_width, new_height)
    print("Done resizing all images in the specified directory")
