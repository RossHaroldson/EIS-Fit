function flatCircuit = flattenCircuit(circuit, modes, elementTypes)
    % Recursively flatten nested components of the same mode, from inside out

    flatComps = {};
    % Extract components
    comps = getDirectComponents(circuit, modes, elementTypes);
    numComps = length(comps);
    % if circuit has comps
    if numComps > 0
        outerMode = circuit(1);
        % Step through components
        for idx = 1:numComps
            % if comp is not an element
            if any(strcmp(comps{idx}(1), modes))
                % Recursively flatten component
                flatComp = flattenCircuit(comps{idx}, modes, elementTypes);
                innerMode = flatComp(1);
                % Check if connection matches
                if strcmp(innerMode,outerMode)
                    % extract subcomponents of flatComp
                    subComps = getDirectComponents(flatComp, modes, elementTypes);
                    % append subcomps
                    for c = 1:length(subComps)
                        flatComps{end+1} = subComps{c};
                    end
                else
                    % append comp
                    flatComps{end+1} = flatComp;
                end
            else
                % append element
                flatComps{end+1} = comps{idx};
            end
        end
        flatComps = join(flatComps,',');
        flatComps = flatComps{1};
        flatCircuit = append(outerMode, '(', flatComps, ')');
    else
        % circuit is an element
        flatCircuit = circuit;
    end
end

function reducedComp = reduceSeriesParallel(mode, subComps)
    % Only apply reduction for R, C, L elements, not T
    elementsToReduce = {'R', 'C', 'L','W'};

    if all(ismember(subComps, elementsToReduce))
        if strcmp(mode, 's') || strcmp(mode, 'p')
            % Remove identical elements in series/parallel
            reducedComp = unique(subComps);
        else
            reducedComp = subComps;
        end
    else
        reducedComp = subComps;  % No reduction if 'T' is involved
    end

    % Recombine the reduced components into a string
    reducedComp = strjoin(reducedComp, ',');
end
