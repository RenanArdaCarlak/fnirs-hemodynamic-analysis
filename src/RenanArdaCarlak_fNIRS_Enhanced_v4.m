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


%% INPUT-DATA PREFLIGHT CHECK
% This addition does not alter the original processing. It checks the full
% data set before the long analysis starts and defines one common analysis
% duration for all blocks.
    PreflightSubjectList = [ 3 4 5 6 8 ];
    PreflightBaselineFrame = 10;
    PreflightExpectedColumnCount = 48; % 16 optodes x (730 nm, ambient, 850 nm).

    Manifest_Subject = [];
    Manifest_Condition = [];
    Manifest_Block = [];
    Manifest_Samples = [];
    Manifest_Columns = [];
    Manifest_Optodes = [];
    Manifest_SourceFile = cell( 0 , 1 );

    for PreflightSubjectIndex = 1 : length( PreflightSubjectList )
        PreflightSubject = PreflightSubjectList( PreflightSubjectIndex );

        for PreflightCondition = 1 : 3
            for PreflightTrial = 1 : 3
                PreflightBlock = 3 + ( PreflightCondition - 1 ) * 3 + PreflightTrial;

                if PreflightCondition == 1
                    PreflightRequestedFilename = sprintf( 'Subject_%i_lightgraph%i.ref.Block%i_DATA,ONE.txt' , PreflightSubject , PreflightSubject , PreflightBlock );
                elseif PreflightCondition == 2
                    PreflightRequestedFilename = sprintf( 'Subject_%i_lightgraph%i.ref.Block%i_DATA,TWO.txt' , PreflightSubject , PreflightSubject , PreflightBlock );
                else
                    PreflightRequestedFilename = sprintf( 'Subject_%i_lightgraph%i.ref.Block%i_DATA,THREE.txt' , PreflightSubject , PreflightSubject , PreflightBlock );
                end

                PreflightSourceFilename = resolveFNIRSSourceFilename( PreflightRequestedFilename );
                PreflightImportedData = importdata( PreflightSourceFilename );

                if ~isstruct( PreflightImportedData ) || ~isfield( PreflightImportedData , 'data' )
                    error( 'fNIRS:InvalidImportedData' , 'The file did not produce a numeric data matrix: %s' , PreflightRequestedFilename );
                end

                PreflightFileSize = size( PreflightImportedData.data );
                PreflightNumberofSample = PreflightFileSize( 1 );
                PreflightNumberofColumn = PreflightFileSize( 2 );

                if PreflightNumberofColumn ~= PreflightExpectedColumnCount
                    error( 'fNIRS:UnexpectedColumnCount' , 'Expected %i columns but found %i in %s.' , ...
                        PreflightExpectedColumnCount , PreflightNumberofColumn , PreflightRequestedFilename );
                end

                if mod( PreflightNumberofColumn , 3 ) ~= 0
                    error( 'fNIRS:InvalidOptodeStructure' , 'Column count is not divisible by three in %s.' , PreflightRequestedFilename );
                end

                if PreflightNumberofSample <= PreflightBaselineFrame
                    error( 'fNIRS:InsufficientSamples' , 'The file has no post-baseline samples: %s' , PreflightRequestedFilename );
                end

                [ ~ , PreflightBaseName , PreflightExtension ] = fileparts( PreflightSourceFilename );

                Manifest_Subject = [ Manifest_Subject; PreflightSubject ];
                Manifest_Condition = [ Manifest_Condition; PreflightCondition ];
                Manifest_Block = [ Manifest_Block; PreflightBlock ];
                Manifest_Samples = [ Manifest_Samples; PreflightNumberofSample ];
                Manifest_Columns = [ Manifest_Columns; PreflightNumberofColumn ];
                Manifest_Optodes = [ Manifest_Optodes; PreflightNumberofColumn / 3 ];
                Manifest_SourceFile = [ Manifest_SourceFile; { [ PreflightBaseName PreflightExtension ] } ];
            end
        end
    end

    InputDataManifest = table( Manifest_Subject , Manifest_Condition , Manifest_Block , Manifest_Samples , ...
        Manifest_Columns , Manifest_Optodes , Manifest_SourceFile , ...
        'VariableNames' , { 'Subject' 'Condition' 'Block' 'Samples' 'Columns' 'Optodes' 'SourceFile' } );

    PreflightCommonAnalysisFrame = min( InputDataManifest.Samples ) - PreflightBaselineFrame;

    if PreflightCommonAnalysisFrame < 1
        error( 'fNIRS:InvalidCommonAnalysisFrame' , 'A positive common post-baseline analysis window could not be defined.' );
    end

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
        sourceFilename = resolveFNIRSSourceFilename( filename{ j , i , 1 } );
        subjects.( subject{ i } ).( filename{ j , i , 2 } ) = importdata( sourceFilename ); % Import light intensity (after absorbtion) data which has converted to mV.
        subjects.( subject{ i } ).( filename{ j , i , 2 } ).sourceFilename = sourceFilename;
        
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
                        AmountofFFTFrame_730 = length( subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t - 2 ) );
                        LastSingleSidedIndex_730 = floor( AmountofFFTFrame_730 / 2 ) + 1;
                        P2_730 = abs( fft_RawData_730 / AmountofFFTFrame_730 );
                        P1_730 = P2_730( 1 : LastSingleSidedIndex_730 );
                        if rem( AmountofFFTFrame_730 , 2 ) == 0
                            P1_730( 2 : end-1 ) = 2 * P1_730( 2 : end-1 );
                        else
                            P1_730( 2 : end ) = 2 * P1_730( 2 : end );
                        end
                        frq_730 = 2 * ( 0 : floor( AmountofFFTFrame_730 / 2 ) ) / AmountofFFTFrame_730;                   
                    % For 850nm
                        fft_RawData_850 = fft( subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t ) );
                        AmountofFFTFrame_850 = length( subjects.( subject{ i } ).( filename{ j , i , 2 } ).data( : , 3*t ) );
                        LastSingleSidedIndex_850 = floor( AmountofFFTFrame_850 / 2 ) + 1;
                        P2_850 = abs( fft_RawData_850 / AmountofFFTFrame_850 );
                        P1_850 = P2_850( 1 : LastSingleSidedIndex_850 );
                        if rem( AmountofFFTFrame_850 , 2 ) == 0
                            P1_850( 2 : end-1 ) = 2 * P1_850( 2 : end-1 );
                        else
                            P1_850( 2 : end ) = 2 * P1_850( 2 : end );
                        end
                        frq_850 = 2 * ( 0 : floor( AmountofFFTFrame_850 / 2 ) ) / AmountofFFTFrame_850;                    
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
                legend( '730 nm 5 sec' , '730 nm 10 sec' , '730 nm 15 sec' ); % 850 nm CV curves are currently commented out above. 
                sgtitle( [filename{ j , i , 7 } ' Light Intensity Coefficient of Variation' ], 'fontsize' ,18 ); % Main Heading.                                                                                                              
        end      

    % Figuring Raw Data & Coefficient of Variation of Subject 3 & 4
        % This comparison uses Subject 3 and Subject 4 together. Therefore,
        % it should be produced only after Subject 4 has also been imported.
        if i == 4
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
        end
        
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
    if usejava('desktop')
        openvar('subjects.AllSubjects_AllExperiments_AllTrials_meanDeltaHbOconcentrationT');
    end

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
    if usejava('desktop')
        openvar('subjects.AllSubjects_AllExperiments_AllTrials_meanDeltaHbOconcF_T');
    end

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

%% ENHANCED AND REPRODUCIBLE ANALYSIS - VERSION 4
% This section preserves the complete legacy analysis above and adds a
% second analysis layer without overwriting the original results.
%
% Version-4 additions:
%   1. The complete legacy analysis and Version-3 processing are preserved.
%   2. The primary low-pass configuration is changed to 0.20 Hz because
%      the synthetic preservation test showed the lowest distortion among
%      the tested low-pass alternatives. TDDR-only, 0.05-Hz and 0.10-Hz
%      results remain available as sensitivity analyses.
%   3. Block-level global HbO results are retained and exported instead of
%      being hidden by the three-block participant average.
%   4. Mean-across-blocks aggregation is compared with median-across-blocks
%      aggregation without deleting any block.
%   5. Leave-one-participant-out influence analysis is added. No participant
%      is excluded from the primary analysis.
%   6. Participant IDs, shared time-course axes, shaded HbO SEM bands and
%      HbO-specific labels are added to the final figures.
%   7. A participant-by-block consistency figure and aggregation-sensitivity
%      figure are produced for transparent interpretation.
%
% IMPORTANT:
%   - Ambient-light measurements are quantified but not subtracted. Direct
%     subtraction is device-dependent.
%   - The original MBLL constants are retained for comparability. Their
%     source and unit convention must be confirmed before assigning an
%     absolute concentration unit.
%   - Channel statistics are exploratory. N = 5 limits inferential power.
%   - Influence and aggregation-sensitivity analyses diagnose robustness;
%     they are not post-hoc rules for deleting inconvenient observations.

% Enhanced Analysis Options
    EnhancedAnalysis.Version = '4.0';
    EnhancedAnalysis.fs = 2; % Sampling frequency in Hz.
    EnhancedAnalysis.BaselineFrame = 10; % First 10 samples = 5 s baseline.
    EnhancedAnalysis.CommonAnalysisFrame = PreflightCommonAnalysisFrame;
    EnhancedAnalysis.CommonAnalysisDurationSeconds = EnhancedAnalysis.CommonAnalysisFrame / EnhancedAnalysis.fs;
    EnhancedAnalysis.FilterOrder = 3;
    EnhancedAnalysis.FilterConfigurationTags = { 'TDDROnly' 'LP050' 'LP100' 'LP200' };
    EnhancedAnalysis.FilterConfigurationNames = { 'TDDR only' 'TDDR + LP 0.05 Hz' 'TDDR + LP 0.10 Hz' 'TDDR + LP 0.20 Hz' };
    EnhancedAnalysis.FilterCutoffOptions = [ NaN 0.05 0.10 0.20 ];
    EnhancedAnalysis.PrimaryFilterTag = 'LP200';
    EnhancedAnalysis.PrimaryFilterCutoff = 0.20; % Primary engineering configuration selected from the preservation test; alternatives are reported.
    EnhancedAnalysis.PrimaryFilterIndex = find( strcmp( EnhancedAnalysis.FilterConfigurationTags , EnhancedAnalysis.PrimaryFilterTag ) , 1 );
    EnhancedAnalysis.PrimaryFilterName = EnhancedAnalysis.FilterConfigurationNames{ EnhancedAnalysis.PrimaryFilterIndex };
    EnhancedAnalysis.MotionCVThreshold = 0.02; % Legacy exploratory threshold; quality metric only.
    EnhancedAnalysis.RobustPeakPercentile = 95;
    EnhancedAnalysis.CreateFigures = true;
    EnhancedAnalysis.SaveResults = true;
    EnhancedAnalysis.SaveFullWorkspace = false;
    EnhancedAnalysis.ScriptFolder = fileparts( mfilename('fullpath') );
    if isempty( EnhancedAnalysis.ScriptFolder )
        EnhancedAnalysis.ScriptFolder = pwd;
    end
    EnhancedAnalysis.OutputFolder = fullfile( EnhancedAnalysis.ScriptFolder , 'results_enhanced_v4' );
    EnhancedAnalysis.SubjectList = [ 3 4 5 6 8 ];
    EnhancedAnalysis.ConditionNames = { '1-back' '2-back' '3-back' };
    EnhancedAnalysis.HbOOutputQuantityLabel = 'Scaled Delta HbO (legacy MBLL parameter convention)';
    EnhancedAnalysis.HbOHbROutputQuantityLabel = 'Scaled Delta HbO/HbR (legacy MBLL parameter convention)';
    EnhancedAnalysis.OutputQuantityLabel = EnhancedAnalysis.HbOHbROutputQuantityLabel; % Backward-compatible general label.
    EnhancedAnalysis.PrimaryBlockAggregation = 'Mean across three blocks';
    EnhancedAnalysis.SensitivityBlockAggregation = 'Median across three blocks';
    EnhancedAnalysis.MBLLParameterStatus = 'Original coefficients retained; source and unit convention require confirmation.';
    EnhancedAnalysis.RepresentativeMotionSubject = [ 3 4 ];
    EnhancedAnalysis.RepresentativeMotionBlock = [ 8 10 ];
    EnhancedAnalysis.RepresentativeMotionOptode = [ 14 14 ];

    if exist( EnhancedAnalysis.OutputFolder , 'dir' ) ~= 7
        mkdir( EnhancedAnalysis.OutputFolder );
    end

    subjects.EnhancedAnalysis.Configuration = EnhancedAnalysis;
    subjects.EnhancedAnalysis.InputDataManifest = InputDataManifest;
    filenameEnhanced = cell( 9 , 8 , 9 );

% Parameter-Audit Table
    Parameter = { 'E_HbR_730nm'; 'E_HbR_850nm'; 'E_HbO_730nm'; 'E_HbO_850nm'; 'SourceDetectorDistance'; 'DPF' };
    Value = [ E_HbR_730nm; E_HbR_850nm; E_HbO_730nm; E_HbO_850nm; d; DPF ];
    UnitOrConvention = { 'Requires confirmation'; 'Requires confirmation'; 'Requires confirmation'; 'Requires confirmation'; 'cm'; 'Requires confirmation' };
    SourceStatus = repmat( { 'Source to be documented before publication' } , 6 , 1 );
    subjects.EnhancedAnalysis.MBLLParameterAudit = table( Parameter , Value , UnitOrConvention , SourceStatus );

% Variables for Quality-Control Table
    QC_Subject = [];
    QC_Block = [];
    QC_Condition = [];
    QC_Optode = [];
    QC_NonFiniteSampleCount = [];
    QC_NonPositiveSampleCount = [];
    QC_BaselineCV730 = [];
    QC_BaselineCV850 = [];
    QC_AmbientToSignalRatio = [];
    QC_AmbientCorrelation730 = [];
    QC_AmbientCorrelation850 = [];
    QC_MotionCandidateFraction = [];
    QC_MathematicallyValidChannel = [];

