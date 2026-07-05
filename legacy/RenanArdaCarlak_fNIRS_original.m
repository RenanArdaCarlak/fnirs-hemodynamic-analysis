clear,clc,close all;

% Constants
    E_HbR_730nm = 1.1022; % Absorption Coefficient of HbR under the 730 nm wavelength InfraRed Light.
    E_HbR_850nm = 0.69132; % Absorption Coefficient of HbR under the 850 nm wavelength InfraRed Light.
    E_HbO_730nm = 0.39; % Absorption Coefficient of HbO under the 730 nm wavelength InfraRed Light.
    E_HbO_850nm = 1.058; % Absorption Coefficient of HbO under the 850 nm wavelength InfraRed Light.
    d = 2.5; % distance (in cm) between the Light Source (Led) and Photodetector
    DPF = 0.015;
    constants = d * DPF * [  E_HbR_730nm ,  E_HbO_730nm ; E_HbR_850nm , E_HbO_850nm ]; % Matrix of constants.
    inv_constants = inv(constants);

subjects.AllSubjects_AllExperiments_AllTrials_meanDeltaHbOconcentration = zeros(1, 16) ; % All mean data will be written in this variable.
subjects.AllSubjects_AllExperiments_AllTrials_meanDeltaHbOconcentrationF = zeros(1, 16) ; % All mean data will be written in this variable.

filename = cell( 9 , 8 , 11 ); % Filenames consist of different number of characters; and so, they can not create a character matrix. However, they can be stored in a cell array.
                                       % 9 for 3x3 trials and 8 for subjects.
                                       % 11 is for keeping dynamically produced character arrays which will be used for variable names under the subject struct.
                                       
subject = cell( 8 , 1 , 1 ); % Keeping dynamically produced subject names which can be consist of different number of characters.

