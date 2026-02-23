% Autor - MechaLogic
% Kanal YouTube - wpadnij po inne poradniki. 
% Link do filmiku z omowieniem - https://youtu.be/jrTjcmbOUaI 

% Zapas stabilnosci ukladow regulacji - kryterium Hurwitza, Nyquista

% inne formy zapisu transmitancji 
% /////////
% k=1;
% G1 = tf(k,[1 2 1]) %  G1 = 1 / (1*s^2 + 2*s^1 + 1*s^0) 
% G2 = tf(k,[1 0.2 1]) % G2 = 1 / (1*s^2 0.2*s^1 + 1*s^0)
% /////////
% Mozesz tez okreslic sobie licznik oraz mianownik w osobnych liniach 
% L1 = [1 2 3] => 1*s^2 + 2*s^1 + 3*s^0 
% M1 = [1 1 1] => 1*s^1 +1*s^1 +1*s^0
% s^0 = 1 
% G3 = tf(L1,M1) 
% ////////

clc; clear;

s = tf('s'); % tf - transfer function, transmitancja 
    
M = 2*s^3 + 7*s^2 + s + 1; % Mianownik
w = logspace(-2, 2, 5000);   % Czeste probkowanie - gesta siatka. w innym wypadku duze zaokraglenia i niezgodnosci 

% Poszczegolne transmitancje 
G1 = 0.5/M
G2 = 1/M
G3 = 1.5/M
G4 = 2/M

[y1, t1] = step(G1);
[y2, t2] = step(G2);
[y3, t3] = step(G3);
[y4, t4] = step(G4);

% Porownanie odpowiedzi skokowej        
figure
plot(t1, y1, 'b', t2, y2, 'r--', t3, y3, 'g', t4, y4, 'y--')
grid on
title('Porównanie odpowiedzi skokowej')
xlabel('Czas (s)')
ylabel('Odpowiedź skokowa')
legend('G1', 'G2', 'G3', 'G4')

% Odpowiedz skokowa
figure
G = {G1, G2, G3, G4};

for i = 1:4 
    subplot(2,2,i)
    step(G{i})
    grid on
    title(['Step – G', num2str(i)]) 
end

% charakterystyki bodego - bez 'for', kazda z osobna wypisana 
figure
bode(G1, w)
grid on
title('Bode - G1')

figure
bode(G2, w)
grid on
title('Bode - G2')

figure
bode(G3, w)
grid on
title('Bode - G3')

figure
bode(G4, w)
grid on
title('Bode - G4')

% obliczenia bode - dla pojedynczej transmitancji

[mag, phase, freq] = bode(G1,w); % tutaj zmieniasz G1 na G2, G3, G4 ....

mag = squeeze(mag); % usuwamy jednowymiarowe pozycje w macierzy - squeeze
phase = squeeze(phase);

phase_unwrap = unwrap(phase*pi/180)*180/pi;

% amplituda w dB
mag_db = 20*log10(mag);

% znajdź wszystkie punkty blisko 0 dB (np. ±0.1 dB - bawiac sie tutaj - zwiekszasz i zmniejszasz blad wyniku)
idx_candidates = find(abs(mag_db) < 0.1); 

% wybierz ten o największej częstotliwości
[~, k] = max(freq(idx_candidates));
idx = idx_candidates(k);

% zapas fazy
kat_dla_dB0 = phase_unwrap(idx)
zapas_fazy = 180 + phase_unwrap(idx)

% (np. tolerancja ±0.2 stopnia – bawiac sie tutaj-  zwiekszasz i zmniejszasz blad wyniku)
idx_candidates_phase = find(abs(phase_unwrap + 180) < 0.2); 

% Wybieramy punkt o największej częstotliwości
[~, k] = max(freq(idx_candidates_phase));
idx_gm = idx_candidates_phase(k);

% Odczyt amplitudy w tym punkcie
mag_at_180 = mag_db(idx_gm);

% Logarytmiczny zapas wzmocnienia
deltaLm = -mag_at_180;     % [dB]

% Bezwymiarowy zapas wzmocnienia
ZapasWzmocnieniaBezwymiarowy_bode = 10^(deltaLm/20);

kat_180 = phase_unwrap(idx_gm)
deltaLm_dB_bode
ZapasWzmocnieniaBezwymiarowy_bode

% Charakterystyki dla wszystkich wykresow
figure
G = {G1, G2, G3, G4};
w = logspace(-2, 2, 3000);

theta = linspace(0, 2*pi, 500);   % parametr okręgu
xc = cos(theta);
yc = sin(theta);

for i = 1:4
    subplot(2,2,i)
    nyquist(G{i}, w)
    hold on
    grid on

    % punkt -1
    plot(-1, 0, 'rx', 'LineWidth', 2, 'MarkerSize', 10)

    % okrag jednostkowy
    plot(xc, yc, 'g--', 'LineWidth', 1.2)

    xlim([-1.5 0.5])
    ylim([-0.3 0.3])
    axis equal
    title(['Charakterystyka Nyquista – G', num2str(i)])
end

% G4 przecina sie najblizej punktu (-1,0) - maly zapas stabilnosc
% G1 przecina najdalej od punktu (-1,0) - duzy zapas stabilnosci 
% Dopoki wykres nie okraza punktu (-1,0) przecina sie za nim, to uklad
% stabilny 


Gj = squeeze(freqresp(G1, w));   % zespolone G(jw)

Re = real(Gj);
Im = imag(Gj);
Mag = abs(Gj);

% Obliczanie zapasu stabilności na podstawie punktu przecięcia
idx_real = find(diff(sign(Im)) ~= 0 & Re(1:end-1) < 0);
% Najblizszy punktu (-1,0) 
[~, k] = min(abs(Re(idx_real) + 1));
idx = idx_real(k);

% interpolacja punktu przeciecia
t = -Im(idx) / (Im(idx+1) - Im(idx));
z_cross = Gj(idx) + t * (Gj(idx+1) - Gj(idx));

x_k = real(z_cross);   % Re
y_k = imag(z_cross);   % ~0

zapas_wzmocnienia_nyquist = 1 / abs(x_k);
zapas_wzmocnienia_dB_nyquist = 20*log10(zapas_wzmocnienia_nyquist);

% punkty blisko okręgu jednostkowego |G| = 1
idx_candidates = find(abs(Mag - 1) < 0.001);

% wybieramy punkt o największej częstotliwości
[~, k] = max(freq(idx_candidates));
idx = idx_candidates(k);

% współrzędne punktu przecięcia
x = Re(idx);
y = Im(idx);

% zapas fazy (geometrycznie)
zapas_fazy_nyquist = atan2(abs(y), abs(x)) * 180/pi;

% okrag jednostkowy
punkt_przeciecia_X = x
punkt_przeciecia_Y = y

zapas_fazy_nyquist
zapas_wzmocnienia_dB_nyquist
zapas_wzmocnienia_nyquist
