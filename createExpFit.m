function [fitresult, gof] = createExpFit(x, y)
% fits for an exponential y=a*exp(b*x)+c


%% Fit: 'untitled fit 1'.
[xData, yData] = prepareCurveData( x, y );

% Set up fittype and options.
ft = fittype( 'a*exp(b*x)+c', 'independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.Lower = [0 0 0];
opts.StartPoint = [0 2.5 0];

% Fit model to data.
[fitresult, gof] = fit( xData, yData, ft, opts );

end


