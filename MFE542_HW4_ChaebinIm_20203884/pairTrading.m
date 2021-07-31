clc
clear all
close all

%% GOOG GOOGL data loading

googReturns = readtable('pairTradingData.xlsx'); 
googReturns = googReturns( table2array(googReturns(:,2)) >= 20140403 , : ); % keep the data after stock issuance

numberOfRows = size(googReturns,1);

googReturns = [table2array(googReturns(1:numberOfRows/2,2)) ...
               table2array(googReturns(1:numberOfRows/2,3)) ...
               table2array(googReturns(numberOfRows/2+1:numberOfRows,3)) ];
% date GOOG GOOGL         
%% Find a stationary relation

y = googReturns(:,3);
X = [ones(length(y),1) googReturns(:,2)];
coeff = (X'*X) \ (X'*y);

stationaryProcess = y - X*coeff;
plot(stationaryProcess)

%% Error Correction Model

y = stationaryProcess(2:end) - stationaryProcess(1:end-1);
X = [ones(length(y),1) stationaryProcess(1:end-1)];
coeff = (X'*X) \ (X'*y);

residual = y - X*coeff;

RV2ofResidual = nan(size(residual));

for t = 21:length(residual)
    
    RV2ofResidual(t) = sum( residual(t-20:t-1).^2 ); 

end

%% Mean-Variance Betting

BettingResults = (stationaryProcess(2:end) - stationaryProcess(1:end-1)).* ...
                 (X*coeff)./ ...
                 RV2ofResidual;
             
           
BettingResults = BettingResults(21:end);
realizedSR = sqrt(252)*mean(BettingResults)/std(BettingResults);
             