for i = 1 : 8 % For subjects
    
    if i == 1 || i == 2 || i == 7 % In this data set there is no subject 1,2 and 7
        continue
    end
    
    for j = 1 : 9 % All subjects data should be unified under a file (which in this case I use the 'Subjects' file) to let the for loop can operates without any crash.
        % Dynamic filename producing
            if j >= 1 && j <= 3 % For 1BB
                filename{ j , i , 1 } = sprintf('Subject_%i_lightgraph%i.ref.Block%i_DATA,ONE.txt' , i,i,j+3 ); % Source filename.
                filename{ j , i , 2 } = sprintf('Subject_%i_lightgraph%i_ref_Block%i_DATA_1' , i,i,j+3 ); % Filename is purified from punctuation marks which can not be used as in struct notation.
                filename{ j , i , 3 } = sprintf('Subject_%i_deltaConcentration_Block%i_DATA_1' , i,j+3 ); % For relative concentration change of HbO and HbR.
                filename{ j , i , 4 } = sprintf('Subject_%i_deltaHbRConcentration_Block%i_DATA_1' , i,j+3 ); % For relative concentration change of HbR. 
                filename{ j , i , 5 } = sprintf('Subject_%i_deltaHbOConcentration_Block%i_DATA_1' , i,j+3 ); % For relative concentration change of HbO. 
                filename{ j , i , 6 } = sprintf('Subject_%i_mean_deltaHbOConcentration_Block%i_DATA_1' , i,j+3 ); % For mean relative concentration change of HbO. 
                filename{ j , i , 7 } = sprintf('Subject %i 1BB Block%i' , i , j+3); % For title.
                filename{ j , i , 8 } = sprintf('Subject_%i_deltaConcentration_Block%i_DATA_1_Filtered' , i,j+3 ); % For relative concentration change of HbO and HbR.
                filename{ j , i , 9 } = sprintf('Subject_%i_deltaHbRConcentration_Block%i_DATA_1_Filtered' , i,j+3 ); % For relative concentration change of HbR. 
                filename{ j , i , 10 } = sprintf('Subject_%i_deltaHbOConcentration_Block%i_DATA_1_Filtered' , i,j+3 ); % For relative concentration change of HbO. 
                filename{ j , i , 11 } = sprintf('Subject_%i_mean_deltaHbOConcentration_Block%i_DATA_1_Filtered' , i,j+3 ); % For mean relative concentration change of HbO.                 
            elseif j >= 4 && j <= 6 % For 2BB
                filename{ j , i , 1 } = sprintf('Subject_%i_lightgraph%i.ref.Block%i_DATA,TWO.txt' , i,i,j+3 ); % Source filename
                filename{ j , i , 2 } = sprintf('Subject_%i_lightgraph%i_ref_Block%i_DATA_2' , i,i,j+3 ); % Filename is purified from punctuation marks which can not be used as in struct notation.
                filename{ j , i , 3 } = sprintf('Subject_%i_deltaConcentration_Block%i_DATA_2' , i,j+3 ); % For relative concentration change of HbO and HbR.
                filename{ j , i , 4 } = sprintf('Subject_%i_deltaHbRConcentration_Block%i_DATA_2' , i,j+3 ); % For relative concentration change of HbR. 
                filename{ j , i , 5 } = sprintf('Subject_%i_deltaHbOConcentration_Block%i_DATA_2' , i,j+3 ); % For relative concentration change of HbO. 
                filename{ j , i , 6 } = sprintf('Subject_%i_mean_deltaHbOConcentration_Block%i_DATA_2' , i,j+3 ); % For mean relative concentration change of HbO.
                filename{ j , i , 7 } = sprintf('Subject %i 2BB Block%i' , i , j+3); % For title.
                filename{ j , i , 8 } = sprintf('Subject_%i_deltaConcentration_Block%i_DATA_2_Filtered' , i,j+3 ); % For relative concentration change of HbO and HbR.
                filename{ j , i , 9 } = sprintf('Subject_%i_deltaHbRConcentration_Block%i_DATA_2_Filtered' , i,j+3 ); % For relative concentration change of HbR. 
                filename{ j , i , 10 } = sprintf('Subject_%i_deltaHbOConcentration_Block%i_DATA_2_Filtered' , i,j+3 ); % For relative concentration change of HbO. 
                filename{ j , i , 11 } = sprintf('Subject_%i_mean_deltaHbOConcentration_Block%i_DATA_2_Filtered' , i,j+3 ); % For mean relative concentration change of HbO.                 
            elseif j >= 7 && j <= 9 % For 3BB
                filename{ j , i , 1 } = sprintf('Subject_%i_lightgraph%i.ref.Block%i_DATA,THREE.txt' , i,i,j+3 ); % Source filename
                filename{ j , i , 2 } = sprintf('Subject_%i_lightgraph%i_ref_Block%i_DATA_3' , i,i,j+3 ); % Filename is purified from punctuation marks which can not be used as in struct notation.
                filename{ j , i , 3 } = sprintf('Subject_%i_deltaConcentration_Block%i_DATA_3' , i,j+3 ); % For relative concentration change of HbO and HbR.
                filename{ j , i , 4 } = sprintf('Subject_%i_deltaHbRConcentration_Block%i_DATA_3' , i,j+3 ); % For relative concentration change of HbR. 
                filename{ j , i , 5 } = sprintf('Subject_%i_deltaHbOConcentration_Block%i_DATA_3' , i,j+3 ); % For relative concentration change of HbO. 
                filename{ j , i , 6 } = sprintf('Subject_%i_mean_deltaHbOConcentration_Block%i_DATA_3' , i,j+3 ); % For mean relative concentration change of HbO.
                filename{ j , i , 7 } = sprintf('Subject %i 3BB Block%i' , i , j+3); % For title.
                filename{ j , i , 8 } = sprintf('Subject_%i_deltaConcentration_Block%i_DATA_3_Filtered' , i,j+3 ); % For relative concentration change of HbO and HbR.
                filename{ j , i , 9 } = sprintf('Subject_%i_deltaHbRConcentration_Block%i_DATA_3_Filtered' , i,j+3 ); % For relative concentration change of HbR. 
                filename{ j , i , 10 } = sprintf('Subject_%i_deltaHbOConcentration_Block%i_DATA_3_Filtered' , i,j+3 ); % For relative concentration change of HbO. 
                filename{ j , i , 11 } = sprintf('Subject_%i_mean_deltaHbOConcentration_Block%i_DATA_3_Filtered' , i,j+3 ); % For mean relative concentration change of HbO. 
            end
        
            subject{ i } = [ 'subject' num2str(i) ];
        subjects.( subject{ i } ).( filename{ j , i , 2 } ) = importdata( filename{ j , i , 1 } ); % Import light intensity (after absorbtion) data which has converted to mV.
        
        % Butterworth Filtering for Physiological Noises
            LightIntensityFileSize = size( subjects.( subject{ i } ).( filename{ j , i , 2 } ).data );
            NumberofOptode = LightIntensityFileSize(1,2) / 3; % For each Optode there are three measurement which are belongs to 730 nm, Ambient and 850 nm.        
            for t = 1 : NumberofOptode
                fc = 0.05;
                fs = 2;
                [b,a] = butter(6,fc/(fs/2));
               % [b,a] = butter(6,[0.1 , 0.9]/(fs/2), 'bandpass');
                subjects.( subject{ i } ).( filename{ j , i , 2 } ).dataFiltered( : , 3*t - 2 ) = filtfilt(b,a, subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t - 2 )); % For 730 nm
                subjects.( subject{ i } ).( filename{ j , i , 2 } ).dataFiltered( : , 3*t - 1 ) = filtfilt(b,a, subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t - 1 )); % For Ambient
                subjects.( subject{ i } ).( filename{ j , i , 2 } ).dataFiltered( : , 3*t ) = filtfilt(b,a, subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t )); % For 850 nm
            end        

        % Motion Filtering 
            %Options
                % with 5 sec wind ow 
                    for t = 1 : NumberofOptode
                        subjects.( subject{ i } ).( filename{ j , i , 2 } ).dataCV_5( : , 3*t - 2 ) = (movstd( (subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t - 2 ))' , 10 ) ./ movmean( (subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t - 2 ))' , 10 ) )'; % For 730 nm
                        subjects.( subject{ i } ).( filename{ j , i , 2 } ).dataCV_5( : , 3*t - 1 ) = (movstd( (subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t - 1 ))' , 10 ) ./ movmean( (subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t - 1 ))' , 10 ) )'; % For Ambient
                        subjects.( subject{ i } ).( filename{ j , i , 2 } ).dataCV_5( : , 3*t ) = (movstd( (subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t ))' , 10 ) ./ movmean( (subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t ))' , 10 ) )'; % For 850 nm
                    end
                % with 10 sec window 
                    for t = 1 : NumberofOptode
                        subjects.( subject{ i } ).( filename{ j , i , 2 } ).dataCV_10( : , 3*t - 2 ) = (movstd( (subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t - 2 ))' , 20 ) ./ movmean( (subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t - 2 ))' , 20 ) )'; % For 730 nm
                        subjects.( subject{ i } ).( filename{ j , i , 2 } ).dataCV_10( : , 3*t - 1 ) = (movstd( (subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t - 1 ))' , 20 ) ./ movmean( (subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t - 1 ))' , 20 ) )'; % For Ambient
                        subjects.( subject{ i } ).( filename{ j , i , 2 } ).dataCV_10( : , 3*t ) = (movstd( (subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t ))' , 20 ) ./ movmean( (subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t ))' , 20 ) )'; % For 850 nm
                    end
                % with 15 sec window 
                    for t = 1 : NumberofOptode
                        subjects.( subject{ i } ).( filename{ j , i , 2 } ).dataCV_15( : , 3*t - 2 ) = (movstd( (subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t - 2 ))' , 30 ) ./ movmean( (subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t - 2 ))' , 30 ) )'; % For 730 nm
                        subjects.( subject{ i } ).( filename{ j , i , 2 } ).dataCV_15( : , 3*t - 1 ) = (movstd( (subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t - 1 ))' , 30 ) ./ movmean( (subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t - 1 ))' , 30 ) )'; % For Ambient
                        subjects.( subject{ i } ).( filename{ j , i , 2 } ).dataCV_15( : , 3*t ) = (movstd( (subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t ))' , 30 ) ./ movmean( (subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t ))' , 30 ) )'; % For 850 nm
                    end
            
        % MBLL Unfiltered
           LightIntensityFileSize = size( subjects.( subject{ i } ).( filename{ j , i , 2 } ).data );
           AmountofTimeFrame = LightIntensityFileSize(1,1); % Duration of the trial.
           NumberofOptode = LightIntensityFileSize(1,2) / 3; % For each Optode there are three measurement which are belongs to 730 nm, Ambient and 850 nm. 

           subjects.( subject{ i } ).( filename{ j , i , 3 } ) = zeros( NumberofOptode * 2 , AmountofTimeFrame - 10 ); % Each Optode has HBR and HBO concentrations. The format is row array. First 10 rows belongs to the baseline period. 
           subjects.( subject{ i } ).( filename{ j , i , 4 } ) = zeros( AmountofTimeFrame - 10 , NumberofOptode ); % For HbR. The format is column array.
           subjects.( subject{ i } ).( filename{ j , i , 5 } ) = zeros( AmountofTimeFrame - 10 , NumberofOptode ); % For HbO. The format is column array.
           subjects.( subject{ i } ).( filename{ j , i , 6 } ) = zeros( 1 , NumberofOptode ); % For mean HbO. The format is row array.
            
           p = 1; % p=1 and p+1=2 are the first Optode.
           q = 1; % The first Optode.
           for k = 1 : 3 : LightIntensityFileSize(1,2) - 2 % To jump to the next Optode's 730 nm column.               
               for m = 1 : AmountofTimeFrame - 10 % Time frame after baseline.
                   % First 10 rows belongs to the baseline period.
                   deltaOpticalDensity = [   log10(   mean( subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( 1:10 , k ) )   /   subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( 10+m , k )   )  ; ...
                                                       log10(   mean( subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( 1:10 , k+2 ) )   /   subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( 10+m , k+2 )   )   ]; % k is for 730 nm and k+2 is for 850 nm.
                        
                   subjects.( subject{ i } ).( filename{ j , i , 3 } )( p : p+1 , m ) = inv_constants * deltaOpticalDensity ; % p for HbR , p+1 for HbO. The format is row array.                              
                   subjects.( subject{ i } ).( filename{ j , i , 4 } )( m , q ) = subjects.( subject{ i } ).( filename{ j , i , 3 } )( p , m ); % For HbR. The format is column array.
                   subjects.( subject{ i } ).( filename{ j , i , 5 } )( m , q ) = subjects.( subject{ i } ).( filename{ j , i , 3 } )( p+1 , m ); % For HbO. The format is column array.
               end               
               subjects.( subject{ i } ).( filename{ j , i , 6 } )( 1 , q ) = mean(   subjects.( subject{ i } ).( filename{ j , i , 5 } )( : , q )   ); % Mean HbO. The format is row array.
               p = p+2; % Optode incrementer
               q = q+1; % Optode incrementer               
           end  
           
        % MBLL Physiological Noise Filtered
           LightIntensityFileSize = size( subjects.( subject{ i } ).( filename{ j , i , 2 } ).dataFiltered );
           AmountofTimeFrame = LightIntensityFileSize(1,1); % Duration of the trial.
           NumberofOptode = LightIntensityFileSize(1,2) / 3; % For each Optode there are three measurement which are belongs to 730 nm, Ambient and 850 nm. 

           subjects.( subject{ i } ).( filename{ j , i , 8 } ) = zeros( NumberofOptode * 2 , AmountofTimeFrame - 10 ); % Each Optode has HBR and HBO concentrations. The format is row array. First 10 rows belongs to the baseline period. 
           subjects.( subject{ i } ).( filename{ j , i , 9 } ) = zeros( AmountofTimeFrame - 10 , NumberofOptode ); % For HbR. The format is column array.
           subjects.( subject{ i } ).( filename{ j , i , 10 } ) = zeros( AmountofTimeFrame - 10 , NumberofOptode ); % For HbO. The format is column array.
           subjects.( subject{ i } ).( filename{ j , i , 11 } ) = zeros( 1 , NumberofOptode ); % For mean HbO. The format is row array.
            
           p = 1; % p=1 and p+1=2 are the first Optode.
           q = 1; % The first Optode.
           for k = 1 : 3 : LightIntensityFileSize(1,2) - 2 % To jump to the next Optode's 730 nm column.               
               for m = 1 : AmountofTimeFrame - 10 % Time frame after baseline.
                   % First 10 rows belongs to the baseline period.
                   deltaOpticalDensity = [   log10(   mean( subjects.( subject{ i } ).( filename{ j , i , 2 } ).dataFiltered( 1:10 , k ) )   /   subjects.( subject{ i } ).( filename{ j , i , 2 } ).dataFiltered( 10+m , k )   )  ; ...
                                                       log10(   mean( subjects.( subject{ i } ).( filename{ j , i , 2 } ).dataFiltered( 1:10 , k+2 ) )   /   subjects.( subject{ i } ).( filename{ j , i , 2 } ).dataFiltered( 10+m , k+2 )   )   ]; % k is for 730 nm and k+2 is for 850 nm.
                        
                   subjects.( subject{ i } ).( filename{ j , i , 8 } )( p : p+1 , m ) = inv_constants * deltaOpticalDensity ; % p for HbR , p+1 for HbO. The format is row array.                              
                   subjects.( subject{ i } ).( filename{ j , i , 9 } )( m , q ) = subjects.( subject{ i } ).( filename{ j , i , 8 } )( p , m ); % For HbR. The format is column array.
                   subjects.( subject{ i } ).( filename{ j , i , 10 } )( m , q ) = subjects.( subject{ i } ).( filename{ j , i , 8 } )( p+1 , m ); % For HbO. The format is column array.
               end               
               subjects.( subject{ i } ).( filename{ j , i , 11 } )( 1 , q ) = mean(   subjects.( subject{ i } ).( filename{ j , i , 10 } )( : , q )   ); % Mean HbO. The format is row array.
               p = p+2; % Optode incrementer
               q = q+1; % Optode incrementer               
           end
    end
    
    % Unfiltered Data
        subjects.( subject{ i } ).DeltaHbOconcentration_means_1BB = zeros ( 3 , NumberofOptode ); % To group 1BB trials of a subject.
        subjects.( subject{ i } ).DeltaHbOconcentration_means_2BB = zeros ( 3 , NumberofOptode ); % To group 2BB trials of a subject.
        subjects.( subject{ i } ).DeltaHbOconcentration_means_3BB = zeros ( 3 , NumberofOptode ); % To group 3BB trials of a subject.
        for r = 1 : 3
            subjects.( subject{ i } ).DeltaHbOconcentration_means_1BB(r , :) = subjects.( subject{ i } ).( filename{ r , i , 6 } ); % For block 4, 5, 6
            subjects.( subject{ i } ).DeltaHbOconcentration_means_2BB(r , :) = subjects.( subject{ i } ).( filename{ r+3 , i , 6 } ); % For block 7, 8, 9
            subjects.( subject{ i } ).DeltaHbOconcentration_means_3BB(r , :) = subjects.( subject{ i } ).( filename{ r+6 , i , 6 } ); % For block 10, 11, 12
        end

        subjects.( subject{ i } ).meanDeltaHbOconcentration_1BB = zeros ( 1 , NumberofOptode );
        subjects.( subject{ i } ).meanDeltaHbOconcentration_2BB = zeros ( 1 , NumberofOptode );
        subjects.( subject{ i } ).meanDeltaHbOconcentration_3BB = zeros ( 1 , NumberofOptode );
        for s = 1 : NumberofOptode
            subjects.( subject{ i } ).meanDeltaHbOconcentration_1BB( 1 , s ) = mean(   subjects.( subject{ i } ).DeltaHbOconcentration_means_1BB( 1:3 , s )   );
            subjects.( subject{ i } ).meanDeltaHbOconcentration_2BB( 1 , s ) = mean(   subjects.( subject{ i } ).DeltaHbOconcentration_means_2BB( 1:3 , s )   );
            subjects.( subject{ i } ).meanDeltaHbOconcentration_3BB( 1 , s ) = mean(   subjects.( subject{ i } ).DeltaHbOconcentration_means_3BB( 1:3 , s )   );
        end

        subjects.AllSubjects_AllExperiments_AllTrials_meanDeltaHbOconcentration = [ subjects.AllSubjects_AllExperiments_AllTrials_meanDeltaHbOconcentration;
                                                                                                                            subjects.( subject{ i } ).meanDeltaHbOconcentration_1BB;
                                                                                                                            subjects.( subject{ i } ).meanDeltaHbOconcentration_2BB;
                                                                                                                            subjects.( subject{ i } ).meanDeltaHbOconcentration_3BB ]; % All mean data is written in this variable.                                                                                              
                                                                                                                        
    % Physiological Noise Filtered Data
        subjects.( subject{ i } ).DeltaHbOconcentration_means_1BB_Filtered = zeros ( 3 , NumberofOptode ); % To group 1BB trials of a subject.
        subjects.( subject{ i } ).DeltaHbOconcentration_means_2BB_Filtered = zeros ( 3 , NumberofOptode ); % To group 2BB trials of a subject.
        subjects.( subject{ i } ).DeltaHbOconcentration_means_3BB_Filtered = zeros ( 3 , NumberofOptode ); % To group 3BB trials of a subject.
        for r = 1 : 3
            subjects.( subject{ i } ).DeltaHbOconcentration_means_1BB_Filtered(r , :) = subjects.( subject{ i } ).( filename{ r , i , 11 } ); % For block 4, 5, 6
            subjects.( subject{ i } ).DeltaHbOconcentration_means_2BB_Filtered(r , :) = subjects.( subject{ i } ).( filename{ r+3 , i , 11 } ); % For block 7, 8, 9
            subjects.( subject{ i } ).DeltaHbOconcentration_means_3BB_Filtered(r , :) = subjects.( subject{ i } ).( filename{ r+6 , i , 11 } ); % For block 10, 11, 12
        end

        subjects.( subject{ i } ).meanDeltaHbOconcentration_1BB_Filtered = zeros ( 1 , NumberofOptode );
        subjects.( subject{ i } ).meanDeltaHbOconcentration_2BB_Filtered = zeros ( 1 , NumberofOptode );
        subjects.( subject{ i } ).meanDeltaHbOconcentration_3BB_Filtered = zeros ( 1 , NumberofOptode );
        for s = 1 : NumberofOptode
            subjects.( subject{ i } ).meanDeltaHbOconcentration_1BB_Filtered( 1 , s ) = mean(   subjects.( subject{ i } ).DeltaHbOconcentration_means_1BB_Filtered( 1:3 , s )   );
            subjects.( subject{ i } ).meanDeltaHbOconcentration_2BB_Filtered( 1 , s ) = mean(   subjects.( subject{ i } ).DeltaHbOconcentration_means_2BB_Filtered( 1:3 , s )   );
            subjects.( subject{ i } ).meanDeltaHbOconcentration_3BB_Filtered( 1 , s ) = mean(   subjects.( subject{ i } ).DeltaHbOconcentration_means_3BB_Filtered( 1:3 , s )   );
        end

        subjects.AllSubjects_AllExperiments_AllTrials_meanDeltaHbOconcentrationF = [ subjects.AllSubjects_AllExperiments_AllTrials_meanDeltaHbOconcentrationF;
                                                                                                                            subjects.( subject{ i } ).meanDeltaHbOconcentration_1BB_Filtered;
                                                                                                                            subjects.( subject{ i } ).meanDeltaHbOconcentration_2BB_Filtered;
                                                                                                                            subjects.( subject{ i } ).meanDeltaHbOconcentration_3BB_Filtered ]; % All mean data is written in this variable.             
                                                                                                                        
    % Figuring Fourier Transformation
        for j = 1:9  % To choose the character array from the 'filename' variable 
            figure('units','normalized','outerposition',[0 0 1 1]);
                for t = 1 : NumberofOptode
                    if mod(t,2) == 1 % If t is odd.
                        index = floor(t/2) + 1; % For upper row of subplot.
                    else % If j is even.
                        index = t/2 + 8; % For lower row of subplot.
                    end
                    % For 730 nm
                        fft_RawData_730 = fft( subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t - 2 ) );
                        P2_730 = abs( fft_RawData_730 / length( subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t - 2 ) ) );
                        P1_730 = P2_730( 1:  length( subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t - 2 ) ) / 2 + 1 );
                        P1_730( 2 : end-1 ) = 2 * P1_730( 2 : end-1 );
                        frq_730 = 2 * (0:( length( subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t - 2 )  ) / 2 ) ) / length( subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t - 2 ) );                   
                    % For 850nm
                        fft_RawData_850 = fft( subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t ) );
                        P2_850 = abs( fft_RawData_850 / length( subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t ) ) );
                        P1_850 = P2_850( 1:  length( subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t ) ) / 2 + 1 );
                        P1_850( 2 : end-1 ) = 2 * P1_850( 2 : end-1 );
                        frq_850 = 2 * (0:( length( subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t )  ) / 2 ) ) / length( subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t ) );                    
                    subplot(2 , NumberofOptode/2 , index);
                        plot( frq_730 , P1_730 );
                        hold on;
                        plot( frq_850 , P1_850 );
                        grid on;
                        xlabel('Frequency (Hz)' , 'fontsize' , 8);
                        ylabel('Amplitude (|P1(frq)|)' , 'fontsize' , 8);
                        title( sprintf( 'Optode %i' , t ) , 'fontsize' , 8 ); % Dynamic titling.
                        hold off;
                end
                legend(' 730 nm' , '850 nm');
                sgtitle( [filename{ j , i , 7 } ' One Sided Amplitude Spectrum' ], 'fontsize' ,18 ); % Main Heading.                 
        end      
        
    % Figuring Raw & Physiological Noise Filtered Light Intensity Data    
        for j = 1 : 9 % To choose the character array from the 'filename' variable 
            figure('units','normalized','outerposition',[0 0 1 1]);
                for t = 1 : NumberofOptode
                    if mod(t,2) == 1 % If t is odd.
                        index = floor(t/2) + 1; % For upper row of subplot.
                    else % If j is even.
                        index = t/2 + 8; % For lower row of subplot.
                    end
                    subplot(2 , NumberofOptode/2 , index);
                        plot( subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t - 2 ) ); % For 730 nm.
                        hold on;
                        plot( subjects.( subject{ i } ).( filename{ j , i , 2 } ).dataFiltered( : , 3*t - 2 ) ); % For Filtered 730 nm.
                        %plot( subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t - 1 ) ); % For Ambient.
                        plot( subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t ) ) % For 850 nm.
                        plot( subjects.( subject{ i } ).( filename{ j , i , 2 } ).dataFiltered( : , 3*t ) ) % For Filtered 850 nm.                        
                        xlabel ( 'Time (sec/2)' , 'fontsize' , 8 ); % Data was collected in 2 Hz.
                        ylabel ( 'mV' , 'fontsize' , 8 ); % Device converts the light intensity to the mV after absorption.
                        title( sprintf( 'Optode %i' , t ) , 'fontsize' , 8 ); % Dynamic titling.
                        hold off;
                        axis( [ 0 length(subjects.( subject{ i } ).( filename{ j , i , 2 } ).data) min(subjects.( subject{ i } ).( filename{ j , i , 2 } ).data,[],'all') max(subjects.( subject{ i } ).( filename{ j , i , 2 } ).data,[],'all') ] ); % Make all plot's scales the same.
                end
                %legend( '730 nm' , 'Ambient' , '850 nm' ); 
                legend( '730 nm' , '730 nm Filtered' , '850 nm' , '850 nm Filtered' ); 
                sgtitle( [filename{ j , i , 7 } ' Light Intensity' ], 'fontsize' ,18 ); % Main Heading.                                                                                                              
        end      
        
    % Figuring Coeeficient of Variation of Different Window Sizes for Light Intensity Data    
        for j = 1 : 9 % To choose the character array from the 'filename' variable 
            figure('units','normalized','outerposition',[0 0 1 1]);
                for t = 1 : NumberofOptode
                    if mod(t,2) == 1 % If t is odd.
                        index = floor(t/2) + 1; % For upper row of subplot.
                    else % If j is even.
                        index = t/2 + 8; % For lower row of subplot.
                    end
                    subplot(2 , NumberofOptode/2 , index);
                        plot( subjects.( subject{ i } ).( filename{ j , i , 2 } ).dataCV_5( : , 3*t - 2 ) ); % CV with 5 sec window size for 730 nm.
                        hold on;
                        plot( subjects.( subject{ i } ).( filename{ j , i , 2 } ).dataCV_10( : , 3*t - 2 ) ); % CV with 10 sec window size for 730 nm.
                        plot( subjects.( subject{ i } ).( filename{ j , i , 2 } ).dataCV_15( : , 3*t - 2 ) ); % CV with 15 sec window size for 730 nm.
