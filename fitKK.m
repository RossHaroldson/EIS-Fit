function [Zfit, Zres, Rinf, Rfit, Cfit, R2] = fitKK(data, method) 
% Fit EIS data by applying Kramers-Kronig relations 
% to an equivalent circuit impedance function.

    % Initialize data
    freq = data.Freq;
    w = 2*pi*freq;
    N = length(freq);
    Zdata = data.Zreal + 1i*data.Zimag;

    %% fminsearch: check initial guesses
    if strcmp(method,'fminsearch')
        % Kramers-Kronig relations for equivalent circuit (Boukamp, 1995)
        numVoigt = N;
        imagSum = @(x,n) sum(x(1:numVoigt)./(1+(w(n)*x(numVoigt+1:end)).^2));
        % weights = data.Zmod.^(-2);
        Rinf = data.Zreal(1);
        ZcirRe = @(x,n) Rinf + imagSum(x,n);
        ZcirIm = @(x,n) -sum(w(n)*x(1:numVoigt).*x(numVoigt+1:end)./(1+(w(n)*x(numVoigt+1:end)).^2));
        Zcircuit = @(x,n) ZcirRe(x,n) + 1i*ZcirIm(x,n);

        % Initial guesses
        R0 = 10^8 * randn(numVoigt,1); % how to optimize guesses?
        tau0 = 1./freq;
        x0 = [R0; tau0];
    
        % Simplex method
        optimFunc = @(x,n) Zcircuit(x,n) - Zdata(n);
        options = optimset(@fminsearch);
        xfit = zeros(2*numVoigt,N);
        Zfit = zeros(N,1);
        for n = 1:N
            [x, Zres] = fminsearch(optimFunc,x0,options,n);
            xfit(:,n) = x;
            Zfit(n) = Zres;
        end
        Rfit = xfit(1:numVoigt)';
        Cfit = xfit(numVoigt+1:end)';
        Zfit = Zres + Zdata;

    %% lsqnonlin: check imagSum and ZcirIm
    elseif strcmp(method,'lsqnonlin')
        % Kramers-Kronig relations for equivalent circuit (Boukamp, 1995)
        numVoigt = N;
        imagSum = @(x) sum(x(1:numVoigt)/(1+(w*x(numVoigt+1:end)).^2));
        weights = data.Zmod.^(-2);
        Rinf = data.Zreal(1);
        ZcirRe = @(x) Rinf + imagSum(x);
        ZcirIm = @(x) -w*sum(x(1:numVoigt).*x(numVoigt+1:end)/(1+w*x(numVoigt+1:end)).^2);
        Zcircuit = @(x) ZcirRe(x) + 1i*ZcirIm(x);
        
        % Initial guesses
        R0 = 10^8 * randn(numVoigt,1);
        tau0 = 1./freq;
        x0 = [R0; tau0];
    
        % Nonlinear least-squares method
        optimFunc = @(x) Zcircuit(x) - Zdata;
        xfit = lsqnonlin(optimFunc, x0');
        Rfit = xfit(1:numVoigt);
        Cfit = xfit(numVoigt+1:end);
        Zfit = Zcircuit(xfit);
        Zres = Zfit - Zdata;

    else
        disp('Please specify a valid fitting method')
        return;
    end

    % Residuals
    ZmodRes = abs(Zfit) - data.Zmod;
    ZfitPh = 180/pi*phase(Zfit);
    ZphRes = ZfitPh - data.Zphz;

    % Goodness of fit
    R2real = 1 - sum(real(Zres).^2)/sum(real(Zdata-mean(Zdata)).^2);
    R2imag = 1 - sum(imag(Zres).^2)/sum(imag(Zdata-mean(Zdata)).^2);
    R2mod = 1 - sum(ZmodRes.^2)/sum((data.Zmod-mean(data.Zmod)).^2);
    R2phase = 1 - sum(ZphRes.^2)/sum(real(data.Zphz-mean(data.Zphz)).^2);
    R2 = [R2real R2imag R2mod R2phase]';

    % Nyquist plot
    figure(1)
    clf,cla
    plot(real(Zdata), -imag(Zdata), '.');
    hold on
    plot(real(Zfit), -imag(Zfit), '-');
    hold off
    xlabel('Re(Z)');
    ylabel('-Im(Z)');
    legend('Data','Fit','Location','southwest');

    % Bode plot
    figure(2)
    clf,cla
    yyaxis left
    loglog(freq, data.Zmod, '.');
    hold on
    loglog(freq, abs(Zfit), '-');
    xlim([freq(end) freq(1)]);
    xlabel('Freq');
    ylabel('Z');
    yyaxis right
    semilogx(freq, data.Zphz, '.');
    semilogx(freq, ZfitPh, '-');
    hold off
    ylabel('Phase');
    legend('Data','Fit','Location','southwest');
    
    % Residual plots
    figure(3)
    clf,cla
    subplot(2,2,1)
    semilogx(freq, real(Zres)./real(Zfit), '.');
    xlim([freq(end) freq(1)]);
    xlabel('Freq');
    ylabel('Normalized Re(Z) Residuals');
    title(['$R^2_{\mathrm{re}}$ = ' num2str(R2real)],'Interpreter','latex');
    
    subplot(2,2,2)
    semilogx(freq, imag(Zres)./imag(Zfit), '.');
    xlim([freq(end) freq(1)]);
    xlabel('Freq');
    ylabel('Normalized Im(Z) Residuals');
    title(['$R^2_{\mathrm{im}}$ = ' num2str(R2imag)],'Interpreter','latex');

    subplot(2,2,3)
    semilogx(freq, ZmodRes./abs(Zfit), '.');
    xlim([freq(end) freq(1)]);
    xlabel('Freq');
    ylabel('Normalized Z Residuals');
    title(['$R^2_{\mathrm{mod}}$ = ' num2str(R2mod)],'Interpreter','latex');

    subplot(2,2,4)
    semilogx(freq, ZphRes./ZfitPh, '.');
    xlim([freq(end) freq(1)]);
    xlabel('Freq');
    ylabel('Normalized Phase Residuals');
    title(['$R^2_{\mathrm{ph}}$ = ' num2str(R2phase)],'Interpreter','latex');

end
