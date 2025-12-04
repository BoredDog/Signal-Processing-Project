clear; clc; close all;

%% ---------- PARAMETERS ----------
Fs    = 2000;       
Ts    = 1/Fs;       
N     = 512;        
n     = 0:N-1;      
t_uniform = n * Ts; 
p_list = 0.01:0.01:0.10; 
p_plot = 0.05;           
trials = 30;             

%% ---------- SIGNAL DEFINITIONS ----------
f1 = 60;   sig1 = @(t) sin(2*pi*f1*t); 
f2 = 120;  sig2 = @(t) cos(2*pi*f2*t + pi/6);  
f3 = 300;  sig3 = @(t) 0.8*sin(2*pi*f3*t);     

signals = {sig1, sig2, sig3};
names   = {'Signal1: 60 Hz sine',...
           'Signal2: 120 Hz cosine',...
           'Signal3: 300 Hz sine'};

numS = numel(signals);
numP = numel(p_list);
RMSE_lin = zeros(numS, numP);

%% ---------- MAIN LOOP ----------
for s = 1:numS
    x_func = signals{s};
    x_true = x_func(t_uniform);
    fprintf("\n=== Processing %s ===\n", names{s});
    
    for ip = 1:numP
        p = p_list(ip);
        rmse_trials = zeros(1,trials);
        
        for tr = 1:trials
            rng(s * 1000 + ip * 100 + tr); 
            avail = rand(1,N) > p;         
            if all(~avail), avail(randi(N)) = true; end 
            
            t_avail = t_uniform(avail); 
            x_avail = x_true(avail);    
            
            % --- LINEAR INTERPOLATION ---
            x_est = zeros(1, N); 
            
            if numel(t_avail) <= 1 
                x_est = x_avail(1) * ones(1,N); 
            else
                t_known = t_avail;
                x_known = x_avail;
                
                for i = 1:N
                    t_interp = t_uniform(i);
                    j = find(t_known <= t_interp, 1, 'last');
                    
                    if isempty(j) || j == numel(t_known)
                        if t_interp < t_known(1)
                            x_est(i) = x_known(1);
                        else
                            x_est(i) = x_known(end);
                        end
                    else
                        t0 = t_known(j);  x0 = x_known(j);
                        t1 = t_known(j+1); x1 = x_known(j+1);
                        if t1 == t0 
                            x_est(i) = x0;
                        else
                            x_est(i) = x0 + (t_interp - t0) * (x1 - x0) / (t1 - t0);
                        end
                    end
                end
            end
            
            rmse_trials(tr) = sqrt(mean((x_est - x_true).^2));
        end
        
        RMSE_lin(s, ip) = mean(rmse_trials); 
        fprintf("p = %.2f  RMSE = %.6e\n", p, RMSE_lin(s,ip));
        
        %% ---------- 4-SUBPLOT FIGURE FOR SELECTED p ----------
        if abs(p - p_plot) < 1e-6
            fig = figure;
            
            subplot(4,1,1);
            plot(t_uniform, x_true, 'k', 'LineWidth', 1.4);
            grid on;
            title(sprintf('%s — Ideal Signal', names{s}), 'Interpreter','none');
            
            subplot(4,1,2);
            plot(t_uniform, x_true, 'k'); hold on;
            stem(t_uniform(avail), x_true(avail), 'r', 'filled', 'MarkerSize',3);
            grid on;
            title(sprintf('Ideal + Missing Samples (p = %.2f)', p));
            
            subplot(4,1,3);
            plot(t_uniform, x_true, 'k'); hold on;
            plot(t_uniform, x_est, 'b--','LineWidth',1.2);
            stem(t_uniform, x_est, 'b', 'filled', 'MarkerSize',2);
            grid on;
            title('Manual Linear Reconstruction of Missing Samples');
            
            subplot(4,1,4);
            plot(t_uniform, x_true, 'k'); hold on;
            stem(t_uniform, x_true, 'g', 'filled', 'MarkerSize',2);
            plot(t_uniform, x_est, 'b.', 'MarkerSize',8);
            grid on;
            title('Ideal @ uniform grid + reconstructed');
            
            sgtitle(sprintf('%s — Scenario (b) Manual Linear Interp (p = %.2f)', ...
                    names{s}, p_plot), 'FontWeight','bold');
        end
    end
end

%% ---------- RMSE SUMMARY PLOT ----------
figure;
plot(p_list, RMSE_lin(1,:), '-o','LineWidth',1.6); hold on;
plot(p_list, RMSE_lin(2,:), '-s','LineWidth',1.6);
plot(p_list, RMSE_lin(3,:), '-^','LineWidth',1.6);
grid on;
xlabel('Missing probability p');
ylabel('RMSE (Average of 20 trials)');
title('Scenario (b): RMSE vs p (Manual Linear Interpolation)');
legend(names, 'Location','northwest', 'Interpreter','none');