%                         plot (subjects.( subject{ i } ).( filename{ j , i , 2 } ).dataCV_5( : , 3*t )) % CV with 5 sec window size for 850 nm.
%                         plot (subjects.( subject{ i } ).( filename{ j , i , 2 } ).dataCV_10( : , 3*t )) % CV with 10 sec window size for 850 nm.
%                         plot (subjects.( subject{ i } ).( filename{ j , i , 2 } ).dataCV_15( : , 3*t )) % CV with 15 sec window size for 850 nm.
                        xlabel ( 'Time (sec/2)' , 'fontsize' , 8 ); % Data was collected in 2 Hz.
                        ylabel ( 'Coeeficient of Variaton' , 'fontsize' , 8 ); 
                        title( sprintf( 'Optode %i' , t ) , 'fontsize' , 8 ); % Dynamic titling.
                        hold off;
                        axis( [ 0 length(subjects.( subject{ i } ).( filename{ j , i , 2 } ).dataCV_5) min(subjects.( subject{ i } ).( filename{ j , i , 2 } ).dataCV_15,[],'all') max(subjects.( subject{ i } ).( filename{ j , i , 2 } ).dataCV_15,[],'all') ] ); % Make all plot's scales the same.
                end
                legend( '730 nm 5 sec' , '730 nm 10 sec' , '730 nm 15 sec', '850 nm 5 sec' , '850 nm 10 sec' , '850 nm 15 sec' ); 
                sgtitle( [filename{ j , i , 7 } ' Light Intensity Coefficient of Variation' ], 'fontsize' ,18 ); % Main Heading.                                                                                                              
        end      

    % Figuring Raw Data & Coefficient of Variation of Subject 3 & 4
        figure('units','normalized','outerposition',[0 0 1 1]);
            % Subject 3, 2BB, Block 8, Optode 14
                % Raw Data
                    subplot(2,2,1);
                        plot( subjects.( subject{ 3 } ).( filename{ 5 , 3 , 2 } ).data( : , 3*14 - 2 ) ); % Raw Data For 730 nm
                        hold on;
                        plot( subjects.( subject{ 3 } ).( filename{ 5 , 3 , 2 } ).data( : , 3*14 ) ); % Raw Data For 850 nm
                        grid on;
                        xlabel ( 'Time (sec/2)' , 'fontsize' , 8 ); % Data was collected in 2 Hz.
                        ylabel ( 'mV' , 'fontsize' , 8 ); % Device converts the light intensity to the mV after absorption.
                        title( 'Subject 3 2BB Block 8 Optode 14 Light Intensity' );
                % Coefficient of Variation    
                    subplot(2,2,3);
                        plot( subjects.( subject{ 3 } ).( filename{ 5 , 3 , 2 } ).dataCV_5( : , 3*14 - 2 ) ); % CV with 5 sec window size for 730 nm.
                        hold on;
                        plot( subjects.( subject{ 3 } ).( filename{ 5 , 3 , 2 } ).dataCV_5( : , 3*14 ) ); % CV with 5 sec window size for 850 nm. 
                        grid on;
                        xlabel ( 'Time (sec/2)' , 'fontsize' , 8 ); % Data was collected in 2 Hz.
                        ylabel ( 'Coeeficient of Variaton' , 'fontsize' , 8 ); 
            % Subject 4, 3BB, Block 10, Optode 14
                % Raw Data
                    subplot(2,2,2);
                        plot( subjects.( subject{ 4 } ).( filename{ 7 , 4 , 2 } ).data( : , 3*14 - 2 ) ); % Raw Data For 730 nm
                        hold on;
                        plot( subjects.( subject{ 4 } ).( filename{ 7 , 4 , 2 } ).data( : , 3*14 ) ); % Raw Data For 850 nm
                        grid on;
                        xlabel ( 'Time (sec/2)' , 'fontsize' , 8 ); % Data was collected in 2 Hz.
                        ylabel ( 'mV' , 'fontsize' , 8 ); % Device converts the light intensity to the mV after absorption.
                        title( 'Subject 4 3BB Block 10 Optode 14 Light Intensity' );
                % Coefficient of Variation    
                    subplot(2,2,4);
                        plot( subjects.( subject{ 4 } ).( filename{ 7 , 4 , 2 } ).dataCV_5( : , 3*14 - 2 ) ); % CV with 5 sec window size for 730 nm.
                        hold on;
                        plot( subjects.( subject{ 4 } ).( filename{ 7 , 4 , 2 } ).dataCV_5( : , 3*14 ) ); % CV with 5 sec window size for 850 nm. 
                        grid on;
                        xlabel ( 'Time (sec/2)' , 'fontsize' , 8 ); % Data was collected in 2 Hz.
                        ylabel ( 'Coeeficient of Variaton' , 'fontsize' , 8 ); 
            legend( '730 nm' , '850 nm' ); 
        
    % Figuring Unfiltered & Physiological Noise Filtered HbR and HbO Concentration Changes Over Each Optode
        for j = 1 : 9 % To choose the character array from the 'filename' variable 
            figure( 'units' , 'normalized' , 'outerposition' , [0 0 1 1] );
                 for t = 1 : NumberofOptode 
                    if mod(t,2) == 1 % If t is odd.
                        index = floor(t/2) + 1; % For upper row of subplot.
                    else % If t is even.
                        index = t/2 + 8; % For lower row of subplot.
                    end
                    subplot(2, NumberofOptode/2 , index);
                        plot( subjects.( subject{ i } ).( filename{ j , i , 5 } )( : , t ) , 'r' ); % For HbO.
                        hold on;
                        plot( subjects.( subject{ i } ).( filename{ j , i , 10 } )( : , t ) , 'r-.' ); % For Filtered HbO.
                        plot( subjects.( subject{ i } ).( filename{ j , i , 4 } )( : , t ) ,'b' ); % For HbR.
                        plot( subjects.( subject{ i } ).( filename{ j , i , 9 } )( : , t ) ,'b-.' ); % For Filtered HbR.
                        xlabel('Time (sec/2)' , 'fontsize' , 8); % Data was collected in 2 Hz.
                        ylabel('Relative Concentration Change (Micro Molar / Liter');
                        title( sprintf( 'Optode %i' , t ) , 'fontsize' , 8 ); % Dynamic titling.
                        hold off;
                        axis( [ 0 length(subjects.( subject{ i } ).( filename{ j , i , 3 } )) min(subjects.( subject{ i } ).( filename{ j , i , 3 } ),[],'all') max(subjects.( subject{ i } ).( filename{ j , i , 3 } ),[],'all') ] ); % Make all plot's scales the same.
                 end
                 legend('HbO' , 'HbO Filtered' , 'HbR' , 'HbR Filtered');
                 sgtitle( filename{ j , i , 7 } , 'fontsize' ,18 ); % Main Heading.
        end                                                                                                                    
                                                                                                                    
