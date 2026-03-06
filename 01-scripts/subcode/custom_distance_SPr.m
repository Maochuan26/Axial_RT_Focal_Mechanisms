% % Custom distance function

% function dist = custom_distance_SPr(u, v)
%     % Ensure u is a row vector
%     u = u(:)';
% 
%     % Preallocate the distance vector
%     num_rows = size(v, 1);
%     dist = zeros(num_rows, 1);
% 
%     % Pre-calculate the valid indices for u
%     u_non_zero_indices = u ~= 0;
% 
%     % Check if a parallel pool is already open
%     pool = gcp('nocreate');
%     if isempty(pool)
%         % Optionally, open a parallel pool
%         parpool(5); % Uncomment this line to open a parallel pool
%     end
% 
%     % Use parfor for parallel execution
%     parfor i = 1:num_rows
%         % Current row of v
%         current_v = v(i, :);
% 
%         % Logical indices where both u and current_v are non-zero
%         valid_indices = u_non_zero_indices & (current_v ~= 0);
% 
%         % Filtered vectors
%         u_filtered = u(valid_indices);
%         v_filtered = current_v(valid_indices);
% 
%         if ~isempty(valid_indices)
%             % Compute the Euclidean distance for the filtered vectors
%             diff = u_filtered - v_filtered;
%             dist(i) = sqrt(sum(diff .^ 2)) / numel(valid_indices);
%         end
%     end
% end

function dist = custom_distance_SPr(u, v)
    % Ensure u is a row vector
    u = u(:)';

    % Preallocate the distance vector
    num_rows = size(v, 1);
    dist = zeros(num_rows, 1);

    for i = 1:num_rows
        % Extract the current row of v
        current_v = v(i, :);

        % Create an array of logical values where both u and current_v are non-zero
        valid_indices = (u ~= 0) & (current_v ~= 0);

        % Filter the vectors using the valid indices
        u_filtered = u(valid_indices);
        v_filtered = current_v(valid_indices);

        if isempty(u_filtered) || isempty(v_filtered)
            dist(i) = 0; % or some other value if you want to handle this case differently
        else
            % Compute the Euclidean distance using the filtered vectors
            dist(i) = sqrt(sum((u_filtered - v_filtered).^2)) / length(valid_indices);
        end
    end
end

% function dist = custom_distance_SPr(u, v)
%     % Ensure the inputs are row vectors
%     u = u(:)';
%     v = v(:)';
% 
%     % Create an array of logical values where both u and v are non-zero
%     valid_indices = (u ~= 0) & (v ~= 0);
% 
%     % Filter the vectors using the valid indices
%     u_filtered = u(valid_indices);
%     v_filtered = v(valid_indices);
% 
%     %clear u v;
%     if isempty(u_filtered) || isempty(v_filtered)
%         dist = 0; % or some other value if you want to handle this case differently
%     else
%         % Compute the Euclidean distance using the filtered vectors
%         dist = sqrt(sum((u_filtered - v_filtered).^2))/length(valid_indices);
%     end
% 
% end

