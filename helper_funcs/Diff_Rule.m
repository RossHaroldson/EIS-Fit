function isValid = Diff_Rule(circuit,modes,elementTypes)
    % Rule 3: see if there is a R,C, or L in direct series or parallel with a
    % diffusion element
    isValid = true;
    % Extract components
    comps = getDirectComponents(circuit,modes,elementTypes);
    elements = {};
    numComps = length(comps);
    if numComps > 0
        for idx = 1:numComps
            % if comp is an element, store it
            if ~any(ismember(['s','p'],comps{idx}))
                elements{end+1} = comps{idx};
            else 
            % if not, validate subcomponent
                isValid = Diff_Rule(comps{idx},modes,elementTypes);
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
