function comps = getDirectComponents(circuit, modes, elementTypes)
    % Return a list of components of circuit
    % comps may be elements or have subcomps
    compStr = circuit(3:end-1);
    [oc,~] = findParentheses(compStr);
    comps = {};
    idx = 1;
    while idx <= length(compStr)
        if any(strcmp(compStr(idx), modes))
            % if idx at 's' or 'p', found component with subcomponents
            % store entire component s(...) or p(...) and step past
            parentheses = oc(oc(:,1)==idx+1,:);
            close = parentheses(2);
            comps{end+1} = compStr(idx:close);
            idx = close+1;
        elseif any(strcmp(compStr(idx), elementTypes))
            % if idx at element, store element and step forward
            comps{end+1} = compStr(idx);
            idx = idx+1;
        else
            % if idx at some other char, step forward
            idx = idx+1;
        end
    end
end
