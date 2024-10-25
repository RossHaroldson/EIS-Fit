% Fitting function for EIS
function output = fitZ(Z,freq,ImpFunc,x0)
% FitZ will take Impedance spectra, a first parameter guess, a circuit impedance function and fit it with an arbitrary impedance
% function cirImp(). It will return the fit coefficiencts, residual curve, sum of R^2, gof,
% coefficienct confidences/error, fit curve. 
 
% Initialize output
output.coeff = [];
output.fitcurve = [];
output.residuals = [];
output.gof = [];
output.R2 = [];
output.Z = Z;
output.ImpFunc = ImpFunc;
output.freq = freq;
% Decompose Z into real, imaginary, phase and magnitude 
output.Zreal=real(Z);
output.Zimag=imag(Z);
output.Zmod=abs(Z);
output.Zphase=angle(Z); 
try
    % FIT
    % Get metrics
catch ME
    rethrow(ME)
    return
end
end