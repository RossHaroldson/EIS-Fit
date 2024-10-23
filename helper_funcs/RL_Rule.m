function isValid = RL_Rule(circuit)
    % Rule 2: Exclude R in parallel with L directly connected
    isValid = true;
    % find parallel components
    [oc, numComps] = findParentheses(circuit);
    for idx = 1:numComps
        if circuit(oc(idx,1)-1) == 'p'
            % isolate the parallel component
            component = circuit(oc(idx,1)-1:oc(idx,2));
            % check for subcomponents
            if ~any(ismember(['s','p'], component(2:end)))
                % if no subcomponents, check for other element types
                if ~any(ismember(['C','W','T','O','G'], component))
                    % if none, parallel component must only contain R and L
                    isValid = false;
                    return;
                end
            end
        end
    end
end
