%% Genetic algorithm for optimized equivalent circuit fitting
clear

%% Load constants and impedance functions
% constants
kb = 1.380662e-23;    % Boltzmann constant (J/K)
kbeV = 8.6173303e-5;    % Boltzmann constant (eV/K)
T = 293; % room temp 21C in kelvin
q = 1.6021892e-19;   % Proton charge (C)
eps0 = 8.85418781e-12;  % Farads/meter;

% diff functions
Yofun = @(Area,C,D) Area.*q^2.*C.*sqrt(D)./kb./T;
Bfun = @(thickness,D) thickness./sqrt(D);

% impedance functions
angfreq = @(f) 2*pi*f;
Res = @(R) R;
Cap = @(w,C) 1./(1j.*w.*C);
Ind = @(w,L) L.*w*1j;
% Infinite warburg impedance
Winf = @(w,Yo) 1./Yo./sqrt(1j.*w);
% Finite warburg open reflective boundary
FSW = @(w,Yo,B) coth(B.*sqrt(1j.*w))./Yo./sqrt(1j.*w);
% Finite warburg short transmittive boundary
FLW = @(w,Yo,B) tanh(B.*sqrt(1j.*w))./Yo./sqrt(1j.*w); 
% Infinite gerischer impedance
Ger = @(w,Yo,k) (k+1j.*w).^(-0.5)./Yo;
% Fractal gerischer impedance
GerFrac = @(w,Yo,k,al) (k+1j.*w).^(-al)./Yo;
% Finite gerischer short impedance maybe transmittive boundary 
FinGerSh= @(w,Yo,k,d,D) tanh(d.*sqrt((k+1j.*w)./D))./sqrt((k+1j.*w).*D); 
% Finite gerischer open impedance maybe reflective boundary (not in literature)
FinGerOp= @(w,Yo,k,d,D) coth(d.*sqrt((k+1j.*w)./D))./sqrt((k+1j.*w).*D); 

% Initalize parameters
freq = logspace(6,-4,100);
area = 4e-6; % in 2mm x 2mm in meters^2
thickness = 5e-7; % in 500nm meters

% Algorithm parameters
maxGen = 5; % maximum number of generations based on initial FitCirc

% Circuit parameters
maxElem = 6;
elemTypes = {'R','C','L','W','O','T','G'};

%% Import Data folder
% import all EIS data from a folder
% get folder with data
% import all .dta files in that folder as tables into a struct.
importfolder=uigetdir(fileparts(matlab.desktop.editor.getActiveFilename),'Choose which folder of data to import');
filelist = dir([importfolder '\*.dta']);
Measurements = struct();
for i = 1:length(filelist)
    % import each file to the measurements struct
    Measurements(i).data = importGamryDTAfile(fullfile(filelist(i).folder,filelist(i).name));
    Measurements(i).name = filelist(i).name(1:end-4);
    Measurements(i).folder = filelist(i).folder;
    Measurements(i).CircuitGuess = struct();
end

%% Prepare fitting
% gather any relavent data before starting fitting
% prepare guess circuit(s) and make sure they are validate them
FitCirc = struct();
FitCirc(1).String = "R";
% check if circuits are valid
for i = 1:length(FitCirc)
    if isValidCircuitString(FitCirc(i).String)
        disp([FitCirc(i).String{1} ' is a valid circuit'])
        FitCirc(i).String = getCanonicalForm(parseCircuitString(FitCirc(i).String));
    else
        warning([FitCirc(i).String{1} ' is not a valid circuit. Replacing it with a resistor.'])
        % use a resistor as a dummy replacement
        FitCirc(i).String = "R";
    end
    FitCirc(i).circuit = parseCircuitString(FitCirc(i).String);
end
% convert circuit strings to function handles
for i = 1: length(FitCirc)
    [FitCirc(i).Func, FitCirc(i).Variables] = CirStr2FuncHan(FitCirc(i).String{1});
end

