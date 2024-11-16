function [Zfunc, x0, lb, ub] = KKfunc(data) 
% Generates an impedance fit based on Kramers-Kronig relations applied to
% Boukamp's equivalent circuit (1995) plus an inductor in series

    % Initialize data
    freq = data.Freq;
    w = 2.*pi.*freq;
    N = length(freq);
    Zdata = data.Zreal + 1i.*data.Zimag;

    % Kramers-Kronig relations for equivalent circuit (Boukamp, 1995)
    % set number of fitting parameters (default and max is M=N)
    M=N;
    Tauk = 1./logspace(log10(max(freq)),log10(min(freq)),M-3)';
    % Tauk = 1./freq;
    % weights = data.Zmod.^(-2);
    % imagSum = @(Rk,Tauk,w) sum( Rk./(1+(w'.*Tauk).^2), 2);
    % Rinf = @(Rk,Tauk,w) sum(weights.*(real(Zdata)-imagSum(Rk,Tauk,w)))./sum(weights);
    % ZcirRe = @(Rk,Tauk,w) Rinf(Rk,Tauk,w) + imagSum(Rk,Tauk,w);
    % realSum = @(Rk,Tauk,w) -sum( w'.*Rk.*Tauk./(1+(w'.*Tauk).^2), 2);
    % % Inductive reactance, determined similarly as Rinf
    %XLinf = @(x,w) sum(weights.*(imag(Zdata)-realSum(x,w)))./sum(weights);
    %ZcirIm = @(x,w) XLinf(x,w) + realSum(Rk,Tauk,w);
    %ZcirIm = @(Rk,Tauk,L,C,w) -L.*w - 1./(C.*w) + realSum(Rk,Tauk,w);
    %Zcircuit = @(V,w) ZcirRe(Rk,Tauk,w) + 1i.*ZcirIm(Rk,Tauk,L,C,w);
    Zfunc = @(V,w) KKvec(V,Tauk,w);
    % note: V(M) is the inductor element and V(2) is the 1/Capacitor and V(1) is the Rinf 

    % Initial guesses
    % Uniform guesses
    %R0 = 1e4 * ones(numVoigt,1);
    % Log-space uniformly distributed random guesses
    %x0 = 10.^(8*rand(M,1));
    %x0(1)= 10;
    % R guesses
    x0 = 1e6 * ones(M,1);
    x0(1) = 10;
    lb = 1 * ones(M,1);
    ub = 1e10 * ones(M,1);
    % 1/C guess
    x0(2) = 1/1e-9;
    lb(2) = 1/1e-5;
    ub(2) = 1/1e-13;
    % L guess
    x0(end) = 1e-6;
    lb(end) = 1e-12;
    ub(end) = 1e-2;

    %tau0 = 1./logspace(max(log10(freq)),min(log10(freq)),numVoigt)';
    %lbTau = 1e-13 * ones(numVoigt,1);
    %ubTau = 1e6 * ones(numVoigt,1);

    %x0 = [R0; tau0];
    %lb = [lbR; lbTau];
    %ub = [ubR; ubTau];
    
end

function fitvec = KKvec(V,Tauk,w)
    fitvec = zeros(length(w),1);
    for i = 1:length(w)
        fitvec(i) =  V(1) + sum( V(3:end-1)./(1+(w(i).*Tauk).^2)) + ...
            1i.*(-V(2)./w(i) + V(end).*w(i) - sum(V(3:end-1).*w(i).*Tauk./(1+(w(i).*Tauk).^2)));
    end
end