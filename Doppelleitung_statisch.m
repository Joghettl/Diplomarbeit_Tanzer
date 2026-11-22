%% 
clear; clc; close all;

% Netz und Leitungsparameter

params.Sn = 1000;                   % Bezugsleistung in MVA
params.Un = 380;                    % Nennspannung in kV
params.f  = 50;                     % Netzfrequenz in Hz
params.Sk = 13000;                  % Kurzschlussleistung Netz 1 in MVA
params.Tg = 32*10^(-3);             % Netzzeitkonstante in s
params.Sk2 = 5000;                  % Kurzschlussleistung Netz 2 in MVA
params.XR2 = 10;                    % X/R Verhältnis Netz 2


params.P_gen = 0.4; % 400 MW Einspeisung
params.Q_gen = 0.1; % 100 Mvar Einspeisung an SS1 und SS2


% Leitungsspezifische Parameter 
params.L_total  = 200;              % Gesamtlänge in km
params.L_mesh = 2000000000;
params.R_per_km = 1.214 / 58;       % Widerstand pro km (Ohm/km)
params.X_per_km = 17.66 / 58;       % Reaktanz pro km (Ohm/km)
params.C_per_km = 13 * 10^-9;       % Kapazität pro km (F/km)
% Numerische Parameter
params.epsilon  = 1e-9;
params.max_iter = 20;

n_segments = 10; 
n_ss = n_segments + 2; 
n_total = n_ss + 1;

% Testszenarien
p_base_steps = (-0.0 : -0.1 : -5)'; % P von 0.0 bis -3.0 
%p_base_steps = [p_base_steps; -0.528849932];
tan_phi_steps = [ -0.48,-0.33,-0.12, 0 ,0.12,0.33, 0.48]; 
%tan_phi_steps = [-0.48,-0.33,-0.12, 0 ,0.12]; 
% Initialisierung
P_all = [];
Q_all = [];
TanPhi_all = []; 
% Schleife zum Aufbau des Musters
for tp_val = tan_phi_steps
    p_block = p_base_steps;
    q_block = p_block * tp_val;
    
    P_all = [P_all; p_block];
    Q_all = [Q_all; q_block];
    TanPhi_all = [TanPhi_all; repmat(tp_val, size(p_block, 1), 1)];
end

disp('--- Generierte Szenarien (P, Q, tan(phi)) ---');
disp([P_all, Q_all, TanPhi_all]);

% Anzeige - Bool  
show_plots_diskret = false; 
show_plots_stability = true;
show_plots_stability_line = true;
show_3d_plot = true;
target_P_val        = -0.0;   
show_only_converged = true;  

% Listen initialisieren
Ergebnis_Spannungsverlauf = table();
U_profiles_n2 = []; d_profiles_n2 = [];
U_profiles_n1 = []; d_profiles_n1 = [];
fprintf('Starte Berechnungen für %d Lastfälle...\n', length(P_all));


%% Berechnungschleife


for i = 1:length(P_all)
    P_soll = P_all(i);
    Q_soll = Q_all(i);
    tp_soll = TanPhi_all(i); 
    
    % Diskretisiert (10 Segmente)
    [T_d2, U2, D2, x_axis, U_init2, d_init2] = berechne_leistungsfluss_diskret(P_soll, Q_soll, 2, params);
    [T_d1, U1, D1, ~]      = berechne_leistungsfluss_diskret(P_soll, Q_soll, 1, params);
    
    T_d2.tan_phi = tp_soll; 
    T_d1.tan_phi = tp_soll; 
    
    U_profiles_n2(:, i) = U2; d_profiles_n2(:, i) = D2;
    U_profiles_n1(:, i) = U1; d_profiles_n1(:, i) = D1;
    Ergebnis_Spannungsverlauf = [Ergebnis_Spannungsverlauf; T_d2; T_d1];
end
fprintf('\n--- ERGEBNISSE MODELL (DISKRETISIERT) ---\n'); disp(Ergebnis_Spannungsverlauf);


% VISUALISIERUNG
% Hier kam KI zum Einsatz

