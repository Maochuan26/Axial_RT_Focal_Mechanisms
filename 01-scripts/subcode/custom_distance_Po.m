% Custom distance function
function dist = custom_distance_Po(u, v)
    % Ensure u is a row vector
    u = u(:)';

    % Preallocate the distance vector
    num_rows = size(v, 1);
    dist = zeros(num_rows, 1);

    for i = 1:num_rows
        % Extract the current row of v
        current_v = v(i, :);

        % Identify indices where both u and current_v are non-zero
        non_zero_indices = (u ~= 0) & (current_v ~= 0);

        % Find indices where u and current_v have different values
        differing_indices = (u ~= current_v) & non_zero_indices;

        % Count the differing non-zero values
        differing_count = sum(differing_indices);

        % Normalize by the number of non-zero elements
        non_zero_count = sum(non_zero_indices);
        
        % Avoid division by zero
        if non_zero_count == 0
            non_zero_count = 1;
        end

        % Calculate the normalized distance for the current row
        dist(i) = differing_count / non_zero_count;
    end
end
% 
% 
% function dist = custom_distance_Po(u, v)
%     % Ensure u is a row vector and v is a matrix with rows as observations
%     u = u(:)';
%     v = v';
% 
%     % Identify indices where both u and v are non-zero
%     % This will create a matrix of logical values
%     non_zero_indices = (u ~= 0) & (v ~= 0);
% 
%     % Find indices where u and v have different values
%     % This will also be a matrix
%     differing_indices = (u ~= v) & non_zero_indices;
% 
%     % Count the differing non-zero values for each row in v
%     differing_counts = sum(differing_indices, 2);
% 
%     % Normalize by the number of non-zero elements in each row
%     non_zero_counts = sum(non_zero_indices, 2);
% 
%     % Avoid division by zero
%     non_zero_counts(non_zero_counts == 0) = 1;
% 
%     % Calculate the normalized distance
%     dist = differing_counts ./ non_zero_counts;
% end
% % 
% 
% 
% function dist = custom_distance_Po(u, v)
%     % Ensure the inputs are row vectors
%     u = u(:)';
%     v = v(:)';
% 
%     % Identify indices where both u and v are non-zero
%     non_zero_indices = (u ~= 0) & (v ~= 0);
% 
%     % From these indices, only consider indices where u and v have different values
%     differing_indices = (u ~= v) & non_zero_indices;
% 
%     % The distance is the count of differing non-zero values
%     dist = sum(differing_indices)/length(non_zero_indices);
% end

