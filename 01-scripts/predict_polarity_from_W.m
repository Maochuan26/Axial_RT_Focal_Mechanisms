function Felix = predict_polarity_from_W(Felix, model_path, out_mat)
% Predict first-motion polarity using a Python Keras model from Felix(i).W_*
% Saves per-station results into:
%   Felix(i).Po_<STA> = [Pred, Confidence, Entropy]   (1x3 single)
%
% Requirements:
% - MATLAB configured to use a Python environment that has tensorflow installed
% - model_path points to your .keras model file

% ----------------------------
% 0) Python environment sanity
% ----------------------------
% If needed (run once): pyenv("Version","/path/to/python");
% pyenv;  % uncomment to display

% ----------------------------
% 1) Import Python modules once
% ----------------------------
tf    = py.importlib.import_module('tensorflow');
%keras = py.importlib.import_module('tensorflow.keras');
keras = py.importlib.import_module('keras');
np    = py.importlib.import_module('numpy');

% Optional: eager mode like your script
try
    tf.config.run_functions_eagerly(true);
catch
end

% ----------------------------
% 2) Load model once
% ----------------------------
model = keras.models.load_model(model_path);
fprintf('✅ Loaded model: %s\n', model_path);

stations = {'AS1','AS2','CC1','EC1','EC2','EC3','ID1'};

% Helper: MATLAB -> numpy float32 2D array
to_np_float32_2d = @(X) np.array(X, pyargs('dtype', np.float32));

% Helper: normalization same as your Python norm() :contentReference[oaicite:2]{index=2}
% X is (nSta x 64)
norm_mat = @(X) X ./ max(max(abs(X),[],2), 1);   % avoid divide by 0

% ----------------------------
% 3) Loop events
% ----------------------------
nEvt = numel(Felix);
for i = 1:nEvt

    % Collect available station waveforms (64)
    waveforms = [];
    usedSta   = {};

    for s = 1:numel(stations)
        sta = stations{s};
        wkey = ['W_' sta];

        if ~isfield(Felix(i), wkey), continue; end
        w = Felix(i).(wkey);

        if isempty(w), continue; end
        w = double(w(:));
        if numel(w) ~= 64, continue; end
        if any(~isfinite(w)), continue; end

        waveforms(end+1,:) = w.'; %#ok<AGROW>  (nSta x 64)
        usedSta{end+1} = sta;     %#ok<AGROW>
    end

    if isempty(waveforms)
        continue;
    end

    % ----------------------------
    % 4) Normalize + predict
    % ----------------------------
    Xn = norm_mat(waveforms);                 % (nSta x 64), MATLAB double
    Xn = single(Xn);                          % float32

    %Xnp = to_np_float32_2d(Xn);
    % ✅ Fix — reshape to (nSta, 64, 1) before converting
Xn3d = reshape(Xn, [size(Xn,1), 64, 1]);   % MATLAB: (nSta x 64 x 1)
Xnp  = np.array(Xn3d, pyargs('dtype', np.float32));

    % Predict: your model sometimes returns list/tuple; use the 2nd output if so :contentReference[oaicite:3]{index=3}
    %y_raw = model.predict(Xnp, pyargs('verbose', int32(0)));
    y_raw = model.predict(Xnp, pyargs('verbose', int32(0)));

    % Handle list/tuple outputs (MATLAB sees py.list / py.tuple)
    if isa(y_raw, 'py.list') || isa(y_raw, 'py.tuple')
        y_prob_py = y_raw{2};     % python index 1 -> MATLAB {2}
    else
        y_prob_py = y_raw;
    end

    % Convert probs to MATLAB (nSta x 2)
    y_prob = double(y_prob_py);   % works if it is a numpy array
    % If conversion fails in your MATLAB, use:
    % y_prob = double(np.array(y_prob_py));

    % ----------------------------
    % 5) Polarity, confidence, entropy
    % ----------------------------
    % Class mapping like your script:
    % argmax==0 => -1, argmax==1 => +1 :contentReference[oaicite:4]{index=4}
    [conf, idx] = max(y_prob, [], 2);   % idx in {1,2}
    pred = ones(size(idx));
    pred(idx == 1) = -1;

    % Entropy: -sum(p*log(p+1e-12)) :contentReference[oaicite:5]{index=5}
    ent = -sum(y_prob .* log(y_prob + 1e-12), 2);

    % ----------------------------
    % 6) Write back to Felix
    % ----------------------------
    for j = 1:numel(usedSta)
        sta = usedSta{j};
        pokey = ['Po_' sta];

        % Store: [Pred, Confidence, Entropy]
        Felix(i).(pokey) = single([pred(j), conf(j), ent(j)]);
    end

    if mod(i,1000)==0
        fprintf('Processed %d / %d\n', i, nEvt);
    end
end

% ----------------------------
% 7) Save
% ----------------------------
if nargin >= 3 && ~isempty(out_mat)
    save(out_mat, 'Felix', '-v7.3');
    fprintf('✅ Saved: %s\n', out_mat);
end
end