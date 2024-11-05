function [circuit, idx] = parseCircuit(str, idx)
    if nargin < 2
        idx = 1;
    end
    if idx > length(str)
        circuit = [];
        return;
    end
    if str(idx) == 's' || str(idx) == 'p'
        circuit.type = connectionType(str(idx));
        idx = idx + 1; % Move past 's' or 'p'
        assert(str(idx) == '(', 'Expected ( after %s', str(idx-1));
        idx = idx + 1; % Move past '('
        components = {};
        while idx <= length(str) && str(idx) ~= ')'
            [comp, idx] = parseCircuit(str, idx);
            components{end+1} = comp;
            if idx <= length(str) && str(idx) == ','
                idx = idx + 1; % Move past ','
            end
        end
        assert(str(idx) == ')', 'Expected ) at position %d', idx);
        idx = idx + 1; % Move past ')'
        circuit.components = components;
    else
        % Parse element
        elemType = '';
        while idx <= length(str) && isLetter(str(idx))
            elemType = [elemType, str(idx)];
            idx = idx + 1;
        end
        circuit.type = 'element';
        circuit.value = elemType;
    end
end

function isLetter = isLetter(c)
    isLetter = ismember(c, 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz');
end

function connType = connectionType(c)
    if c == 's'
        connType = 'series';
    elseif c == 'p'
        connType = 'parallel';
    else
        error('Unknown connection type: %s', c);
    end
end