% Filter-Preservation Test Using a Synthetic Hemodynamic-Like Response
    SyntheticSignalDuration = 64;
    SyntheticTime = ( 0 : 1 / EnhancedAnalysis.fs : SyntheticSignalDuration - 1 / EnhancedAnalysis.fs )';
    SyntheticTask = zeros( length(SyntheticTime) , 1 );
    SyntheticTask( SyntheticTime >= 10 & SyntheticTime <= 40 ) = 1;
    SyntheticHRFTime = ( 0 : 1 / EnhancedAnalysis.fs : 30 )';
    SyntheticHRF = ( SyntheticHRFTime .^ 8 ) .* exp( -SyntheticHRFTime / 0.9 );
    SyntheticHRF = SyntheticHRF / max( SyntheticHRF );
    SyntheticHemodynamicResponse = conv( SyntheticTask , SyntheticHRF );
    SyntheticHemodynamicResponse = SyntheticHemodynamicResponse( 1 : length(SyntheticTime) );
    SyntheticHemodynamicResponse = SyntheticHemodynamicResponse - mean( SyntheticHemodynamicResponse( 1 : EnhancedAnalysis.BaselineFrame ) );

    FilterConfiguration = EnhancedAnalysis.FilterConfigurationNames';
    LowPassCutoffHz = EnhancedAnalysis.FilterCutoffOptions';
    SyntheticCorrelation = zeros( length(FilterConfiguration) , 1 );
    SyntheticPeakRetention = zeros( length(FilterConfiguration) , 1 );
    SyntheticRMSE = zeros( length(FilterConfiguration) , 1 );

    for f = 1 : length( FilterConfiguration )
        if isnan( LowPassCutoffHz(f) )
            SyntheticFiltered = SyntheticHemodynamicResponse;
        else
            [ bEnhanced , aEnhanced ] = butter( EnhancedAnalysis.FilterOrder , LowPassCutoffHz(f) / ( EnhancedAnalysis.fs / 2 ) , 'low' );
            SyntheticFiltered = filtfilt( bEnhanced , aEnhanced , SyntheticHemodynamicResponse );
            SyntheticFiltered = SyntheticFiltered - mean( SyntheticFiltered( 1 : EnhancedAnalysis.BaselineFrame ) );
        end

        SyntheticCorrelation(f) = safeCorrelation( SyntheticHemodynamicResponse , SyntheticFiltered );
        SyntheticPeakRetention(f) = ( max(SyntheticFiltered) - min(SyntheticFiltered) ) / ...
            ( max(SyntheticHemodynamicResponse) - min(SyntheticHemodynamicResponse) );
        SyntheticRMSE(f) = sqrt( mean( ( SyntheticHemodynamicResponse - SyntheticFiltered ) .^ 2 ) );
    end

    subjects.EnhancedAnalysis.FilterPreservationTest = table( FilterConfiguration , LowPassCutoffHz , ...
        SyntheticCorrelation , SyntheticPeakRetention , SyntheticRMSE );

% Enhanced Trial-Level Processing
    for i = 1 : 8 % For subjects

        if i == 1 || i == 2 || i == 7
            continue
        end

        for j = 1 : 9 % For all experimental blocks

            ConditionNumber = ceil( j / 3 );
            BlockNumber = j + 3;

            % Dynamic enhanced-output filenames, following the original structure.
                filenameEnhanced{ j , i , 1 } = sprintf( 'Subject_%i_deltaOpticalDensity_Block%i_DATA_%i_Enhanced' , i , BlockNumber , ConditionNumber );
                filenameEnhanced{ j , i , 2 } = sprintf( 'Subject_%i_deltaOpticalDensity_Block%i_DATA_%i_TDDR_Enhanced' , i , BlockNumber , ConditionNumber );
                filenameEnhanced{ j , i , 3 } = sprintf( 'Subject_%i_deltaConcentration_Block%i_DATA_%i_Enhanced' , i , BlockNumber , ConditionNumber );
                filenameEnhanced{ j , i , 4 } = sprintf( 'Subject_%i_deltaHbRConcentration_Block%i_DATA_%i_Enhanced' , i , BlockNumber , ConditionNumber );
                filenameEnhanced{ j , i , 5 } = sprintf( 'Subject_%i_deltaHbOConcentration_Block%i_DATA_%i_Enhanced' , i , BlockNumber , ConditionNumber );
                filenameEnhanced{ j , i , 6 } = sprintf( 'Subject_%i_mean_deltaHbOConcentration_Block%i_DATA_%i_Enhanced' , i , BlockNumber , ConditionNumber );
                filenameEnhanced{ j , i , 7 } = sprintf( 'Subject_%i_AUC_deltaHbOConcentration_Block%i_DATA_%i_Enhanced' , i , BlockNumber , ConditionNumber );
                filenameEnhanced{ j , i , 8 } = sprintf( 'Subject_%i_maximum_deltaHbOConcentration_Block%i_DATA_%i_Enhanced' , i , BlockNumber , ConditionNumber );
                filenameEnhanced{ j , i , 9 } = sprintf( 'Subject_%i_robustPeak_deltaHbOConcentration_Block%i_DATA_%i_Enhanced' , i , BlockNumber , ConditionNumber );

            CurrentData = subjects.( subject{ i } ).( filename{ j , i , 2 } ).data;
            LightIntensityFileSize = size( CurrentData );
            AmountofTimeFrame = LightIntensityFileSize(1,1);
            NumberofOptode = LightIntensityFileSize(1,2) / 3;
            AmountofAnalysisFrame = EnhancedAnalysis.CommonAnalysisFrame;

            if AmountofTimeFrame < EnhancedAnalysis.BaselineFrame + AmountofAnalysisFrame
                error( 'fNIRS:CommonWindowExceedsRecording' , 'Common analysis window exceeds Subject %i Block %i.' , i , BlockNumber );
            end

            subjects.( subject{ i } ).( filenameEnhanced{ j , i , 1 } ) = NaN( NumberofOptode * 2 , AmountofTimeFrame );
            subjects.( subject{ i } ).( filenameEnhanced{ j , i , 2 } ) = NaN( NumberofOptode * 2 , AmountofTimeFrame );

            % Channel Quality Control and Optical-Density Calculation
                p = 1;
                q = 1;
                for k = 1 : 3 : LightIntensityFileSize(1,2) - 2

                    Data730 = CurrentData( : , k );
                    DataAmbient = CurrentData( : , k+1 );
                    Data850 = CurrentData( : , k+2 );

                    NonFiniteSampleCount = sum( ~isfinite(Data730) ) + sum( ~isfinite(Data850) );
                    NonPositiveSampleCount = sum( Data730 <= 0 ) + sum( Data850 <= 0 );
                    MathematicallyValidChannel = NonFiniteSampleCount == 0 && NonPositiveSampleCount == 0;

                    BaselineCV730 = std( Data730( 1 : EnhancedAnalysis.BaselineFrame ) ) / mean( Data730( 1 : EnhancedAnalysis.BaselineFrame ) );
                    BaselineCV850 = std( Data850( 1 : EnhancedAnalysis.BaselineFrame ) ) / mean( Data850( 1 : EnhancedAnalysis.BaselineFrame ) );
                    AmbientToSignalRatio = mean( DataAmbient ) / mean( ( Data730 + Data850 ) / 2 );
                    AmbientCorrelation730 = safeCorrelation( DataAmbient , Data730 );
                    AmbientCorrelation850 = safeCorrelation( DataAmbient , Data850 );

                    MotionCandidate730 = abs( subjects.( subject{ i } ).( filename{ j , i , 2 } ).dataCV_5( : , k ) ) > EnhancedAnalysis.MotionCVThreshold;
                    MotionCandidate850 = abs( subjects.( subject{ i } ).( filename{ j , i , 2 } ).dataCV_5( : , k+2 ) ) > EnhancedAnalysis.MotionCVThreshold;
                    MotionCandidateFraction = mean( MotionCandidate730 | MotionCandidate850 );

                    QC_Subject = [ QC_Subject; i ];
                    QC_Block = [ QC_Block; BlockNumber ];
                    QC_Condition = [ QC_Condition; ConditionNumber ];
                    QC_Optode = [ QC_Optode; q ];
                    QC_NonFiniteSampleCount = [ QC_NonFiniteSampleCount; NonFiniteSampleCount ];
                    QC_NonPositiveSampleCount = [ QC_NonPositiveSampleCount; NonPositiveSampleCount ];
                    QC_BaselineCV730 = [ QC_BaselineCV730; BaselineCV730 ];
                    QC_BaselineCV850 = [ QC_BaselineCV850; BaselineCV850 ];
                    QC_AmbientToSignalRatio = [ QC_AmbientToSignalRatio; AmbientToSignalRatio ];
                    QC_AmbientCorrelation730 = [ QC_AmbientCorrelation730; AmbientCorrelation730 ];
                    QC_AmbientCorrelation850 = [ QC_AmbientCorrelation850; AmbientCorrelation850 ];
                    QC_MotionCandidateFraction = [ QC_MotionCandidateFraction; MotionCandidateFraction ];
                    QC_MathematicallyValidChannel = [ QC_MathematicallyValidChannel; MathematicallyValidChannel ];

                    if MathematicallyValidChannel
                        DeltaOpticalDensity730 = log10( mean( Data730( 1 : EnhancedAnalysis.BaselineFrame ) ) ./ Data730 );
                        DeltaOpticalDensity850 = log10( mean( Data850( 1 : EnhancedAnalysis.BaselineFrame ) ) ./ Data850 );

                        subjects.( subject{ i } ).( filenameEnhanced{ j , i , 1 } )( p , : ) = DeltaOpticalDensity730';
                        subjects.( subject{ i } ).( filenameEnhanced{ j , i , 1 } )( p+1 , : ) = DeltaOpticalDensity850';

                        % TDDR is applied to optical density.
                        subjects.( subject{ i } ).( filenameEnhanced{ j , i , 2 } )( p , : ) = ...
                            temporalDerivativeDistributionRepair( DeltaOpticalDensity730 , EnhancedAnalysis.fs )';
                        subjects.( subject{ i } ).( filenameEnhanced{ j , i , 2 } )( p+1 , : ) = ...
                            temporalDerivativeDistributionRepair( DeltaOpticalDensity850 , EnhancedAnalysis.fs )';
                    end

                    p = p + 2;
                    q = q + 1;
                end

            % Filter Sensitivity Analysis, Post-Processing Re-Baselining and MBLL
                subjects.( subject{ i } ).( filename{ j , i , 2 } ).EnhancedSensitivity = struct;

                for f = 1 : length( EnhancedAnalysis.FilterConfigurationTags )

                    FilterTag = EnhancedAnalysis.FilterConfigurationTags{ f };
                    CurrentCutoff = EnhancedAnalysis.FilterCutoffOptions(f);
                    DeltaOpticalDensityProcessed = NaN( NumberofOptode * 2 , AmountofTimeFrame );

                    if ~isnan( CurrentCutoff )
                        [ bEnhanced , aEnhanced ] = butter( EnhancedAnalysis.FilterOrder , CurrentCutoff / ( EnhancedAnalysis.fs / 2 ) , 'low' );
                    end

                    for p = 1 : NumberofOptode * 2
                        CurrentOpticalDensity = subjects.( subject{ i } ).( filenameEnhanced{ j , i , 2 } )( p , : );

                        if all( isfinite(CurrentOpticalDensity) )
                            if isnan( CurrentCutoff )
                                CurrentOpticalDensityProcessed = CurrentOpticalDensity;
                            else
                                CurrentOpticalDensityProcessed = filtfilt( bEnhanced , aEnhanced , CurrentOpticalDensity );
                            end

                            % The processed optical-density baseline is explicitly
                            % returned to zero before MBLL conversion.
                            CurrentOpticalDensityProcessed = CurrentOpticalDensityProcessed - ...
                                mean( CurrentOpticalDensityProcessed( 1 : EnhancedAnalysis.BaselineFrame ) );
                            DeltaOpticalDensityProcessed( p , : ) = CurrentOpticalDensityProcessed;
                        end
                    end

                    DeltaConcentrationProcessedFull = NaN( NumberofOptode * 2 , AmountofTimeFrame );
                    DeltaConcentrationProcessed = NaN( NumberofOptode * 2 , AmountofAnalysisFrame );
                    DeltaHbRProcessed = NaN( AmountofAnalysisFrame , NumberofOptode );
                    DeltaHbOProcessed = NaN( AmountofAnalysisFrame , NumberofOptode );
                    MeanDeltaHbOProcessed = NaN( 1 , NumberofOptode );
                    AUCDeltaHbOProcessed = NaN( 1 , NumberofOptode );
                    MaximumDeltaHbOProcessed = NaN( 1 , NumberofOptode );
                    RobustPeakDeltaHbOProcessed = NaN( 1 , NumberofOptode );
                    AnalysisTime = ( 0 : AmountofAnalysisFrame - 1 ) / EnhancedAnalysis.fs;
                    FirstAnalysisFrame = EnhancedAnalysis.BaselineFrame + 1;
                    LastAnalysisFrame = EnhancedAnalysis.BaselineFrame + AmountofAnalysisFrame;

                    p = 1;
                    q = 1;
                    for t = 1 : NumberofOptode
                        if all( isfinite(DeltaOpticalDensityProcessed( p : p+1 , : )) , 'all' )
                            DeltaConcentrationProcessedFull( p : p+1 , : ) = constants \ DeltaOpticalDensityProcessed( p : p+1 , : );
                            DeltaConcentrationProcessed( p : p+1 , : ) = ...
                                DeltaConcentrationProcessedFull( p : p+1 , FirstAnalysisFrame : LastAnalysisFrame );
                            DeltaHbRProcessed( : , q ) = DeltaConcentrationProcessed( p , : )';
                            DeltaHbOProcessed( : , q ) = DeltaConcentrationProcessed( p+1 , : )';
                            MeanDeltaHbOProcessed( 1 , q ) = mean( DeltaHbOProcessed( : , q ) );
                            AUCDeltaHbOProcessed( 1 , q ) = trapz( AnalysisTime , DeltaHbOProcessed( : , q ) );
                            MaximumDeltaHbOProcessed( 1 , q ) = max( DeltaHbOProcessed( : , q ) );
                            RobustPeakDeltaHbOProcessed( 1 , q ) = empiricalPercentile( DeltaHbOProcessed( : , q ) , EnhancedAnalysis.RobustPeakPercentile );
                        end
                        p = p + 2;
                        q = q + 1;
                    end

                    subjects.( subject{ i } ).( filename{ j , i , 2 } ).EnhancedSensitivity.( FilterTag ).FilterConfigurationName = ...
                        EnhancedAnalysis.FilterConfigurationNames{ f };
                    subjects.( subject{ i } ).( filename{ j , i , 2 } ).EnhancedSensitivity.( FilterTag ).LowPassCutoffHz = CurrentCutoff;
                    subjects.( subject{ i } ).( filename{ j , i , 2 } ).EnhancedSensitivity.( FilterTag ).deltaOpticalDensity = DeltaOpticalDensityProcessed;
                    subjects.( subject{ i } ).( filename{ j , i , 2 } ).EnhancedSensitivity.( FilterTag ).deltaConcentration = DeltaConcentrationProcessed;
                    subjects.( subject{ i } ).( filename{ j , i , 2 } ).EnhancedSensitivity.( FilterTag ).deltaHbRConcentration = DeltaHbRProcessed;
                    subjects.( subject{ i } ).( filename{ j , i , 2 } ).EnhancedSensitivity.( FilterTag ).deltaHbOConcentration = DeltaHbOProcessed;
                    subjects.( subject{ i } ).( filename{ j , i , 2 } ).EnhancedSensitivity.( FilterTag ).meanDeltaHbOConcentration = MeanDeltaHbOProcessed;
                    subjects.( subject{ i } ).( filename{ j , i , 2 } ).EnhancedSensitivity.( FilterTag ).AUCDeltaHbOConcentration = AUCDeltaHbOProcessed;
                    subjects.( subject{ i } ).( filename{ j , i , 2 } ).EnhancedSensitivity.( FilterTag ).maximumDeltaHbOConcentration = MaximumDeltaHbOProcessed;
                    subjects.( subject{ i } ).( filename{ j , i , 2 } ).EnhancedSensitivity.( FilterTag ).robustPeakDeltaHbOConcentration = RobustPeakDeltaHbOProcessed;
                end

            % Copy the primary-filter result into fields matching the original
            % subject-level concentration structure.
                PrimaryFilterTag = EnhancedAnalysis.PrimaryFilterTag;
                subjects.( subject{ i } ).( filenameEnhanced{ j , i , 3 } ) = subjects.( subject{ i } ).( filename{ j , i , 2 } ).EnhancedSensitivity.( PrimaryFilterTag ).deltaConcentration;
                subjects.( subject{ i } ).( filenameEnhanced{ j , i , 4 } ) = subjects.( subject{ i } ).( filename{ j , i , 2 } ).EnhancedSensitivity.( PrimaryFilterTag ).deltaHbRConcentration;
                subjects.( subject{ i } ).( filenameEnhanced{ j , i , 5 } ) = subjects.( subject{ i } ).( filename{ j , i , 2 } ).EnhancedSensitivity.( PrimaryFilterTag ).deltaHbOConcentration;
                subjects.( subject{ i } ).( filenameEnhanced{ j , i , 6 } ) = subjects.( subject{ i } ).( filename{ j , i , 2 } ).EnhancedSensitivity.( PrimaryFilterTag ).meanDeltaHbOConcentration;
                subjects.( subject{ i } ).( filenameEnhanced{ j , i , 7 } ) = subjects.( subject{ i } ).( filename{ j , i , 2 } ).EnhancedSensitivity.( PrimaryFilterTag ).AUCDeltaHbOConcentration;
                subjects.( subject{ i } ).( filenameEnhanced{ j , i , 8 } ) = subjects.( subject{ i } ).( filename{ j , i , 2 } ).EnhancedSensitivity.( PrimaryFilterTag ).maximumDeltaHbOConcentration;
                subjects.( subject{ i } ).( filenameEnhanced{ j , i , 9 } ) = subjects.( subject{ i } ).( filename{ j , i , 2 } ).EnhancedSensitivity.( PrimaryFilterTag ).robustPeakDeltaHbOConcentration;
        end
    end

