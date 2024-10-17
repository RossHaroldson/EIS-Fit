function repr = getCanonicalForm(circuit)
    % Get a canonical string representation of the circuit
    if strcmp(circuit.type, 'element')
        repr = circuit.value;
    else
        compReprs = cellfun(@getCanonicalForm, circuit.components, 'UniformOutput', false);
        % Sort the representations to account for commutativity
        compReprs = sort(compReprs);
        if strcmp(circuit.type, 'series')
            operatorstr = 's';
        elseif strcmp(circuit.type, 'parallel')
            operatorstr = 'p';
        end
        repr = [operatorstr, '(', strjoin(compReprs, ','), ')'];
    end
end