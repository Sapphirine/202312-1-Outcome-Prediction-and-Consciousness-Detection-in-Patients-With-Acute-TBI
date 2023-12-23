function [] = split_train_test()    
    clear;clc;
    load('PID.mat')
    load('eeg_data.mat')
    
    turn = 1;
    numpat = 0;
    unused = 1;
    unused_ids = [];
    training_ids = [];
    test_ids = [];
    
    for i = 1:size(eeg_data,2)
            data = eeg_data(i).Data;
            data = transpose(table2array(data));
    
             %round to nearest number divisible by 1000 which is 2 seconds
             cutoff = floor(size(data,2)/1000)*1000;
    
            n = floor(size(data,2)/1000);
            if isKey(PID, convertCharsToStrings(eeg_data(i).Patient_ID))
                if PID(convertCharsToStrings(eeg_data(i).Patient_ID)) == "responsive"
                    %labels = ones(n, 1) .* (-1).^(0:n-1)';
                    labels = ones(n, 1);
                    if mod(turn, 3) == 1
                        if exist('test_set', 'var')
                            test_set = horzcat(test_set, data(:,1:cutoff));
                            test_labels = vertcat(test_labels, labels);
                            test_ids = [test_ids; eeg_data(i).Patient_ID];
                        else
                            test_set = data(:,1:cutoff);
                            test_labels = labels;
                            test_ids = [test_ids; eeg_data(i).Patient_ID];
                        end 
                    else
                        if exist('training_set', 'var')
                            training_set = horzcat(training_set, data(:,1:cutoff));
                            training_labels = vertcat(training_labels,labels);
                            training_ids = [training_ids; eeg_data(i).Patient_ID];
                        else
                            training_set = data(:,1:cutoff);
                            training_labels = labels;
                            training_ids = [training_ids; eeg_data(i).Patient_ID];
                        end 
                    end
    
                else
                    labels = -1 * ones(n,1);
                     if mod(turn, 3) == 1
                        if exist('test_set', 'var')
                            test_set = horzcat(test_set, data(:,1:cutoff));
                            test_labels = vertcat(test_labels, labels);
                            test_ids = [test_ids; eeg_data(i).Patient_ID];
                        else
                            test_set = data(:,1:cutoff);
                            test_labels = labels;
                            test_ids = [test_ids; eeg_data(i).Patient_ID];
                        end 
                    else
                        if exist('training_set', 'var')
                            training_set = horzcat(training_set, data(:,1:cutoff));
                            training_labels = vertcat(training_labels,labels);
                            training_ids = [training_ids; eeg_data(i).Patient_ID];
                        else
                            training_set = data(:,1:cutoff);
                            training_labels = labels;
                            training_ids = [training_ids; eeg_data(i).Patient_ID];
                        end 
                    end
                end
                turn = turn + 1;
            else          
               numpat = numpat + 1;
               unused_ids = [unused_ids, eeg_data(i).Patient_ID];
               unused = unused + 1;
    
            end
    
            %temp_patient_IDs = struct("Patient_ID", eeg_data(i).Patient_ID, 'Trial_Num', size(labels));
            %patient_IDs(i) = temp_patient_IDs;
    
    end
    
    
    
    
    
    
    
    %% Split into trials 
    
    
    total_test_trials = size(test_set,2)/1000;
    total_train_trials = size(training_set,2)/1000;
    
    
    
    start = 1;
    finish = 1000;
    
    X = zeros(total_test_trials-1,32,1000);
    for i = 1:((total_test_trials)-1)
        X(i,:,:) = test_set(:,start:finish);
        start = start + 1000;
        finish = finish + 1000;
    end
    
    Y = test_labels(1:end-1);
    
    save('test.mat','X', "Y", '-v7.3')
    
    %%
    
    clear X
    clear Y
    
    start = 1;
    finish = 1000;
    X = zeros((total_train_trials-1),32,1000);
    for i = 1:((total_train_trials)-1)
        X(i,:,:) = training_set(:,start:finish);
        start = start + 1000;
        finish = finish + 1000;
    end
    
    Y = training_labels(1:end-1);
    
    save('train.mat','X', "Y",'-v7.3')


    save('training_ids','training_ids')
    save('test_ids','test_ids')
end