end

% Unfiltered Data
    subjects.AllSubjects_AllExperiments_AllTrials_meanDeltaHbOconcentration( 1 , : ) = []; % Deleting first row which was created with zeros function  
    % All mean HbO data is placed into Optode variables 
        for i = 1 : NumberofOptode
            eval( sprintf( 'Optode%i = subjects.AllSubjects_AllExperiments_AllTrials_meanDeltaHbOconcentration( : , %i )' , i , i ) );
        end

    Block = [ 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 ]';
    Subject = [ 3 3 3 4 4 4 5 5 5 6 6 6 8 8 8 ]';
    subjects.AllSubjects_AllExperiments_AllTrials_meanDeltaHbOconcentrationT = table(Subject , Block , Optode1 , Optode2 , Optode3 , Optode4 , Optode5 , Optode6 , Optode7 , Optode8 , Optode9 , Optode10 , Optode11 , Optode12 , Optode13 , Optode14 , Optode15 , Optode16);
    openvar('subjects.AllSubjects_AllExperiments_AllTrials_meanDeltaHbOconcentrationT');

    % Grouping 1BB, 2BB and 3BB 
        for i = 1 : NumberofOptode
            eval( sprintf( ' Optode%i_1BB = zeros(7,1) ' , i ) ); % 1:5 for Subjects 3,4,5,6 and 8; 6 for mean of subjects' data; 7 for std error. 
            eval( sprintf( ' Optode%i_2BB = zeros(7,1) ' , i ) ); % 1:5 for Subjects 3,4,5,6 and 8; 6 for mean of subjects' data; 7 for std error. 
            eval( sprintf( ' Optode%i_3BB = zeros(7,1) ' , i ) ); % 1:5 for Subjects 3,4,5,6 and 8; 6 for mean of subjects' data; 7 for std error. 
            k = 1; % For 1BB
            l = 2; % For 2BB
            m = 3; % For 3BB
            for j = 1 : 5 % For subjects
                eval( sprintf( ' Optode%i_1BB(%i) = subjects.AllSubjects_AllExperiments_AllTrials_meanDeltaHbOconcentration( %i , %i ) ' , i , j , k , i ) );
                eval( sprintf( ' Optode%i_2BB(%i) = subjects.AllSubjects_AllExperiments_AllTrials_meanDeltaHbOconcentration( %i , %i ) ' , i , j , l , i ) );
                eval( sprintf( ' Optode%i_3BB(%i) = subjects.AllSubjects_AllExperiments_AllTrials_meanDeltaHbOconcentration( %i , %i ) ' , i , j , m , i ) );
                k = k+3; % To jump on next 1BB data.
                l = l+3; % To jump on next 2BB data.
                m = m+3; % To jump on next 3BB data.
            end
            % Mean
                eval( sprintf( ' Optode%i_1BB(6) = mean( Optode%i_1BB( 1:5 ) ) ' , i , i ) );
                eval( sprintf( ' Optode%i_2BB(6) = mean( Optode%i_2BB( 1:5 ) ) ' , i , i ) );
                eval( sprintf( ' Optode%i_3BB(6) = mean( Optode%i_3BB( 1:5 ) ) ' , i , i ) );
            % Std Error
                eval( sprintf( ' Optode%i_1BB(7) = sqrt( (   ( Optode%i_1BB(6) - Optode%i_1BB(1) )^2 + ( Optode%i_1BB(6) - Optode%i_1BB(2) )^2 + ( Optode%i_1BB(6) - Optode%i_1BB(3) )^2 + ( Optode%i_1BB(6) - Optode%i_1BB(4) )^2 + ( Optode%i_1BB(6) - Optode%i_1BB(5) )^2   ) / 5 )   /   sqrt(5)  '  , i , i , i , i , i , i , i , i , i , i , i ) );
                eval( sprintf( ' Optode%i_2BB(7) = sqrt( (   ( Optode%i_2BB(6) - Optode%i_2BB(1) )^2 + ( Optode%i_2BB(6) - Optode%i_2BB(2) )^2 + ( Optode%i_2BB(6) - Optode%i_2BB(3) )^2 + ( Optode%i_2BB(6) - Optode%i_2BB(4) )^2 + ( Optode%i_2BB(6) - Optode%i_2BB(5) )^2   ) / 5 )   /   sqrt(5)  '  , i , i , i , i , i , i , i , i , i , i , i ) );
                eval( sprintf( ' Optode%i_3BB(7) = sqrt( (   ( Optode%i_3BB(6) - Optode%i_3BB(1) )^2 + ( Optode%i_3BB(6) - Optode%i_3BB(2) )^2 + ( Optode%i_3BB(6) - Optode%i_3BB(3) )^2 + ( Optode%i_3BB(6) - Optode%i_3BB(4) )^2 + ( Optode%i_3BB(6) - Optode%i_3BB(5) )^2   ) / 5 )   /   sqrt(5)  '  , i , i , i , i , i , i , i , i , i , i , i ) );
        end

        Subject = { '3' '4' '5' '6' '8' 'mean' 'std error' }';
        subjects.AllSubjects_1BB_AllTrials_meanDeltaHbOconcentrationT = table(Subject , Optode1_1BB , Optode2_1BB , Optode3_1BB , Optode4_1BB , Optode5_1BB , Optode6_1BB , Optode7_1BB , Optode8_1BB , Optode9_1BB , Optode10_1BB , Optode11_1BB , Optode12_1BB , Optode13_1BB , Optode14_1BB , Optode15_1BB , Optode16_1BB);
        subjects.AllSubjects_2BB_AllTrials_meanDeltaHbOconcentrationT = table(Subject , Optode1_2BB , Optode2_2BB , Optode3_2BB , Optode4_2BB , Optode5_2BB , Optode6_2BB , Optode7_2BB , Optode8_2BB , Optode9_2BB , Optode10_2BB , Optode11_2BB , Optode12_2BB , Optode13_2BB , Optode14_2BB , Optode15_2BB , Optode16_2BB);
        subjects.AllSubjects_3BB_AllTrials_meanDeltaHbOconcentrationT = table(Subject , Optode1_3BB , Optode2_3BB , Optode3_3BB , Optode4_3BB , Optode5_3BB , Optode6_3BB , Optode7_3BB , Optode8_3BB , Optode9_3BB , Optode10_3BB , Optode11_3BB , Optode12_3BB , Optode13_3BB , Optode14_3BB , Optode15_3BB , Optode16_3BB);

    %Bar Chart
        optodes = categorical( { 'Opt1-1BB' 'Opt2-1BB' 'Opt3-1BB' 'Opt4-1BB' 'Opt5-1BB' 'Opt6-1BB' 'Opt7-1BB' 'Opt8-1BB' 'Opt9-1BB' 'Opt10-1BB' 'Opt11-1BB' 'Opt12-1BB' 'Opt13-1BB' 'Opt14-1BB' 'Opt15-1BB' 'Opt16-1BB' ; ... 
                                           'Opt1-2BB' 'Opt2-2BB' 'Opt3-2BB' 'Opt4-2BB' 'Opt5-2BB' 'Opt6-2BB' 'Opt7-2BB' 'Opt8-2BB' 'Opt9-2BB' 'Opt10-2BB' 'Opt11-2BB' 'Opt12-2BB' 'Opt13-2BB' 'Opt14-2BB' 'Opt15-2BB' 'Opt16-2BB' ; ...                                            
                                           'Opt1-3BB' 'Opt2-3BB' 'Opt3-3BB' 'Opt4-3BB' 'Opt5-3BB' 'Opt6-3BB' 'Opt7-3BB' 'Opt8-3BB' 'Opt9-3BB' 'Opt10-3BB' 'Opt11-3BB' 'Opt12-3BB' 'Opt13-3BB' 'Opt14-3BB' 'Opt15-3BB' 'Opt16-3BB' } ) ; 

        optodes = reordercats( optodes, { 'Opt1-1BB' 'Opt2-1BB' 'Opt3-1BB' 'Opt4-1BB' 'Opt5-1BB' 'Opt6-1BB' 'Opt7-1BB' 'Opt8-1BB' 'Opt9-1BB' 'Opt10-1BB' 'Opt11-1BB' 'Opt12-1BB' 'Opt13-1BB' 'Opt14-1BB' 'Opt15-1BB' 'Opt16-1BB' ; ... 
                                                         'Opt1-2BB' 'Opt2-2BB' 'Opt3-2BB' 'Opt4-2BB' 'Opt5-2BB' 'Opt6-2BB' 'Opt7-2BB' 'Opt8-2BB' 'Opt9-2BB' 'Opt10-2BB' 'Opt11-2BB' 'Opt12-2BB' 'Opt13-2BB' 'Opt14-2BB' 'Opt15-2BB' 'Opt16-2BB' ; ...                                            
                                                         'Opt1-3BB' 'Opt2-3BB' 'Opt3-3BB' 'Opt4-3BB' 'Opt5-3BB' 'Opt6-3BB' 'Opt7-3BB' 'Opt8-3BB' 'Opt9-3BB' 'Opt10-3BB' 'Opt11-3BB' 'Opt12-3BB' 'Opt13-3BB' 'Opt14-3BB' 'Opt15-3BB' 'Opt16-3BB' } ) ; 

        means = [ Optode1_1BB(6) Optode2_1BB(6) Optode3_1BB(6) Optode4_1BB(6) Optode5_1BB(6) Optode6_1BB(6) Optode7_1BB(6) Optode8_1BB(6) Optode9_1BB(6) Optode10_1BB(6) Optode11_1BB(6) Optode12_1BB(6) Optode13_1BB(6) Optode14_1BB(6) Optode15_1BB(6) Optode16_1BB(6) ; ...
                        Optode1_2BB(6) Optode2_2BB(6) Optode3_2BB(6) Optode4_2BB(6) Optode5_2BB(6) Optode6_2BB(6) Optode7_2BB(6) Optode8_2BB(6) Optode9_2BB(6) Optode10_2BB(6) Optode11_2BB(6) Optode12_2BB(6) Optode13_2BB(6) Optode14_2BB(6) Optode15_2BB(6) Optode16_2BB(6) ; ...      
                        Optode1_3BB(6) Optode2_3BB(6) Optode3_3BB(6) Optode4_3BB(6) Optode5_3BB(6) Optode6_3BB(6) Optode7_3BB(6) Optode8_3BB(6) Optode9_3BB(6) Optode10_3BB(6) Optode11_3BB(6) Optode12_3BB(6) Optode13_3BB(6) Optode14_3BB(6) Optode15_3BB(6) Optode16_3BB(6) ] ;                             

        stdErrors = [ Optode1_1BB(7) Optode2_1BB(7) Optode3_1BB(7) Optode4_1BB(7) Optode5_1BB(7) Optode6_1BB(7) Optode7_1BB(7) Optode8_1BB(7) Optode9_1BB(7) Optode10_1BB(7) Optode11_1BB(7) Optode12_1BB(7) Optode13_1BB(7) Optode14_1BB(7) Optode15_1BB(7) Optode16_1BB(7) ; ...
                           Optode1_2BB(7) Optode2_2BB(7) Optode3_2BB(7) Optode4_2BB(7) Optode5_2BB(7) Optode6_2BB(7) Optode7_2BB(7) Optode8_2BB(7) Optode9_2BB(7) Optode10_2BB(7) Optode11_2BB(7) Optode12_2BB(7) Optode13_2BB(7) Optode14_2BB(7) Optode15_2BB(7) Optode16_2BB(7) ; ...      
                           Optode1_3BB(7) Optode2_3BB(7) Optode3_3BB(7) Optode4_3BB(7) Optode5_3BB(7) Optode6_3BB(7) Optode7_3BB(7) Optode8_3BB(7) Optode9_3BB(7) Optode10_3BB(7) Optode11_3BB(7) Optode12_3BB(7) Optode13_3BB(7) Optode14_3BB(7) Optode15_3BB(7) Optode16_3BB(7) ] ;                             

        figure( 'units' , 'normalized' , 'outerposition' , [0 0 1 1] );
            bar( optodes , means , 4);
            hold on;
            errorbar( optodes , means , stdErrors , 'ko' );
            ylabel('Average Delta HbO Conccentration');
            hold off;
            title('Unfiltered Data');
                            
