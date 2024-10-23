function [idx, numElem] = findElements(str,elem)
    idx = {};
    numElemTypes = length(elem);
    numElem = zeros(size(elem));
    % get indices of each elem in str
    for e = 1:numElemTypes
        loc = strfind(str,elem(e));
        idx{end+1} = loc; 
        numElem(e) = length(loc);
    end
end
