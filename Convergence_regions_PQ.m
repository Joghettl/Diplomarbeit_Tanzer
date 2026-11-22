
clear; clc; close all;

%Parameter & Systemaufbau
Sn = 1000; % MVA
Un = 380;  % kV 
Zn = (Un^2)/Sn; 

Sk_netz1 = 13000; % MVA (Slack)
Sk_netz2 = 5000;  % MVA (PV- Knoten an SS2)

% Netzimpedanzen berechnen
XR_ratio = 10;
theta_k = atan(XR_ratio);
z_k1_abs = (1.1 * Un^2 / Sk_netz1) / Zn; % in pu
z_grid1 = z_k1_abs * exp(1j * theta_k);
y_grid1 = 1 / z_grid1;

z_k2_abs = (1.1 * Un^2 / Sk_netz2) / Zn; % in pu
z_grid2 = z_k2_abs * exp(1j * theta_k);
y_grid2 = 1 / z_grid2;

% Leitungsparameter (zwischen Sammelschiene 1 und 2)
n_active = 2; 
l_line_mesh = 20000000000;
R_L = 1.214/58*200;   
X_L = 17.66/58*200;   
C_L = 13*10^(-9)*200; 
z_line_s = (R_L + 1j*X_L)/Zn;
z_line_mesh = (R_L / 200 * l_line_mesh + 1j*X_L/200*l_line_mesh)/Zn;
y_line_s = n_active / z_line_s;
y_line_s_mesh = 1/z_line_mesh;

y_line_q = n_active * 2*pi*50*C_L/(1/Zn);
y_line_q_mesh = 1 * 2*pi*50*C_L/200*l_line_mesh/(1/Zn);

if l_line_mesh>200
    y_line_q_mesh = 0;
end

% Admittanzmatrix erstellen
Y_bus = zeros(4,4);

% Verbindung Slack - SS1
Y_bus(1,1) = y_grid1; Y_bus(2,2) = y_grid1;
Y_bus(1,2) = -y_grid1; Y_bus(2,1) = -y_grid1;
% Verbindung SS1 - SS2
Y_bus(2,2) = Y_bus(2,2) + y_line_s + 1j*y_line_q/2 + y_line_s_mesh + 1j*y_line_q_mesh/2;
Y_bus(3,3) = y_line_s + 1j*y_line_q/2+ y_line_s_mesh + 1j*y_line_q_mesh/2;
Y_bus(2,3) = -y_line_s - y_line_s_mesh; 
Y_bus(3,2) = -y_line_s - y_line_s_mesh;
% Verbindung SS2 - PU-Knoten
Y_bus(3,3) = Y_bus(3,3) + y_grid2;
Y_bus(4,4) = y_grid2;
Y_bus(3,4) = -y_grid2; Y_bus(4,3) = -y_grid2;

Y_mag = abs(Y_bus);
theta = angle(Y_bus);

% Iterationsparameter
epsilon = 1e-5; 
max_iter = 20;

% ZIP-Parameter für die Last (SS2)
a_p = 0.0; b_p = 0.0; c_p = 1.0; % Wirkleistung
a_q = 0.0; b_q = 0.0; c_q = 1.0; % Blindleistung

% 2. Gitter für Last (P/Q an SS2) definieren
res = 150; 
p2_range = linspace(-4.0, 0.0, res); 
q2_range = linspace(-2.5, 4.0, res); 
[P2_grid, Q2_grid] = meshgrid(p2_range, q2_range);

Conv_Map = zeros(size(P2_grid)); 
Iter_Map = zeros(size(P2_grid)); 
U3_Map   = NaN(size(P2_grid));

% Simulation über das Gitter
idx_P = [2, 3, 4]; % Knoten mit definierter Wirkleistung
idx_Q = [2, 3];    % Knoten mit definierter Blindleistung
n_ang = length(idx_P);
n_vol = length(idx_Q);

