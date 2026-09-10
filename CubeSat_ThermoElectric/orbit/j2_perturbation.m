function [pr, ps, pw] = j2_perturbation(r, i, om, theta, mu, R_E, J2)
%J2_PERTURBATION  Perturbation due a l'aplatissement terrestre (J2), en
%   repere LVLH [r_hat, s_hat, w_hat] (radial, transverse, normal).
%
%   [pr, ps, pw] = J2_PERTURBATION(r, i, om, theta, mu, R_E, J2)
%
%   ENTREES
%     r      : rayon orbital courant [km]
%     i      : inclinaison [rad]
%     om     : argument du perigee [rad]
%     theta  : anomalie vraie [rad]
%     mu     : parametre gravitationnel terrestre [km^3/s^2]
%     R_E    : rayon terrestre [km]
%     J2     : second harmonique zonal [-]
%
%   SORTIES : composantes de l'acceleration perturbatrice [km/s^2]
%     pr : composante radiale
%     ps : composante transverse (dans le plan orbital, perp. a r)
%     pw : composante normale (hors du plan orbital)
%
%   SOURCE : Morsch Filho, Seman, Rigo, de Paulo Nicolau, Garcia
%   Ovejero, Leithardt, "Irradiation Flux Modelling for
%   Thermal-Electrical Simulation of CubeSats: Orbit, Attitude and
%   Radiation Integration", Energies 13(24):6691, 2020, Eq.18a-c.

% Argument de latitude (om + theta), recurrent dans les 3 formules.
u = om + theta;

% --- Eq.18a : composante radiale -----------------------------------------
pr = -1.5 * (J2*mu*R_E^2/r^4) * (1 - 3*sin(i)^2*sin(u)^2);

% --- Eq.18b : composante transverse (s_hat) ------------------------------
ps = -1.5 * (J2*mu*R_E^2/r^4) * sin(i)^2 * sin(2*u);

% --- Eq.18c : composante normale (w_hat) ---------------------------------
pw = -1.5 * (J2*mu*R_E^2/r^4) * sin(2*i) * sin(u);

end