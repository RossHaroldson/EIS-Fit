function isValid = C_Limit_Rule(circuit)
    % Rule 6: Limit capacitors C to n
    isValid=true;
    numC = 4;
    %[~,n] = findElements(circuit, {'C'});
    n=findNumElements(circuit,{'C'});
    if n > numC
        isValid = false;
        return;
    end
end
