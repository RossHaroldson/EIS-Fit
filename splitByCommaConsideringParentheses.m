function parts = splitByCommaConsideringParentheses(str)
    % Split the string by commas, but consider nested parentheses
    parts = {};
    bracketLevel = 0;
    lastSplit = 1;
    for i = 1:length(str)
        if str(i) == '('
            bracketLevel = bracketLevel + 1;
        elseif str(i) == ')'
            bracketLevel = bracketLevel - 1;
        elseif str(i) == ',' && bracketLevel == 0
            parts{end+1} = str(lastSplit:i-1);
            lastSplit = i + 1;
        end
    end
    % Add the last part
    parts{end+1} = str(lastSplit:end);
end
