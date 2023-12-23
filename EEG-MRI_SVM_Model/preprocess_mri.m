    
function [] = preprocess_mri()
    %% get technique folder path
    
    clear;clc;
    path1 = '../Data/MRI/responsive';
    path2 = '../Data/MRI/unresponsive';
    path3 = '../Data/MRI/';
    %Initialize varibles
    %dcm_paths = struct();
    num = 1;
    
    % Convert table to structure
    designator_folders = dir(path3);
    
    technique_folder_paths = string.empty(0, 1);
    dicom_paths = string.empty(0, 1);
    
    % loop thorugh patient folders 
    for i = 4:size(designator_folders)
    
        
        % Split patient folder name for later use
        %parts = strsplit(patient_folders(i).name, '_');
    
        % if strcmp(designator_folders(i).name, 'responsive') || strcmp(designator_folders(i).name, 'unresponsive')
        %     %do nothing
        % else
        %     continue
        % end
    
        new_path = [path3,designator_folders(i).name];
        designator = designator_folders(i).name;
    
        % loop through technique folders, skipping fodlers not containing
        % images
        patient_folders = dir(new_path);
    
        path = new_path;
    
    
        for ii = 4:size(patient_folders)
    
            new_path = [path, '/',patient_folders(ii).name];
            next_directory = dir(new_path);
    
            for iii = 4:size(next_directory)
    
                if contains(next_directory(iii).name, '(-C)')
                    temp_str = [new_path, '/',next_directory(iii).name];
                    technique_folder_paths(end+1) = temp_str;
                else 
                    temp_path = [new_path, '/', next_directory(iii).name];
                    technique_dir = dir(temp_path);
                    for iiii = 4:size(technique_dir)
                        temp_str = [temp_path, '/',technique_dir(iiii).name];
                        technique_folder_paths(end+1) = temp_str;
                    end
                end
            end
    
        end
    end
    
    
    %% loop through to save dcm files
    
    technique_folder_paths = technique_folder_paths';
    
    % loop thorugh each and save dcm images
    for j = 1:size(technique_folder_paths)
        newer_path = technique_folder_paths(j);
        file_list = dir(fullfile(newer_path, '*.dcm'));
    
        % % Split technique folder name for later use
        % delimiters = {'_', '/'};
        % parts = strsplit(technique_folder_paths(i), delimiters);
    
        % Save all relevant file info in new struct
        for k = 1:size(file_list)
            % temp = struct('Patient_ID', parts(5), 'Designator', parts(4), ...
            %     'Imaging_Type', parts(9), 'Technique', parts(10), ...
            %     'Path', newer_path, 'File_Name', file_list(k).name); 
            % 
            temp_str2 = [char(newer_path), '/', file_list(k).name];
            dicom_paths(end+1) = temp_str2;
            
        end 
    end
    
    %% Extract image data using paths 
    
    %for i=1:length(dicom_paths)
    jj = 1;
    for i=1:3000
        % Split technique folder name for later use
        delimiters = {'_', '/'};
        parts = strsplit(dicom_paths(i), delimiters);
    
        image = dicomread(dicom_paths(i));
        if numel(parts) > 9 
            temp_image_data = struct('Patient_ID', char(parts(5)), 'Designator', char(parts(4)), ...
                            'Imaging_Type', char(parts(9)), 'Technique', char(parts(10)), ...
                            'Data', image, 'Number', i);
        else
            temp_image_data = struct('Patient_ID', char(parts(5)), 'Designator', char(parts(4)), ...
                            'Imaging_Type', (parts(9)), 'Technique', '', ...
                            'Data', image, 'Number', i);
        end
    
    
        image_data(jj) = temp_image_data;
        jj = jj + 1;
    
    end
    %% Save image data to mat file
    save('image_data1', 'image_data')
end