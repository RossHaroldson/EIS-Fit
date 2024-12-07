% Fitting function for EIS using multiple methods
function fit = fitZ(Z, freq, ImpFunc, v0, lb, ub, options)
% FitZ takes impedance spectra Z, frequency freq, an array of initial guesses v0,
% lower bounds lb, upper bounds ub, and a circuit impedance function ImpFunc.
% It fits the data using three methods: Simplex (fminsearch with bounds),
% Levenberg-Marquardt (lsqnonlin without bounds), and Trust-Region-Reflective (lsqnonlin with bounds).
% Returns fit coefficients, residuals, goodness of fit (gof), R2, adjusted R2, fit curves,
% and confidence intervals for each method.

% Convert frequency to angular frequency
w = 2.*pi.*freq;
if nargin < 7
    MaxIter = 30000;
    MaxFunEval = 5000*length(v0);
    Tol = 1e-12;
    SimpFactor = 200;
    display = 'iter';
    SimplexSeed = true;
else
    MaxIter = options.MaxIter;
    MaxFunEval = options.MaxFunEval;
    Tol = options.Tol;
    SimpFactor = options.SimpFactor;
    display = options.display;
    SimplexSeed = options.SimplexSeed;
end
% Initialize output structure
fit.Z = Z;
fit.w = w;
fit.freq=freq;
fit.ImpFunc = ImpFunc;

% Ensure lb and ub are column vectors
lb = lb(:);
ub = ub(:);
v0 = v0(:);
fit.lb = lb;
fit.ub = ub;
fit.v0 = v0;

%% Method 1: Simplex Method (fminsearch with bounds)
try
    tic
    % Transform initial guess to unbounded space
    x0 = paramTransform(v0, lb, ub);

    % Define the transformed error function
    errfcn_transformed = @(x) errFunction(transformParams(x, lb, ub), Z, w, ImpFunc);

    % Optimization options
    options = optimset('Display', display, 'PlotFcns',@optimplotfval, 'MaxFunEvals', SimpFactor*MaxFunEval, 'MaxIter', SimpFactor*MaxIter,'TolFun',Tol,'TolX',Tol);

    % Perform the fitting using fminsearch
    % [xfit, fval, exitflag,output] = fminsearch(errfcn_transformed, x0, options);
    [xfit, ~, exitflag,output] = fminsearch(errfcn_transformed, x0, options);

    % Transform the fitted parameters back to original space
    vfit = transformParams(xfit, lb, ub);

    % Store results
    fit.simplex.coeff = vfit;
    fit.simplex.exitflag = exitflag;
    disp(['Simplex exit flag: ' num2str(exitflag)])
    fit.simplex.output = output;
    fit.simplex.fitcurve = ImpFunc(vfit, w);
    % weighted residuals for plotting
    % fit.simplex.weightedresiduals = (Z - fit.simplex.fitcurve)./abs(fit.simplex.fitcurve);
    % residuals of used by the method
    fit.simplex.residuals = (Z - fit.simplex.fitcurve)./abs(fit.simplex.fitcurve);
    % i think this goodness of fit isn't right. Do to the transformations
    % we do it's residuals and gof aren't correct. We need to reevaluate
    % the function and residuals without the transformations.
    fit.simplex.gof = sum(abs(fit.simplex.residuals).^2);
    [fit.simplex.R2, fit.simplex.R2adjusted] = computeR2(Z, fit.simplex.fitcurve, length(v0));
    % Confidence intervals estimation is complex here and not provided
    fit.simplex.coeffCI = NaN(length(v0), 2);
    fit.simplex.timeElapsed = toc;
catch ME
    warning(ME.identifier, 'Simplex method failed: %s', ME.message);
    fit.simplex = [];
end