%% Offspring generation and fitting loop
%for i = 1:length(Measurements)
    i=1;        
    KKfits = struct();
    Zdata = Measurements(i).data.Zreal+1j.*Measurements(i).data.Zimag;
    % generate Kramers-Kronig fit
    [KKfits(i).Z, KKfits(i).x0, KKfits(i).lb, KKfits(i).ub, KKfits(i).Variables] = KKfunc(Measurements(i).data);
    Measurements(i).KKfit = fitZ( Zdata, Measurements(i).data.Freq, KKfits(i).Z, KKfits(i).x0, KKfits(i).lb, KKfits(i).ub );
    Measurements(i).KKfit.Variables = KKfits(i).Variables;
    for k = 1:length(FitCirc)
        % fit starting circuit guess
        [v0,lb,ub] = getInitialGuess(FitCirc(k).Variables,1,1);
        Measurements(i).CircuitGuess(k).Func = FitCirc(k).Func;
        Measurements(i).CircuitGuess(k).Variables = FitCirc(k).Variables;
        Measurements(i).CircuitGuess(k).String = FitCirc(k).String;
        Measurements(i).CircuitGuess(k).fit = fitZ(Zdata, Measurements(i).data.Freq,FitCirc(k).Func,v0,lb,ub);
        %% Create new generation of circuits            
        localFitCirc = FitCirc(k);
        localNumElem = getNumElements(localFitCirc.circuit);
        localNewCircuits = "";
        for g = 1:maxGen
            for c = 1:length(localFitCirc)
                localNewCircuits = createNewCircuits(elemTypes, localNewCircuits, localFitCirc(c).circuit, localNumElem+1);
            end
            FitCirc(k).Generations(g).String = localNewCircuits(2:end);
            for c = 1:length(FitCirc(k).Generations(g).String)
                FitCirc(k).Generations(g).circuit(c) = parseCircuitString(FitCirc(k).Generations(g).String(c));
                [FitCirc(k).Generations(g).Func(c), FitCirc(k).Generations(g).Variables(c)] = CirStr2FuncHan(FitCirc(k).Generations(g).String(c));
            end
            %% Fit new circuits to EIS data
            for c = 1:length(FitCirc(k).Generations(g).String)
                [v0,lb,ub] = getInitialGuess(FitCirc(k).Generations(g).Variables(c),1,1);
                Measurements(i).CircuitGuess(k).Generations(g).Func(c) = FitCirc(k).Generations(g).Func(c);
                Measurements(i).CircuitGuess(k).Generations(g).Variables(c) = FitCirc(k).Generations(g).Variables(c);
                Measurements(i).CircuitGuess(k).Generations(g).String(c) = FitCirc(k).Generations(g).String(c);
                Measurements(i).CircuitGuess(k).Generations(g).fit(c) = fitZ(Zdata, Measurements(i).data.Freq,FitCirc(k).Generations(g).Func(c),v0,lb,ub);
                Measurements(i).CircuitGuess(k).Generations(g).fit(c).Variables = FitCirc(k).Generations(g).Variables(c);
            end
            %% Sort new circuits by best fit
            
            %% Mutate poorly fit circuits
            
            %% Reset local circuits for next loop iteration
            localFitCirc = FitCirc(k).Generations(g);
            localNumElem = getNumElements(localFitCirc(1).circuit);
            localNewCircuits = "";
        end
    end
%end
% plot best fit results
m=1;
Zdata = Measurements(m).data.Zreal+1j.*Measurements(m).data.Zimag;
plotFit(Measurements(m).data.Freq, Zdata, Measurements(m).KKfit);
plotFit(Measurements(m).data.Freq, Zdata, Measurements(m).CircuitGuess(2).fit);
for i = 1:length(Measurements)
   simplexgof(i)=Measurements(i).KKfit.simplex.gof;
   trustRegiongof(i)=Measurements(i).KKfit.trustRegion.gof;
   levenbergMarquardtgof(i)=Measurements(i).KKfit.levenbergMarquardt.gof;
end
figure;hold on;
semilogy(simplexgof)
semilogy(trustRegiongof)
semilogy(levenbergMarquardtgof)
grid on
set(gca,'yscale','log')
hold off