% Quality-Control Table
    subjects.EnhancedAnalysis.QualityControlTable = table( QC_Subject , QC_Block , QC_Condition , QC_Optode , ...
        QC_NonFiniteSampleCount , QC_NonPositiveSampleCount , QC_BaselineCV730 , QC_BaselineCV850 , ...
        QC_AmbientToSignalRatio , QC_AmbientCorrelation730 , QC_AmbientCorrelation850 , ...
        QC_MotionCandidateFraction , logical(QC_MathematicallyValidChannel) , ...
        'VariableNames' , { 'Subject' 'Block' 'Condition' 'Optode' 'NonFiniteSampleCount' ...
        'NonPositiveSampleCount' 'BaselineCV730' 'BaselineCV850' 'AmbientToSignalRatio' ...
        'AmbientCorrelation730' 'AmbientCorrelation850' 'MotionCandidateFraction' 'MathematicallyValidChannel' } );

% Enhanced Subject- and Block-Level Aggregation
    NumberofSubject = length( EnhancedAnalysis.SubjectList );
    NumberofCondition = 3;
    NumberofTrialPerCondition = 3;
    NumberofFilterConfiguration = length( EnhancedAnalysis.FilterConfigurationTags );

    subjects.EnhancedAnalysis.BlockLevelMeanHbO = NaN( NumberofSubject , NumberofCondition , NumberofTrialPerCondition , NumberofOptode );
    subjects.EnhancedAnalysis.BlockLevelAUCHbO = NaN( NumberofSubject , NumberofCondition , NumberofTrialPerCondition , NumberofOptode );
    subjects.EnhancedAnalysis.BlockLevelMaximumHbO = NaN( NumberofSubject , NumberofCondition , NumberofTrialPerCondition , NumberofOptode );
    subjects.EnhancedAnalysis.BlockLevelRobustPeakHbO = NaN( NumberofSubject , NumberofCondition , NumberofTrialPerCondition , NumberofOptode );
    subjects.EnhancedAnalysis.BlockLevelGlobalMeanHbO = NaN( NumberofSubject , NumberofCondition , NumberofTrialPerCondition );
    subjects.EnhancedAnalysis.BlockLevelGlobalMedianHbO = NaN( NumberofSubject , NumberofCondition , NumberofTrialPerCondition );

    subjects.EnhancedAnalysis.SubjectLevelMeanHbO = NaN( NumberofSubject , NumberofCondition , NumberofOptode );
    subjects.EnhancedAnalysis.SubjectLevelMedianAcrossBlocksMeanHbO = NaN( NumberofSubject , NumberofCondition , NumberofOptode );
    subjects.EnhancedAnalysis.SubjectLevelAUCHbO = NaN( NumberofSubject , NumberofCondition , NumberofOptode );
    subjects.EnhancedAnalysis.SubjectLevelMaximumHbO = NaN( NumberofSubject , NumberofCondition , NumberofOptode );
    subjects.EnhancedAnalysis.SubjectLevelRobustPeakHbO = NaN( NumberofSubject , NumberofCondition , NumberofOptode );
    subjects.EnhancedAnalysis.FilterSensitivity.SubjectGlobalMeanHbO = NaN( NumberofSubject , NumberofCondition , NumberofFilterConfiguration );
    subjects.EnhancedAnalysis.LegacySubjectGlobalMeanHbO = NaN( NumberofSubject , NumberofCondition );
    subjects.EnhancedAnalysis.SubjectHbOTimeCourse = cell( NumberofSubject , NumberofCondition );
    subjects.EnhancedAnalysis.SubjectHbRTimeCourse = cell( NumberofSubject , NumberofCondition );

    for SubjectIndex = 1 : NumberofSubject

        i = EnhancedAnalysis.SubjectList( SubjectIndex );

        subjects.( subject{ i } ).Enhanced_DeltaHbOconcentration_means_1BB = NaN( 3 , NumberofOptode );
        subjects.( subject{ i } ).Enhanced_DeltaHbOconcentration_means_2BB = NaN( 3 , NumberofOptode );
        subjects.( subject{ i } ).Enhanced_DeltaHbOconcentration_means_3BB = NaN( 3 , NumberofOptode );

        for ConditionNumber = 1 : NumberofCondition

            FirstBlockIndex = ( ConditionNumber - 1 ) * NumberofTrialPerCondition + 1;
            BlockMeanHbO = NaN( NumberofTrialPerCondition , NumberofOptode );
            BlockAUCHbO = NaN( NumberofTrialPerCondition , NumberofOptode );
            BlockMaximumHbO = NaN( NumberofTrialPerCondition , NumberofOptode );
            BlockRobustPeakHbO = NaN( NumberofTrialPerCondition , NumberofOptode );
            HbOTrialTimeCourse = NaN( EnhancedAnalysis.CommonAnalysisFrame , NumberofOptode , NumberofTrialPerCondition );
            HbRTrialTimeCourse = NaN( EnhancedAnalysis.CommonAnalysisFrame , NumberofOptode , NumberofTrialPerCondition );

            for r = 1 : NumberofTrialPerCondition
                j = FirstBlockIndex + r - 1;
                BlockMeanHbO( r , : ) = subjects.( subject{ i } ).( filenameEnhanced{ j , i , 6 } );
                BlockAUCHbO( r , : ) = subjects.( subject{ i } ).( filenameEnhanced{ j , i , 7 } );
                BlockMaximumHbO( r , : ) = subjects.( subject{ i } ).( filenameEnhanced{ j , i , 8 } );
                BlockRobustPeakHbO( r , : ) = subjects.( subject{ i } ).( filenameEnhanced{ j , i , 9 } );
                HbOTrialTimeCourse( : , : , r ) = subjects.( subject{ i } ).( filenameEnhanced{ j , i , 5 } );
                HbRTrialTimeCourse( : , : , r ) = subjects.( subject{ i } ).( filenameEnhanced{ j , i , 4 } );

                subjects.EnhancedAnalysis.BlockLevelMeanHbO( SubjectIndex , ConditionNumber , r , : ) = BlockMeanHbO( r , : );
                subjects.EnhancedAnalysis.BlockLevelAUCHbO( SubjectIndex , ConditionNumber , r , : ) = BlockAUCHbO( r , : );
                subjects.EnhancedAnalysis.BlockLevelMaximumHbO( SubjectIndex , ConditionNumber , r , : ) = BlockMaximumHbO( r , : );
                subjects.EnhancedAnalysis.BlockLevelRobustPeakHbO( SubjectIndex , ConditionNumber , r , : ) = BlockRobustPeakHbO( r , : );
                subjects.EnhancedAnalysis.BlockLevelGlobalMeanHbO( SubjectIndex , ConditionNumber , r ) = mean( BlockMeanHbO( r , : ) , 'omitnan' );
                subjects.EnhancedAnalysis.BlockLevelGlobalMedianHbO( SubjectIndex , ConditionNumber , r ) = median( BlockMeanHbO( r , : ) , 'omitnan' );
            end

            SubjectMeanHbO = mean( BlockMeanHbO , 1 , 'omitnan' );
            SubjectMedianAcrossBlocksMeanHbO = median( BlockMeanHbO , 1 , 'omitnan' );
            SubjectAUCHbO = mean( BlockAUCHbO , 1 , 'omitnan' );
            SubjectMaximumHbO = mean( BlockMaximumHbO , 1 , 'omitnan' );
            SubjectRobustPeakHbO = mean( BlockRobustPeakHbO , 1 , 'omitnan' );
            SubjectHbOTimeCourse = mean( HbOTrialTimeCourse , 3 , 'omitnan' );
            SubjectHbRTimeCourse = mean( HbRTrialTimeCourse , 3 , 'omitnan' );

            subjects.EnhancedAnalysis.SubjectLevelMeanHbO( SubjectIndex , ConditionNumber , : ) = SubjectMeanHbO;
            subjects.EnhancedAnalysis.SubjectLevelMedianAcrossBlocksMeanHbO( SubjectIndex , ConditionNumber , : ) = SubjectMedianAcrossBlocksMeanHbO;
            subjects.EnhancedAnalysis.SubjectLevelAUCHbO( SubjectIndex , ConditionNumber , : ) = SubjectAUCHbO;
            subjects.EnhancedAnalysis.SubjectLevelMaximumHbO( SubjectIndex , ConditionNumber , : ) = SubjectMaximumHbO;
            subjects.EnhancedAnalysis.SubjectLevelRobustPeakHbO( SubjectIndex , ConditionNumber , : ) = SubjectRobustPeakHbO;
            subjects.EnhancedAnalysis.SubjectHbOTimeCourse{ SubjectIndex , ConditionNumber } = SubjectHbOTimeCourse;
            subjects.EnhancedAnalysis.SubjectHbRTimeCourse{ SubjectIndex , ConditionNumber } = SubjectHbRTimeCourse;

            if ConditionNumber == 1
                subjects.( subject{ i } ).Enhanced_DeltaHbOconcentration_means_1BB = BlockMeanHbO;
                subjects.( subject{ i } ).Enhanced_meanDeltaHbOconcentration_1BB = SubjectMeanHbO;
                subjects.( subject{ i } ).Enhanced_medianDeltaHbOconcentration_1BB = SubjectMedianAcrossBlocksMeanHbO;
            elseif ConditionNumber == 2
                subjects.( subject{ i } ).Enhanced_DeltaHbOconcentration_means_2BB = BlockMeanHbO;
                subjects.( subject{ i } ).Enhanced_meanDeltaHbOconcentration_2BB = SubjectMeanHbO;
                subjects.( subject{ i } ).Enhanced_medianDeltaHbOconcentration_2BB = SubjectMedianAcrossBlocksMeanHbO;
            else
                subjects.( subject{ i } ).Enhanced_DeltaHbOconcentration_means_3BB = BlockMeanHbO;
                subjects.( subject{ i } ).Enhanced_meanDeltaHbOconcentration_3BB = SubjectMeanHbO;
                subjects.( subject{ i } ).Enhanced_medianDeltaHbOconcentration_3BB = SubjectMedianAcrossBlocksMeanHbO;
            end

            % Filter-sensitivity subject means, averaged across the three
            % blocks and all mathematically valid optodes.
                for f = 1 : NumberofFilterConfiguration
                    FilterTag = EnhancedAnalysis.FilterConfigurationTags{ f };
                    FilterBlockMeanHbO = NaN( NumberofTrialPerCondition , NumberofOptode );
                    for r = 1 : NumberofTrialPerCondition
                        j = FirstBlockIndex + r - 1;
                        FilterBlockMeanHbO( r , : ) = subjects.( subject{ i } ).( filename{ j , i , 2 } ).EnhancedSensitivity.( FilterTag ).meanDeltaHbOConcentration;
                    end
                    subjects.EnhancedAnalysis.FilterSensitivity.SubjectGlobalMeanHbO( SubjectIndex , ConditionNumber , f ) = ...
                        mean( FilterBlockMeanHbO , 'all' , 'omitnan' );
                end

            % Original filtered result retained for direct legacy comparison.
                if ConditionNumber == 1
                    subjects.EnhancedAnalysis.LegacySubjectGlobalMeanHbO( SubjectIndex , ConditionNumber ) = ...
                        mean( subjects.( subject{ i } ).meanDeltaHbOconcentration_1BB_Filtered , 'omitnan' );
                elseif ConditionNumber == 2
                    subjects.EnhancedAnalysis.LegacySubjectGlobalMeanHbO( SubjectIndex , ConditionNumber ) = ...
                        mean( subjects.( subject{ i } ).meanDeltaHbOconcentration_2BB_Filtered , 'omitnan' );
                else
                    subjects.EnhancedAnalysis.LegacySubjectGlobalMeanHbO( SubjectIndex , ConditionNumber ) = ...
                        mean( subjects.( subject{ i } ).meanDeltaHbOconcentration_3BB_Filtered , 'omitnan' );
                end
        end
    end

