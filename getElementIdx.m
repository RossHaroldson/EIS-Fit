function match = getElementIdx(expr_str, elem_symbol)
    pattern = ['\<', elem_symbol, '\>'];
    [match,~] = regexp(expr_str, pattern);
end
