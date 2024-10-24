function isValid = Diff_Rule(circuit, elementTypes)
    % Rule 3: see if there is a R,C, or L in direct series or parallel with a
    % diffusion element
    isValid = true;
    % Extract components
    comps = splitByCommaConsideringParentheses(circuit(3:end-1));
    elements = {};
    numComps = length(comps);
    if numComps > 0
        for idx = 1:numComps
            % if comp is an element, store it
            if ~strcmp('s', comps{idx}(1)) && ~strcmp('p', comps{idx}(1))
                elements{end+1} = comps{idx};
            else 
            % if not, validate subcomponent
                isValid = Diff_Rule(comps{idx}, elementTypes);
                if ~isValid
                    return;
                end
            end
        end
        if any(ismember({'R','L','C'},comps)) && any(ismember({'W','T','O','G'},comps))
            isValid = false;
            return;
        end
    else
        isValid = true;
    end
end