% Group-Level Means and Standard Errors
    subjects.EnhancedAnalysis.GroupMeanHbO = squeeze( mean( subjects.EnhancedAnalysis.SubjectLevelMeanHbO , 1 , 'omitnan' ) );
    subjects.EnhancedAnalysis.GroupMedianHbO = squeeze( median( subjects.EnhancedAnalysis.SubjectLevelMeanHbO , 1 , 'omitnan' ) );
    subjects.EnhancedAnalysis.GroupValidSubjectCount = squeeze( sum( isfinite(subjects.EnhancedAnalysis.SubjectLevelMeanHbO) , 1 ) );
    subjects.EnhancedAnalysis.GroupSEMHbO = squeeze( std( subjects.EnhancedAnalysis.SubjectLevelMeanHbO , 0 , 1 , 'omitnan' ) ) ./ ...
        sqrt( subjects.EnhancedAnalysis.GroupValidSubjectCount );
    subjects.EnhancedAnalysis.GroupMeanAUCHbO = squeeze( mean( subjects.EnhancedAnalysis.SubjectLevelAUCHbO , 1 , 'omitnan' ) );
    subjects.EnhancedAnalysis.GroupMeanMaximumHbO = squeeze( mean( subjects.EnhancedAnalysis.SubjectLevelMaximumHbO , 1 , 'omitnan' ) );
    subjects.EnhancedAnalysis.GroupMeanRobustPeakHbO = squeeze( mean( subjects.EnhancedAnalysis.SubjectLevelRobustPeakHbO , 1 , 'omitnan' ) );

% Block-Level Global Result Table
    BlockResult_Subject = [];
    BlockResult_Condition = [];
    BlockResult_ConditionName = cell( 0 , 1 );
    BlockResult_Block = [];
    BlockResult_GlobalMeanHbO = [];
    BlockResult_GlobalMedianHbO = [];
    BlockResult_GlobalMeanAUCHbO = [];
    BlockResult_GlobalMeanMaximumHbO = [];
    BlockResult_GlobalMeanRobustPeakHbO = [];

    for SubjectIndex = 1 : NumberofSubject
        for ConditionNumber = 1 : NumberofCondition
            for r = 1 : NumberofTrialPerCondition
                BlockNumber = 3 + ( ConditionNumber - 1 ) * NumberofTrialPerCondition + r;
                CurrentBlockAUCHbO = squeeze( subjects.EnhancedAnalysis.BlockLevelAUCHbO( SubjectIndex , ConditionNumber , r , : ) );
                CurrentBlockMaximumHbO = squeeze( subjects.EnhancedAnalysis.BlockLevelMaximumHbO( SubjectIndex , ConditionNumber , r , : ) );
                CurrentBlockRobustPeakHbO = squeeze( subjects.EnhancedAnalysis.BlockLevelRobustPeakHbO( SubjectIndex , ConditionNumber , r , : ) );

                BlockResult_Subject = [ BlockResult_Subject; EnhancedAnalysis.SubjectList(SubjectIndex) ];
                BlockResult_Condition = [ BlockResult_Condition; ConditionNumber ];
                BlockResult_ConditionName = [ BlockResult_ConditionName; EnhancedAnalysis.ConditionNames(ConditionNumber) ];
                BlockResult_Block = [ BlockResult_Block; BlockNumber ];
                BlockResult_GlobalMeanHbO = [ BlockResult_GlobalMeanHbO; subjects.EnhancedAnalysis.BlockLevelGlobalMeanHbO( SubjectIndex , ConditionNumber , r ) ];
                BlockResult_GlobalMedianHbO = [ BlockResult_GlobalMedianHbO; subjects.EnhancedAnalysis.BlockLevelGlobalMedianHbO( SubjectIndex , ConditionNumber , r ) ];
                BlockResult_GlobalMeanAUCHbO = [ BlockResult_GlobalMeanAUCHbO; mean( CurrentBlockAUCHbO , 'omitnan' ) ];
                BlockResult_GlobalMeanMaximumHbO = [ BlockResult_GlobalMeanMaximumHbO; mean( CurrentBlockMaximumHbO , 'omitnan' ) ];
                BlockResult_GlobalMeanRobustPeakHbO = [ BlockResult_GlobalMeanRobustPeakHbO; mean( CurrentBlockRobustPeakHbO , 'omitnan' ) ];
            end
        end
    end

    subjects.EnhancedAnalysis.BlockLevelResultsTable = table( BlockResult_Subject , BlockResult_Condition , ...
        BlockResult_ConditionName , BlockResult_Block , BlockResult_GlobalMeanHbO , BlockResult_GlobalMedianHbO , ...
        BlockResult_GlobalMeanAUCHbO , BlockResult_GlobalMeanMaximumHbO , BlockResult_GlobalMeanRobustPeakHbO , ...
        'VariableNames' , { 'Subject' 'Condition' 'ConditionName' 'Block' 'GlobalChannelAverageMeanHbO' ...
        'GlobalChannelMedianMeanHbO' 'GlobalChannelAverageAUCHbO' 'GlobalChannelAverageMaximumHbO' ...
        'GlobalChannelAverageRobustPeakHbO95' } );

% Long-Format Subject-Level Result Table
    Result_Subject = [];
    Result_Condition = [];
    Result_Optode = [];
    Result_MeanHbO = [];
    Result_MedianAcrossBlocksMeanHbO = [];
    Result_AUCHbO = [];
    Result_MaximumHbO = [];
    Result_RobustPeakHbO = [];

    for SubjectIndex = 1 : NumberofSubject
        for ConditionNumber = 1 : NumberofCondition
            for t = 1 : NumberofOptode
                Result_Subject = [ Result_Subject; EnhancedAnalysis.SubjectList(SubjectIndex) ];
                Result_Condition = [ Result_Condition; ConditionNumber ];
                Result_Optode = [ Result_Optode; t ];
                Result_MeanHbO = [ Result_MeanHbO; subjects.EnhancedAnalysis.SubjectLevelMeanHbO( SubjectIndex , ConditionNumber , t ) ];
                Result_MedianAcrossBlocksMeanHbO = [ Result_MedianAcrossBlocksMeanHbO; ...
                    subjects.EnhancedAnalysis.SubjectLevelMedianAcrossBlocksMeanHbO( SubjectIndex , ConditionNumber , t ) ];
                Result_AUCHbO = [ Result_AUCHbO; subjects.EnhancedAnalysis.SubjectLevelAUCHbO( SubjectIndex , ConditionNumber , t ) ];
                Result_MaximumHbO = [ Result_MaximumHbO; subjects.EnhancedAnalysis.SubjectLevelMaximumHbO( SubjectIndex , ConditionNumber , t ) ];
                Result_RobustPeakHbO = [ Result_RobustPeakHbO; subjects.EnhancedAnalysis.SubjectLevelRobustPeakHbO( SubjectIndex , ConditionNumber , t ) ];
            end
        end
    end

    subjects.EnhancedAnalysis.SubjectLevelResultsTable = table( Result_Subject , Result_Condition , Result_Optode , ...
        Result_MeanHbO , Result_MedianAcrossBlocksMeanHbO , Result_AUCHbO , Result_MaximumHbO , Result_RobustPeakHbO , ...
        'VariableNames' , { 'Subject' 'Condition' 'Optode' 'MeanAcrossBlocksHbO' 'MedianAcrossBlocksHbO' ...
        'AUCHbO' 'MaximumHbO' 'RobustPeakHbO95' } );

% Exploratory Channel-Wise Statistics - primary mean-across-blocks analysis
    Statistical_Optode = ( 1 : NumberofOptode )';
    Statistical_ValidSubjectCount = NaN( NumberofOptode , 1 );
    Statistical_MeanDifference3minus1 = NaN( NumberofOptode , 1 );
    Statistical_CohenDz = NaN( NumberofOptode , 1 );
    Statistical_CI95Lower = NaN( NumberofOptode , 1 );
    Statistical_CI95Upper = NaN( NumberofOptode , 1 );
    Statistical_ExactPairedSignFlipP = NaN( NumberofOptode , 1 );
    Statistical_OmnibusStatistic = NaN( NumberofOptode , 1 );
    Statistical_ExactOmnibusP = NaN( NumberofOptode , 1 );

    for t = 1 : NumberofOptode
        CurrentChannelData = squeeze( subjects.EnhancedAnalysis.SubjectLevelMeanHbO( : , : , t ) );
        CurrentDifference = CurrentChannelData( : , 3 ) - CurrentChannelData( : , 1 );
        [ Statistical_MeanDifference3minus1(t) , Statistical_ExactPairedSignFlipP(t) , Statistical_ValidSubjectCount(t) ] = ...
            exactPairedSignFlipPermutation( CurrentDifference );
        [ Statistical_OmnibusStatistic(t) , Statistical_ExactOmnibusP(t) ] = ...
            exactRepeatedMeasuresOmnibusPermutation( CurrentChannelData );

        CurrentDifference = CurrentDifference( isfinite(CurrentDifference) );
        if length( CurrentDifference ) >= 2
            CurrentDifferenceStandardDeviation = std( CurrentDifference );
            if CurrentDifferenceStandardDeviation > 0
                Statistical_CohenDz(t) = mean( CurrentDifference ) / CurrentDifferenceStandardDeviation;
            end
            [ Statistical_CI95Lower(t) , Statistical_CI95Upper(t) ] = exactBootstrapMeanCI( CurrentDifference , 0.95 );
        end
    end

    Statistical_PairedFDRAdjustedP = benjaminiHochbergFDR( Statistical_ExactPairedSignFlipP );
    Statistical_PairedSignificantAtFDR05 = Statistical_PairedFDRAdjustedP <= 0.05;
    Statistical_OmnibusFDRAdjustedP = benjaminiHochbergFDR( Statistical_ExactOmnibusP );
    Statistical_OmnibusSignificantAtFDR05 = Statistical_OmnibusFDRAdjustedP <= 0.05;

    subjects.EnhancedAnalysis.ChannelStatisticsTable = table( Statistical_Optode , Statistical_ValidSubjectCount , ...
        Statistical_MeanDifference3minus1 , Statistical_CohenDz , Statistical_CI95Lower , Statistical_CI95Upper , ...
        Statistical_ExactPairedSignFlipP , Statistical_PairedFDRAdjustedP , Statistical_PairedSignificantAtFDR05 , ...
        Statistical_OmnibusStatistic , Statistical_ExactOmnibusP , Statistical_OmnibusFDRAdjustedP , Statistical_OmnibusSignificantAtFDR05 , ...
        'VariableNames' , { 'Optode' 'ValidSubjectCount' 'MeanDifference3minus1' 'CohenDz' 'CI95Lower' 'CI95Upper' ...
        'ExactPairedSignFlipP' 'PairedFDRAdjustedP' 'PairedSignificantAtFDR05' ...
        'OmnibusStatistic' 'ExactOmnibusP' 'OmnibusFDRAdjustedP' 'OmnibusSignificantAtFDR05' } );

% Global Channel-Average Summaries
    subjects.EnhancedAnalysis.SubjectGlobalMeanHbO = squeeze( mean( subjects.EnhancedAnalysis.SubjectLevelMeanHbO , 3 , 'omitnan' ) );
    subjects.EnhancedAnalysis.SubjectGlobalMedianAcrossBlocksHbO = squeeze( ...
        mean( subjects.EnhancedAnalysis.SubjectLevelMedianAcrossBlocksMeanHbO , 3 , 'omitnan' ) );

    GlobalDifference = subjects.EnhancedAnalysis.SubjectGlobalMeanHbO( : , 3 ) - subjects.EnhancedAnalysis.SubjectGlobalMeanHbO( : , 1 );
    [ GlobalMeanDifference3minus1 , GlobalExactPairedSignFlipP , GlobalValidSubjectCount ] = ...
        exactPairedSignFlipPermutation( GlobalDifference );
    [ GlobalOmnibusStatistic , GlobalExactOmnibusP ] = ...
        exactRepeatedMeasuresOmnibusPermutation( subjects.EnhancedAnalysis.SubjectGlobalMeanHbO );

    GlobalDifferenceValid = GlobalDifference( isfinite(GlobalDifference) );
    GlobalCohenDz = NaN;
    if length( GlobalDifferenceValid ) >= 2 && std( GlobalDifferenceValid ) > 0
        GlobalCohenDz = mean( GlobalDifferenceValid ) / std( GlobalDifferenceValid );
    end
    [ GlobalCI95Lower , GlobalCI95Upper ] = exactBootstrapMeanCI( GlobalDifferenceValid , 0.95 );
    GlobalMinimumAttainableTwoSidedSignFlipP = 2 / ( 2 ^ GlobalValidSubjectCount );

