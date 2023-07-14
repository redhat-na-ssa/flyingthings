#!/usr/bin/python3
import os
import random
import shutil

path = os.getcwd()
print("My Current Path is: " + str(path))
os.chdir('datasets')
path = os.getcwd()
print("My Current Path is: " + str(path))
def count_files(directory):
    file_count = 0
    # Iterate over all files in the directory
    for _, _, files in os.walk(directory):
        file_count += len(files)
    return file_count

# Set the paths for the original image and label directories
image_dir = 'images'
label_dir = 'labels'

# Set the path for the training directory
training_dir = 'training'

# Set the desired proportions for train, test, and valid sets
train_split = 0.7
test_split = 0.15
valid_split = 0.15

# Create the training directory
os.makedirs(training_dir, exist_ok=True)

# Create the train, test, and valid directories within the training directory
train_dir = os.path.join(training_dir, 'train')
test_dir = os.path.join(training_dir, 'test')
valid_dir = os.path.join(training_dir, 'valid')

os.makedirs(train_dir, exist_ok=True)
os.makedirs(test_dir, exist_ok=True)
os.makedirs(valid_dir, exist_ok=True)

# Create image and label directories within train, test, and valid directories
train_image_dir = os.path.join(train_dir, 'images')
train_label_dir = os.path.join(train_dir, 'labels')
os.makedirs(train_image_dir, exist_ok=True)
os.makedirs(train_label_dir, exist_ok=True)

test_image_dir = os.path.join(test_dir, 'images')
test_label_dir = os.path.join(test_dir, 'labels')
os.makedirs(test_image_dir, exist_ok=True)
os.makedirs(test_label_dir, exist_ok=True)

valid_image_dir = os.path.join(valid_dir, 'images')
valid_label_dir = os.path.join(valid_dir, 'labels')
os.makedirs(valid_image_dir, exist_ok=True)
os.makedirs(valid_label_dir, exist_ok=True)

# Retrieve the list of image filenames
image_filenames = os.listdir(image_dir)

# Shuffle the image filenames
random.shuffle(image_filenames)

# Calculate the number of images for each set
total_images = len(image_filenames)
train_count = int(total_images * train_split)
test_count = int(total_images * test_split)
valid_count = total_images - train_count - test_count

# Copy images and labels to the train directory
for filename in image_filenames[:train_count]:
    name, extension = os.path.splitext(filename)

    src_image_path = os.path.join(image_dir, filename)
    dest_image_path = os.path.join(train_image_dir, filename)
    shutil.copy(src_image_path, dest_image_path)

    label_filename = filename.replace(extension, '.txt')
    src_label_path = os.path.join(label_dir, label_filename)
    dest_label_path = os.path.join(train_label_dir, label_filename)
    shutil.copy(src_label_path, dest_label_path)

# Copy images and labels to the test directory
for filename in image_filenames[train_count:train_count + test_count]:
    src_image_path = os.path.join(image_dir, filename)
    dest_image_path = os.path.join(test_image_dir, filename)
    shutil.copy(src_image_path, dest_image_path)

    label_filename = filename.replace(extension, '.txt')
    src_label_path = os.path.join(label_dir, label_filename)
    dest_label_path = os.path.join(test_label_dir, label_filename)
    shutil.copy(src_label_path, dest_label_path)

# Copy images and labels to the valid directory
for filename in image_filenames[train_count + test_count:]:
    src_image_path = os.path.join(image_dir, filename)
    dest_image_path = os.path.join(valid_image_dir, filename)
    shutil.copy(src_image_path, dest_image_path)

    label_filename = filename.replace(extension, '.txt')
    src_label_path = os.path.join(label_dir, label_filename)
    dest_label_path = os.path.join(valid_label_dir, label_filename)
    shutil.copy(src_label_path, dest_label_path)

print("dataset files distributed to test, train, and valid")
directory_path = "training/test/images"
num_test = count_files(directory_path)
directory_path = "training/train/images"
num_train = count_files(directory_path)
directory_path = "training/valid/images"
num_valid = count_files(directory_path)

print("Test image count: " + str(num_test))
print("Train image count: " + str(num_train))
print("Validation image count: " + str(num_valid))