if show_plots_diskret
    fig = figure('Name', 'Netzanalyse: Flexible Profile', 'Color', 'w', 'Units', 'normalized', 'Position', [0.1 0.05 0.5 0.9]);
    plot_configs = {U_profiles_n2, 2, 1, 1; d_profiles_n2, 2, 2, 2; U_profiles_n1, 1, 1, 3; d_profiles_n1, 1, 2, 4};
    farben = lines(length(P_all));
    for p = 1:4
        data = plot_configs{p, 1}; n_val = plot_configs{p, 2}; is_v = (plot_configs{p, 3} == 1);
        subplot(4, 1, plot_configs{p, 4}); hold on;
        ax = gca; ax.Color = 'w'; ax.XColor = 'k'; ax.YColor = 'k'; grid on; ax.GridColor = 'k'; ax.GridAlpha = 0.2;
        plot_handles = []; legende_txt = {};
        current_min = inf; current_max = -inf;
        for i = 1:length(P_all)
            idx = (i-1)*2 + (3-n_val); row = Ergebnis_Spannungsverlauf(idx, :);
            if show_only_converged && row.Iter >= params.max_iter, continue; end
            if abs(row.P_soll - target_P_val) > 0.001, continue; end
            h = plot(x_axis, data(:, i), '-o', 'Color', farben(i,:), 'LineWidth', 1.2, 'MarkerSize', 3, 'MarkerFaceColor', 'w');
            plot_handles(end+1) = h;
            legende_txt{end+1} = sprintf('P=%.2f, Q=%.2f (%d It.)', row.P_soll, row.Q_soll, row.Iter);
            current_min = min([current_min; data(:, i)]); current_max = max([current_max; data(:, i)]);
        end
        if ~isinf(current_min)
            range = current_max - current_min; if range == 0, range = 0.1; end 
            ylim([current_min - 0.1*range, max(1.02, current_max + 0.1*range)]);
        end
        if is_v, yline(1.0, '--k', 'Color', 'k'); ylabel('U / pu', 'Color', 'k'); title(['Spannung (n = ', num2str(n_val), ')'], 'Color', 'k');
        else, ylabel('\delta [°]','Color', 'k'); title(['Leitungswinkel (n = ', num2str(n_val), ')'], 'Color', 'k'); end
        if p == 4, xlabel('Länge [km]', 'Color', 'k'); end
        if ~isempty(plot_handles) && (p == 2 || p == 4)
            lgd = legend(plot_handles, legende_txt, 'Location', 'southoutside', 'Orientation', 'horizontal', 'FontSize', 7, 'Color', 'w', 'EdgeColor', 'k', 'TextColor', 'k');
            lgd.NumColumns = 4;
        end
        hold off;
    end
end

% STABILITÄTSANALYSE 

% Hier kam KI zum Einsatz

if show_plots_stability
    for n_val = [1, 2] 
        fig_name = sprintf('Stabilitätsanalyse Netzzustand n = %d', n_val);
        figure('Name', fig_name, 'Color', 'w', 'Units', 'normalized', 'Position', [0.1 0.1 0.5 0.7]);
        subplot(1, 1, 1); hold on;
        ax1 = gca; ax1.Color = 'w'; ax1.XColor = 'k'; ax1.YColor = 'k'; grid on; ax1.GridColor = 'k'; ax1.GridAlpha = 0.2;
        tps = unique(TanPhi_all, 'stable');
        farben_q = lines(length(tps));
        for k = 1:length(tps)
            sub = Ergebnis_Spannungsverlauf(Ergebnis_Spannungsverlauf.LTG == n_val & Ergebnis_Spannungsverlauf.tan_phi == tps(k), :);
            if show_only_converged, sub = sub(sub.Iter < params.max_iter, :); end
            [~, sortIdx] = sort(sub.P_soll, 'descend');
            if ~isempty(sub)
                plot(sub.P_soll(sortIdx)*(-1), sub.U_End(sortIdx), '-o', 'Color', farben_q(k,:), 'LineWidth', 1.5, 'MarkerFaceColor', 'w', 'MarkerSize', 5);
            end
        end
        title(['PU-Kurven (n = ', num2str(n_val), ')'], 'Color', 'k', 'FontSize', 12);
        ylabel('Spannung U_{2} / pu', 'Color', 'k'); 
        xlabel('Wirkleistung P_{2} / pu', 'Color', 'k');
        lgd = legend(arrayfun(@(x) sprintf('tan\\phi = %+.2f', x), tps, 'UniformOutput', false), ...
               'Location', 'southoutside', 'TextColor', 'k', 'EdgeColor', 'k', 'FontSize', 8, 'Color', 'w');
        lgd.NumColumns = 4;
    end
