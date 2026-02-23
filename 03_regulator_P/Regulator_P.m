
% Autor - MechaLogic
% Kanal YouTube - wpadnij po inne poradniki. 
% Link do filmiku z omowieniem - https://youtu.be/cLqq47w5H48

% Regulator P, synteza parametryczna - Matlab + Simulink
clc; clear; 

% Kr -> licznik transmitancji, wzmocnienie podstawowe naszego sygnalu
% Kp -> wzmocnienie regulatora P 

% L1 - licznik
L1 = [3];

% m2, m3, m4 - (s+1), (6s+1), (9s+1) - mianownik
m2 = [1 1];
m3 = [6 1];
m4 = [9 1];

% zapis mnozenia nawiasow
m5 = conv(m2,m3);
M1 = conv(m4,m5);

% zapis transmitancji 
G = tf(L1,M1)

% Odpowiedz skokowa
figure(1);
step(G)
grid on
title('Odpowiedź skokowa obiektu - G')

[y,t] = step(G);

% Bode - funkcja margin(G) automatycznie zaznacza nam zapas wzmocnienia i
% fazy. W pierwszym odcinku z tej serii omawialem dokladniej jak czytac
% wykresy Bodego i Nyquista

figure(2);
margin(G)

% Regulator P

% Odczytany z Bodego zapas wzmocnienia - Gain Margin(dB), punkt na gornym
% wykresie 
deltaLm = 16.2;
ZapasWzmocnieniaBezwymiarowy_bode = 10^(deltaLm/20)

% Przyjmij sobie mnoznik jaki chcesz, ale nie wiekszy niz 1, bo uklad bedzie
% nie stabilny 
mnoznik = 0.5;
Kp_Bode = mnoznik*ZapasWzmocnieniaBezwymiarowy_bode

% Wyznaczanie stycznej funkcji y(t) - step response 
dy = gradient(y, t);

% punkt najwiekszego nachylenia 
[~, idx] = max(dy);

% t_inflect, y_inflect - punkt przeciecia stycznej z odpowiedzia
% skokowa
t_inflect = t(idx); 
y_inflect = y(idx);
slope = dy(idx); % tangens Y/X, stycznej

% rownanie stycznej
y_tan = slope * (t - t_inflect) + y_inflect;

% wykres step + styczna
figure(3);
step(G)
grid on
title('Odpowiedź skokowa obiektu')

hold on
plot(t, y_tan, '--r')
legend('step', 'tangent')

% miejsce zerowe stycznej - tau
tau = t_inflect - y_inflect / slope
Kr = L1;

% Amplituda sygnalu wejsciowego 
A = 1;

% To jest metoda do 3 rzedu
T = Kr/slope

% obliczamy Kp za pomoca T i tau 

Kp_Tau_T = (0.3)/(Kr*(tau/T))

% Wykresy step po zadaniu roznych wzmocnien 
figure(4)
for K = [0.2 0.5 1 2 5 Kp_Bode, Kp_Tau_T]
    step(feedback(K*G,1))
    hold on
end
grid on
legend('0.2','0.5','1','2','5','Kp_Bode','Kp_Tau_T')
