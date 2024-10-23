function isValid = L_Limit_Rule(circuit)
    % Rule 5: Limit inductors L to n
    isValid = true;
    numL = 2;
    % [~,n] = findElements(circuit, {'L'});
    n=findNumElements(circuit,{'L'});
    if n > numL
        isValid = false;
        return;
    end
end
