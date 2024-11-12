function [] = plotFit(freq, Zdata, fit)

    % Nyquist plot
    figure();
    plot(real(Zdata), -imag(Zdata), '.');
    hold on
    plot(real(fit.simplex.fitcurve), -imag(fit.simplex.fitcurve), '-');
    plot(real(fit.levenbergMarquardt.fitcurve), -imag(fit.levenbergMarquardt.fitcurve), '--');
    plot(real(fit.trustRegion.fitcurve), -imag(fit.trustRegion.fitcurve), '-.k');
    hold off
    xlabel('Re(Z)');
    ylabel('-Im(Z)');
    legend('Data','Simplex','Levenberg-Marquardt','Trust-Region-Reflexive','Location','northeast');

    % Bode plots
    figure();
    loglog(freq, abs(Zdata), '.');
    hold on
    loglog(freq, abs(fit.simplex.fitcurve), '-');
    loglog(freq, abs(fit.levenbergMarquardt.fitcurve), '--');
    loglog(freq, abs(fit.trustRegion.fitcurve), '-.k');
    hold off
    xlim([freq(end) freq(1)]);
    xlabel('Freq');
    ylabel('Z');
    legend('Data','Simplex','Levenberg-Marquardt','Trust-Region-Reflexive','Location','northeast');

    figure();
    semilogx(freq, phase(Zdata), '.');
    hold on
    semilogx(freq, phase(fit.simplex.fitcurve), '-');
    semilogx(freq, phase(fit.levenbergMarquardt.fitcurve), '--');
    semilogx(freq, phase(fit.trustRegion.fitcurve), '-.k');
    hold off
    xlim([freq(end) freq(1)]);
    xlabel('Freq');
    ylabel('Phase');
    legend('Data','Simplex','Levenberg-Marquardt','Trust-Region-Reflexive','Location','north');
    
    % Error plot
    figure();
    semilogx(freq, abs(fit.simplex.residuals), '-');
    hold on
    semilogx(freq, abs(fit.levenbergMarquardt.residuals), '--');
    semilogx(freq, abs(fit.trustRegion.residuals), '-.k');
    hold off
    xlim([freq(end) freq(1)]);
    xlabel('Freq');
    ylabel('Residuals');
    legend('Simplex','Levenberg-Marquardt','Trust-Region-Reflexive','Location','northeast');

end