% Mean-versus-Median Block-Aggregation Sensitivity
    MedianAggregationDifference = subjects.EnhancedAnalysis.SubjectGlobalMedianAcrossBlocksHbO( : , 3 ) - ...
        subjects.EnhancedAnalysis.SubjectGlobalMedianAcrossBlocksHbO( : , 1 );
    [ MedianAggregationMeanDifference3minus1 , MedianAggregationExactPairedSignFlipP , MedianAggregationValidSubjectCount ] = ...
        exactPairedSignFlipPermutation( MedianAggregationDifference );
    [ MedianAggregationOmnibusStatistic , MedianAggregationExactOmnibusP ] = ...
        exactRepeatedMeasuresOmnibusPermutation( subjects.EnhancedAnalysis.SubjectGlobalMedianAcrossBlocksHbO );

    MedianAggregationDifferenceValid = MedianAggregationDifference( isfinite(MedianAggregationDifference) );
    MedianAggregationCohenDz = NaN;
    if length( MedianAggregationDifferenceValid ) >= 2 && std( MedianAggregationDifferenceValid ) > 0
        MedianAggregationCohenDz = mean( MedianAggregationDifferenceValid ) / std( MedianAggregationDifferenceValid );
    end
    [ MedianAggregationCI95Lower , MedianAggregationCI95Upper ] = ...
        exactBootstrapMeanCI( MedianAggregationDifferenceValid , 0.95 );

    AggregationMethod = { EnhancedAnalysis.PrimaryBlockAggregation; EnhancedAnalysis.SensitivityBlockAggregation };
    Aggregation_MeanDifference3minus1 = [ GlobalMeanDifference3minus1; MedianAggregationMeanDifference3minus1 ];
    Aggregation_CohenDz = [ GlobalCohenDz; MedianAggregationCohenDz ];
    Aggregation_CI95Lower = [ GlobalCI95Lower; MedianAggregationCI95Lower ];
    Aggregation_CI95Upper = [ GlobalCI95Upper; MedianAggregationCI95Upper ];
    Aggregation_ExactPairedSignFlipP = [ GlobalExactPairedSignFlipP; MedianAggregationExactPairedSignFlipP ];
    Aggregation_OmnibusStatistic = [ GlobalOmnibusStatistic; MedianAggregationOmnibusStatistic ];
    Aggregation_ExactOmnibusP = [ GlobalExactOmnibusP; MedianAggregationExactOmnibusP ];
    Aggregation_ValidSubjectCount = [ GlobalValidSubjectCount; MedianAggregationValidSubjectCount ];

    subjects.EnhancedAnalysis.BlockAggregationStatisticsTable = table( AggregationMethod , ...
        Aggregation_MeanDifference3minus1 , Aggregation_CohenDz , Aggregation_CI95Lower , Aggregation_CI95Upper , ...
        Aggregation_ExactPairedSignFlipP , Aggregation_OmnibusStatistic , Aggregation_ExactOmnibusP , Aggregation_ValidSubjectCount , ...
        'VariableNames' , { 'AggregationMethod' 'MeanDifference3minus1' 'CohenDz' 'CI95Lower' 'CI95Upper' ...
        'ExactPairedSignFlipP' 'OmnibusStatistic' 'ExactOmnibusP' 'ValidSubjectCount' } );

    Aggregation_Subject = [];
    Aggregation_Condition = [];
    Aggregation_ConditionName = cell( 0 , 1 );
    Aggregation_MeanAcrossBlocksGlobalHbO = [];
    Aggregation_MedianAcrossBlocksGlobalHbO = [];
    Aggregation_MedianMinusMean = [];

    for SubjectIndex = 1 : NumberofSubject
        for ConditionNumber = 1 : NumberofCondition
            CurrentMeanAggregation = subjects.EnhancedAnalysis.SubjectGlobalMeanHbO( SubjectIndex , ConditionNumber );
            CurrentMedianAggregation = subjects.EnhancedAnalysis.SubjectGlobalMedianAcrossBlocksHbO( SubjectIndex , ConditionNumber );
            Aggregation_Subject = [ Aggregation_Subject; EnhancedAnalysis.SubjectList(SubjectIndex) ];
            Aggregation_Condition = [ Aggregation_Condition; ConditionNumber ];
            Aggregation_ConditionName = [ Aggregation_ConditionName; EnhancedAnalysis.ConditionNames(ConditionNumber) ];
            Aggregation_MeanAcrossBlocksGlobalHbO = [ Aggregation_MeanAcrossBlocksGlobalHbO; CurrentMeanAggregation ];
            Aggregation_MedianAcrossBlocksGlobalHbO = [ Aggregation_MedianAcrossBlocksGlobalHbO; CurrentMedianAggregation ];
            Aggregation_MedianMinusMean = [ Aggregation_MedianMinusMean; CurrentMedianAggregation - CurrentMeanAggregation ];
        end
    end

    subjects.EnhancedAnalysis.BlockAggregationSensitivityTable = table( Aggregation_Subject , Aggregation_Condition , ...
        Aggregation_ConditionName , Aggregation_MeanAcrossBlocksGlobalHbO , Aggregation_MedianAcrossBlocksGlobalHbO , ...
        Aggregation_MedianMinusMean , 'VariableNames' , { 'Subject' 'Condition' 'ConditionName' ...
        'MeanAcrossBlocksGlobalHbO' 'MedianAcrossBlocksGlobalHbO' 'MedianMinusMean' } );

% Leave-One-Participant-Out Influence Analysis
    FullSampleConditionMeans = mean( subjects.EnhancedAnalysis.SubjectGlobalMeanHbO , 1 , 'omitnan' );
    FullSampleDifference3minus1 = FullSampleConditionMeans(3) - FullSampleConditionMeans(1);

    Influence_AnalysisSet = cell( NumberofSubject + 1 , 1 );
    Influence_OmittedSubject = NaN( NumberofSubject + 1 , 1 );
    Influence_RemainingSubjectCount = NaN( NumberofSubject + 1 , 1 );
    Influence_Mean1Back = NaN( NumberofSubject + 1 , 1 );
    Influence_Mean2Back = NaN( NumberofSubject + 1 , 1 );
    Influence_Mean3Back = NaN( NumberofSubject + 1 , 1 );
    Influence_Difference3minus1 = NaN( NumberofSubject + 1 , 1 );
    Influence_CohenDz = NaN( NumberofSubject + 1 , 1 );
    Influence_ExactPairedSignFlipP = NaN( NumberofSubject + 1 , 1 );
    Influence_DirectionChangedFromFull = false( NumberofSubject + 1 , 1 );
    Influence_Interpretation = cell( NumberofSubject + 1 , 1 );

    for InfluenceIndex = 0 : NumberofSubject
        RemainingSubject = true( NumberofSubject , 1 );
        if InfluenceIndex == 0
            InfluenceRow = 1;
            Influence_AnalysisSet{ InfluenceRow } = 'Full sample';
            Influence_Interpretation{ InfluenceRow } = 'Reference';
        else
            InfluenceRow = InfluenceIndex + 1;
            RemainingSubject( InfluenceIndex ) = false;
            Influence_OmittedSubject( InfluenceRow ) = EnhancedAnalysis.SubjectList( InfluenceIndex );
            Influence_AnalysisSet{ InfluenceRow } = sprintf( 'Leave out Subject %i' , EnhancedAnalysis.SubjectList(InfluenceIndex) );
        end

        RemainingData = subjects.EnhancedAnalysis.SubjectGlobalMeanHbO( RemainingSubject , : );
        RemainingConditionMeans = mean( RemainingData , 1 , 'omitnan' );
        RemainingDifference = RemainingData( : , 3 ) - RemainingData( : , 1 );
        [ CurrentMeanDifference , CurrentSignFlipP , CurrentValidSubjectCount ] = ...
            exactPairedSignFlipPermutation( RemainingDifference );

        CurrentCohenDz = NaN;
        RemainingDifferenceValid = RemainingDifference( isfinite(RemainingDifference) );
        if length( RemainingDifferenceValid ) >= 2 && std( RemainingDifferenceValid ) > 0
            CurrentCohenDz = mean( RemainingDifferenceValid ) / std( RemainingDifferenceValid );
        end

        Influence_RemainingSubjectCount( InfluenceRow ) = CurrentValidSubjectCount;
        Influence_Mean1Back( InfluenceRow ) = RemainingConditionMeans(1);
        Influence_Mean2Back( InfluenceRow ) = RemainingConditionMeans(2);
        Influence_Mean3Back( InfluenceRow ) = RemainingConditionMeans(3);
        Influence_Difference3minus1( InfluenceRow ) = CurrentMeanDifference;
        Influence_CohenDz( InfluenceRow ) = CurrentCohenDz;
        Influence_ExactPairedSignFlipP( InfluenceRow ) = CurrentSignFlipP;

        if InfluenceIndex > 0
            Influence_DirectionChangedFromFull( InfluenceRow ) = sign( CurrentMeanDifference ) ~= sign( FullSampleDifference3minus1 );
            if Influence_DirectionChangedFromFull( InfluenceRow )
                Influence_Interpretation{ InfluenceRow } = 'Direction changed';
            else
                Influence_Interpretation{ InfluenceRow } = 'Direction retained';
            end
        end
    end

    subjects.EnhancedAnalysis.LeaveOneParticipantOutTable = table( Influence_AnalysisSet , Influence_OmittedSubject , ...
        Influence_RemainingSubjectCount , Influence_Mean1Back , Influence_Mean2Back , Influence_Mean3Back , ...
        Influence_Difference3minus1 , Influence_CohenDz , Influence_ExactPairedSignFlipP , ...
        Influence_DirectionChangedFromFull , Influence_Interpretation , ...
        'VariableNames' , { 'AnalysisSet' 'OmittedSubject' 'RemainingSubjectCount' 'Mean1Back' 'Mean2Back' 'Mean3Back' ...
        'MeanDifference3minus1' 'CohenDz' 'ExactPairedSignFlipP' 'DirectionChangedFromFull' 'Interpretation' } );

    LeaveOneOutDirectionChangeCount = sum( Influence_DirectionChangedFromFull( 2 : end ) );
    LeaveOneOutMaximumAbsoluteDifferenceShift = max( abs( Influence_Difference3minus1( 2 : end ) - FullSampleDifference3minus1 ) );

% Global Statistics Table
    Metric = { 'Mean 3-back minus 1-back'; 'Cohen dz'; '95% CI lower'; '95% CI upper'; ...
        'Exact paired sign-flip p'; 'Minimum attainable two-sided sign-flip p'; ...
        'Repeated-measures omnibus statistic'; 'Exact repeated-measures omnibus p'; 'Valid subject count'; ...
        'Leave-one-out direction-change count'; 'Maximum absolute leave-one-out difference shift' };
    MetricValue = [ GlobalMeanDifference3minus1; GlobalCohenDz; GlobalCI95Lower; GlobalCI95Upper; ...
        GlobalExactPairedSignFlipP; GlobalMinimumAttainableTwoSidedSignFlipP; ...
        GlobalOmnibusStatistic; GlobalExactOmnibusP; GlobalValidSubjectCount; ...
        LeaveOneOutDirectionChangeCount; LeaveOneOutMaximumAbsoluteDifferenceShift ];
    subjects.EnhancedAnalysis.GlobalStatisticsTable = table( Metric , MetricValue );

% Group Condition Summary
    Summary_Condition = ( 1 : NumberofCondition )';
    Summary_ConditionName = EnhancedAnalysis.ConditionNames';
    Summary_GlobalMeanHbO = mean( subjects.EnhancedAnalysis.SubjectGlobalMeanHbO , 1 , 'omitnan' )';
    Summary_GlobalSEMHbO = ( std( subjects.EnhancedAnalysis.SubjectGlobalMeanHbO , 0 , 1 , 'omitnan' ) ./ ...
        sqrt( sum( isfinite(subjects.EnhancedAnalysis.SubjectGlobalMeanHbO) , 1 ) ) )';
    Summary_GlobalMedianHbO = median( subjects.EnhancedAnalysis.SubjectGlobalMeanHbO , 1 , 'omitnan' )';
    Summary_MedianBlockAggregationMeanHbO = mean( subjects.EnhancedAnalysis.SubjectGlobalMedianAcrossBlocksHbO , 1 , 'omitnan' )';
    Summary_MedianBlockAggregationMedianHbO = median( subjects.EnhancedAnalysis.SubjectGlobalMedianAcrossBlocksHbO , 1 , 'omitnan' )';

    subjects.EnhancedAnalysis.GroupConditionSummaryTable = table( Summary_Condition , Summary_ConditionName , ...
        Summary_GlobalMeanHbO , Summary_GlobalSEMHbO , Summary_GlobalMedianHbO , ...
        Summary_MedianBlockAggregationMeanHbO , Summary_MedianBlockAggregationMedianHbO , ...
        'VariableNames' , { 'Condition' 'ConditionName' 'PrimaryGlobalMeanHbO' 'PrimaryGlobalSEMHbO' ...
        'PrimaryGlobalMedianHbO' 'MedianBlockAggregationGroupMeanHbO' 'MedianBlockAggregationGroupMedianHbO' } );

% Group Time Courses - all blocks already use the same analysis window
    subjects.EnhancedAnalysis.Time = ( 0 : EnhancedAnalysis.CommonAnalysisFrame - 1 )' / EnhancedAnalysis.fs;
    subjects.EnhancedAnalysis.SubjectGlobalHbOTimeCourse = NaN( EnhancedAnalysis.CommonAnalysisFrame , NumberofCondition , NumberofSubject );
    subjects.EnhancedAnalysis.SubjectGlobalHbRTimeCourse = NaN( EnhancedAnalysis.CommonAnalysisFrame , NumberofCondition , NumberofSubject );

    for SubjectIndex = 1 : NumberofSubject
        for ConditionNumber = 1 : NumberofCondition
            CurrentHbOTimeCourse = subjects.EnhancedAnalysis.SubjectHbOTimeCourse{ SubjectIndex , ConditionNumber };
            CurrentHbRTimeCourse = subjects.EnhancedAnalysis.SubjectHbRTimeCourse{ SubjectIndex , ConditionNumber };
            subjects.EnhancedAnalysis.SubjectGlobalHbOTimeCourse( : , ConditionNumber , SubjectIndex ) = mean( CurrentHbOTimeCourse , 2 , 'omitnan' );
            subjects.EnhancedAnalysis.SubjectGlobalHbRTimeCourse( : , ConditionNumber , SubjectIndex ) = mean( CurrentHbRTimeCourse , 2 , 'omitnan' );
        end
    end

    subjects.EnhancedAnalysis.GroupGlobalHbOTimeCourseMean = mean( subjects.EnhancedAnalysis.SubjectGlobalHbOTimeCourse , 3 , 'omitnan' );
    GroupGlobalHbOValidCount = sum( isfinite(subjects.EnhancedAnalysis.SubjectGlobalHbOTimeCourse) , 3 );
    subjects.EnhancedAnalysis.GroupGlobalHbOTimeCourseSEM = std( subjects.EnhancedAnalysis.SubjectGlobalHbOTimeCourse , 0 , 3 , 'omitnan' ) ./ ...
        sqrt( GroupGlobalHbOValidCount );
    subjects.EnhancedAnalysis.GroupGlobalHbRTimeCourseMean = mean( subjects.EnhancedAnalysis.SubjectGlobalHbRTimeCourse , 3 , 'omitnan' );
    GroupGlobalHbRValidCount = sum( isfinite(subjects.EnhancedAnalysis.SubjectGlobalHbRTimeCourse) , 3 );
    subjects.EnhancedAnalysis.GroupGlobalHbRTimeCourseSEM = std( subjects.EnhancedAnalysis.SubjectGlobalHbRTimeCourse , 0 , 3 , 'omitnan' ) ./ ...
        sqrt( GroupGlobalHbRValidCount );

