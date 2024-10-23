% Rule 7: replaces uniqueComponents -- should be called first in validation.
% Check for RR, CC, LL, and WW components. 
% Since duplicates are reduced, numElements is violated. 
% So instead of reducing, just find and confirm invalidity.
function isValid = reductionRule(circuit)
    % Rule 7: see if there is a R,C,L, or W in direct series or parallel
    % with a like element
    isValid = true;
    % find elements of reducible type
    [Redidx, numRed] = findElements(circuit, {'R','L','C','W'});
    numRedTypes = length(numRed);
    for e = 1:numRedTypes
        for i = 1:numRed(e)-1
            % Assuming a flattened, canonically ordered circuit:
            % If sorted elements of the same type are two indices
            % away, then they are directly connected and reducible.
            if Redidx{e}(i) + 2 == Redidx{e}(i+1)
                isValid = false;
                return;
            end
        end
    end
end
