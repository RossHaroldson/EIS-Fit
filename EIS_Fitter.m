% EISDataFitting.m
% This script will import the EIS Data, organize them, then call the
% fitting algorithm. The fitting algorithm should return the top M fits per
% number of parameters 

% Clear Data
clear all
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
FinGerSh= @(w,Yo,k,d,D) tanh(d.*sqrt((k1+1j.*w)./D))./sqrt((k1+1j.*w).*D); 
% Finite gerischer open impedance maybe reflective boundary (not in literature)
FinGerOp= @(w,Yo,k,d,D) coth(d.*sqrt((k1+1j.*w)./D))./sqrt((k1+1j.*w).*D); 

% Initalize parameters
freq = logspace(6,-4,100);
area = 4e-6; % in 2mm x 2mm in meters^2
thickness = 5e-7; % in 500nm meters
%% Import Data folder
% import all EIS data from a folder
% get folder with data
% import all .dta files in that folder as tables into a struct.
importfolder=uigetdir(fileparts(matlab.desktop.editor.getActiveFilename),'Choose which folder of data to import');
filelist = dir([importfolder '\*.dta']);
measurements = struct();
for i = 1:length(filelist)
    % import each file to the measurements struct
    measurements(i).table = importGamryDTAfile(fullfile(filelist(i).folder,filelist(i).name));
    measurements(i).name = filelist(i).name(1:end-4);
    measurements(i).folder = filelist(i).folder;
end
%% Prepare fitting
% gather any relavent data before starting fitting
% prepare guess circuit(s)
gcirc1='s(R,p(C,R))'; % randles circuit
gcirc2='s(R,p(s(R,p(R,C)),C,s(p(O,O),p(O,O))))';
gcirc3='s(R,L,p(s(R,p(R,C)),C,s(p(O,O),p(O,O))))';
% convert circuits to function handles
[gcircfun1, cirvar1] = CirStr2FuncHan(gcirc1);
[gcircfun2, cirvar2] = CirStr2FuncHan(gcirc2);
[gcircfun3, cirvar3] = CirStr2FuncHan(gcirc3);
%% Start fitting

%% Plot fits and errors