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
