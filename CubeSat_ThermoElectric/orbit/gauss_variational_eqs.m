function dc = gauss_variational_eqs(~, c, mu, R_E, J2)
%GAUSS_VARIATIONAL_EQS  Equations variationnelles de Gauss, perturbees
%   par J2 uniquement (pas de trainee atmospherique dans cette version).
%
%   dc = GAUSS_VARIATIONAL_EQS(t, c, mu, R_E, J2)
%
%   Fonction "derivee d'etat" au format attendu par les solveurs ODE de
%   MATLAB (ode45, etc.) : dc/dt = f(t, c).
%
%   VECTEUR D'ETAT c = [h; e; theta; Omega; i; omega]
%     h      : moment cinetique specifique [km^2/s]
%     e      : excentricite [-]
%     theta  : anomalie vraie [rad]
%     Omega  : RAAN [rad]
%     i      : inclinaison [rad]
%     omega  : argument du perigee [rad]
%
%   SOURCE : Morsch Filho et al., Energies 13(24):6691, 2020, Eq.19a-f.
%   Singularites documentees par les auteurs pour e=0 ou i=0 (division
%   par e et par sin(i)/tan(i) dans les formules ci-dessous) : ne pas
%   utiliser telle quelle pour une orbite parfaitement circulaire ou
%   equatoriale.

h     = c(1);
e     = c(2);
theta = c(3);
Omega = c(4);  % n'intervient pas dans Eq.19a-f elles-memes (juste
                  % transporte pour completer le vecteur d'etat integre,
                  % utilise ensuite pour la transformation perifocal->ECI)
i     = c(5);
om    = c(6);

% --- Rayon orbital courant (equation de la conique) ------------------------
r = h^2/mu / (1 + e*cos(theta));

% --- Perturbation J2 courante (Eq.18a-c) ------------------------------------
[pr, ps, pw] = j2_perturbation(r, i, om, theta, mu, R_E, J2);

% --- Eq.19a : dh/dt = r*ps ---------------------------------------------------
dh = r * ps;

% --- Eq.19b : de/dt ------------------------------------------------------------
de = (h/mu)*sin(theta)*pr ...
     + (ps/(mu*h)) * ( (h^2 + mu*r)*cos(theta) + mu*e*r );

% --- Eq.19c : dtheta/dt ---------------------------------------------------------
dtheta = h/r^2 + (1/(e*h)) * ( (h^2/mu)*cos(theta)*pr ...
                                - (r + h^2/mu)*sin(theta)*ps );

% --- Eq.19d : dOmega/dt (precession du noeud) -----------------------------------
dOm = (r / (h*sin(i))) * sin(om+theta) * pw;

% --- Eq.19e : di/dt -----------------------------------------------------------------
di = (r/h) * cos(om+theta) * pw;

% --- Eq.19f : domega/dt -------------------------------------------------------------
dom = -(1/(e*h)) * ( (h^2/mu)*cos(theta)*pr - (r + h^2/mu)*sin(theta)*ps ) ...
      - (r*sin(om+theta) / (h*tan(i))) * pw;

dc = [dh; de; dtheta; dOm; di; dom];

end