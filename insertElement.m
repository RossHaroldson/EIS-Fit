function newCircuits = insertElement(circuit, element)
    newCircuits = {};
    elementNode = struct('type', 'element', 'value', element);
    modes = {'series', 'parallel'};
    % Combine element with entire circuit
    for m = 1:length(modes)
        mode = modes{m};
        newCircuit = struct('type', mode, 'components', {{elementNode, circuit}});
        newCircuit = simplifyCircuit(newCircuit);
        if isValidCircuit(newCircuit)
            newCircuits{end+1} = newCircuit;
        else
            %disp(['Bad circuit found in outer: ' getCanonicalForm(newCircuit)])
        end
    end
    % Recurse into components
    if isfield(circuit, 'components')
        for i = 1:length(circuit.components)
            subcomponent = circuit.components{i};
            % Recurse into subcomponent
            subNewCircuits = insertElement(subcomponent, element);
            for j = 1:length(subNewCircuits)
                newSubcomponent = subNewCircuits{j};
                % Create new circuit by replacing subcomponent
                newCircuit = circuit;
                newCircuit.components{i} = newSubcomponent;
                newCircuit = simplifyCircuit(newCircuit);
                if isValidCircuit(newCircuit)
                    newCircuits{end+1} = newCircuit;
                else
                    %disp(['Bad circuit found in inner: ' getCanonicalForm(newCircuit)])
                end
            end
        end
    end
end
