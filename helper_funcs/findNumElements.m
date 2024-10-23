function totalElements = findNumElements(charArray,elementTypes)
    totalElements = 0;
    for i = 1:length(elementTypes)
        totalElements = totalElements + sum(charArray == elementTypes{i});
    end
end
