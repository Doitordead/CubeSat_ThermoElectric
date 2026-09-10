# `orbit/` Propagation orbitale réelle avec perturbation J2

Récupère l'orbite réelle d'un satellite (TLE, CelesTrak) et la propage dans le temps avec la perturbation due à l'aplatissement terrestre (J2), en éléments **équinoxiaux modifiés**, un choix de coordonnées qui évite la singularité numérique classique des orbites quasi circulaires (voir [Notes de conception](#notes-de-conception) plus bas).

## Pipeline

```
fetch_tle(norad_id)
        │  → tle (struct : name, line1, line2, norad_id, fetched)
        ▼
tle_to_coe(tle)
        │  → coe (struct : éléments orbitaux classiques + mu, R_E, epoch_JD)
        ▼
propagate_orbit(coe, tspan)
        │
        │  en interne : coe_to_equinoctial → ode45(equinoctial_variational_eqs)
        │                                          └─ j2_perturbation
        ▼
   orbit (struct : t, r_eci, r_mag, h, e, theta, Omega, i, omega, ...)

sun_position(JD)  →  [r_sun, u_sun]   (indépendant, ne dépend que de la date)

eclipse_geometry(r_eci, r_sun, R_E)  →  [ecl, cos_sz]
```

## Démarrage rapide

```matlab
% 1. Récupérer et propager l'orbite
tle  = fetch_tle(69920);              % NORAD ID (ex: MARINA)
coe  = tle_to_coe(tle);
tspan = linspace(0, 2*coe.T_orb, 2000);
orbit = propagate_orbit(coe, tspan);

% 2. Position du Soleil sur la même fenêtre temporelle
JD_t = coe.epoch_JD + orbit.t/86400;
[r_sun, u_sun] = sun_position(JD_t);

% 3. Éclipse
[ecl, cos_sz] = eclipse_geometry(orbit.r_eci, r_sun, orbit.R_E);

% 4. Attitude nadir (voir attitude/nadir_frame_eci.m)
Rbody = nadir_frame_eci(orbit.r_eci(:,1), orbit.Omega(1), orbit.i(1));
```

Aucune toolbox MATLAB payante requise. Connexion internet nécessaire pour `fetch_tle` (requête HTTP vers `celestrak.org`). Les TLE sont mis en cache localement dans `data/tle_cache/` pour éviter les requêtes répétées.

## Référence des fonctions

| Fichier | Rôle | Entrées principales | Sorties |
|---|---|---|---|
| `fetch_tle.m` | Récupère le TLE (avec cache) | `norad_id` | `tle` |
| `tle_to_coe.m` | Parse le TLE → éléments classiques | `tle` | `coe` |
| `coe_to_equinoctial.m` | Convertit vers les éléments équinoxiaux | `coe` | `eq` (p, f, g, h_eq, k_eq, L) |
| `j2_perturbation.m` | Perturbation J2 (repère LVLH) | `r, i, om, theta, mu, R_E, J2` | `pr, ps, pw` |
| `equinoctial_variational_eqs.m` | Équations de Gauss (éléments équinoxiaux) — **fonction d'état utilisée par `propagate_orbit`** | `t, c, mu, R_E, J2` | `dc` |
| `gauss_variational_eqs.m` | Équations de Gauss (éléments classiques) — **conservée pour référence/diagnostic uniquement, non utilisée en production** | idem | `dc` |
| `propagate_orbit.m` | Orchestrateur : intègre et reconstruit la position ECI | `coe, tspan, [options]` | `orbit` |
| `sun_position.m` | Éphéméride solaire analytique | `JD` | `r_sun, u_sun` |
| `eclipse_geometry.m` | Éclipse + angle solaire zénithal (test angulaire) | `r_eci, r_sun, R_E` | `ecl, cos_sz` |

## Notes de conception

**Pourquoi les éléments équinoxiaux plutôt que les éléments classiques ?**
Pour une orbite quasi circulaire (excentricité `e→0`), l'excentricité et l'argument du périgée pris séparément deviennent numériquement mal conditionnés dans les équations de Gauss classiques (termes en `1/e`), diagnostiqué sur le satellite MARINA (`e≈6,4×10⁻⁴`), voir `validation/test_diagnose_attitude.m`. `propagate_orbit.m` intègre donc en éléments équinoxiaux modifiés (Walker, Ireland & Owens, 1985), insensibles à cette singularité. L'interface (`orbit.theta`, `orbit.omega`, etc.) reste identique. La correction est interne, transparente pour l'appelant.

**Pourquoi deux méthodes d'attitude (`attitude/nadir_attitude.m` vs `attitude/nadir_frame_eci.m`) ?**
`nadir_attitude.m` est le modèle idéalisé historique (repère LVLH, β constant). `nadir_frame_eci.m` est la méthode robuste retenue pour l'orbite réelle reconstruit l'attitude directement depuis `r_eci` et le moment cinétique (`Ω`, `i`), jamais depuis `θ`/`ω` séparément. **C'est `nadir_frame_eci.m` qu'il faut utiliser pour tout travail sur orbite réelle.**

**`eclipse_geometry.m` — condition à reconfirmer**
Le modèle actuel (test angulaire, cône d'ombre) a remplacé le modèle d'ombre cylindrique. Le sens de l'inégalité du test final a été **corrigé** par rapport au document source (qui semblait inversé un satellite en plein jour aurait été systématiquement marqué en éclipse). La version actuelle a été validée par comparaison croisée avec l'ancien modèle cylindrique (`validation/test_step_flux.m`, écart < 1 %), mais mérite une dernière vérification contre le texte original de la référence avant citation dans un article.

## Tests

```matlab
validation/test_step_orbit.m        % précession héliosynchrone, tracés 3D/2D
validation/test_diagnose_attitude.m % diagnostic de la singularité e→0 (théorique, ne pas utiliser en production)
validation/test_step_flux.m         % chaîne complète, y compris comparaison des 2 modèles d'éclipse
```

## Dépendances

- MATLAB (`ode45`, aucune toolbox payante)
- Connexion internet pour `fetch_tle.m` (CelesTrak)
- [`planet3D`](https://github.com/tamaskis/planet3D-MATLAB) pour les scripts de `results/` (visualisation 3D uniquement — pas requis pour `orbit/` lui-même)