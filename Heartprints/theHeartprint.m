function heartPrint=theHeartprint(filename)
% Initialize and load library
[~, config]=wfdbloadlib;

% Get sampling frequency and calculate number of samples
record_info=wfdbdesc(filename);
fs=double(record_info(1).SamplingFrequency);

% Find first annotated sample in the first 2 mins
[annIndices, annTypes]=rdann(filename, 'ari',[],30000,[],[]);
validIndices=annIndices(annTypes ~= '?'); 
N0=validIndices(1)-1;  

    for segment = 1:3
        start_time=(segment-1)*8;   
        end_time=segment*8;
        [sinus_intervals,ventricular_intervals,NIB,CI]=initHP(filename,start_time,end_time,fs,N0);
        combinedData=mergeSegmentData(sinus_intervals,ventricular_intervals,NIB,CI);
    end

[nn_edges_max,nn_edges,vv_edges,nib_edges,ci_edges,nn_vv,nn_nib,nn_ci]=calcHeartprint(combinedData);
heartPrint=generateHeartPrintPlots(combinedData.sinus_intervals, combinedData.ventricular_intervals, combinedData.CI, combinedData.NIB,nn_edges_max,nn_edges,vv_edges,nib_edges,ci_edges,nn_vv,nn_nib,nn_ci,filename)

end