%% Method 2: Levenberg-Marquardt Method (lsqnonlin without bounds)
try
    tic
    if SimplexSeed
        try
            v0=fit.simplex.coeff;
        catch
            % stay with initial guesses
        end
    end
    
    % Optimization options
    options = optimoptions('lsqnonlin', 'FunctionTolerance', Tol, 'StepTolerance', Tol, ...
        'MaxIterations', MaxIter,'MaxFunctionEvaluations', MaxFunEval,'Display', 'off', 'Algorithm', 'levenberg-marquardt');
    
    % Perform the fitting without bounds
    [vfit, resnorm, residuals, exitflag, output, ~, J] = lsqnonlin(@(v) weightFunction(v, Z, w, ImpFunc), v0, lb, ub, options);
    
    % Store results
    fit.levenbergMarquardt.coeff = vfit;
    fit.levenbergMarquardt.output = output;
    fit.levenbergMarquardt.exitflag=exitflag;
    disp(['Levenberg-Marquardt exit flag: ' num2str(exitflag)])
    fit.levenbergMarquardt.fitcurve = ImpFunc(vfit, w);
     % weighted residuals for plotting
    fit.levenbergMarquardt.residuals = (Z - fit.levenbergMarquardt.fitcurve)./abs(fit.levenbergMarquardt.fitcurve);
    % residuals of used by the method
    % fit.levenbergMarquardt.residuals = residuals;
    fit.levenbergMarquardt.gof = resnorm;
    [fit.levenbergMarquardt.R2, fit.levenbergMarquardt.R2adjusted] = computeR2(Z, fit.levenbergMarquardt.fitcurve, length(v0));
    % Confidence intervals using nlparci
    ci = nlparci(vfit, residuals, 'jacobian', J);
    fit.levenbergMarquardt.coeffCI = ci;
    fit.levenbergMarquardt.timeElapsed = toc;
catch ME
    warning(ME.identifier,'Levenberg-Marquardt method failed: %s',ME.message);
    fit.levenbergMarquardt = [];
end

%% Method 3: Trust-Region-Reflective Method (lsqnonlin with bounds)
try
    tic
    if SimplexSeed
        try
            v0=fit.simplex.coeff;
        catch
            % stay with initial guesses
        end
    end
    % Optimization options
    options = optimoptions('lsqnonlin', 'FunctionTolerance', Tol, ...
        'MaxIterations', MaxIter,'MaxFunctionEvaluations', MaxFunEval,'Display', 'off', 'Algorithm', 'trust-region-reflective');
    
    % Perform the fitting with bounds
    [vfit, resnorm, residuals, exitflag, output, ~, J] = lsqnonlin(@(v) weightFunction(v, Z, w, ImpFunc), v0, lb, ub, options);
    
    % Store results
    fit.trustRegion.coeff = vfit;
    fit.trustRegion.output = output;
    fit.trustRegion.exitflag=exitflag;
    disp(['Trust Region exit flag: ' num2str(exitflag)])
    fit.trustRegion.fitcurve = ImpFunc(vfit, w);
    % weighted residuals for plotting
    fit.trustRegion.residuals = (Z - fit.trustRegion.fitcurve)./abs(fit.trustRegion.fitcurve);
    % residuals of used by the method
    % fit.trustRegion.residuals = residuals;
    fit.trustRegion.gof = resnorm;
    [fit.trustRegion.R2, fit.trustRegion.R2adjusted] = computeR2(Z, fit.trustRegion.fitcurve, length(v0));
    % Confidence intervals using nlparci
    ci = nlparci(vfit, residuals, 'jacobian', J);
    fit.trustRegion.coeffCI = ci;
    fit.trustRegion.timeElapsed = toc;
catch ME 
    warning(ME.identifier,'Trust-Region-Reflective method failed: %s', ME.message);
    fit.trustRegion = [];
end

end

% Error function with original weighting for fminsearch
function err = errFunction(v, Zmeas, w, ImpFunc)
    Zfit = ImpFunc(v, w);
    errVec = ((real(Zmeas) - real(Zfit)).^2 + (imag(Zmeas) - imag(Zfit)).^2) ./ abs(Zmeas).^2;
    err = sum(errVec);
end

% Weighted function for lsqnonlin
function errVec = weightFunction(v, Zmeas, w, ImpFunc)
    Zfit = ImpFunc(v, w);
    %ZmodelData = [real(Zmodel); imag(Zmodel)];
    %weights = 1 ./ abs(Z);
    errVec = ((real(Zmeas) - real(Zfit)).^2 + (imag(Zmeas) - imag(Zfit)).^2) ./ abs(Zmeas).^2;
end

% Compute R-squared and adjusted R-squared
function [R2, R2adjusted] = computeR2(Z, Zfit, p)
    %residuals = Z - Zfit;
    SSres = sum(abs(Z - Zfit).^2);
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