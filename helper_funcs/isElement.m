function result = isElement(part, elementTypes)
    % Check if the part is one of the element types
    result = any(strcmp(part, elementTypes));
end
