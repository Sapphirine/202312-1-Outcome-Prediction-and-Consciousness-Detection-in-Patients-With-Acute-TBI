% Get the total number of elements in the 'Data' field
totalDataPoints = 48657;

% Determine the quarter points
quarter1 = 1;
quarter2 = ceil(totalDataPoints / 4);
quarter3 = ceil(totalDataPoints / 2);
quarter4 = ceil(3 * totalDataPoints / 4);

% Split the structure into four parts



% Initialize the structure with empty cells
myStructure = struct('Patient_IDs', {}, 'Designators', {}, 'Imaging_Types', {}, ...
                    'Techniques', {}, 'Datas', {}, 'Numbers', {});

% Loop through image_data and add values to the structure
for i = 1:numel(image_data)
    % Add values to the structure fields
    myStructure.Patient_IDs{end+1} = image_data(i).Patient_ID;
    myStructure.Designators{end+1} = image_data(i).Designator;
    myStructure.Imaging_Types{end+1} = image_data(i).Imaging_Type;
    myStructure.Techniques{end+1} = image_data(i).Technique;
    myStructure.Datas{end+1} = image_data(i).Data;
    myStructure.Numbers{end+1} = image_data(i).Number;
end

% Display the resulting structure
disp('My Structure:');
disp(myStructure);

