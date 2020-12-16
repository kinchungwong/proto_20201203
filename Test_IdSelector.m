function Test_IdSelector
    % Smoke test for IdSelector. 
    % Illustrates basic requirements, including:
    % The use of MinCount and MaxCount (greater than 1), and also 
    % The Removal of items while enumeration is in progress.

    ids = 1:3:30;

    idsel = IdSelector(ids);
    idsel.MinCount = 3;
    idsel.MaxCount = 5;

    for k = 1:20
        sel = idsel.Select();
        if isempty(sel)
            fprintf("ended\n");
            break;
        end
        fprintf("[%d] : %s\n", k, num2str(sel));
        if ismember(16, sel) && (ismember(7, sel) || ismember(10, sel))
            fprintf("Upon seeing 16, removing 7 and 10.\n");
            idsel.Remove(7);
            idsel.Remove(10);
        end
    end
end
