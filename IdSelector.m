classdef IdSelector < handle
    % Given a sequence of integer-valued IDs, enumerate consecutive
    % subsequences having a certain number of elements.
    %
    % The integer-valued IDs are not necessarily sorted, not necessarily
    % consecutive, not necessarily all-positive nor non-negative.
    %
    % An example of subsequence is the extraction of the 3rd, 4th, and 5th
    % from the input sequence. In this example, the subsequence has 3
    % elements.
    %
    % The Select() method advances the enumeration of selections to 
    % the next one.
    %
    % At any time, the Remove() method can be called to exclude a certain
    % ID. After calling Remove(), the next call to Select() will choose
    % the next valid subsequence from the modified input sequence.
    %
    properties (SetAccess = private)
        Ids(1, :) int32
        Selected(1, :) int32
    end
    properties (GetAccess = private)
        HasStarted(1, 1) logical = false
        HasFinished(1, 1) logical = false
        HasJustRemoved(1, 1) logical = false
    end
    properties
        MinCount(1, 1) int32 = 1
        MaxCount(1, 1) int32 = 1
    end
    methods
        function idsel = IdSelector(ids)
            % Constructs IdSelector given a vector of integer IDs.
            if ~exist('ids', 'var')
                error('missing argument');
            end
            if isa(ids, "IdSelector")
                idsel.Ids = ids.Ids;
                idsel.Selected = ids.Selected;
                return;
            elseif isvector(ids) && isnumeric(ids) && isreal(ids) && isequal(ids, floor(ids))
                idsel.Ids = ids(:)';
            elseif isprop(ids, 'Ids')
                idvec = ids.Ids;
                idsel.Ids = idvec(:)';
            elseif ismethod(ids, 'Ids')
                idvec = ids.Ids();
                idsel.Ids = idvec(:)';
            else
                error('Unable to handle input');
            end
        end
        
        function sel = Select(idsel)
            % Advances to the next valid subsequence.
            sel = [];
            if idsel.HasFinished
                return;
            end
            if idsel.MinCount < 1 || idsel.MaxCount < idsel.MinCount
                error('Invalid MinCount or MaxCount.');
            end
            hasMoved = false;
            if idsel.HasJustRemoved
                idsel.HasJustRemoved = false;
                hasMoved = true;
            end
            if ~idsel.HasStarted
                idsel.HasStarted = true;
                idsel.Selected = idsel.FirstItem();
                hasMoved = true;
            end
            while true
                count = numel(idsel.Selected);
                if hasMoved && count >= idsel.MinCount && count <= idsel.MaxCount
                    break;
                end
                if count > idsel.MaxCount
                    n = idsel.NextItem();
                    idsel.Selected = n;
                    hasMoved = true;
                    if ~isempty(n)
                        continue;
                    else
                        idsel.HasFinished = true;
                        break;
                    end
                else
                    m = idsel.MoreItem();
                    if ~isempty(m)
                        idsel.Selected = union(idsel.Selected, m, 'stable');
                        hasMoved = true;
                        continue;
                    else
                        n = idsel.NextItem();
                        idsel.Selected = n;
                        hasMoved = true;
                        if ~isempty(n)
                            continue;
                        else
                            idsel.HasFinished = true;
                            break;
                        end
                    end
                end
            end
            sel = idsel.Selected;
        end
        
        function Remove(idsel, idToRemove)
            % Removes an ID value from the sequence, and also removes it
            % from the current selection. After removing, the caller may
            % call Select() again to advance to the next valid subsequence.
            idsel.Ids = setdiff(idsel.Ids, idToRemove, 'stable');
            if ismember(idToRemove, idsel.Selected)
                if isscalar(idsel.Selected)
                    idsel.Selected = NextItem();
                else
                    idsel.Selected = setdiff(idsel.Selected, idToRemove, 'stable');
                end
                idsel.HasJustRemoved = true;
            end
        end
        
        function item = FirstItem(idsel)
            % Returns the first element of the input sequence.
            %
            % If there is no such element, the empty vector is returned.
            %
            % This method does not change any state in this object.
            %
            item = [];
            if isempty(idsel.Ids)
                return;
            end
            item = idsel.Ids(1);
        end
        
        function item = MoreItem(idsel)
            % Returns an element that can be used to grow the current
            % subsequence. This element is chosen to be the element whose
            % position on the input sequence is strictly greater than the
            % position of every other element currently on the subsequence.
            %
            % If there is no such element, the empty vector is returned.
            %
            % This method does not change any state in this object.
            %
            item = [];
            if isempty(idsel.Selected)
                return;
            end
            [~, selIdx] = ismember(idsel.Selected, idsel.Ids);
            lastSelIdx = max(selIdx);
            if lastSelIdx == numel(idsel.Ids)
                return;
            end
            item = idsel.Ids(lastSelIdx + 1);
        end
        
        function item = NextItem(idsel)
            % Returns an element that will become the next "head" of the
            % subsequence. The "head" is the element on the subsequence
            % that has the lowest position on the input sequence.
            %
            % For example, if the current subsequence contains an element
            % that is taken from the 7th position from the input sequence,
            % and that the current subsequence doesn't contain anything
            % from the 1st to the 6th position, this method will return
            % the value of the 8th element on the input sequence, if it
            % exists.
            %
            % If there is no such element, the empty vector is returned.
            %
            % This method does not change any state in this object.
            %
            item = [];
            if isempty(idsel.Selected)
                return;
            end
            sel = idsel.Selected;
            [~, selIdx] = ismember(sel, idsel.Ids);
            firstSelIdx = min(selIdx);
            if firstSelIdx == numel(idsel.Ids)
                return;
            end
            item = idsel.Ids(firstSelIdx + 1);
        end        
    end
end
    