fprintf('Simuliere Konvergenzregionen für %d Punkte...\n', numel(P2_grid));
for i = 1:numel(P2_grid)
    % Nennlast aus dem Gitter (P0, Q0)
    P2_soll = P2_grid(i);
    Q2_soll = Q2_grid(i);
    
    % Basiswerte 
    P_soll = [0; 0.4; P2_soll+0.4; 0]; 
    Q_soll = [0; 0.1; Q2_soll + 0.1; 0]; 
    
    % Startwerte (Flat start)
    U = [1.0; 1.0; 1.0; 1.0];
    delta = [0; 0; 0; 0];
    
    converged = false;
    
    for k = 1:max_iter
        
        %Last berechnen
        P_soll(3) = P2_soll * (a_p * U(3)^2 + b_p * U(3) + c_p);
        Q_soll(3) = Q2_soll * (a_q * U(3)^2 + b_q * U(3) + c_q);

        % Leistungsfluss berechnen
        P_c = zeros(4,1); 
        Q_c = zeros(4,1);
        for m = 1:4
            for n = 1:4
                P_c(m) = P_c(m) + U(m)*U(n)*Y_mag(m,n)*cos(theta(m,n) + delta(n) - delta(m));
                Q_c(m) = Q_c(m) - U(m)*U(n)*Y_mag(m,n)*sin(theta(m,n) + delta(n) - delta(m));
            end
        end
           
        dP = P_soll(idx_P) - P_c(idx_P);
        dQ = Q_soll(idx_Q) - Q_c(idx_Q);
        mis = [dP; dQ];
        
        if norm(mis) < epsilon
            converged = true;
            break;
        end
        
        % Jacobi-Matrix
        J11 = zeros(n_ang, n_ang); J12 = zeros(n_ang, n_vol);
        J21 = zeros(n_vol, n_ang); J22 = zeros(n_vol, n_vol);
        
        for r1 = 1:n_ang
            m = idx_P(r1);
            for r2 = 1:n_ang
                n = idx_P(r2);
                if m == n
                    J11(r1,r2) = -Q_c(m) - U(m)^2 * imag(Y_bus(m,m));
                else
                    J11(r1,r2) = U(m)*U(n)*(real(Y_bus(m,n))*sin(delta(m)-delta(n)) - imag(Y_bus(m,n))*cos(delta(m)-delta(n))); 
                end
            end
            for r2 = 1:n_vol
                n = idx_Q(r2);
                if m == n
                    J12(r1,r2) = P_c(m)/U(m) + U(m)*real(Y_bus(m,m));
                    if m == 3 
                        J12(r1,r2) = J12(r1,r2) - P2_soll * (2 * a_p * U(3) + b_p);
                    end
                else
                    J12(r1,r2) = U(m)*(real(Y_bus(m,n))*cos(delta(m)-delta(n)) + imag(Y_bus(m,n))*sin(delta(m)-delta(n))); 
                end
            end
        end
        
        for r1 = 1:n_vol
            m = idx_Q(r1);
            for r2 = 1:n_ang
                n = idx_P(r2);
                if m == n
                    J21(r1,r2) = P_c(m) - U(m)^2 * real(Y_bus(m,m));
                else
                    J21(r1,r2) = U(m)*U(n)*(-real(Y_bus(m,n))*cos(delta(m)-delta(n)) - imag(Y_bus(m,n))*sin(delta(m)-delta(n))); 
                end
            end
            for r2 = 1:n_vol
                n = idx_Q(r2);
                if m == n
                    J22(r1,r2) = Q_c(m)/U(m) - U(m)*imag(Y_bus(m,m));
                    if m == 3 
                        J22(r1,r2) = J22(r1,r2) - Q2_soll * (2 * a_q * U(3) + b_q);
                    end
                else
                    J22(r1,r2) = U(m)*(real(Y_bus(m,n))*sin(delta(m)-delta(n)) - imag(Y_bus(m,n))*cos(delta(m)-delta(n))); 
                end
            end
        end
        
        % Update Schritt
        dx = [J11 J12; J21 J22] \ mis;
        delta(idx_P) = delta(idx_P) + dx(1:n_ang);
        U(idx_Q)     = U(idx_Q)     + dx(n_ang+1:end);
        
        if any(U > 2.0) || any(U < 0.1), break; end % Divergenz-Check
    end
    
    if converged
        if U(3) > 0.6
            Conv_Map(i) = 1; %stabil
        else
            Conv_Map(i) = 2; % instabil
        end
        Iter_Map(i) = k; % Divergenz
        U3_Map(i) = U(3);
    else
        Conv_Map(i) = 0; 
        U3_Map(i) = NaN; 
    end
end

% Hier kam KI zum Einsatz
subplot(1,2,1);

% imagesc zeichnet die Heatmap, NaN-Werte werden transparent
im = imagesc(-p2_range, -q2_range, U3_Map);
set(im, 'AlphaData', ~isnan(U3_Map)); 
set(gca, 'YDir', 'normal', 'XColor', 'k', 'YColor', 'k', 'Color', [1 1 1]); 

colormap(gca, parula); 
hold on;
contour(-P2_grid, -Q2_grid, U3_Map, [0.90 1.105], 'Color', 'r' , 'LineWidth', 2.5); 
hold off;


cb2 = colorbar;
cb2.Color = 'k';
title(cb2, 'U_2 [pu]');
xlabel('Wirkleistung P_2 / pu', 'Color', 'k'); 
ylabel('Blindleistung Q_2 / pu', 'Color', 'k');
title('Spannung an SS2 (U_2)', 'Color', 'k');
% --- Plot 2: Iterationen ---
subplot(1,2,2);
imagesc(-p2_range, -q2_range, Iter_Map);
set(gca, 'YDir', 'normal', 'XColor', 'k', 'YColor', 'k');
colormap(gca, jet); 
cb = colorbar;
cb.Color = 'k';
title(cb, 'Iterationen');
xlabel('Wirkleistung P_2 / pu', 'Color', 'k'); 
ylabel('Blindleistung Q_2 / pu', 'Color', 'k');
title('Anzahl der Iterationen', 'Color', 'k');

