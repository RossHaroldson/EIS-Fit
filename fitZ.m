% Fitting function for EIS using multiple methods
function fit = fitZ(Z, freq, ImpFunc, v0, lb, ub)
% FitZ takes impedance spectra Z, frequency freq, an array of initial guesses v0,
% lower bounds lb, upper bounds ub, and a circuit impedance function ImpFunc.
% It fits the data using three methods: Simplex (fminsearch with bounds),
% Levenberg-Marquardt (lsqnonlin without bounds), and Trust-Region-Reflective (lsqnonlin with bounds).
% Returns fit coefficients, residuals, goodness of fit (gof), R2, adjusted R2, fit curves,
% and confidence intervals for each method.

% Initialize output structure
fit.Z = Z;
fit.freq = freq;
fit.ImpFunc = ImpFunc;

% Ensure lb and ub are column vectors
lb = lb(:);
ub = ub(:);
v0 = v0(:);

%% Method 1: Simplex Method (fminsearch with bounds)
try
    % Transform initial guess to unbounded space
    x0 = paramTransform(v0, lb, ub);
    
    % Define the transformed error function
    errfcn_transformed = @(x) errFunction(transformParams(x, lb, ub), Z, freq, ImpFunc);
    
    % Optimization options
    options = optimset('Display', 'off', 'MaxFunEvals', 5000, 'MaxIter', 5000);
    
    % Perform the fitting using fminsearch
    [xfit, fval] = fminsearch(errfcn_transformed, x0, options);
    
    % Transform the fitted parameters back to original space
    vfit = transformParams(xfit, lb, ub);
    
    % Store results
    fit.simplex.coeff = vfit;
    fit.simplex.fitcurve = ImpFunc(vfit, freq);
    fit.simplex.residuals = Z - fit.simplex.fitcurve;
    fit.simplex.gof = fval;
    [fit.simplex.R2, fit.simplex.R2adjusted] = computeR2(Z, fit.simplex.fitcurve, length(v0));
    % Confidence intervals estimation is complex here and not provided
    fit.simplex.coeffCI = NaN(length(v0), 2);
catch ME
    warning('Simplex method failed: %s', ME.message);
    fit.simplex = [];
end

%% Method 2: Levenberg-Marquardt Method (lsqnonlin without bounds)
try
    % Concatenate real and imaginary parts of Z into a real vector
    Zdata = [real(Z); imag(Z)];
    
    % Optimization options
    options = optimoptions('lsqnonlin', 'Display', 'off', 'Algorithm', 'levenberg-marquardt');
    
    % Perform the fitting without bounds
    [vfit, resnorm, residuals, ~, ~, ~, J] = lsqnonlin(@(v) weightFunction(v, Zdata, freq, ImpFunc), v0, [], [], options);
    
    % Store results
    fit.levenbergMarquardt.coeff = vfit;
    fit.levenbergMarquardt.fitcurve = ImpFunc(vfit, freq);
    fit.levenbergMarquardt.residuals = Z - fit.levenbergMarquardt.fitcurve;
    fit.levenbergMarquardt.gof = resnorm;
    [fit.levenbergMarquardt.R2, fit.levenbergMarquardt.R2adjusted] = computeR2(Z, fit.levenbergMarquardt.fitcurve, length(v0));
    % Confidence intervals using nlparci
    ci = nlparci(vfit, residuals, 'jacobian', J);
    fit.levenbergMarquardt.coeffCI = ci;
catch ME
    warning('Levenberg-Marquardt method failed: %s', ME.message);
    fit.levenbergMarquardt = [];
end

%% Method 3: Trust-Region-Reflective Method (lsqnonlin with bounds)
try
    % Concatenate real and imaginary parts of Z into a real vector
    Zdata = [real(Z); imag(Z)];
    
    % Optimization options
    options = optimoptions('lsqnonlin', 'Display', 'off', 'Algorithm', 'trust-region-reflective');
    
    % Perform the fitting with bounds
    [vfit, resnorm, residuals, ~, ~, ~, J] = lsqnonlin(@(v) weightFunction(v, Zdata, freq, ImpFunc), v0, lb, ub, options);
    
    % Store results
    fit.trustRegion.coeff = vfit;
    fit.trustRegion.fitcurve = ImpFunc(vfit, freq);
    fit.trustRegion.residuals = Z - fit.trustRegion.fitcurve;
    fit.trustRegion.gof = resnorm;
    [fit.trustRegion.R2, fit.trustRegion.R2adjusted] = computeR2(Z, fit.trustRegion.fitcurve, length(v0));
    % Confidence intervals using nlparci
    ci = nlparci(vfit, residuals, 'jacobian', J);
    fit.trustRegion.coeffCI = ci;
catch ME
    warning('Trust-Region-Reflective method failed: %s', ME.message);
    fit.trustRegion = [];
end

end

% Error function with original weighting for fminsearch
function err = errFunction(v, Zmeas, freq, ImpFunc)
    Zmodel = ImpFunc(v, freq);
    errVec = ((real(Zmeas) - real(Zmodel)).^2 + (imag(Zmeas) - imag(Zmodel)).^2) ./ abs(Zmeas).^2;
    err = sum(errVec);
end

% Weighted function for lsqnonlin
function errVec = weightFunction(v, Zdata, freq, ImpFunc)
    Zmodel = ImpFunc(v, freq);
    ZmodelData = [real(Zmodel); imag(Zmodel)];
    weights = 1 ./ abs([real(Zmodel); imag(Zmodel)]);
    errVec = weights .* (Zdata - ZmodelData);
end

% Compute R-squared and adjusted R-squared
function [R2, R2adjusted] = computeR2(Z, Zfit, p)
    residuals = Z - Zfit;
    SSres = sum(abs(residuals).^2);
    SStot = sum(abs(Z - mean(Z)).^2);
    R2 = 1 - SSres / SStot;
    n = length(Z);
    R2adjusted = 1 - (1 - R2) * (n - 1) / (n - p - 1);
end

% Transform parameters from unbounded space to bounded space
function v = transformParams(x, lb, ub)
    % Transformation using inverse sigmoid function
    v = lb + (ub - lb) ./ (1 + exp(-x));
end

% Transform initial parameters from bounded to unbounded space
function x = paramTransform(v, lb, ub)
    % Avoid division by zero
    epsilon = 1e-8;
    v = min(max(v, lb + epsilon), ub - epsilon);
    % Transformation using sigmoid function
    x = -log((ub - lb) ./ (v - lb) - 1);
end