% Filter-Sensitivity Summary Table
    Sensitivity_Subject = [];
    Sensitivity_Condition = [];
    Sensitivity_FilterConfiguration = cell( 0 , 1 );
    Sensitivity_LowPassCutoffHz = [];
    Sensitivity_GlobalMeanHbO = [];

    for SubjectIndex = 1 : NumberofSubject
        for ConditionNumber = 1 : NumberofCondition
            for f = 1 : NumberofFilterConfiguration
                Sensitivity_Subject = [ Sensitivity_Subject; EnhancedAnalysis.SubjectList(SubjectIndex) ];
                Sensitivity_Condition = [ Sensitivity_Condition; ConditionNumber ];
                Sensitivity_FilterConfiguration = [ Sensitivity_FilterConfiguration; EnhancedAnalysis.FilterConfigurationNames(f) ];
                Sensitivity_LowPassCutoffHz = [ Sensitivity_LowPassCutoffHz; EnhancedAnalysis.FilterCutoffOptions(f) ];
                Sensitivity_GlobalMeanHbO = [ Sensitivity_GlobalMeanHbO; ...
                    subjects.EnhancedAnalysis.FilterSensitivity.SubjectGlobalMeanHbO( SubjectIndex , ConditionNumber , f ) ];
            end
        end
    end

    subjects.EnhancedAnalysis.FilterSensitivityTable = table( Sensitivity_Subject , Sensitivity_Condition , ...
        Sensitivity_FilterConfiguration , Sensitivity_LowPassCutoffHz , Sensitivity_GlobalMeanHbO , ...
        'VariableNames' , { 'Subject' 'Condition' 'FilterConfiguration' 'LowPassCutoffHz' 'GlobalMeanHbO' } );

% Legacy-versus-Enhanced Comparison Table
    Comparison_Subject = [];
    Comparison_Condition = [];
    Comparison_LegacyMeanHbO = [];
    Comparison_EnhancedMeanHbO = [];
    Comparison_Difference = [];

    for SubjectIndex = 1 : NumberofSubject
        for ConditionNumber = 1 : NumberofCondition
            LegacyMean = subjects.EnhancedAnalysis.LegacySubjectGlobalMeanHbO( SubjectIndex , ConditionNumber );
            EnhancedMean = subjects.EnhancedAnalysis.SubjectGlobalMeanHbO( SubjectIndex , ConditionNumber );
            Comparison_Subject = [ Comparison_Subject; EnhancedAnalysis.SubjectList(SubjectIndex) ];
            Comparison_Condition = [ Comparison_Condition; ConditionNumber ];
            Comparison_LegacyMeanHbO = [ Comparison_LegacyMeanHbO; LegacyMean ];
            Comparison_EnhancedMeanHbO = [ Comparison_EnhancedMeanHbO; EnhancedMean ];
            Comparison_Difference = [ Comparison_Difference; EnhancedMean - LegacyMean ];
        end
    end

    subjects.EnhancedAnalysis.LegacyVersusEnhancedTable = table( Comparison_Subject , Comparison_Condition , ...
        Comparison_LegacyMeanHbO , Comparison_EnhancedMeanHbO , Comparison_Difference , ...
        'VariableNames' , { 'Subject' 'Condition' 'LegacyMeanHbO' 'EnhancedMeanHbO' 'EnhancedMinusLegacy' } );

