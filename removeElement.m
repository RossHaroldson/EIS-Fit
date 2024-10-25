function canonCircuit = removeElement(circuit,idx,elementTypes)
% remove element at idx from canonical circuit string
% reorganize, simplify, and canonize new circuit
    % start with copy of circuit as a char vector
    newCircuit = convertStringsToChars(circuit);
    % check if newCircuit(idx) is an element
    if any(ismember(newCircuit(idx),elementTypes))
        % locate all parentheses pairs
        [oc,~] = findParentheses(newCircuit);
        % get parentheses pairs that open before idx
        parentParentheses = oc(oc(:,1)<idx,:);
        % last parent parentheses pair is the direct parent of element
        open = parentParentheses(end,1);
        close = parentParentheses(end,2);
        % get all components of parent comp
        comps = splitByCommaConsideringParentheses(newCircuit(open+1:close-1));
        if length(comps) == 2
            % remove parent ')'
            newCircuit = eraseBetween(newCircuit,close,close);
            % remove element and following comma
            newCircuit = eraseBetween(newCircuit,idx,idx+1);
            % remove parent 's(' or 'p('
            newCircuit = eraseBetween(newCircuit,open-1,open);
        else
            % if element appears last in the parent component
            if close == idx+1
                % remove element and preceding comma
                newCircuit = eraseBetween(newCircuit,idx-1,idx);
            else
                % remove element and following comma
                newCircuit = eraseBetween(newCircuit,idx,idx+1);
            end
        end
        % simplify and canonize
        canonCircuit = simplifyCircuitString(newCircuit);
    end
end

