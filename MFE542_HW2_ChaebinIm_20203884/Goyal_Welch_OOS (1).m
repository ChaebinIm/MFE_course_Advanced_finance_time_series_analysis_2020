clear all %#ok<CLALL>
close all
clc
%% S&P 500 Index Return (vwretd and ewretd include dividends)
fid = fopen('SP500Ret_for_Goyal_Welch_Comparison.csv');
C = textscan(fid, '%f %f %f', 'HeaderLines', 1, 'Delimiter',','); 

SP500_date = C{1,1};
SP500_vwretd = C{1,2};
SP500_ewretd = C{1,3};

% Sample period: from 1927/10 to 2015/12
SP500_vwretd_filtered = SP500_vwretd(SP500_date >= 19270100 & SP500_date <= 20151231);
SP500_ewretd_filtered = SP500_ewretd(SP500_date >= 19270100 & SP500_date <= 20151231);
SP500_date_filtered = SP500_date(SP500_date >= 19270100 & SP500_date <= 20151231);

%% Data from Goyal and Welch (2008)
filename = 'PredictorData2016.xlsx';
Goyal_Welch_data = xlsread(filename);

% Sample period: from 1927/10
Goyal_Welch_data_filtered = Goyal_Welch_data( Goyal_Welch_data(:, 1) >= 192612 & Goyal_Welch_data(:, 1) <= 201512, :);


%% Independent Variable Construction 

Date = Goyal_Welch_data_filtered(:, 1);
Index = Goyal_Welch_data_filtered(:, 2);
D12 = Goyal_Welch_data_filtered(:, 3);
E12 = Goyal_Welch_data_filtered(:, 4);
b_m = Goyal_Welch_data_filtered(:, 5);
tbl = Goyal_Welch_data_filtered(:, 6);
AAA = Goyal_Welch_data_filtered(:, 7);
BAA = Goyal_Welch_data_filtered(:, 8);
lty = Goyal_Welch_data_filtered(:, 9);
ntis = Goyal_Welch_data_filtered(:, 10);
Rfree = Goyal_Welch_data_filtered(:, 11);
infl = Goyal_Welch_data_filtered(:, 12);
ltr = Goyal_Welch_data_filtered(:, 13);
corpr = Goyal_Welch_data_filtered(:, 14);
svar = Goyal_Welch_data_filtered(:, 15);
csp = Goyal_Welch_data_filtered(:, 16);
CRSP_SPvw = Goyal_Welch_data_filtered(:, 17);
CRSP_SPvwx = Goyal_Welch_data_filtered(:, 18);

% Variables for Prediction (Goyal and Welch (2008))
Dividend_Price_Ratio = log(D12) - log(Index);
Dividend_Yield = log(D12(2:end)) - log(Index(1:end-1));
Earnings_Price_Ratio = log(E12) - log(Index);
Dividend_Payout_Ratio = log(D12) - log(E12);
Stock_Variance = svar;
Book_to_Market_Ratio = b_m;
Net_Equity_Expansion = ntis;
Treasury_Bill_Rate = tbl;
Long_Term_Yield = lty;
Long_Term_Return = ltr;
Term_Spread = Long_Term_Yield - Treasury_Bill_Rate;
Default_Yield_Spread = BAA - AAA;
% Default_Return_Spread 
Inflation = infl;

% Data starting from 192701
Dividend_Price_Ratio = Dividend_Price_Ratio(2:end);
% Dividend_Yield = Dividend_Yield(2:end); Dividend yield is alread starting
% from year 2
Earnings_Price_Ratio = Earnings_Price_Ratio(2:end);
Dividend_Payout_Ratio = Dividend_Payout_Ratio(2:end);
Stock_Variance = Stock_Variance(2:end);
Book_to_Market_Ratio = Book_to_Market_Ratio(2:end);
Net_Equity_Expansion = Net_Equity_Expansion(2:end);
Treasury_Bill_Rate = Treasury_Bill_Rate(2:end);
Long_Term_Yield = Long_Term_Yield(2:end);
Long_Term_Return = Long_Term_Return(2:end);
Term_Spread = Term_Spread(2:end);
Default_Yield_Spread = Default_Yield_Spread(2:end);
Inflation = Inflation(2:end);

Set_of_predictors = [Dividend_Price_Ratio Dividend_Yield Earnings_Price_Ratio Dividend_Payout_Ratio Stock_Variance Book_to_Market_Ratio Net_Equity_Expansion Treasury_Bill_Rate Long_Term_Yield Long_Term_Return Term_Spread Default_Yield_Spread Inflation];

%% In-Sample Regression (From 1996/01 to 2015/12)

