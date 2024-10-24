function comps = getDirectComponents(circuit, elementTypes)
    % Return a list of components of circuit
    % comps may be elements or have subcomps
    compStr = circuit(3:end-1);
    [oc,~] = findParentheses(compStr);
    comps = {};
    idx = length(compStr);
    while idx > 0
        if strcmp(compStr(idx), ')')
            % if idx at ')', store entire preceding component 
            % s(...) or p(...) and step past
            parentheses = oc(oc(:,2)==idx,:);
            mode = parentheses(1)-1;
            comps{end+1} = compStr(mode:idx);
            idx = mode-1;
        elseif any(strcmp(compStr(idx), elementTypes))
            % if idx at element, store element and step past
            comps{end+1} = compStr(idx);
            idx = idx-1;
        else
            % if idx at some other char, step past
            idx = idx-1;
        end
    end
end
