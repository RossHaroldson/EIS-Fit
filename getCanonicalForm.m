function repr = getCanonicalForm(circuit)
    % Get a canonical string representation of the circuit struct
    if strcmp(circuit.type, 'element')
        repr = circuit.value;
    else
        % Precompute operator string with the first letter of the
        % circuit.type
        operatorstr = circuit.type(1);  % 's' for series, 'p' for parallel


        % Recurse and sort components' representations
        compReprs = cell(size(circuit.components));  % Preallocate
        for i = 1:numel(circuit.components)
            compReprs{i} = getCanonicalForm(circuit.components{i});
        end
        compReprs = sort(compReprs);

        % Concatenate results
        repr = [operatorstr, '(', strjoin(compReprs, ','), ')'];
    end
end