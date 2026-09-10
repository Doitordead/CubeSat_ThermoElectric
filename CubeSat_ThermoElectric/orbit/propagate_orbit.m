function orbit = propagate_orbit(coe, tspan, varargin)
%PROPAGATE_ORBIT  Integre les equations de Gauss perturbees par J2 et
%   calcule la position ECI du satellite a chaque instant.
%
%   orbit = PROPAGATE_ORBIT(coe, tspan)
%   orbit = PROPAGATE_ORBIT(coe, tspan, 'mu', ..., 'R_E', ..., 'J2', ...)
%
%   ENTREES
%     coe   : struct issue de TLE_TO_COE
%     tspan : vecteur des instants de sortie souhaites [s], ex.
%             linspace(0, 3*coe.T_orb, 2000)
%
%   OPTIONS (paires nom/valeur)
%     'mu'     (defaut 398600 km^3/s^2)
%     'R_E'    (defaut 6378 km)
%     'J2'     (defaut 1.08263e-3)
%     'RelTol' (defaut 1e-10)
%     'AbsTol' (defaut 1e-10)
%
%   SORTIE (struct orbit)
%     .t                          : instants de sortie [s]
%     .h, .e, .theta, .Omega, .i, .omega : elements orbitaux au cours
%                                     du temps (Eq.19a-f integrees)
%     .r_eci   : position ECI [km], 3 x N
%     .r_mag   : rayon orbital [km], 1 x N
%     .mu, .R_E, .J2, .coe0 : parametres et etat initial, pour tracabilite
%
%   METHODE : ode45 (Runge-Kutta 4/5 adaptatif). Le papier de reference
%   (Morsch Filho et al. 2020) laisse le choix du solveur libre ; ode45
%   est un choix standard, tolerance resserree car les equations de
%   Gauss sont sensibles pres de e~0 (cf. remarque dans
%   gauss_variational_eqs.m).

p = inputParser;
addParameter(p, 'mu', 398600);
addParameter(p, 'R_E', 6378);
addParameter(p, 'J2', 1.08263e-3);
addParameter(p, 'RelTol', 1e-10);
addParameter(p, 'AbsTol', 1e-10);
parse(p, varargin{:});
mu = p.Results.mu; R_E = p.Results.R_E; J2 = p.Results.J2;

% --- Etat initial : c = [h, e, theta, Omega, i, omega] --------------------
c0 = [coe.h0; coe.e; coe.theta0; coe.Omega; coe.i; coe.omega];

opts = odeset('RelTol', p.Results.RelTol, 'AbsTol', p.Results.AbsTol);
[t_out, c_out] = ode45(@(t,c) gauss_variational_eqs(t, c, mu, R_E, J2), ...
                        tspan, c0, opts);

N = numel(t_out);
[R1, R3] = rotation_matrices();
r_eci = zeros(3, N);
r_mag = zeros(1, N);

for k = 1:N
    h_  = c_out(k,1); e_  = c_out(k,2); th_ = c_out(k,3);
    Om_ = c_out(k,4); i_  = c_out(k,5); om_ = c_out(k,6);

    % --- Eq.5 : position dans le repere perifocal --------------------------
    rk = (h_^2/mu) / (1 + e_*cos(th_));
    r_pf = rk * [cos(th_); sin(th_); 0];

    % --- Eq.6-8 : transformation perifocal -> ECI ---------------------------
    Q = R3(om_) * R1(i_) * R3(Om_);   % ECI -> perifocal
    r_eci(:,k) = Q.' * r_pf;          % perifocal -> ECI
    r_mag(k)   = rk;
end

orbit.t     = t_out;
orbit.h     = c_out(:,1);
orbit.e     = c_out(:,2);
orbit.theta = c_out(:,3);
orbit.Omega = c_out(:,4);
orbit.i     = c_out(:,5);
orbit.omega = c_out(:,6);
orbit.r_eci = r_eci;
orbit.r_mag = r_mag;
orbit.mu    = mu;
orbit.R_E   = R_E;
orbit.J2    = J2;
orbit.coe0  = coe;

end