SP500_date_to_be_predicted = SP500_date_filtered( SP500_date_filtered >= 19960100 );
SP500_to_be_predicted = SP500_vwretd_filtered( SP500_date_filtered >= 19960100 );
Predictors_to_be_used = Set_of_predictors( SP500_date_filtered >= 19960100, :);

% Matching time for the predictive regression
SP500_to_be_predicted = SP500_to_be_predicted(2:end);
Predictors_to_be_used = Predictors_to_be_used(1:end-1, :);

% Regression
number_of_predictors = size(Predictors_to_be_used, 2);
Name_of_predictors = {'Dividend_Price_Ratio', 'Dividend_Yield', 'Earnings_Price_Ratio', 'Dividend_Payout_Ratio', 'Stock_Variance', 'Book_to_Market_Ratio', 'Net_Equity_Expansion', 'Treasury_Bill_Rate', 'Long_Term_Yield', 'Long_Term_Return', 'Term_Spread', 'Default_Yield_Spread', 'Inflation'}; 

In_sample_R_squared = nan(number_of_predictors+1, 1);

for i = 1:number_of_predictors
    
    mdl = fitlm(Predictors_to_be_used(:, i), SP500_to_be_predicted); % same as regression
    In_sample_R_squared(i, 1) = mdl.Rsquared.Ordinary;
    
end

mdl_all = fitlm(Predictors_to_be_used, SP500_to_be_predicted);
In_sample_R_squared(end, 1) = mdl_all.Rsquared.Ordinary;


%% Out-of-Sample Regression (From 1996/01 to 2015/12)  

T = size(SP500_to_be_predicted, 1);
T_prediction = 12*5;    % 5-years of out-of-sample prediction
squared_error_of_predicted_value = nan(T_prediction, number_of_predictors);
squared_error_of_predicted_value_combined = nan(T_prediction, 1);
squared_error_of_historical_mean = nan(T_prediction, 1);

for variable_index = 1:number_of_predictors
    
    for number_of_remaining_periods = T_prediction:-1:1 


        % Predictors through t
        x_to_use = Predictors_to_be_used(1:T-number_of_remaining_periods, variable_index);
        X = [ones(length(x_to_use), 1) x_to_use];

        % Market Return through t
        y = SP500_to_be_predicted(1:T-number_of_remaining_periods, 1);

        % Predictive regression estiamtes
        estimated_coefficients = (X'*X) \ (X' * y);


        % Fitted value from a predictive regression through t
        X_next_period = Predictors_to_be_used(T-number_of_remaining_periods + 1, variable_index);    
        fitted_y = estimated_coefficients(1) + estimated_coefficients(2) * X_next_period;

        % Historical average return through t-1: 
        % Starting from 1927 as the advantage of historical returns
        historical_returns = SP500_vwretd_filtered(1:T-number_of_remaining_periods, 1);
        historical_mean = mean(historical_returns);

        % Realized market return at t+1
        realized_y = SP500_to_be_predicted(T-number_of_remaining_periods + 1, 1);

        squared_error_of_predicted_value(number_of_remaining_periods, variable_index) = (realized_y - fitted_y)^2;
        squared_error_of_historical_mean(number_of_remaining_periods, 1) = (realized_y - historical_mean)^2;

    end
    
    
end

% Kitchen Sink Regression
for number_of_remaining_periods = T_prediction:-1:1 

    % Predictors through t
    x_to_use = Predictors_to_be_used(1:T-number_of_remaining_periods, :);
    X = [ones(length(x_to_use), 1) x_to_use];

    % Market Return through t
    y = SP500_to_be_predicted(1:T-number_of_remaining_periods, 1);

    % Predictive regression estiamtes
    estimated_coefficients = (X'*X) \ (X' * y);


    % Fitted value from a predictive regression through t
    X_next_period = Predictors_to_be_used(T-number_of_remaining_periods + 1, :);    
    fitted_y = estimated_coefficients(1) + X_next_period * estimated_coefficients(2:end);

    % Realized market return at t+1
    realized_y = SP500_to_be_predicted(T-number_of_remaining_periods + 1, 1);

    squared_error_of_predicted_value_combined(number_of_remaining_periods, 1) = (realized_y - fitted_y)^2;

end

squared_error_of_predicted_value = flipud(squared_error_of_predicted_value);
squared_error_of_predicted_value_combined = flipud(squared_error_of_predicted_value_combined);
squared_error_of_historical_mean = flipud(squared_error_of_historical_mean);

Out_of_sample_R2_individual = 1 - sum(squared_error_of_predicted_value) ./ sum(squared_error_of_historical_mean);
Out_of_sample_R2_combined = 1 - sum(squared_error_of_predicted_value_combined) / sum(squared_error_of_historical_mean);



