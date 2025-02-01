function fit = fitZ(Z, freq, ImpFunc, v0, lb, ub, userOptions)
% FITZ Fit electrochemical impedance spectroscopy data to an equivalent circuit model.
%
%   fit = fitZ(Z, freq, ImpFunc, v0, lb, ub, userOptions)
%
%   INPUTS:
%     Z          : Measured complex impedance data.
%     freq       : Frequency vector (Hz). The code converts it to angular frequency.
%     ImpFunc    : Function handle for the circuit impedance model. It should be of
%                  the form Zmodel = ImpFunc(v, w), where v are the parameters and w = 2*pi*freq.
%     v0         : Initial guess vector for the parameters.
%     lb         : Lower bounds (vector).
%     ub         : Upper bounds (vector).
%     userOptions (optional): A struct with the fields:
%             MaxIter, MaxFunEval, Tol, SimpFactor, display, SimplexSeed.
%
%   OUTPUT:
%     fit : A structure containing the measured data, the angular frequencies,
%           the input function handle, and a sub-structure for each method (Simplex,
%           Levenberg–Marquardt, and Trust–Region–Reflective). Each sub-structure contains
%           the best-fit coefficients, the fit curve, residuals, goodness-of-fit, R2, adjusted R2,
%           confidence intervals (where available), and the elapsed time.
%
%   The three methods are:
%     1. Simplex method using fminsearch (with a transformation to enforce bounds)
%     2. Levenberg–Marquardt using lsqnonlin (without bounds)
%     3. Trust–Region–Reflective using lsqnonlin (with bounds)
%
%   Author: Ross Haroldson, Matthew Lochridge
%   Date:   2025

%% --- Input Processing and Default Options ---

% Convert frequency to angular frequency
w = 2*pi*freq;

% Ensure v0, lb, and ub are column vectors
v0 = v0(:);
lb = lb(:);
ub = ub(:);

% Default options if userOptions is not provided
if nargin < 7 || isempty(userOptions)
    userOptions.MaxIter       = 30000;
    userOptions.MaxFunEval    = 5000 * length(v0);
    userOptions.Tol           = 1e-12;
    userOptions.SimpFactor    = 200;
    userOptions.display       = 'iter';
    userOptions.SimplexSeed   = true;
end

% Unpack user options for clarity
MaxIter       = userOptions.MaxIter;
MaxFunEval    = userOptions.MaxFunEval;
Tol           = userOptions.Tol;
SimpFactor    = userOptions.SimpFactor;
dispSetting   = userOptions.display;
SimplexSeed   = userOptions.SimplexSeed;

%% --- Initialize Output Structure ---
fit.Z      = Z;
fit.w      = w;
fit.freq   = freq;
fit.ImpFunc = ImpFunc;
fit.lb     = lb;
fit.ub     = ub;
fit.v0     = v0;

% Initialize substructures with NaN (or empty) fields
methods = {'simplex', 'levenbergMarquardt', 'trustRegion'};
for m = methods
    fit.(m{1}).gof       = NaN;
    fit.(m{1}).coeff     = NaN;
    fit.(m{1}).coeffCI   = NaN;
    fit.(m{1}).residuals = NaN;
end

%% --- Method 1: Simplex Method (fminsearch with bounds via transformation) ---
try
    tStart = tic;
    % Transform initial guess from bounded to unbounded space.
    x0 = bounded2unbounded(v0, lb, ub);
    
    % Define cost function: compute the residuals, then sum their squares.
    costFunc = @(x) sum( computeResiduals( unbounded2bounded(x, lb, ub), Z, w, ImpFunc ).^2 );
    
    % Set optimization options for fminsearch
    simplexOpts = optimset('Display', dispSetting, ...
                            'PlotFcns', @optimplotfval, ...
                            'MaxFunEvals', SimpFactor * MaxFunEval, ...
                            'MaxIter', SimpFactor * MaxIter, ...
                            'TolFun', Tol, ...
                            'TolX', Tol);
                        
    % Run the Simplex optimization.
    [xFit, fval, exitflag, output] = fminsearch(costFunc, x0, simplexOpts);
    
    % Transform the fitted unbounded parameters back to the original (bounded) space.
    vFit = unbounded2bounded(xFit, lb, ub);
    
    % Store results.
    fit.simplex.coeff     = vFit;
    fit.simplex.exitflag  = exitflag;
    fit.simplex.output    = output;
    fit.simplex.fitcurve  = ImpFunc(vFit, w);
    % Compute residuals using the common function.
    fit.simplex.residuals = computeResiduals(vFit, Z, w, ImpFunc);
    fit.simplex.gof       = fval;  % Sum of squared weighted residuals.
    [fit.simplex.R2, fit.simplex.R2adjusted] = computeR2(Z, fit.simplex.fitcurve, length(v0));
    % Confidence intervals are not computed for Simplex.
    fit.simplex.coeffCI   = NaN(length(v0), 2);
    fit.simplex.timeElapsed = toc(tStart);
    
    disp(['Simplex exit flag: ' num2str(exitflag)]);
catch ME
    warning('Simplex method failed: %s', '%s', ME.message);
    fit.simplex = [];
end

