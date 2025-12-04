clear; clc; close all;

Fs    = 240;        
Ts    = 1/Fs;       
Delta = Ts/10;      
N     = 512;        
n     = 0:N-1;      
t_uniform = n * Ts; 
K_list = 1:4;       

% --- Define signals ---
f_sig1 = 60;   sig1 = @(t) sin(2*pi*f_sig1.*t); 
f_sig2 = 100;  sig2 = @(t) cos(2*pi*f_sig2.*t + pi/4);
f_sig3 = 180;  sig3 = @(t) 0.5 * sin(2*pi*f_sig3.*t);

signals = {sig1, sig2, sig3};
names   = {'Signal 1: Sine 60Hz','Signal 2: Cosine 100Hz','Signal 3: Sine 180Hz (Aliased)'};

% --- RMSE storage ---
RMSE = zeros(numel(signals), numel(K_list));

%% --- MAIN LOOP ---
for s = 1:numel(signals)
    
    x_func = signals{s};    
    x_true = x_func(t_uniform); 
    
    for ik = 1:numel(K_list)
        K = K_list(ik);
        
        rng(100 + s*10 + ik);        
        k_n   = randi([-K, K], 1, N);  
        eps_n = k_n * Delta;         
        t_jit = t_uniform + eps_n;   
        x_hat = x_func(t_jit);       
        
        x_est = zeros(1, N); 
        [t_jit_sorted, idx] = sort(t_jit);
        x_hat_sorted = x_hat(idx);
        
        for i = 1:N
            t_interp = t_uniform(i);
            j = find(t_jit_sorted <= t_interp, 1, 'last');
            
            if isempty(j) || j == N
                if t_interp < t_jit_sorted(1)
                    x_est(i) = x_hat_sorted(1);
                else
                    x_est(i) = x_hat_sorted(N);
                end
            else
                t0 = t_jit_sorted(j);  x0 = x_hat_sorted(j);
                t1 = t_jit_sorted(j+1); x1 = x_hat_sorted(j+1);
                if t1 == t0 
                    x_est(i) = x0;
                else
                    x_est(i) = x0 + (t_interp - t0) * (x1 - x0) / (t1 - t0);
                end
            end
        end
        
        RMSE(s, ik) = sqrt(mean((x_est - x_true).^2)); 
        
        % --- Plotting for K=2 ---
        if K == 2
            figure;
            subplot(4,1,1); plot(t_uniform, x_true, 'k','LineWidth',1.4);
            title(sprintf('%s — Ideal Signal', names{s}), 'Interpreter','none');
            
            subplot(4,1,2); plot(t_uniform, x_true,'k','LineWidth',1.2); hold on;
            stem(t_jit, x_hat,'r','filled','MarkerSize',3);
            title('Ideal Signal + Jittered Samples');
            
            subplot(4,1,3); plot(t_uniform, x_true,'k','LineWidth',1.2); hold on;
            plot(t_uniform, x_est,'b--','LineWidth',1.2);
            stem(t_uniform, x_est,'b','filled','MarkerSize',2);
            title('Reconstructed Signal (Linear Interp)');
            
            subplot(4,1,4); plot(t_uniform, x_true,'k','LineWidth',1.1); hold on;
            stem(t_uniform, x_true,'g','filled','MarkerSize',2);
            plot(t_uniform, x_est,'b.','MarkerSize',8);
            title('Comparison: Ideal vs Reconstructed');
            
            sgtitle(sprintf('%s — Jittered Reconstruction (K=2)', names{s}),'FontWeight','bold');
        end
    end
    
    fprintf('RMSE for %s : ', names{s});
    fprintf('%0.5e ', RMSE(s,:));
    fprintf('\n');
end

%% --- RMSE Summary Plot ---
figure;
plot(K_list, RMSE(1,:), '-o','LineWidth',1.6); hold on;
plot(K_list, RMSE(2,:), '-s','LineWidth',1.6);
plot(K_list, RMSE(3,:), '-^','LineWidth',1.6);
xlabel('K (max |k_n|)'); ylabel('RMSE');
title('RMSE vs K for 3 Sinusoid Signals');
legend(names,'Location','northwest','Interpreter','none'); grid on;