function totalComps = findNumComponents(charArray,modes)
    totalComps = 0;
    for i = 1:length(modes)
        totalComps = totalComps + sum(charArray == modes{i});
    end
end
