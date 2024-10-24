function isValid = RC_Rule(circuit)
    % Rule 1: Exclude R in series with C directly connected
    isValid = true;
    % find series components
    [oc, numComps] = findParentheses(circuit);
    for idx = 1:numComps
        if circuit(oc(idx,1)-1) == 's'
            % isolate the series component
            component = circuit(oc(idx,1)-1:oc(idx,2));
            % check for subcomponents
            if ~any(ismember(['s','p'], component(3:end-1)))
                % if no subcomponents, check for other element types
                if ~any(ismember(['L','W','T','O','G'], component))
                    % if none, series component must only contain R and C
                    isValid = false;
                    return;
                end
            end
        end
    end
end