end

% KOMBINIERTE n-0 vs n-1 STABILITÄTSANALYSE (PU & VQ)
% Hier kam KI zum Einsatz

if show_plots_stability_line
    fig_comb = figure('Name', 'Stabilitätsanalyse: Vergleich N-0 vs. N-1', 'Color', 'w', 'Units', 'normalized', 'Position', [0.1 0.1 0.5 0.7]);
    
    subplot(1, 1, 1); hold on;
    ax1 = gca; ax1.Color = 'w'; ax1.XColor = 'k'; ax1.YColor = 'k'; grid on; ax1.GridColor = 'k'; ax1.GridAlpha = 0.2;
    
    plot_handles_pv = []; legende_txt_pv = {};
    yline(0.9, '--k', '0.90 pu (Min)', 'LabelHorizontalAlignment', 'right', 'FontSize', 8);
    yline(1.105, '--b', '1.105 pu (420 kV)', 'LabelHorizontalAlignment', 'right', 'FontSize', 8);
    yline(1.16, '--r', '1.16 pu (Max)', 'LabelHorizontalAlignment', 'right', 'FontSize', 8);
    
    tps = unique(TanPhi_all, 'stable');
    farben_q = lines(length(tps));
    
    for k = 1:length(tps)
        sub0 = Ergebnis_Spannungsverlauf(Ergebnis_Spannungsverlauf.LTG == 2 & Ergebnis_Spannungsverlauf.tan_phi == tps(k), :);
        sub1 = Ergebnis_Spannungsverlauf(Ergebnis_Spannungsverlauf.LTG == 1 & Ergebnis_Spannungsverlauf.tan_phi == tps(k), :);
        
        if show_only_converged
            sub0 = sub0(sub0.Iter < params.max_iter, :);
            sub1 = sub1(sub1.Iter < params.max_iter, :);
        end
        
        if ~isempty(sub0)
            [~, sortIdx] = sort(sub0.P_soll, 'descend');
            h0 = plot(sub0.P_recv_line(sortIdx), sub0.U_End(sortIdx), '-s', 'Color', farben_q(k,:), 'LineWidth', 1.8, 'MarkerFaceColor', 'w', 'MarkerSize', 4);
            plot_handles_pv(end+1) = h0;
            legende_txt_pv{end+1} = sprintf('tan\\phi=%+.2f (n-0)', tps(k));
        end
        
        if ~isempty(sub1)
            [~, sortIdx] = sort(sub1.P_soll, 'descend');
            h1 = plot(sub1.P_recv_line(sortIdx), sub1.U_End(sortIdx), '--x', 'Color', farben_q(k,:), 'LineWidth', 1.5, 'MarkerSize', 5);
            plot_handles_pv(end+1) = h1;
            legende_txt_pv{end+1} = sprintf('tan\\phi=%+.2f (n-1)', tps(k));
        end
    end
    
    title('PU-Kurven Vergleich: N-0 vs. N-1', 'Color', 'k', 'FontSize', 12);
    ylabel('Spannung U_{2} / pu', 'Color', 'k'); 
    xlabel('Empfangene Wirkleistung P_{recv}/Leitung an SS2 / pu', 'Color', 'k');
    lgd1 = legend(plot_handles_pv, legende_txt_pv, 'Location', 'southoutside', 'Orientation', 'horizontal', 'FontSize', 8, 'Color', 'w', 'EdgeColor', 'k', 'TextColor', 'k');
    lgd1.NumColumns = 4;
end

% 3D-VISUALISIERUNG (UPQ-Fläche) 
% Hier kam KI zum Einsatz

