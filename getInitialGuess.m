function [v0,lb,ub] = getInitialGuess(VariableNames,area,thickness)
% come up with an initial guess for the parameters v0 based off the
% variable names and create upper and lower bounds
% be sure to add the

% Normalize based off area and thickness
% work in progress

for l = 1:length(VariableNames)
    % for each variable we need to give a guess and determine
    % upper and lower bounds depeneding on what type of variable it
    % is. probably make a function to do this.
    if contains(VariableNames{l},'R')
        v0(l) = 1; % guess
        lb(l) = 1; % lower bound
        ub(l) = 1e10; % upper bound
    elseif contains(VariableNames{l},'C')
        v0(l) = 1e-9; % guess farads
        lb(l) = 1e-13; % lower bound
        ub(l) = 1e-5; % upper bound
    elseif contains(VariableNames{l},'L')
        v0(l) = 1e-11; % guess farads
        lb(l) = 1e-12; % lower bound
        ub(l) = 1e-2; % upper bound
    elseif contains(VariableNames{l},'Yo')
        v0(l) = 1e-9; % guess farads
        lb(l) = 1e-13; % lower bound
        ub(l) = 1e-5; % upper bound
    elseif contains(VariableNames{l},'B')
        v0(l) = 1; % guess farads
        lb(l) = 1e-6; % lower bound
        ub(l) = 1e4; % upper bound
    elseif contains(VariableNames{l},'k')
        v0(l) = 1; % guess farads
        lb(l) = 1e-3; % lower bound
        ub(l) = 1e6; % upper bound
    else
        error(['Encountered variable name ' VariableNames{l} ' that isn''t known to getInitialGuess()'])
    end
end
end