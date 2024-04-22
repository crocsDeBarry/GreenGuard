import numpy as np
import os
import matplotlib.pyplot as plt
import torch
import cv2
from ultralytics import YOLO

def custom_images(img_path):
    """
    Verifies the shape of the input image and reshapes it if necessary.

    Args:
        img_path (str): The path to the input image.

    Returns:
        img (numpy.ndarray): The reshaped image.
    """
    # Load the image
    img = cv2.imread(img_path)

    # Check the shape of the image
    if img.shape != (512, 512, 3):
        # Reshape the image to (512, 512, 3)
        img = cv2.resize(img, (512, 512))

    return img

def plant_disease_detect(img, model):
    """
    Performs plant disease detection on the given image using the YOLO model.

    Args:
        img (numpy.ndarray): The input image.
        model (YOLO): The YOLO model to use for detection.

    Returns:
        detect_img (numpy.ndarray): The image with the detected objects and their classes.
        classes (list): A list of the predicted class names.
    """
    # Pass the image through the detection model and get the result
    detect_result = model(img)

    # Plot the detections
    detect_img = detect_result[0].plot()
    detections = detect_result[0].boxes.data.tolist()
    classes = [model.names[int(detection[5])] for detection in detections]

    # Convert the image to RGB format
    detect_img = cv2.cvtColor(detect_img, cv2.COLOR_BGR2RGB)

    return detect_img, classes

def plot_predicted_image(detect_img, classes):
    """
    Plots the predicted image with the detected objects and their classes.

    Args:
        detect_img (numpy.ndarray): The image with the detected objects and their classes.
        classes (list): A list of the predicted class names.
    """
    # Create a figure with subplots for each image
    fig, axe = plt.subplots(figsize=(15, 7))

    # Plot the current image on the appropriate subplot
    axe.imshow(detect_img)
    axe.axis('off')
    axe.set_title("Prediction")

    # Adjust the spacing between the subplots
    plt.subplots_adjust(wspace=0.2, hspace=0.2)
    plt.show()

    for i, class_ in enumerate(classes):
        print(f"\nClass Name {i + 1} : {class_}")


def main_IA(image_filename):
    print(image_filename)
    print("Je suis dans la fonction IA")
    # Load the YOLO model
    model = YOLO('ia/best.pt')

    # Define the directory where the custom images are stored
    custom_image_dir = 'image/' + image_filename

    # Verify and reshape the input image if necessary
    img = custom_images(custom_image_dir)

    # Perform plant disease detection and plot the predicted image
    detect_img, classes = plant_disease_detect(img, model)
    
    #plot_predicted_image(detect_img, classes)
    detect_img = cv2.cvtColor(detect_img, cv2.COLOR_BGR2RGB)
    cv2.imwrite("image/"+image_filename, detect_img)
    print ("La classe c bien ca", classes)
    return classes