% Enhanced Figures
    if EnhancedAnalysis.CreateFigures

        % Group mean and standard error for each measurement channel.
            FigureGroupOptode = figure( 'Visible' , 'off' , 'units' , 'normalized' , 'outerposition' , [0 0 1 1] );
            BarHandle = bar( 1 : NumberofOptode , subjects.EnhancedAnalysis.GroupMeanHbO' );
            hold on;
            for ConditionNumber = 1 : NumberofCondition
                errorbar( BarHandle(ConditionNumber).XEndPoints , subjects.EnhancedAnalysis.GroupMeanHbO( ConditionNumber , : ) , ...
                    subjects.EnhancedAnalysis.GroupSEMHbO( ConditionNumber , : ) , 'k.' , 'LineWidth' , 1 );
            end
            xlabel( 'Measurement channel (legacy optode index)' );
            ylabel( EnhancedAnalysis.HbOOutputQuantityLabel );
            title( sprintf( 'Enhanced Analysis: Group Mean HbO by Condition and Channel (%s)' , ...
                EnhancedAnalysis.PrimaryFilterName ) );
            legend( EnhancedAnalysis.ConditionNames , 'Location' , 'best' );
            grid on;
            hold off;
            exportgraphics( FigureGroupOptode , fullfile( EnhancedAnalysis.OutputFolder , 'enhanced_group_hbo_by_channel.png' ) , 'Resolution' , 300 );
            close( FigureGroupOptode );

        % Participant-level paired global channel-average responses with IDs.
            FigurePaired = figure( 'Visible' , 'off' , 'units' , 'normalized' , 'outerposition' , [0 0 0.72 0.78] );
            hold on;
            IndividualHandle = gobjects( 1 , 1 );
            for SubjectIndex = 1 : NumberofSubject
                CurrentHandle = plot( 1 : NumberofCondition , subjects.EnhancedAnalysis.SubjectGlobalMeanHbO( SubjectIndex , : ) , ...
                    '-o' , 'LineWidth' , 1 );
                if SubjectIndex == 1
                    IndividualHandle = CurrentHandle;
                else
                    set( CurrentHandle , 'HandleVisibility' , 'off' );
                end
                text( 3.04 , subjects.EnhancedAnalysis.SubjectGlobalMeanHbO( SubjectIndex , 3 ) , ...
                    sprintf( 'S%i' , EnhancedAnalysis.SubjectList(SubjectIndex) ) , 'FontSize' , 9 );
            end
            GroupMeanHandle = plot( 1 : NumberofCondition , mean( subjects.EnhancedAnalysis.SubjectGlobalMeanHbO , 1 , 'omitnan' ) , ...
                'k-o' , 'LineWidth' , 3 , 'MarkerFaceColor' , 'k' );
            GroupMedianHandle = plot( 1 : NumberofCondition , median( subjects.EnhancedAnalysis.SubjectGlobalMeanHbO , 1 , 'omitnan' ) , ...
                'k--s' , 'LineWidth' , 2 );
            yline( 0 , ':' , 'HandleVisibility' , 'off' );
            xlim( [0.8 3.35] );
            xticks( 1 : NumberofCondition );
            xticklabels( EnhancedAnalysis.ConditionNames );
            ylabel( EnhancedAnalysis.HbOOutputQuantityLabel );
            title( sprintf( 'Participant-Level Channel-Average HbO: paired sign-flip p = %.4f' , GlobalExactPairedSignFlipP ) );
            legend( [ IndividualHandle GroupMeanHandle GroupMedianHandle ] , ...
                { 'Individual participants' 'Group mean' 'Group median' } , 'Location' , 'best' );
            grid on;
            hold off;
            exportgraphics( FigurePaired , fullfile( EnhancedAnalysis.OutputFolder , 'enhanced_global_hbo_paired.png' ) , 'Resolution' , 300 );
            close( FigurePaired );

        % Participant- and block-level global HbO consistency.
            AllBlockValues = subjects.EnhancedAnalysis.BlockLevelGlobalMeanHbO( : );
            AllBlockValues = AllBlockValues( isfinite(AllBlockValues) );
            if isempty( AllBlockValues )
                BlockYMinimum = -1;
                BlockYMaximum = 1;
            else
                BlockYMinimum = min( AllBlockValues );
                BlockYMaximum = max( AllBlockValues );
                BlockYMargin = 0.08 * max( BlockYMaximum - BlockYMinimum , eps );
                BlockYMinimum = BlockYMinimum - BlockYMargin;
                BlockYMaximum = BlockYMaximum + BlockYMargin;
            end

            FigureBlockConsistency = figure( 'Visible' , 'off' , 'units' , 'normalized' , 'outerposition' , [0 0 1 1] );
            BlockLayout = tiledlayout( 2 , 3 , 'TileSpacing' , 'compact' , 'Padding' , 'compact' );
            ConditionHandle = gobjects( 1 , NumberofCondition );
            MeanBlockHandle = gobjects( 1 , 1 );
            MedianBlockHandle = gobjects( 1 , 1 );

            for SubjectIndex = 1 : NumberofSubject
                nexttile;
                hold on;
                for ConditionNumber = 1 : NumberofCondition
                    CurrentBlockValues = squeeze( subjects.EnhancedAnalysis.BlockLevelGlobalMeanHbO( SubjectIndex , ConditionNumber , : ) );
                    CurrentBlockX = ConditionNumber + [ -0.16 0 0.16 ]';
                    CurrentConditionHandle = plot( CurrentBlockX , CurrentBlockValues , '-o' , 'LineWidth' , 1 );
                    if SubjectIndex == 1
                        ConditionHandle( ConditionNumber ) = CurrentConditionHandle;
                    else
                        set( CurrentConditionHandle , 'HandleVisibility' , 'off' );
                    end
                    CurrentMeanHandle = plot( ConditionNumber , mean( CurrentBlockValues , 'omitnan' ) , ...
                        'ks' , 'MarkerFaceColor' , 'k' , 'MarkerSize' , 7 );
                    CurrentMedianHandle = plot( ConditionNumber , median( CurrentBlockValues , 'omitnan' ) , ...
                        'kd' , 'MarkerSize' , 7 , 'LineWidth' , 1.2 );
                    if SubjectIndex == 1 && ConditionNumber == 1
                        MeanBlockHandle = CurrentMeanHandle;
                        MedianBlockHandle = CurrentMedianHandle;
                    else
                        set( CurrentMeanHandle , 'HandleVisibility' , 'off' );
                        set( CurrentMedianHandle , 'HandleVisibility' , 'off' );
                    end
                end
                yline( 0 , ':' , 'HandleVisibility' , 'off' );
                xlim( [0.65 3.35] );
                ylim( [BlockYMinimum BlockYMaximum] );
                xticks( 1 : NumberofCondition );
                xticklabels( EnhancedAnalysis.ConditionNames );
                ylabel( EnhancedAnalysis.HbOOutputQuantityLabel );
                title( sprintf( 'Subject %i' , EnhancedAnalysis.SubjectList(SubjectIndex) ) );
                grid on;
                if SubjectIndex == 1
                    legend( [ ConditionHandle MeanBlockHandle MedianBlockHandle ] , ...
                        [ EnhancedAnalysis.ConditionNames { 'Three-block mean' 'Three-block median' } ] , 'Location' , 'best' );
                end
                hold off;
            end

            nexttile;
            axis off;
            text( 0 , 0.80 , 'Each colored line contains the three recorded blocks for one condition.' , 'FontSize' , 11 );
            text( 0 , 0.62 , 'Square: arithmetic mean across blocks.' , 'FontSize' , 11 );
            text( 0 , 0.46 , 'Diamond: median across blocks.' , 'FontSize' , 11 );
            text( 0 , 0.24 , 'No participant or block is removed from the primary analysis.' , 'FontSize' , 11 );
            title( BlockLayout , 'Participant- and Block-Level Global HbO Responses' );
            exportgraphics( FigureBlockConsistency , fullfile( EnhancedAnalysis.OutputFolder , ...
                'enhanced_block_level_hbo_consistency.png' ) , 'Resolution' , 300 );
            close( FigureBlockConsistency );

        % Sensitivity of the 3-back minus 1-back contrast to block aggregation.
            FigureAggregationSensitivity = figure( 'Visible' , 'off' , 'units' , 'normalized' , 'outerposition' , [0 0 0.65 0.72] );
            MeanAggregationDifference = subjects.EnhancedAnalysis.SubjectGlobalMeanHbO( : , 3 ) - ...
                subjects.EnhancedAnalysis.SubjectGlobalMeanHbO( : , 1 );
            MedianAggregationDifferencePlot = subjects.EnhancedAnalysis.SubjectGlobalMedianAcrossBlocksHbO( : , 3 ) - ...
                subjects.EnhancedAnalysis.SubjectGlobalMedianAcrossBlocksHbO( : , 1 );
            hold on;
            AggregationIndividualHandle = gobjects( 1 , 1 );
            for SubjectIndex = 1 : NumberofSubject
                CurrentHandle = plot( [1 2] , [ MeanAggregationDifference(SubjectIndex) MedianAggregationDifferencePlot(SubjectIndex) ] , ...
                    '-o' , 'LineWidth' , 1 );
                if SubjectIndex == 1
                    AggregationIndividualHandle = CurrentHandle;
                else
                    set( CurrentHandle , 'HandleVisibility' , 'off' );
                end
                text( 2.03 , MedianAggregationDifferencePlot(SubjectIndex) , ...
                    sprintf( 'S%i' , EnhancedAnalysis.SubjectList(SubjectIndex) ) , 'FontSize' , 9 );
            end
            AggregationMeanHandle = plot( [1 2] , [ mean(MeanAggregationDifference,'omitnan') mean(MedianAggregationDifferencePlot,'omitnan') ] , ...
                'k-o' , 'LineWidth' , 3 , 'MarkerFaceColor' , 'k' );
            yline( 0 , ':' , 'HandleVisibility' , 'off' );
            xlim( [0.8 2.35] );
            xticks( [1 2] );
            xticklabels( { 'Mean across blocks' 'Median across blocks' } );
            ylabel( [ EnhancedAnalysis.HbOOutputQuantityLabel ' (3-back minus 1-back)' ] );
            title( sprintf( 'Block-Aggregation Sensitivity: p_{mean} = %.4f, p_{median} = %.4f' , ...
                GlobalExactPairedSignFlipP , MedianAggregationExactPairedSignFlipP ) );
            legend( [ AggregationIndividualHandle AggregationMeanHandle ] , ...
                { 'Individual participants' 'Group mean difference' } , 'Location' , 'best' );
            grid on;
            hold off;
            exportgraphics( FigureAggregationSensitivity , fullfile( EnhancedAnalysis.OutputFolder , ...
                'enhanced_block_aggregation_sensitivity.png' ) , 'Resolution' , 300 );
            close( FigureAggregationSensitivity );

        % Leave-one-participant-out influence on the global 3-back minus 1-back contrast.
            FigureInfluence = figure( 'Visible' , 'off' , 'units' , 'normalized' , 'outerposition' , [0 0 0.72 0.70] );
            InfluenceX = 1 : height( subjects.EnhancedAnalysis.LeaveOneParticipantOutTable );
            plot( InfluenceX , subjects.EnhancedAnalysis.LeaveOneParticipantOutTable.MeanDifference3minus1 , '-o' , 'LineWidth' , 2 );
            hold on;
            yline( 0 , ':' );
            xticks( InfluenceX );
            xticklabels( subjects.EnhancedAnalysis.LeaveOneParticipantOutTable.AnalysisSet );
            xtickangle( 20 );
            ylabel( [ EnhancedAnalysis.HbOOutputQuantityLabel ' (3-back minus 1-back)' ] );
            title( 'Leave-One-Participant-Out Influence Analysis' );
            grid on;
            hold off;
            exportgraphics( FigureInfluence , fullfile( EnhancedAnalysis.OutputFolder , ...
                'enhanced_leave_one_participant_out.png' ) , 'Resolution' , 300 );
            close( FigureInfluence );

        % Group HbO and HbR time courses with a common y-axis and shaded HbO SEM.
            TimeCourseLowerHbO = subjects.EnhancedAnalysis.GroupGlobalHbOTimeCourseMean - ...
                subjects.EnhancedAnalysis.GroupGlobalHbOTimeCourseSEM;
            TimeCourseUpperHbO = subjects.EnhancedAnalysis.GroupGlobalHbOTimeCourseMean + ...
                subjects.EnhancedAnalysis.GroupGlobalHbOTimeCourseSEM;
            TimeCourseYValues = [ TimeCourseLowerHbO(:); TimeCourseUpperHbO(:); ...
                subjects.EnhancedAnalysis.GroupGlobalHbRTimeCourseMean(:) ];
            TimeCourseYValues = TimeCourseYValues( isfinite(TimeCourseYValues) );
            if isempty( TimeCourseYValues )
                TimeCourseYMinimum = -1;
                TimeCourseYMaximum = 1;
            else
                TimeCourseYMinimum = min( TimeCourseYValues );
                TimeCourseYMaximum = max( TimeCourseYValues );
                TimeCourseYMargin = 0.08 * max( TimeCourseYMaximum - TimeCourseYMinimum , eps );
                TimeCourseYMinimum = TimeCourseYMinimum - TimeCourseYMargin;
                TimeCourseYMaximum = TimeCourseYMaximum + TimeCourseYMargin;
            end

            FigureTimeCourse = figure( 'Visible' , 'off' , 'units' , 'normalized' , 'outerposition' , [0 0 1 1] );
            for ConditionNumber = 1 : NumberofCondition
                subplot( 1 , 3 , ConditionNumber );
                CurrentTime = subjects.EnhancedAnalysis.Time;
                CurrentHbOMean = subjects.EnhancedAnalysis.GroupGlobalHbOTimeCourseMean( : , ConditionNumber );
                CurrentHbOSEM = subjects.EnhancedAnalysis.GroupGlobalHbOTimeCourseSEM( : , ConditionNumber );
                CurrentHbRMean = subjects.EnhancedAnalysis.GroupGlobalHbRTimeCourseMean( : , ConditionNumber );

                SEMHandle = fill( [ CurrentTime; flipud(CurrentTime) ] , ...
                    [ CurrentHbOMean - CurrentHbOSEM; flipud(CurrentHbOMean + CurrentHbOSEM) ] , ...
                    [0.75 0.75 0.75] , 'EdgeColor' , 'none' , 'FaceAlpha' , 0.35 );
                hold on;
                HbOHandle = plot( CurrentTime , CurrentHbOMean , 'LineWidth' , 2 );
                HbRHandle = plot( CurrentTime , CurrentHbRMean , 'LineWidth' , 2 );
                yline( 0 , ':' , 'HandleVisibility' , 'off' );
                xlabel( 'Time after baseline (s)' );
                ylabel( EnhancedAnalysis.HbOHbROutputQuantityLabel );
                title( EnhancedAnalysis.ConditionNames{ ConditionNumber } );
                ylim( [TimeCourseYMinimum TimeCourseYMaximum] );
                grid on;
                if ConditionNumber == 3
                    legend( [ HbOHandle HbRHandle SEMHandle ] , { 'HbO' 'HbR' 'HbO SEM' } , 'Location' , 'best' );
                end
                hold off;
            end
            sgtitle( 'Enhanced Analysis: Group-Averaged Hemodynamic Time Courses (Common Y-Axis)' );
            exportgraphics( FigureTimeCourse , fullfile( EnhancedAnalysis.OutputFolder , 'enhanced_group_hbo_hbr_timecourses.png' ) , 'Resolution' , 300 );
            close( FigureTimeCourse );

        % Filter sensitivity, including the TDDR-only reference.
            FigureSensitivity = figure( 'Visible' , 'off' , 'units' , 'normalized' , 'outerposition' , [0 0 0.8 0.75] );
            GroupFilterSensitivity = squeeze( mean( subjects.EnhancedAnalysis.FilterSensitivity.SubjectGlobalMeanHbO , 1 , 'omitnan' ) );
            plot( 1 : NumberofFilterConfiguration , GroupFilterSensitivity' , '-o' , 'LineWidth' , 2 );
            xticks( 1 : NumberofFilterConfiguration );
            xticklabels( EnhancedAnalysis.FilterConfigurationNames );
            xtickangle( 20 );
            xlabel( 'Processing configuration' );
            ylabel( EnhancedAnalysis.HbOOutputQuantityLabel );
            title( 'Processing Sensitivity of Global Channel-Average Mean HbO' );
            legend( EnhancedAnalysis.ConditionNames , 'Location' , 'best' );
            grid on;
            exportgraphics( FigureSensitivity , fullfile( EnhancedAnalysis.OutputFolder , 'enhanced_filter_sensitivity.png' ) , 'Resolution' , 300 );
            close( FigureSensitivity );

        % Average quality-control metrics by subject and optode.
            MotionQualityMatrix = NaN( NumberofSubject , NumberofOptode );
            AmbientQualityMatrix = NaN( NumberofSubject , NumberofOptode );
            for SubjectIndex = 1 : NumberofSubject
                i = EnhancedAnalysis.SubjectList( SubjectIndex );
                for t = 1 : NumberofOptode
                    CurrentRows = subjects.EnhancedAnalysis.QualityControlTable.Subject == i & ...
                        subjects.EnhancedAnalysis.QualityControlTable.Optode == t;
                    MotionQualityMatrix( SubjectIndex , t ) = mean( ...
                        subjects.EnhancedAnalysis.QualityControlTable.MotionCandidateFraction( CurrentRows ) , 'omitnan' );
                    AmbientQualityMatrix( SubjectIndex , t ) = mean( ...
                        subjects.EnhancedAnalysis.QualityControlTable.AmbientToSignalRatio( CurrentRows ) , 'omitnan' );
                end
            end

            FigureQuality = figure( 'Visible' , 'off' , 'units' , 'normalized' , 'outerposition' , [0 0 1 0.8] );
            subplot( 2 , 1 , 1 );
                imagesc( MotionQualityMatrix );
                colorbar;
                xticks( 1 : NumberofOptode );
                yticks( 1 : NumberofSubject );
                yticklabels( string(EnhancedAnalysis.SubjectList) );
                xlabel( 'Optode' );
                ylabel( 'Subject' );
                title( 'Mean Fraction of Samples Exceeding the Legacy CV Motion Threshold' );
            subplot( 2 , 1 , 2 );
                imagesc( AmbientQualityMatrix );
                colorbar;
                xticks( 1 : NumberofOptode );
                yticks( 1 : NumberofSubject );
                yticklabels( string(EnhancedAnalysis.SubjectList) );
                xlabel( 'Optode' );
                ylabel( 'Subject' );
                title( 'Mean Ambient-to-Signal Ratio' );
            exportgraphics( FigureQuality , fullfile( EnhancedAnalysis.OutputFolder , 'enhanced_quality_control_summary.png' ) , 'Resolution' , 300 );
            close( FigureQuality );

        % Representative motion-artifact examples selected in the original work.
            FigureMotionCorrection = figure( 'Visible' , 'off' , 'units' , 'normalized' , 'outerposition' , [0 0 1 1] );
            for ExampleIndex = 1 : length( EnhancedAnalysis.RepresentativeMotionSubject )
                i = EnhancedAnalysis.RepresentativeMotionSubject( ExampleIndex );
                BlockNumber = EnhancedAnalysis.RepresentativeMotionBlock( ExampleIndex );
                j = BlockNumber - 3;
                t = EnhancedAnalysis.RepresentativeMotionOptode( ExampleIndex );
                p = 2 * t - 1;
                CurrentData = subjects.( subject{ i } ).( filename{ j , i , 2 } ).data;
                CurrentTime = ( 0 : size(CurrentData,1) - 1 )' / EnhancedAnalysis.fs;
                CurrentRaw730 = CurrentData( : , 3*t - 2 );
                CurrentRaw850 = CurrentData( : , 3*t );
                CurrentOD = subjects.( subject{ i } ).( filenameEnhanced{ j , i , 1 } )( p : p+1 , : )';
                CurrentODTDDR = subjects.( subject{ i } ).( filenameEnhanced{ j , i , 2 } )( p : p+1 , : )';
                CurrentCV730 = subjects.( subject{ i } ).( filename{ j , i , 2 } ).dataCV_5( : , 3*t - 2 );
                CurrentCV850 = subjects.( subject{ i } ).( filename{ j , i , 2 } ).dataCV_5( : , 3*t );

                subplot( 4 , 2 , ExampleIndex );
                    plot( CurrentTime , CurrentRaw730 );
                    hold on;
                    plot( CurrentTime , CurrentRaw850 );
                    title( sprintf( 'Subject %i, Block %i, Optode %i: raw intensity' , i , BlockNumber , t ) );
                    ylabel( 'Raw intensity' );
                    legend( '730 nm' , '850 nm' , 'Location' , 'best' );
                    grid on;
                    hold off;

                subplot( 4 , 2 , 2 + ExampleIndex );
                    plot( CurrentTime , CurrentOD( : , 1 ) );
                    hold on;
                    plot( CurrentTime , CurrentOD( : , 2 ) );
                    title( 'Optical density before TDDR' );
                    ylabel( 'Delta optical density' );
                    grid on;
                    hold off;

                subplot( 4 , 2 , 4 + ExampleIndex );
                    plot( CurrentTime , CurrentODTDDR( : , 1 ) );
                    hold on;
                    plot( CurrentTime , CurrentODTDDR( : , 2 ) );
                    title( 'Optical density after TDDR' );
                    ylabel( 'Delta optical density' );
                    grid on;
                    hold off;

                subplot( 4 , 2 , 6 + ExampleIndex );
                    plot( CurrentTime , CurrentCV730 );
                    hold on;
                    plot( CurrentTime , CurrentCV850 );
                    yline( EnhancedAnalysis.MotionCVThreshold , '--' );
                    yline( -EnhancedAnalysis.MotionCVThreshold , '--' );
                    title( 'Legacy moving coefficient of variation' );
                    xlabel( 'Time (s)' );
                    ylabel( 'Coefficient of variation' );
                    grid on;
                    hold off;
            end
            sgtitle( 'Representative Motion-Artifact Detection and TDDR Attenuation' );
            exportgraphics( FigureMotionCorrection , fullfile( EnhancedAnalysis.OutputFolder , ...
                'representative_motion_artifact_correction.png' ) , 'Resolution' , 300 );
            close( FigureMotionCorrection );

        % Synthetic-filter preservation result.
            FigureFilterTest = figure( 'Visible' , 'off' , 'units' , 'normalized' , 'outerposition' , [0 0 0.8 0.7] );
            plot( SyntheticTime , SyntheticHemodynamicResponse , 'LineWidth' , 2 );
            hold on;
            for f = 2 : length( EnhancedAnalysis.FilterConfigurationTags )
                CurrentCutoff = EnhancedAnalysis.FilterCutoffOptions(f);
                [ bEnhanced , aEnhanced ] = butter( EnhancedAnalysis.FilterOrder , CurrentCutoff / ( EnhancedAnalysis.fs / 2 ) , 'low' );
                SyntheticFiltered = filtfilt( bEnhanced , aEnhanced , SyntheticHemodynamicResponse );
                SyntheticFiltered = SyntheticFiltered - mean( SyntheticFiltered( 1 : EnhancedAnalysis.BaselineFrame ) );
                plot( SyntheticTime , SyntheticFiltered , 'LineWidth' , 1 );
            end
            xlabel( 'Time (s)' );
            ylabel( 'Normalized amplitude' );
            title( 'Synthetic Hemodynamic-Like Signal: Low-Pass Preservation Test' );
            legend( [ { 'No low-pass' } EnhancedAnalysis.FilterConfigurationNames(2:end) ] , 'Location' , 'best' );
            grid on;
            hold off;
            exportgraphics( FigureFilterTest , fullfile( EnhancedAnalysis.OutputFolder , ...
                'enhanced_synthetic_filter_preservation.png' ) , 'Resolution' , 300 );
            close( FigureFilterTest );
    end

% Save Reproducible Outputs
    if EnhancedAnalysis.SaveResults
        writetable( subjects.EnhancedAnalysis.InputDataManifest , fullfile( EnhancedAnalysis.OutputFolder , 'input_data_manifest.csv' ) );
        writetable( subjects.EnhancedAnalysis.MBLLParameterAudit , fullfile( EnhancedAnalysis.OutputFolder , 'mbll_parameter_audit.csv' ) );
        writetable( subjects.EnhancedAnalysis.FilterPreservationTest , fullfile( EnhancedAnalysis.OutputFolder , 'filter_preservation_test.csv' ) );
        writetable( subjects.EnhancedAnalysis.QualityControlTable , fullfile( EnhancedAnalysis.OutputFolder , 'quality_control_metrics.csv' ) );
        writetable( subjects.EnhancedAnalysis.BlockLevelResultsTable , fullfile( EnhancedAnalysis.OutputFolder , 'block_level_hbo_results.csv' ) );
        writetable( subjects.EnhancedAnalysis.SubjectLevelResultsTable , fullfile( EnhancedAnalysis.OutputFolder , 'subject_level_hbo_results.csv' ) );
        writetable( subjects.EnhancedAnalysis.BlockAggregationSensitivityTable , fullfile( EnhancedAnalysis.OutputFolder , 'block_aggregation_sensitivity.csv' ) );
        writetable( subjects.EnhancedAnalysis.BlockAggregationStatisticsTable , fullfile( EnhancedAnalysis.OutputFolder , 'block_aggregation_statistics.csv' ) );
        writetable( subjects.EnhancedAnalysis.LeaveOneParticipantOutTable , fullfile( EnhancedAnalysis.OutputFolder , 'leave_one_participant_out.csv' ) );
        writetable( subjects.EnhancedAnalysis.ChannelStatisticsTable , fullfile( EnhancedAnalysis.OutputFolder , 'exploratory_channel_statistics.csv' ) );
        writetable( subjects.EnhancedAnalysis.GlobalStatisticsTable , fullfile( EnhancedAnalysis.OutputFolder , 'global_statistics.csv' ) );
        writetable( subjects.EnhancedAnalysis.GroupConditionSummaryTable , fullfile( EnhancedAnalysis.OutputFolder , 'group_condition_summary.csv' ) );
        writetable( subjects.EnhancedAnalysis.FilterSensitivityTable , fullfile( EnhancedAnalysis.OutputFolder , 'filter_sensitivity_results.csv' ) );
        writetable( subjects.EnhancedAnalysis.LegacyVersusEnhancedTable , fullfile( EnhancedAnalysis.OutputFolder , 'legacy_vs_enhanced_global_hbo.csv' ) );

        EnhancedAnalysisResults = subjects.EnhancedAnalysis;
        save( fullfile( EnhancedAnalysis.OutputFolder , 'fnirs_summary_results.mat' ) , ...
            'EnhancedAnalysisResults' , 'EnhancedAnalysis' , 'InputDataManifest' );

        if EnhancedAnalysis.SaveFullWorkspace
            save( fullfile( EnhancedAnalysis.OutputFolder , 'fnirs_full_workspace.mat' ) , ...
                'subjects' , 'filename' , 'filenameEnhanced' , 'subject' , 'EnhancedAnalysis' , '-v7.3' );
        end
    end

%% LOCAL FUNCTIONS
function SourceFilename = resolveFNIRSSourceFilename( RequestedFilename )
% Resolve original filenames and upload-copy filenames ending in "(1)".
    ScriptFolder = fileparts( mfilename('fullpath') );
    if isempty( ScriptFolder )
        ScriptFolder = pwd;
    end

    RepositoryFolder = fileparts( ScriptFolder );

    CandidateFilename = { RequestedFilename , strrep( RequestedFilename , '.txt' , '(1).txt' ) , ...
        fullfile( ScriptFolder , RequestedFilename ) , fullfile( ScriptFolder , strrep( RequestedFilename , '.txt' , '(1).txt' ) ) , ...
        fullfile( ScriptFolder , 'data' , RequestedFilename ) , fullfile( ScriptFolder , 'data' , strrep( RequestedFilename , '.txt' , '(1).txt' ) ) , ...
        fullfile( ScriptFolder , 'data' , 'raw' , RequestedFilename ) , fullfile( ScriptFolder , 'data' , 'raw' , strrep( RequestedFilename , '.txt' , '(1).txt' ) ) , ...
        fullfile( RepositoryFolder , 'data' , RequestedFilename ) , fullfile( RepositoryFolder , 'data' , strrep( RequestedFilename , '.txt' , '(1).txt' ) ) , ...
        fullfile( RepositoryFolder , 'data' , 'raw' , RequestedFilename ) , fullfile( RepositoryFolder , 'data' , 'raw' , strrep( RequestedFilename , '.txt' , '(1).txt' ) ) };

    SourceFilename = '';
    for iCandidate = 1 : length( CandidateFilename )
        if exist( CandidateFilename{ iCandidate } , 'file' ) == 2
            SourceFilename = CandidateFilename{ iCandidate };
            break
        end
    end

    if isempty( SourceFilename )
        error( 'fNIRS:SourceFileNotFound' , 'Could not find source file: %s' , RequestedFilename );
    end
end

function SignalCorrected = temporalDerivativeDistributionRepair( Signal , SampleRate )
% Temporal Derivative Distribution Repair (TDDR).
% Fishburn FA, Ludlum RS, Vaidya CJ, Medvedev AV. NeuroImage 2019.
    Signal = Signal( : );
    FilterCutoff = 0.5;
    FilterOrder = 3;
    NormalizedCutoff = FilterCutoff / ( SampleRate / 2 );
    SignalMean = mean( Signal );
    Signal = Signal - SignalMean;

    if NormalizedCutoff < 1
        [ bTDDR , aTDDR ] = butter( FilterOrder , NormalizedCutoff , 'low' );
        SignalLow = filtfilt( bTDDR , aTDDR , Signal );
    else
        SignalLow = Signal;
    end

    SignalHigh = Signal - SignalLow;
    Tune = 4.685;
    MachinePrecisionCriterion = sqrt( eps( class(Signal) ) );
    Mu = inf;
    Derivative = diff( SignalLow );
    Weight = ones( size(Derivative) );

    for Iteration = 1 : 50
        MuOld = Mu;
        Mu = sum( Weight .* Derivative ) / sum( Weight );
        Deviation = abs( Derivative - Mu );
        Sigma = 1.4826 * median( Deviation );

        if Sigma == 0 || ~isfinite(Sigma)
            break
        end

        RobustDistance = Deviation / ( Sigma * Tune );
        Weight = ( ( 1 - RobustDistance .^ 2 ) .* ( RobustDistance < 1 ) ) .^ 2;

        if abs( Mu - MuOld ) < MachinePrecisionCriterion * max( abs(Mu) , abs(MuOld) )
            break
        end
    end

    NewDerivative = Weight .* ( Derivative - Mu );
    SignalLowCorrected = cumsum( [ 0; NewDerivative ] );
    SignalLowCorrected = SignalLowCorrected - mean( SignalLowCorrected );
    SignalCorrected = SignalLowCorrected + SignalHigh + SignalMean;
end

function CorrelationValue = safeCorrelation( Signal1 , Signal2 )
% Correlation without requiring a separate statistics function.
    Signal1 = Signal1( : );
    Signal2 = Signal2( : );
    Valid = isfinite( Signal1 ) & isfinite( Signal2 );
    Signal1 = Signal1( Valid );
    Signal2 = Signal2( Valid );

    if length( Signal1 ) < 2 || std(Signal1) == 0 || std(Signal2) == 0
        CorrelationValue = NaN;
        return
    end

    Signal1 = Signal1 - mean( Signal1 );
    Signal2 = Signal2 - mean( Signal2 );
    CorrelationValue = sum( Signal1 .* Signal2 ) / sqrt( sum(Signal1.^2) * sum(Signal2.^2) );
end

function [ ObservedStatistic , ExactP , ValidSubjectCount ] = exactPairedSignFlipPermutation( PairedDifference )
% Exact two-sided paired sign-flip test for the mean paired difference.
    PairedDifference = PairedDifference( isfinite(PairedDifference) );
    ValidSubjectCount = length( PairedDifference );

    if ValidSubjectCount < 2
        ObservedStatistic = NaN;
        ExactP = NaN;
        return
    end

    ObservedStatistic = mean( PairedDifference );
    NumberofExactCombination = 2 ^ ValidSubjectCount;
    PermutedStatistic = zeros( NumberofExactCombination , 1 );

    for CombinationIndex = 0 : NumberofExactCombination - 1
        SignVector = ones( ValidSubjectCount , 1 );
        for SubjectIndex = 1 : ValidSubjectCount
            if bitget( CombinationIndex , SubjectIndex ) == 0
                SignVector( SubjectIndex ) = -1;
            end
        end
        PermutedStatistic( CombinationIndex + 1 ) = mean( SignVector .* PairedDifference );
    end

    NumericalTolerance = 10 * eps( max(1,abs(ObservedStatistic)) );
    ExactP = sum( abs(PermutedStatistic) >= abs(ObservedStatistic) - NumericalTolerance ) / NumberofExactCombination;
end

function [ ObservedStatistic , ExactP , ValidSubjectCount ] = exactRepeatedMeasuresOmnibusPermutation( ConditionData )
% Exact within-subject condition-label permutation test across all three
% conditions. The statistic is the sum of squared condition means after
% subtracting each participant's across-condition mean.
    ValidSubject = all( isfinite(ConditionData) , 2 );
    ConditionData = ConditionData( ValidSubject , : );
    ValidSubjectCount = size( ConditionData , 1 );

    if ValidSubjectCount < 2 || size( ConditionData , 2 ) ~= 3
        ObservedStatistic = NaN;
        ExactP = NaN;
        return
    end

    ConditionDataCentered = ConditionData - mean( ConditionData , 2 );
    ObservedConditionMean = mean( ConditionDataCentered , 1 );
    ObservedStatistic = sum( ObservedConditionMean .^ 2 );

    ConditionPermutation = perms( 1 : 3 );
    NumberofPermutationPerSubject = size( ConditionPermutation , 1 );
    NumberofExactCombination = NumberofPermutationPerSubject ^ ValidSubjectCount;
    PermutedStatistic = zeros( NumberofExactCombination , 1 );

    for CombinationIndex = 0 : NumberofExactCombination - 1
        RemainingIndex = CombinationIndex;
        PermutedData = zeros( size(ConditionDataCentered) );

        for SubjectIndex = 1 : ValidSubjectCount
            CurrentPermutationIndex = mod( RemainingIndex , NumberofPermutationPerSubject ) + 1;
            RemainingIndex = floor( RemainingIndex / NumberofPermutationPerSubject );
            PermutedData( SubjectIndex , : ) = ConditionDataCentered( SubjectIndex , ConditionPermutation( CurrentPermutationIndex , : ) );
        end

        PermutedConditionMean = mean( PermutedData , 1 );
        PermutedStatistic( CombinationIndex + 1 ) = sum( PermutedConditionMean .^ 2 );
    end

    NumericalTolerance = 10 * eps( max(1,abs(ObservedStatistic)) );
    ExactP = sum( PermutedStatistic >= ObservedStatistic - NumericalTolerance ) / NumberofExactCombination;
end

function [ LowerCI , UpperCI ] = exactBootstrapMeanCI( Data , ConfidenceLevel )
% Deterministic complete bootstrap for small samples.
    Data = Data( isfinite(Data) );
    NumberofData = length( Data );

    if NumberofData < 2
        LowerCI = NaN;
        UpperCI = NaN;
        return
    end

    NumberofBootstrapCombination = NumberofData ^ NumberofData;
    BootstrapMean = zeros( NumberofBootstrapCombination , 1 );

    for CombinationIndex = 0 : NumberofBootstrapCombination - 1
        RemainingIndex = CombinationIndex;
        BootstrapIndex = zeros( NumberofData , 1 );

        for DataIndex = 1 : NumberofData
            BootstrapIndex( DataIndex ) = mod( RemainingIndex , NumberofData ) + 1;
            RemainingIndex = floor( RemainingIndex / NumberofData );
        end

        BootstrapMean( CombinationIndex + 1 ) = mean( Data( BootstrapIndex ) );
    end

    BootstrapMean = sort( BootstrapMean );
    Alpha = 1 - ConfidenceLevel;
    LowerCI = empiricalPercentile( BootstrapMean , 100 * Alpha / 2 );
    UpperCI = empiricalPercentile( BootstrapMean , 100 * ( 1 - Alpha / 2 ) );
end

function PercentileValue = empiricalPercentile( Data , Percentile )
% Linear-interpolation percentile calculation without toolbox dependence.
    Data = Data( isfinite(Data) );
    SortedData = sort( Data( : ) );
    NumberofData = length( SortedData );

    if NumberofData == 0
        PercentileValue = NaN;
        return
    end

    Position = 1 + ( NumberofData - 1 ) * Percentile / 100;
    LowerIndex = floor( Position );
    UpperIndex = ceil( Position );

    if LowerIndex == UpperIndex
        PercentileValue = SortedData( LowerIndex );
    else
        Fraction = Position - LowerIndex;
        PercentileValue = SortedData( LowerIndex ) + Fraction * ( SortedData( UpperIndex ) - SortedData( LowerIndex ) );
    end
end

function AdjustedP = benjaminiHochbergFDR( PValue )
% Benjamini-Hochberg adjusted p-values.
    AdjustedP = NaN( size(PValue) );
    ValidIndex = find( isfinite(PValue) );

    if isempty( ValidIndex )
        return
    end

    [ SortedP , SortOrder ] = sort( PValue( ValidIndex ) );
    NumberofTest = length( SortedP );
    SortedAdjustedP = NaN( NumberofTest , 1 );

    for Rank = NumberofTest : -1 : 1
        CurrentAdjustedP = SortedP(Rank) * NumberofTest / Rank;
        if Rank == NumberofTest
            SortedAdjustedP(Rank) = CurrentAdjustedP;
        else
            SortedAdjustedP(Rank) = min( CurrentAdjustedP , SortedAdjustedP(Rank+1) );
        end
    end

    SortedAdjustedP = min( SortedAdjustedP , 1 );
    UnsortedAdjustedP = NaN( NumberofTest , 1 );
    UnsortedAdjustedP( SortOrder ) = SortedAdjustedP;
    AdjustedP( ValidIndex ) = UnsortedAdjustedP;
end
