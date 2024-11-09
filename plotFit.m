function [] = plotFit(freq, Zdata, Zfit, fitError)

    % Nyquist plot
    [figNyq, axNyq] = figure();
    plot(real(Zdata), -imag(Zdata), '.');
    hold on
    plot(real(Zfit), -imag(Zfit), '-');
    hold off
    xlabel('Re(Z)');
    ylabel('-Im(Z)');
    legend('Data','Fit','Location','southwest');

    % Bode plot
    [figBode, axBode] = figure();
    yyaxis left
    loglog(freq, abs(Zdata), '.');
    hold on
    loglog(freq, abs(Zfit), '-');
    xlim([freq(end) freq(1)]);
    xlabel('Freq');
    ylabel('Z');
    yyaxis right
    semilogx(freq, phase(Zdata), '.');
    semilogx(freq, phase(Zfit), '-');
    hold off
    ylabel('Phase');
    legend('Data','Fit','Location','southwest');
    
    % Error plot
    [figErr, axErr] = figure();
    semilogx(freq, fitError, '-');
    xlim([freq(end) freq(1)]);
    xlabel('Freq');
    ylabel('Fit Error');

end