%% --- Method 2: Levenberg-Marquardt (lsqnonlin without bounds) ---
try
    tStart = tic;
    % Optionally seed with the Simplex result if available.
    if SimplexSeed && isfield(fit, 'simplex') && ~isempty(fit.simplex) && ~any(isnan(fit.simplex.coeff))
        v0_seed = fit.simplex.coeff;
    else
        v0_seed = v0;
    end
    
    % Set optimization options for lsqnonlin using Levenberg–Marquardt.
    lmOpts = optimoptions('lsqnonlin', ...
                          'FunctionTolerance', Tol, ...
                          'StepTolerance', Tol, ...
                          'MaxIterations', MaxIter, ...
                          'MaxFunctionEvaluations', MaxFunEval, ...
                          'Display', 'off', ...
                          'Algorithm', 'levenberg-marquardt');
                      
    % Run lsqnonlin with the common residual function.
    [vFit, resnorm, residuals, exitflag, output, ~, J] = lsqnonlin(@(v) computeResiduals(v, Z, w, ImpFunc), ...
                                                                   v0_seed, lb, ub, lmOpts);
    % Store results.
    fit.levenbergMarquardt.coeff     = vFit;
    fit.levenbergMarquardt.exitflag  = exitflag;
    fit.levenbergMarquardt.output    = output;
    fit.levenbergMarquardt.fitcurve  = ImpFunc(vFit, w);
    fit.levenbergMarquardt.residuals = residuals;
    fit.levenbergMarquardt.gof       = resnorm;
    [fit.levenbergMarquardt.R2, fit.levenbergMarquardt.R2adjusted] = computeR2(Z, fit.levenbergMarquardt.fitcurve, length(v0));
    % Compute confidence intervals using the Jacobian.
    ci = nlparci(vFit, residuals, 'jacobian', J);
    fit.levenbergMarquardt.coeffCI   = ci;
    fit.levenbergMarquardt.timeElapsed = toc(tStart);
    
    disp(['Levenberg–Marquardt exit flag: ' num2str(exitflag)]);
catch ME
    warning('Levenberg–Marquardt method failed: %s', '%s', ME.message);
    fit.levenbergMarquardt = [];
end

%% --- Method 3: Trust-Region–Reflective (lsqnonlin with bounds) ---
try
    tStart = tic;
    % Optionally seed with the Simplex result if available.
    if SimplexSeed && isfield(fit, 'simplex') && ~isempty(fit.simplex) && ~any(isnan(fit.simplex.coeff))
        v0_seed = fit.simplex.coeff;
    else
        v0_seed = v0;
    end
    
    % Set optimization options for lsqnonlin using Trust–Region–Reflective algorithm.
    trOpts = optimoptions('lsqnonlin', ...
                          'FunctionTolerance', Tol, ...
                          'MaxIterations', MaxIter, ...
                          'MaxFunctionEvaluations', MaxFunEval, ...
                          'Display', 'off', ...
                          'Algorithm', 'trust-region-reflective');
                      
    % Run lsqnonlin.
    [vFit, resnorm, residuals, exitflag, output, ~, J] = lsqnonlin(@(v) computeResiduals(v, Z, w, ImpFunc), ...
                                                                   v0_seed, lb, ub, trOpts);
    % Store results.
    fit.trustRegion.coeff     = vFit;
    fit.trustRegion.exitflag  = exitflag;
    fit.trustRegion.output    = output;
    fit.trustRegion.fitcurve  = ImpFunc(vFit, w);
    fit.trustRegion.residuals = residuals;
    fit.trustRegion.gof       = resnorm;
    [fit.trustRegion.R2, fit.trustRegion.R2adjusted] = computeR2(Z, fit.trustRegion.fitcurve, length(v0));
    ci = nlparci(vFit, residuals, 'jacobian', J);
    fit.trustRegion.coeffCI   = ci;
    fit.trustRegion.timeElapsed = toc(tStart);
    
    disp(['Trust–Region–Reflective exit flag: ' num2str(exitflag)]);
catch ME
    warning('Trust–Region–Reflective method failed: %s', '%s',ME.message);
    fit.trustRegion = [];
end

end

%% ===== Helper Functions =====

% Compute the weighted residuals. The residual vector is constructed by stacking
% the weighted differences of the real and imaginary parts.
function res = computeResiduals(v, Z, w, ImpFunc)
    Zfit = ImpFunc(v, w);
    % Avoid division by zero; use a small epsilon.
    epsilon = 1e-12;
    weights = 1 ./ max(abs(Z), epsilon);
    res = [ (real(Z) - real(Zfit)).*weights;
            (imag(Z) - imag(Zfit)).*weights ];
end

% Compute R-squared and adjusted R-squared using the absolute differences.
function [R2, R2adjusted] = computeR2(Z, Zfit, p)
    SSres = sum(abs(Z - Zfit).^2);
    SStot = sum(abs(Z - mean(Z)).^2);
    R2 = 1 - SSres / SStot;
    n = length(Z);
    R2adjusted = 1 - (1 - R2) * (n - 1) / (n - p - 1);
end

% Transform parameters from bounded space to unbounded space.
% This is useful for fminsearch which is unconstrained.
function x = bounded2unbounded(v, lb, ub)
    % Ensure v is strictly within (lb,ub) to avoid division by zero.
    epsilon = 1e-8;
    v = min(max(v, lb + epsilon), ub - epsilon);
    x = -log((ub - lb) ./ (v - lb) - 1);
end

% Transform parameters from unbounded space back to the original bounded space.
function v = unbounded2bounded(x, lb, ub)
    v = lb + (ub - lb) ./ (1 + exp(-x));
end