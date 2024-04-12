clc;clear;close all;
    filename = 'sddb/51';
    attr = 'ari';
%% Loading ECG signal file
    startN =50000;
    stopN = 2000;
    [signal,Fs,tm]=rdsamp(filename,[],startN);
    ecgsig = signal(:,1);
    annV=rdann(filename,attr,1,startN,[],'V');
    annN=rdann(filename,attr,1,startN,[],'N');
    [allann,char] = rdann(filename,attr,1,startN);
%     ecgsig=ecgsig(annN(1):end);
%     tm = tm(annN(1):end);
%% Filtering
    filt = ecgsig-mean(ecgsig); 
% % decomposing the ECG to level 5 using sym4 wavelet
%     wt = modwt(filt,5);
% % reconstruct the ECG to covers the passband (for scale 5,[5.625,11.25]Hz)
%     wtrec = zeros(size(wt));
%     wtrec(4:4,:) = wt(4:4,:);
%     filt = imodwt(wtrec,'sym4');
    
    f1=1;                                                                    
    f2=55;                                                                     
    Wn=[f1 f2]*2/Fs;                                                           
    N = 3;                                                                     
    [a,b] = butter(N,Wn);                                                      
    filt = filtfilt(a,b,filt);

%% R-peak detection
% first stage
    passmark1 = 0.1*max(filt);
    [peaks1,locs1] = findpeaks(filt,tm,'MinPeakHeight',passmark1);
    passmark2 = 0.45*mean(peaks1);

% second stage
    [bpeaks,blocs] = findpeaks(filt,tm,'MinPeakHeight',passmark2);
    [rpeaks,rlocs,rwidth] = findpeaks(filt,tm,'MinPeakHeight',passmark2,'MinPeakDistance',0.4);%,'MinPeakProminence',0.5);
%     rpeaks = rpeaks(rpeaks<3*passmark2);
%     rlocs = rlocs(rpeaks<3*passmark2);
%     length(rpeaks)
    
% matching to original peaks
    detectedRpeak=[];
    detectedRloc=[];
    for i=1:1:length(rlocs)
        if rpeaks(i)<(1.75*median(rpeaks))
            detectedRpeak = [detectedRpeak filt(find(tm==rlocs(i)))];
            detectedRloc = [detectedRloc rlocs(i)];
        end
    end
    RRintervals = diff(detectedRloc);
    meanRR = mean(RRintervals);
    
    PVClocs=[];
    PVCpeaks=[];
    ectopic=0;
    for j=2:1:length(RRintervals)
        if (RRintervals(j)>(2*RRintervals(j-1)))&((RRintervals(j)+RRintervals(j-1))<=2*meanRR)
            PVClocs=[PVClocs rlocs(j)];
            PVCpeaks=[PVCpeaks detectedRpeak(j)];
            continue
        end
        if(RRintervals(j)<0.75*meanRR)|((rpeaks(j)>1.1*rpeaks(j-1))&&(rpeaks(j)>1.1*rpeaks(j+1)))
            PVClocs=[PVClocs rlocs(j)];
            PVCpeaks=[PVCpeaks detectedRpeak(j)];
            continue
        end
        if rwidth(j)>1.25*mean(rwidth)
            PVClocs=[PVClocs rlocs(j)];
            PVCpeaks=[PVCpeaks detectedRpeak(j)];
            continue
        end
            
    end

 %% P wave detection
 % Storing

 % To store max P peak values
 pPeaksMax = [];
 % To store min P peak values 
 pPeaksMin = [];
 % To store locations of max P peaks
 pLocsMax = [];
 % To store locations of min P peaks
 pLocsMin = [];
 % Threshold
 threshold = #######;

 
 for i = 1:length(rlocs)
    if rlocs(i) > ###### % Ensuring there's enough signal before the R peak for analysis
        searchWindow = max(1, rlocs(i)-#####):rlocs(i); % 200ms window before the R peak
        % Finding the highest point of the P wave
        [pPeakMax, pLocMax] = findpeaks(filt(searchWindow), 'NPeaks', 1, 'SortStr', 'descend');
        % Finding the lowest point of the P wave by inverting the signal
        [pPeakMin, pLocMin] = findpeaks(-filt(searchWindow), 'NPeaks', 1, 'SortStr', 'descend');
        
        if ~isempty(pPeakMax)
            pPeaksMax = [pPeaksMax, pPeakMax];
            pLocsMax = [pLocsMax, searchWindow(1) + pLocMax - 1];
        end
        if ~isempty(pPeakMin)
            pPeaksMin = [pPeaksMin, -pPeakMin]; % Inverting back to original signal's value
            pLocsMin = [pLocsMin, searchWindow(1) + pLocMin - 1]; 
        end
    end
end

pacBooleans = zeros(1, length(pLocsMax)); % Initialize PAC Booleans to 0

for i = 1:length(pLocsMax)
    pPeak = pPeaksMax(i);
    pLoc = pLocsMax(i);
    
    % Assuming you have a way to identify the two lowest points around each P peak
    % Let's say pLocsMinBefore and pLocsMinAfter are their locations
    pLocMinBefore = ...; % Location of the first lowest point before the P peak
    pLocMinAfter = ...; % Location of the second lowest point after the P peak

    pLocMinBefore = findPreviousMinPoint(filt, pLoc);
    pLocMinAfter = findNextMinPoint(filt, pLoc);
    
    % Calculate gradients
    gradientBefore = (pPeak - filt(pLocMinBefore)) / (pLoc - pLocMinBefore);
    gradientAfter = (pPeak - filt(pLocMinAfter)) / (pLocMinAfter - pLoc);
    
    % Compare gradients and assign boolean for PAC
    if abs(gradientBefore - gradientAfter) > threshold
        pacBooleans(i) = 1; % Mark as PAC
    else
        pacBooleans(i) = 0; % Not PAC
    end
end

    
    
    
    