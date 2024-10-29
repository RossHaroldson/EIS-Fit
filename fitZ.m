% Fitting function for EIS
function fit = fitZ(Z,freq,ImpFunc,x0)
% FitZ will take Impedance spectra Z, frequency freq, an array of guesses of parameters x0, a circuit impedance function ImpFunc and fit it with an arbitrary impedance
% function cirImp(). It will return the fit coefficiencts, residual curve, sum of R^2, gof,
% coefficienct confidences/error, fit curve. 
 
% Initialize output
fit.coeff = [];
fit.fitcurve = [];
fit.residuals = [];
fit.gof = [];
fit.R2 = [];
fit.Z = Z;
fit.ImpFunc = ImpFunc;
fit.freq = freq;
% Decompose Z into real, imaginary, phase and magnitude 
fit.Zreal=real(Z);
fit.Zimag=imag(Z);
fit.Zmod=abs(Z);
fit.Zphase=angle(Z); 
residualfunc = (fit.Zreal-real(fit.ImpFunc(x0,freq)))^2 + (fit.Zimag-imag(fit.ImpFunc(x0,freq)))^2;
errfcn = @(v) (fit.ImpFunc(v) - Z).^2;
try
    % Fit using simplex method
    % Fit the fit.Zimag- 
    % Fit using lsqnonlin method
    % Fit using method that gives confidence of each parameter
    % Get metrics
catch ME
    rethrow(ME)
    return
end
end