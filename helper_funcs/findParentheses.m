function [oc, numPairs] = findParentheses(str)
    % column 1 = index of '(' in str
    % column 2 = index of ')' in str
    % rows are pairs of '(' and ')' indices
    % rows are sorted by ascending ')' index by default
    oc = [];
    op = strfind(str, '(');
    cl = strfind(str, ')');
    
    % search for pairs until all are identified
    while ~isempty(op) && ~isempty(cl)
        % find '(' for first ')'
        idx = find(op < cl(1), 1, 'last');
        % append this pair to function output
        oc = [oc; op(idx), cl(1)];
        % remove paired '(' and ')'
        op(idx) = [];
        cl(1) = [];
    end
    numPairs = size(oc, 1);
end
