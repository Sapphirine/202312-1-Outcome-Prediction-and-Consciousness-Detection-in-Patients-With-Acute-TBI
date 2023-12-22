import scipy.io
import pydicom
from pydicom.dataset import Dataset, FileMetaDataset
import numpy as np
import os
import argparse
import cv2

# Set up the argument parser
parser = argparse.ArgumentParser(description="Process DICOM files.")
parser.add_argument('input_path', type=str, help='Path to the input .mat file')
parser.add_argument('output_directory', type=str, help='Path to the output directory for DICOM files')
args = parser.parse_args()

# Use the command line arguments
mat_file_path = args.input_path
output_directory = args.output_directory

mat_contents = scipy.io.loadmat(mat_file_path)
image_data_array = mat_contents['image_data']

if not os.path.exists(output_directory):
    os.makedirs(output_directory)

def create_struct_array(image_data_structs):
    # Convert the list of structs to a numpy structured array with the same format as the original
    dtypes = [('Patient_ID', 'O'), ('Data', 'O'), ('Number', 'O'), 
              ('Designator', 'O'), ('Imaging_Type', 'O'), ('Technique', 'O')]
    structured_array = np.zeros((len(image_data_structs),), dtype=dtypes)
    
    for i, struct in enumerate(image_data_structs):
        for field in dtypes:
            value = struct[field[0]]
            if field[0] in ['Patient_ID', 'Designator', 'Imaging_Type', 'Technique']:
                # For strings, ensure they are stored as numpy objects
                structured_array[i][field[0]] = np.array([value], dtype='object')
            elif field[0] == 'Number':
                # For numbers, ensure they are stored as numpy integers
                structured_array[i][field[0]] = np.array([int(value)], dtype='object')
            else:
                # For the Data, store the array directly
                structured_array[i][field[0]] = value
    
    return structured_array

def extract_info(struct):
    patient_id = struct['Patient_ID'][0][0]
    image_number = struct['Number'][0][0]
    return patient_id, image_number

def create_dicom_file(data, patient_id, image_number, output_path):
    patient_id = str(patient_id)
    image_number = int(image_number)
    file_meta = FileMetaDataset()
    file_meta.FileMetaInformationVersion = b'\x00\x01'
    file_meta.MediaStorageSOPClassUID = pydicom.uid.SecondaryCaptureImageStorage
    file_meta.MediaStorageSOPInstanceUID = pydicom.uid.generate_uid()
    file_meta.TransferSyntaxUID = pydicom.uid.ExplicitVRLittleEndian
    file_meta.ImplementationClassUID = pydicom.uid.PYDICOM_IMPLEMENTATION_UID
    ds = Dataset()
    ds.file_meta = file_meta
    ds.is_little_endian = True
    ds.is_implicit_VR = False
    ds.PatientID = patient_id[:64]
    ds.InstanceNumber = image_number
    ds.PixelData = data.tobytes()
    ds.Rows = data.shape[0]
    ds.Columns = data.shape[1]
    ds.SamplesPerPixel = 1
    ds.PhotometricInterpretation = "MONOCHROME2"
    ds.BitsStored = 16
    ds.BitsAllocated = 16
    ds.HighBit = 15
    ds.PixelRepresentation = 0
    pydicom.dcmwrite(output_path, ds)

def apply_synthetic_technique(image, technique):
    if technique == 'binary_thresholded':
        _, modified_image = cv2.threshold(image, 127, 255, cv2.THRESH_BINARY)
    elif technique == 'inverted_colors':
        modified_image = cv2.bitwise_not(image)
    elif technique == 'rotated':
        center = (image.shape[1] // 2, image.shape[0] // 2)
        rotation_matrix = cv2.getRotationMatrix2D(center, 45, 1)
        modified_image = cv2.warpAffine(image, rotation_matrix, (image.shape[1], image.shape[0]))
    elif technique == 'adaptive_thresholded':
        modified_image = cv2.adaptiveThreshold(image, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                                               cv2.THRESH_BINARY, 11, 2)
    elif technique == 'colored':
        modified_image = cv2.applyColorMap(image, cv2.COLORMAP_JET)
    elif technique == 'equalized':
        modified_image = cv2.equalizeHist(image)
    return modified_image

# Define the list of synthetic techniques to apply
technique_names = ['binary_thresholded', 'inverted_colors', 'rotated',
                   'adaptive_thresholded', 'colored', 'equalized']

# Process each technique
for technique_name in technique_names:
    # This list will store the structs for the new .mat file
    new_image_data_struct = []

    # Apply technique to each image and create a new DICOM file
    for index, struct in enumerate(image_data_array[0]):
        patient_id, image_number = extract_info(struct)
        original_output_path = os.path.join(output_directory, f'image_{patient_id}_{image_number}.dcm')
        
        try:
            ds = pydicom.dcmread(original_output_path, force=True)
            modified_image = apply_synthetic_technique(ds.pixel_array, technique_name)

            # Create a new DICOM file for the modified image
            modified_output_path = os.path.join(output_directory, f'image_{patient_id}_{image_number}_{technique_name}.dcm')
            create_dicom_file(modified_image, patient_id, image_number, modified_output_path)

            # Append the modified image data to the list for the new .mat file
            image_struct = {
                'Patient_ID': np.array([patient_id], dtype='object'),
                'Data': modified_image,
                'Number': np.array([image_number], dtype='object'),
                'Designator': np.array([struct['Designator'][0]], dtype='object'),
                'Imaging_Type': np.array([struct['Imaging_Type'][0]], dtype='object'),
                'Technique': np.array([technique_name], dtype='object'),
            }
            new_image_data_struct.append(image_struct)
        
        except Exception as e:
            print(f"Error processing index {index} with technique {technique_name}: {e}")

    # Create the structured array with the correct format
    new_image_data_array = create_struct_array(new_image_data_struct)

    # Save the structured array to a .mat file
    new_mat_file_path = os.path.join(output_directory, f'new_image_data_{technique_name}.mat')
    scipy.io.savemat(new_mat_file_path, {'image_data': new_image_data_array})

    print(f"New .mat file with {technique_name} data created.")