if show_3d_plot
    n_plot = 1; 
    sub3d = Ergebnis_Spannungsverlauf(Ergebnis_Spannungsverlauf.LTG == n_plot, :);
    if show_only_converged
        sub3d = sub3d(sub3d.Iter < params.max_iter, :);
    end
    
    if ~isempty(sub3d)
        figure('Name', ['UPQ-Stabilitätsfläche n=', num2str(n_plot)], 'Color', 'w');
        x_raw = -sub3d.P_soll; 
        y_raw = -sub3d.Q_soll; 
        z_raw = sub3d.U_End;
        p_lin = linspace(min(x_raw), max(x_raw), 50); 
        q_lin = linspace(min(y_raw), max(y_raw), 50);
        [P_mesh, Q_mesh] = meshgrid(p_lin, q_lin);
        U_mesh = griddata(x_raw, y_raw, z_raw, P_mesh, Q_mesh);
        
        surf(P_mesh, Q_mesh, U_mesh, 'FaceAlpha', 0.85, 'EdgeColor', 'interp');
        colormap(turbo); shading interp; %lighting gouraud; camlight; 
        hold on;
        
        contour3(P_mesh, Q_mesh, U_mesh, [0.90, 1.0, 1.105], 'Color', 'r', 'LineWidth', 2.5);
        contour3(P_mesh, Q_mesh, U_mesh, [1.0, 1.0], 'Color', 'g', 'LineWidth', 2.5);
        plot3(x_raw, y_raw, z_raw, 'k.', 'MarkerSize', 6);
        
        zlim([0.5 1.2]); 
        ax = gca; ax.Color = 'w'; ax.XColor = 'k'; ax.YColor = 'k'; ax.ZColor = 'k';
        ax.GridColor = 'k'; ax.GridAlpha = 0.2; grid on;
        
        title(['UPQ-Diagramm: Spannungsstabilität (n = ', num2str(n_plot), ')'], 'Color', 'k', 'FontSize', 12);
        xlabel('Wirkleistung P_{2} / pu', 'Color', 'k');
        ylabel('Blindleistung Q_{2} / pu', 'Color', 'k');
        zlabel('Spannung U_{2} / pu', 'Color', 'k');
        
        cb = colorbar; cb.Color = 'k'; cb.Label.String = 'Spannung U_{2} / pu'; cb.Label.Color = 'k'; 
        view(45, 25); 
    else
        warning('Keine konvergierten Daten für den 3D-Plot gefunden.');
    end
end


