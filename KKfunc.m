function [Zcircuit, x0, lb, ub, Rinf] = KKfunc(data) 
% Generates an impedance fit based on Kramers-Kronig relations applied to
% Boukamp's equivalent circuit (1995)

    % Initialize data
    freq = data.Freq;
    w = 2*pi*freq;
    N = length(freq);
    Zdata = data.Zreal + 1i*data.Zimag;

    % Kramers-Kronig relations for equivalent circuit (Boukamp, 1995)
    numVoigt = N;
    imagSum = @(x,w) sum( x(1:numVoigt)./(1+(w'*x(numVoigt+1:end)).^2), 2);
    weights = data.Zmod.^(-2);
    Rinf = @(x,w) sum(weights.*(real(Zdata)-imagSum(x,w)))/sum(weights);
    ZcirRe = @(x,w) Rinf(x,w) + imagSum(x,w);
    ZcirIm = @(x,w) -sum( w'*x(1:numVoigt).*x(numVoigt+1:end)./(1+(w'*x(numVoigt+1:end)).^2), 2);
    Zcircuit = @(x,w) ZcirRe(x,w) + 1i*ZcirIm(x,w);

    % Initial guesses
    % Uniform guesses
    R0 = 1e5 * ones(numVoigt,1);
    % Log-space uniformly distributed random guesses
    % R0 = 10.^(10*rand(numVoigt,1));
    lbR = 1 * ones(numVoigt,1);
    ubR = 1e10 * ones(numVoigt,1);

    tau0 = 1./freq;
    lbTau = 1e-13 * ones(numVoigt,1);
    ubTau = 1e5 * ones(numVoigt,1);

    x0 = [R0; tau0];
    lb = [lbR; lbTau];
    ub = [ubR; ubTau];
    
end
