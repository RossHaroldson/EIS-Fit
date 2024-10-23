function isValid = isValidCircuit(circuit,modes,elementTypes)
% Recursively search the circuit components until it finds a R,C, or L
% in series or parallel directly with a diffusion element W,T,O, or G
% and return false if it does find it or true if it doesn't

    % Rule 7: should be called first -- other rules were written under the
    % assumption that components are irreducible.
    % Dump circuits with reducible elements, since numElements is
    % violated by reducing elements to canonical form.
    isValid = reductionRule(circuit);
    if ~isValid
        return;
    end

    % Rule 5: Limit inductors L to numL
    isValid = L_Limit_Rule(circuit);
    if ~isValid
        return;
    end

    % Rule 6: Limit capacitors C to numC
    isValid = C_Limit_Rule(circuit);
    if ~isValid
        return;
    end

    % Rule 4: Limit diffusion elements W, O, T, G to numDiff
    isValid = Diff_Limit_Rule(circuit);
    if ~isValid
        return;
    end

    % Rule 1: Exclude R in series with C directly connected
    isValid = RC_Rule(circuit);
    if ~isValid
        return;
    end
    % Rule 2: Exclude R in parallel with L directly connected
    isValid = RL_Rule(circuit);
    if ~isValid
        return;
    end

    % Rule 3: Check if a R,C, or L in series or parallel directly with a 
    % diffusion element W,T,O, or G
    isValid = Diff_Rule(circuit,modes,elementTypes);
    if ~isValid
        return;
    end
end