% Physiological Noise Filtered Data
    subjects.AllSubjects_AllExperiments_AllTrials_meanDeltaHbOconcentrationF( 1 , : ) = []; % Deleting first row which was created with zeros function  
    % All mean HbO data is placed into Optode variables 
        for i = 1 : NumberofOptode
            eval( sprintf( 'Optode%iF = subjects.AllSubjects_AllExperiments_AllTrials_meanDeltaHbOconcentrationF( : , %i )' , i , i ) );
        end

    Block = [ 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 ]';
    Subject = [ 3 3 3 4 4 4 5 5 5 6 6 6 8 8 8 ]';
    subjects.AllSubjects_AllExperiments_AllTrials_meanDeltaHbOconcF_T = table(Subject , Block , Optode1F , Optode2F , Optode3F , Optode4F , Optode5F , Optode6F , Optode7F , Optode8F , Optode9F , Optode10F , Optode11F , Optode12F , Optode13F , Optode14F , Optode15F , Optode16F);
    openvar('subjects.AllSubjects_AllExperiments_AllTrials_meanDeltaHbOconcF_T');

    % Grouping 1BB, 2BB and 3BB 
        for i = 1 : NumberofOptode
            eval( sprintf( ' Optode%iF_1BB = zeros(7,1) ' , i ) ); % 1:5 for Subjects 3,4,5,6 and 8; 6 for mean of subjects' data; 7 for std error. 
            eval( sprintf( ' Optode%iF_2BB = zeros(7,1) ' , i ) ); % 1:5 for Subjects 3,4,5,6 and 8; 6 for mean of subjects' data; 7 for std error. 
            eval( sprintf( ' Optode%iF_3BB = zeros(7,1) ' , i ) ); % 1:5 for Subjects 3,4,5,6 and 8; 6 for mean of subjects' data; 7 for std error. 
            k = 1; % For 1BB
            l = 2; % For 2BB
            m = 3; % For 3BB
            for j = 1 : 5 % For subjects
                eval( sprintf( ' Optode%iF_1BB(%i) = subjects.AllSubjects_AllExperiments_AllTrials_meanDeltaHbOconcentrationF( %i , %i ) ' , i , j , k , i ) );
                eval( sprintf( ' Optode%iF_2BB(%i) = subjects.AllSubjects_AllExperiments_AllTrials_meanDeltaHbOconcentrationF( %i , %i ) ' , i , j , l , i ) );
                eval( sprintf( ' Optode%iF_3BB(%i) = subjects.AllSubjects_AllExperiments_AllTrials_meanDeltaHbOconcentrationF( %i , %i ) ' , i , j , m , i ) );
                k = k+3; % To jump on next 1BB data.
                l = l+3; % To jump on next 2BB data.
                m = m+3; % To jump on next 3BB data.
            end
            % Mean
                eval( sprintf( ' Optode%iF_1BB(6) = mean( Optode%iF_1BB( 1:5 ) ) ' , i , i ) );
                eval( sprintf( ' Optode%iF_2BB(6) = mean( Optode%iF_2BB( 1:5 ) ) ' , i , i ) );
                eval( sprintf( ' Optode%iF_3BB(6) = mean( Optode%iF_3BB( 1:5 ) ) ' , i , i ) );
            % Std Error
                eval( sprintf( ' Optode%iF_1BB(7) = sqrt( (   ( Optode%iF_1BB(6) - Optode%iF_1BB(1) )^2 + ( Optode%iF_1BB(6) - Optode%iF_1BB(2) )^2 + ( Optode%iF_1BB(6) - Optode%iF_1BB(3) )^2 + ( Optode%iF_1BB(6) - Optode%iF_1BB(4) )^2 + ( Optode%iF_1BB(6) - Optode%iF_1BB(5) )^2   ) / 5 )   /   sqrt(5)  '  , i , i , i , i , i , i , i , i , i , i , i ) );
                eval( sprintf( ' Optode%iF_2BB(7) = sqrt( (   ( Optode%iF_2BB(6) - Optode%iF_2BB(1) )^2 + ( Optode%iF_2BB(6) - Optode%iF_2BB(2) )^2 + ( Optode%iF_2BB(6) - Optode%iF_2BB(3) )^2 + ( Optode%iF_2BB(6) - Optode%iF_2BB(4) )^2 + ( Optode%iF_2BB(6) - Optode%iF_2BB(5) )^2   ) / 5 )   /   sqrt(5)  '  , i , i , i , i , i , i , i , i , i , i , i ) );
                eval( sprintf( ' Optode%iF_3BB(7) = sqrt( (   ( Optode%iF_3BB(6) - Optode%iF_3BB(1) )^2 + ( Optode%iF_3BB(6) - Optode%iF_3BB(2) )^2 + ( Optode%iF_3BB(6) - Optode%iF_3BB(3) )^2 + ( Optode%iF_3BB(6) - Optode%iF_3BB(4) )^2 + ( Optode%iF_3BB(6) - Optode%iF_3BB(5) )^2   ) / 5 )   /   sqrt(5)  '  , i , i , i , i , i , i , i , i , i , i , i ) );
        end

        Subject = { '3' '4' '5' '6' '8' 'mean' 'std error' }';
        subjects.AllSubjects_1BB_AllTrials_meanDeltaHbOconcentrationFT = table(Subject , Optode1F_1BB , Optode2F_1BB , Optode3F_1BB , Optode4F_1BB , Optode5F_1BB , Optode6F_1BB , Optode7F_1BB , Optode8F_1BB , Optode9F_1BB , Optode10F_1BB , Optode11F_1BB , Optode12F_1BB , Optode13F_1BB , Optode14F_1BB , Optode15F_1BB , Optode16F_1BB);
        subjects.AllSubjects_2BB_AllTrials_meanDeltaHbOconcentrationFT = table(Subject , Optode1F_2BB , Optode2F_2BB , Optode3F_2BB , Optode4F_2BB , Optode5F_2BB , Optode6F_2BB , Optode7F_2BB , Optode8F_2BB , Optode9F_2BB , Optode10F_2BB , Optode11F_2BB , Optode12F_2BB , Optode13F_2BB , Optode14F_2BB , Optode15F_2BB , Optode16F_2BB);
        subjects.AllSubjects_3BB_AllTrials_meanDeltaHbOconcentrationFT = table(Subject , Optode1F_3BB , Optode2F_3BB , Optode3F_3BB , Optode4F_3BB , Optode5F_3BB , Optode6F_3BB , Optode7F_3BB , Optode8F_3BB , Optode9F_3BB , Optode10F_3BB , Optode11F_3BB , Optode12F_3BB , Optode13F_3BB , Optode14F_3BB , Optode15F_3BB , Optode16F_3BB);

    %Bar Chart
        optodes = categorical( { 'Opt1-1BB' 'Opt2-1BB' 'Opt3-1BB' 'Opt4-1BB' 'Opt5-1BB' 'Opt6-1BB' 'Opt7-1BB' 'Opt8-1BB' 'Opt9-1BB' 'Opt10-1BB' 'Opt11-1BB' 'Opt12-1BB' 'Opt13-1BB' 'Opt14-1BB' 'Opt15-1BB' 'Opt16-1BB' ; ... 
                                           'Opt1-2BB' 'Opt2-2BB' 'Opt3-2BB' 'Opt4-2BB' 'Opt5-2BB' 'Opt6-2BB' 'Opt7-2BB' 'Opt8-2BB' 'Opt9-2BB' 'Opt10-2BB' 'Opt11-2BB' 'Opt12-2BB' 'Opt13-2BB' 'Opt14-2BB' 'Opt15-2BB' 'Opt16-2BB' ; ...                                            
                                           'Opt1-3BB' 'Opt2-3BB' 'Opt3-3BB' 'Opt4-3BB' 'Opt5-3BB' 'Opt6-3BB' 'Opt7-3BB' 'Opt8-3BB' 'Opt9-3BB' 'Opt10-3BB' 'Opt11-3BB' 'Opt12-3BB' 'Opt13-3BB' 'Opt14-3BB' 'Opt15-3BB' 'Opt16-3BB' } ) ; 

        optodes = reordercats( optodes, { 'Opt1-1BB' 'Opt2-1BB' 'Opt3-1BB' 'Opt4-1BB' 'Opt5-1BB' 'Opt6-1BB' 'Opt7-1BB' 'Opt8-1BB' 'Opt9-1BB' 'Opt10-1BB' 'Opt11-1BB' 'Opt12-1BB' 'Opt13-1BB' 'Opt14-1BB' 'Opt15-1BB' 'Opt16-1BB' ; ... 
                                                         'Opt1-2BB' 'Opt2-2BB' 'Opt3-2BB' 'Opt4-2BB' 'Opt5-2BB' 'Opt6-2BB' 'Opt7-2BB' 'Opt8-2BB' 'Opt9-2BB' 'Opt10-2BB' 'Opt11-2BB' 'Opt12-2BB' 'Opt13-2BB' 'Opt14-2BB' 'Opt15-2BB' 'Opt16-2BB' ; ...                                            
                                                         'Opt1-3BB' 'Opt2-3BB' 'Opt3-3BB' 'Opt4-3BB' 'Opt5-3BB' 'Opt6-3BB' 'Opt7-3BB' 'Opt8-3BB' 'Opt9-3BB' 'Opt10-3BB' 'Opt11-3BB' 'Opt12-3BB' 'Opt13-3BB' 'Opt14-3BB' 'Opt15-3BB' 'Opt16-3BB' } ) ; 

        means = [ Optode1F_1BB(6) Optode2F_1BB(6) Optode3F_1BB(6) Optode4F_1BB(6) Optode5F_1BB(6) Optode6F_1BB(6) Optode7F_1BB(6) Optode8F_1BB(6) Optode9F_1BB(6) Optode10F_1BB(6) Optode11F_1BB(6) Optode12F_1BB(6) Optode13F_1BB(6) Optode14F_1BB(6) Optode15F_1BB(6) Optode16F_1BB(6) ; ...
                        Optode1F_2BB(6) Optode2F_2BB(6) Optode3F_2BB(6) Optode4F_2BB(6) Optode5F_2BB(6) Optode6F_2BB(6) Optode7F_2BB(6) Optode8F_2BB(6) Optode9F_2BB(6) Optode10F_2BB(6) Optode11F_2BB(6) Optode12F_2BB(6) Optode13F_2BB(6) Optode14F_2BB(6) Optode15F_2BB(6) Optode16F_2BB(6) ; ...      
                        Optode1F_3BB(6) Optode2F_3BB(6) Optode3F_3BB(6) Optode4F_3BB(6) Optode5F_3BB(6) Optode6F_3BB(6) Optode7F_3BB(6) Optode8F_3BB(6) Optode9F_3BB(6) Optode10F_3BB(6) Optode11F_3BB(6) Optode12F_3BB(6) Optode13F_3BB(6) Optode14F_3BB(6) Optode15F_3BB(6) Optode16F_3BB(6) ] ;                             

        stdErrors = [ Optode1F_1BB(7) Optode2F_1BB(7) Optode3F_1BB(7) Optode4F_1BB(7) Optode5F_1BB(7) Optode6F_1BB(7) Optode7F_1BB(7) Optode8F_1BB(7) Optode9F_1BB(7) Optode10F_1BB(7) Optode11F_1BB(7) Optode12F_1BB(7) Optode13F_1BB(7) Optode14F_1BB(7) Optode15F_1BB(7) Optode16F_1BB(7) ; ...
                           Optode1F_2BB(7) Optode2F_2BB(7) Optode3F_2BB(7) Optode4F_2BB(7) Optode5F_2BB(7) Optode6F_2BB(7) Optode7F_2BB(7) Optode8F_2BB(7) Optode9F_2BB(7) Optode10F_2BB(7) Optode11F_2BB(7) Optode12F_2BB(7) Optode13F_2BB(7) Optode14F_2BB(7) Optode15F_2BB(7) Optode16F_2BB(7) ; ...      
                           Optode1F_3BB(7) Optode2F_3BB(7) Optode3F_3BB(7) Optode4F_3BB(7) Optode5F_3BB(7) Optode6F_3BB(7) Optode7F_3BB(7) Optode8F_3BB(7) Optode9F_3BB(7) Optode10F_3BB(7) Optode11F_3BB(7) Optode12F_3BB(7) Optode13F_3BB(7) Optode14F_3BB(7) Optode15F_3BB(7) Optode16F_3BB(7) ] ;                             

        figure( 'units' , 'normalized' , 'outerposition' , [0 0 1 1] );
            bar( optodes , means , 4);
            hold on;
            errorbar( optodes , means , stdErrors , 'ko' );
            ylabel('Average Delta HbO Conccentration');
            hold off;
            title('Physiological Noise Filtered Data');
            