% UP:  Diskretisiertes Modell 
function [T_res, U_out, d_out, x, U, delta] = berechne_leistungsfluss_diskret(P_load, Q_load, n_active, p)
    Z_bez = (p.Un^2)/p.Sn; 
    n_segments = 10;  % Aufteilung der Leitung in 10 Segmente 
    n_ss = n_segments + 2;  % +2 für Externe Netze
    n_total = n_ss + 1;
    
    km_per_seg = p.L_total / n_segments;  % Länge der Segemente 
    x = [0, 0:km_per_seg:p.L_total];
    
    % Netz 1 (Startpunkt)
    z_grid_abs = 1.1*(p.Un)^2/p.Sk;
    X_grid = 1*2*pi*p.f*(z_grid_abs/((1/p.Tg)^2+(2*pi*p.f)^2)^(1/2));
    R_grid = (z_grid_abs^2-X_grid^2)^(1/2);
    z_grid = (R_grid+1j*X_grid)/Z_bez;
    y_grid = 1 / z_grid;
    
    % Netz 2 (Endpunkt an der Last)
    theta_k2 = atan(p.XR2);
    z_grid2_abs = (1.1 * p.Un^2 / p.Sk2) / Z_bez;
    z_grid2 = z_grid2_abs * exp(1j * theta_k2);
    y_grid2 = 1 / z_grid2;
    
    % Leitung
    R_L = (p.R_per_km * p.L_total) / n_active; 
    X_L = (p.X_per_km * p.L_total) / n_active; 
    C_L = (p.C_per_km * p.L_total) * n_active;
    z_seg = ((R_L + 1j*X_L) / n_segments) / Z_bez; 
    y_seg_s = 1 / z_seg; 
    y_seg_q = (2 * pi * p.f * C_L / n_segments) * Z_bez;

    z_line_mesh = (p.R_per_km + 1j*p.X_per_km)*p.L_mesh /Z_bez;
    y_s_mesh = 1/z_line_mesh;
    y_q_mesh = (2 * pi * p.f * p.C_per_km *p.L_mesh) *Z_bez;

    if p.L_mesh > 200
        y_q_mesh = 0;
    end
    
    % Admittanzmatrix aufbauen
    Y_bus = zeros(n_total, n_total);
    Y_bus(1,1) = y_grid; 
    Y_bus(2,2) = y_grid; 
    Y_bus(1,2) = -y_grid; 
    Y_bus(2,1) = -y_grid;
    for i = 2:n_ss-1
        Y_bus(i,i) = Y_bus(i,i) + y_seg_s + 1j*y_seg_q/2; 
        Y_bus(i+1,i+1) = Y_bus(i+1,i+1) + y_seg_s + 1j*y_seg_q/2;
        Y_bus(i,i+1) = -y_seg_s; 
        Y_bus(i+1,i) = -y_seg_s;
    end
    % Meshing
    Y_bus(2,2) = Y_bus(2,2)+ y_s_mesh + 1j*y_q_mesh/2;
    Y_bus(n_ss, n_ss) = Y_bus(n_ss, n_ss) + y_s_mesh + 1j*y_q_mesh/2;
    Y_bus(2,n_ss) = -y_s_mesh;
    Y_bus(n_ss,2) = -y_s_mesh;

    % Anbindung von Netz 2 an die Sammelschiene der Last (n_ss)
    Y_bus(n_ss, n_ss) = Y_bus(n_ss, n_ss) + y_grid2;
    Y_bus(n_total, n_total) = y_grid2;
    Y_bus(n_ss, n_total) = -y_grid2;
    Y_bus(n_total, n_ss) = -y_grid2;
    
    Y_mag = abs(Y_bus); 
    theta = angle(Y_bus);

    U = ones(n_total, 1); 
    delta = zeros(n_total, 1); 

    idx_P = 2:n_total; 
    idx_Q = 2:n_ss;    
    n_ang = length(idx_P);
    n_vol = length(idx_Q);
    
    for iter = 1:p.max_iter
        P_c = zeros(n_total, 1); 
        Q_c = zeros(n_total, 1);
        for i = 1:n_total
            for j = 1:n_total
                P_c(i) = P_c(i) + U(i)*U(j)*Y_mag(i,j)*cos(theta(i,j) + delta(j) - delta(i)); %Leistungsgleichungen
                Q_c(i) = Q_c(i) - U(i)*U(j)*Y_mag(i,j)*sin(theta(i,j) + delta(j) - delta(i)); % Blindleistungsgleichung
            end
        end
        
        dP = zeros(n_ang, 1); dQ = zeros(n_vol, 1);
        for ir = 1:n_ang
            i = idx_P(ir);
            if i == 2
                dP(ir) = p.P_gen - P_c(i);                 % Einspeisung Generator 1 an SS1
            elseif i == n_ss
                dP(ir) = P_load + p.P_gen - P_c(i);        % Einspeisung Gen 2Lastknoten an SS2
            elseif i == n_total
                dP(ir) = 0 - P_c(i);             % Generator am PU-Knoten (SS2)
            else
                dP(ir) = 0 - P_c(i);             % Zwischenknoten - Auf Leitung nur PQ Knoten
            end
        end
        for ir = 1:n_vol
            i = idx_Q(ir);

            if i == 2, dQ(ir) = p.Q_gen - Q_c(i);
            elseif i == n_ss,      dQ(ir) = Q_load+ p.Q_gen - Q_c(i);
            else,              dQ(ir) = 0 - Q_c(i);
            end
        end
        
        mis = [dP; dQ]; 
        if norm(mis) < p.epsilon, break; end
        
        J11 = zeros(n_ang, n_ang); J12 = zeros(n_ang, n_vol);
        J21 = zeros(n_vol, n_ang); J22 = zeros(n_vol, n_vol);
        % Jacobimatrix berechnen
        % Leistungsgleichungen nach Spannungswinkel berechnen
        for r1 = 1:n_ang
            i = idx_P(r1);
            for r2 = 1:n_ang
                j = idx_P(r2);
                if i == j, J11(r1,r2) = -Q_c(i) - (U(i)^2)* imag(Y_bus(i,i)); %Ableitung nach Spannungswinkel, Hauptdiagonal Element
                else,      J11(r1,r2) = U(i)*U(j)* (real(Y_bus(i,j))*sin(delta(i)-delta(j)) - imag(Y_bus(i,j))*cos(delta(i)-delta(j))); end %Ableitung nach Spannungswinkel, Nebendiagonal Element
            end
            % Leistungsgleichungen Ableitungen der Spannung
            for r2 = 1:n_vol
                j = idx_Q(r2);
                if i == j, J12(r1,r2) = (P_c(i)/U(i)) + U(i)*real(Y_bus(i,i));
                else,      J12(r1,r2) = U(i)*(real(Y_bus(i,j))*cos(delta(i)-delta(j)) + imag(Y_bus(i,j))*sin(delta(i)-delta(j))); end
            end
        end
        % Blindleistungsgleichungen Ableitungen dem Spannungswinkel
        for r1 = 1:n_vol
            i = idx_Q(r1);
            for r2 = 1:n_ang
                j = idx_P(r2);
                if i == j, J21(r1,r2) = P_c(i) - (U(i)^2)*real(Y_bus(i,i)); 
                else,      J21(r1,r2) = U(i)*U(j)*(-real(Y_bus(i,j))*cos(delta(i)-delta(j)) - imag(Y_bus(i,j))*sin(delta(i)-delta(j))); end
            end
            % Blindleistungsgleichungen Ableitungen dem Spannungswinkel
            for r2 = 1:n_vol
                j = idx_Q(r2);
                if i == j, J22(r1,r2) = (Q_c(i)/U(i))- U(i)*imag(Y_bus(i,i)); %Hauptdiagonalelemnt
                else,      J22(r1,r2) = U(i)*(real(Y_bus(i,j))*sin(delta(i)-delta(j)) - imag(Y_bus(i,j))*cos(delta(i)-delta(j))); end % Nebendiagonal
            end
        end
        
        dx = [J11 J12; J21 J22] \ mis; 
        delta(idx_P) = delta(idx_P) + dx(1:n_ang); 
        U(idx_Q) = U(idx_Q) + dx(n_ang+1:end);
    end
    
    delta_deg = delta * 180/pi;

   
    % Komplexe Spannung an allen Knoten
    U_c = U .* exp(1j * delta); 

    % Strom vom vorletzten Knoten (n_ss-1) zum Empfangsknoten (n_ss) über die Hauptleitung
    I_recv = (U_c(n_ss-1) - U_c(n_ss)) * y_seg_s - U_c(n_ss) * (1j * y_seg_q / 2);
    % Scheinleistung, die über die Hauptleitung am Empfangsknoten ankommt
    S_recv = U_c(n_ss) * conj(I_recv); 
    % Wirkleistung pro aktivem Einzelsystem (Doppelleitung = /2, Einzelleitung = /1)
    P_recv_per_line = real(S_recv) / n_active; 
    % --------------------------------------------------------------------
    
    T_res = table(n_active, P_load, Q_load, U(n_ss), delta_deg(n_ss), iter, P_recv_per_line, ...
                  'VariableNames', {'LTG', 'P_soll', 'Q_soll', 'U_End', 'd_End', 'Iter', 'P_recv_line'});
    
                  
    for k = 1:n_ss 
        T_res.(['U' num2str(k)]) = U(k); T_res.(['d' num2str(k)]) = delta_deg(k);
    end
    
    U_out = U(1:n_ss);
    d_out = delta_deg(1:n_ss);

end


Export_Tabelle = Ergebnis_Spannungsverlauf(:, {'LTG', 'P_soll', 'Q_soll', 'U2','d2', 'U_End', 'd_End', 'tan_phi'});

fprintf('\n--- ERGEBNISSE MODELL (REDUZIERT FÜR EXPORT) ---\n'); 
disp(Export_Tabelle);


% EXCEL-EXPORT

dateiname = 'Ergebnis_Spannungsverlauf.xlsx';
% Reduzierte Tabelle als Excel-Datei speichern
writetable(Export_Tabelle, dateiname);
fprintf('\nDie Tabelle wurde erfolgreich als "%s" gespeichert.\n', dateiname);