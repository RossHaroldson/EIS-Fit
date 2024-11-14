function [] = plotFit(freq, Zdata, fit)

    % Nyquist plot
    figure();
    subplot(2,2,1)
    plot(real(Zdata), -imag(Zdata), '.');
    hold on
    plot(real(fit.simplex.fitcurve), -imag(fit.simplex.fitcurve), '-');
    plot(real(fit.levenbergMarquardt.fitcurve), -imag(fit.levenbergMarquardt.fitcurve), '--');
    plot(real(fit.trustRegion.fitcurve), -imag(fit.trustRegion.fitcurve), '-.k');
    hold off
    grid on
    xlabel('Real(Z)');
    ylabel('-Imag(Z)');
    legend('Data','Simplex','Levenberg-Marquardt','Trust-Region-Reflexive','Location','northeast');

    % Bode plots
    %figure();
    subplot(2,2,2)
    loglog(freq, abs(Zdata), '.');
    hold on
    loglog(freq, abs(fit.simplex.fitcurve), '-');
    loglog(freq, abs(fit.levenbergMarquardt.fitcurve), '--');
    loglog(freq, abs(fit.trustRegion.fitcurve), '-.k');
    hold off
    grid on
    xlim([freq(end) freq(1)]);
    xlabel('Frequency (Hz)');
    ylabel('Impedance Magnitude |Z| (ohms)');
    legend('Data','Simplex','Levenberg-Marquardt','Trust-Region-Reflexive','Location','northeast');

    %figure();
    subplot(2,2,3)
    semilogx(freq, phase(Zdata), '.');
    hold on
    semilogx(freq, phase(fit.simplex.fitcurve), '-');
    semilogx(freq, phase(fit.levenbergMarquardt.fitcurve), '--');
    semilogx(freq, phase(fit.trustRegion.fitcurve), '-.k');
    hold off
    grid on
    xlim([freq(end) freq(1)]);
    xlabel('Frequency (Hz)');
    ylabel('Phase (degrees)');
    legend('Data','Simplex','Levenberg-Marquardt','Trust-Region-Reflexive','Location','north');
    
    % Error plot
    %figure();
    subplot(2,2,4)
    loglog(freq, abs(fit.simplex.residuals), '-');
    hold on
    loglog(freq, abs(fit.levenbergMarquardt.residuals), '--');
    loglog(freq, abs(fit.trustRegion.residuals), '-.k');
    hold off
    grid on
    xlim([freq(end) freq(1)]);
    xlabel('Frequency (Hz)');
    ylabel('Weighted Residuals');
    legend('Simplex','Levenberg-Marquardt','Trust-Region-Reflexive','Location','northeast');

end

