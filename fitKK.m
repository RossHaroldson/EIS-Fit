function [] = fitKK(freq, Zdata, Zcircuit, elementVals)
% Fit EIS data by applying Kramers-Kronig relations 
% to the equivalent circuit impedance function.

% Assumes a vectorized impedance function that takes arguments as
% -> Zcircuit([elementVals ',' freq])
    
    % Kramers-Kronig calculations
    ZcirPoints = Zcircuit([elementVals ',' freq]);
    weights = 1./(abs(ZcirPoints).^2);
    imagIntegral = 2/pi * integral(@(x) (x*imag(Zcircuit(elementVals,x)) - freq.*imag(ZcirPoints))./(x^2-freq.^2), 0, Inf);
    Rinf = sum(weights.*(real(ZcirPoints)-imagIntegral))/sum(weights);
    ZfitRe = Rinf + imagIntegral;
    ZfitIm = 2/pi*freq .* integral(@(x) (real(Zcircuit(elementVals,x) - real(ZcirPoints)))./(x^2-freq.^2), 0, Inf);
    Zfit = ZfitRe + 1i*ZfitIm;

    % Residuals
    ZcirRes = Zdata - ZcirPoints;
    ZfitRes = Zdata - Zfit;

    % Goodness of Fit (R^2)
    R2cirRe = 1 - sum(real(ZcirRes).^2)/sum(real(Zdata-mean(Zdata)).^2);
    R2fitRe = 1 - sum(real(ZcircFit).^2)/sum(real(Zdata-mean(Zdata)).^2);
    R2cirIm = 1 - sum(imag(ZcirRes).^2)/sum(imag(Zdata-mean(Zdata)).^2);
    R2fitIm = 1 - sum(imag(ZcircFit).^2)/sum(imag(Zdata-mean(Zdata)).^2);
    R2cirMod = 1 - sum(abs(ZcirRes).^2)/sum(abs(Zdata-mean(Zdata)).^2);
    R2fitMod = 1 - sum(abs(ZcircFit).^2)/sum(abs(Zdata-mean(Zdata)).^2);
    R2cirPh = 1 - sum(phase(ZcirRes).^2)/sum(phase(Zdata-mean(Zdata)).^2);
    R2fitPh = 1 - sum(phase(ZcircFit).^2)/sum(phase(Zdata-mean(Zdata)).^2);

    %{
    % Brute force KK fit without an equivalent circuit
    realIntegrals = zeros(length(freq),1);
    imagIntegrals = zeros(length(freq),1);
    for n = 1:length(freq)
        if n <= 2
            imagIntegrals(n) = 2/pi * trapz(freq(n+1:end), (freq(n+1:end).*Zimag(n+1:end)-freq(n)*Zimag(n))./(freq(n+1:end).^2-freq(n)^2));
            realIntegrals(n) = -2/pi * freq(n) * trapz(freq(n+1:end), (Zreal(n+1:end)-Zreal(n))./(freq(n+1:end).^2-freq(n)^2));
        elseif n >= length(freq)-1
            imagIntegrals(n) = 2/pi * trapz(freq(1:n-1), (freq(1:n-1).*Zimag(1:n-1)-freq(n)*Zimag(n))./(freq(1:n-1).^2-freq(n)^2));
            realIntegrals(n) = -2/pi * freq(n) * trapz(freq(1:n-1), (Zreal(1:n-1)-Zreal(n))./(freq(1:n-1).^2-freq(n)^2));
        else
            imagIntegrals(n) = 2/pi * ( trapz(freq(1:n-1), (freq(1:n-1).*Zimag(1:n-1)-freq(n)*Zimag(n))./(freq(1:n-1).^2-freq(n)^2)) + trapz(freq(n+1:end), freq(n)./freq(n+1:end).*(Zimag(n+1:end)-Zimag(n))./(freq(n+1:end).^2-freq(n)^2)) );
            realIntegrals(n) = -2/pi * freq(n) * ( trapz(freq(1:n-1), (Zreal(1:n-1)-Zreal(n))./(freq(1:n-1).^2-freq(n)^2)) + trapz(freq(n+1:end), (Zreal(n+1:end)-Zreal(n))./(freq(n+1:end).^2-freq(n)^2)) );
        end
    end
    
    Rinf = sum(weights.*(Zreal - imagIntegrals))/(sum(weights));
    ZrealKK = Rinf + imagIntegrals;
    ZimagKK = realIntegrals;
    
    ZmodKK = (ZrealKK.^2+ZimagKK.^2).^(1/2);
    ZphzKK = 180/pi.*atan(ZimagKK./ZrealKK);
    ZphzKK(ZphzKK>0) = ZphzKK(ZphzKK>0) - 180;
    
    ZrealRes = Zreal-ZrealKK;
    ZimagRes = Zimag-ZimagKK;
    ZmodRes = Zmod-ZmodKK;
    ZphzRes = Zphz-ZphzKK;
    
    R2real = 1 - sum(ZrealRes.^2)/sum((Zreal-mean(Zreal)).^2);
    R2imag = 1 - sum(ZimagRes.^2)/sum((Zimag-mean(Zimag)).^2);
    R2mod = 1 - sum(ZmodRes.^2)/sum((Zmod-mean(Zmod)).^2);
    R2phz = 1 - sum(ZphzRes.^2)/sum((Zphz-mean(Zphz)).^2);
    %}

    % Nyquist plot
    figure(1)
    clf,cla
    plot(real(Zdata),-imag(Zdata),'ok');
    hold on
    plot(real(ZcirPoints),-imag(ZcirPoints),'ob');
    plot(ZfitRe,-ZfitIm,'-b');
    hold off
    xlabel('Re(Z)');
    ylabel('-Im(Z)');
    legend('Data','Circuit','Fit','Location','southwest');

    % Bode plot
    figure(2)
    clf,cla
    yyaxis left
    loglog(freq,abs(ZData),'o');
    hold on
    loglog(freq,abs(ZcirPoints),'.');
    loglog(freq,abs(Zfit),'-');
    xlim([freq(end),freq(1)]);
    xlabel('Freq');
    ylabel('Z');
    yyaxis right
    semilogx(freq,phase(Zdata),'o');
    semilogx(freq,phase(ZcirPoints),'.');
    semilogx(freq,phase(Zfit),'-');
    hold off
    ylabel('Phase');
    legend('Data','Circuit','Fit','Location','southwest');
    
    % Residual plots
    figure(3)
    clf,cla
    subplot(2,2,1)
    semilogx(freq,real(ZcirRes./Zdata),'.');
    hold on
    semilogx(freq,real(ZfitRes./Zdata),'.');
    hold off
    xlim([freq(end),freq(1)]);
    xlabel('Freq');
    ylabel('Normalized Re(Z) Residuals');
    legend('Circuit','Fit');
    title(['Circuit $R_{\mathrm{re}}^2$ = ',num2str(R2cirRe),'; Fit $R_{\mathrm{re}}^2$ = ',num2str(R2fitRe)],'Interpreter','latex');
    
    subplot(2,2,2)
    semilogx(freq,imag(ZcirRes./Zdata),'.');
    hold on
    semilogx(freq,imag(ZcirRes./Zdata),'.');
    hold off
    xlim([freq(end),freq(1)]);
    xlabel('Freq');
    ylabel('Normalized Im(Z) Residuals');
    legend('Circuit','Fit');
    title(['Circuit $R_{\mathrm{im}}^2$ = ',num2str(R2cirIm),'; Fit $R_{\mathrm{im}}^2$ = ',num2str(R2fitIm)],'Interpreter','latex');
    
    subplot(2,2,3)
    semilogx(freq,abs(ZcirRes./Zdata),'.');
    hold on
    semilogx(freq,abs(ZfitRes./Zdata),'.');
    hold off
    xlim([freq(end),freq(1)]);
    xlabel('Freq');
    ylabel('Normalized Z Residuals');
    legend('Circuit','Fit');
    title(['Circuit $R_{\mathrm{mod}}^2$ = ',num2str(R2cirMod),'; Fit $R_{\mathrm{mod}}^2$ = ',num2str(R2fitMod)],'Interpreter','latex');
    
    subplot(2,2,4)
    semilogx(freq,phase(ZcirRes./Zdata),'.');
    hold on
    semilogx(freq,phase(ZfitRes./Zdata),'.');
    hold off
    xlim([freq(end),freq(1)]);
    xlabel('Freq');
    ylabel('Normalized Phase Residuals');
    legend('Circuit','Fit');
    title(['Circuit $R_{\mathrm{ph}}^2$ = ',num2str(R2cirPh),'; Fit $R_{\mathrm{ph}}^2$ = ',num2str(R2fitPh)],'Interpreter','latex');

    % Brute force KK fit without equivalent circuit


end
