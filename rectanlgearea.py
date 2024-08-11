import cv2
import pytesseract
import numpy as np
import re

# Update the path to Tesseract executable
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

# Load the image
image = cv2.imread(r'C:\Users\tanwa\Documents\Python Scripts\rectangle.jpg')

# Load the image
image = cv2.imread(r'C:\Users\tanwa\Documents\Python Scripts\rectangle.jpg')


# Convert image to grayscale
gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

# Use thresholding to improve text extraction
_, thresh = cv2.threshold(gray, 128, 255, cv2.THRESH_BINARY_INV)

# Perform OCR to extract text
text = pytesseract.image_to_string(thresh)

print("Extracted Text:")
print(text)




# Extract numeric values from the text using regex
def extract_dimensions(text):
    # Find all numbers followed by 'm'
    numbers = re.findall(r'(\d+)\s*m', text)
    return list(map(int, numbers))

# Extract dimensions
dimensions = extract_dimensions(text)

if len(dimensions) == 2:
    length, width = dimensions
    area = length * width
    print(f"Length: {length} m")
    print(f"Width: {width} m")
    print(f"Area: {area} square meters")
else:
    print("Could not extract dimensions correctly.")
