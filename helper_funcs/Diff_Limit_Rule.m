function isValid = Diff_Limit_Rule(circuit)
    % Rule 4: Limit diffusion elements W, O, T, G to n
    isValid = true;
    numDiff = 4;
    % [~,nums] = findElements(circuit, {'W','T','O','G'});
    % n = sum(nums);
    n=findNumElements(circuit,{'W','T','O','G'});
    if n > numDiff
        isValid = false;
        return;
    end
end
