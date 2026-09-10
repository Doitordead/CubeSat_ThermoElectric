function tle = fetch_tle(norad_id, cache_dir)
%FETCH_TLE  Recupere le TLE (Two-Line Element) d'un satellite depuis
%   CelesTrak, avec mise en cache locale (un fichier par jour).
%
%   tle = FETCH_TLE(norad_id)
%   tle = FETCH_TLE(norad_id, cache_dir)
%
%   ENTREES
%     norad_id  : identifiant NORAD du satellite (ex: 69920 pour MARINA)
%     cache_dir : dossier de cache (defaut : data/tle_cache/, relatif a
%                 la racine du projet)
%
%   SORTIE (struct tle)
%     .name      : nom du satellite (ligne 0 du TLE)
%     .line1     : ligne 1 du TLE (epoque, derivees...)
%     .line2     : ligne 2 du TLE (elements orbitaux)
%     .norad_id  : identifiant NORAD
%     .fetched   : date de recuperation (AAAAMMJJ)
%
%   SOURCE : CelesTrak, requete GP standard.
%     https://celestrak.org/NORAD/elements/gp.php?CATNR=<id>&FORMAT=tle
%   Documentation du format de requete : "How to Perform GP Queries",
%   T.S. Kelso, CelesTrak.
%
%   NOTE SUR LE CACHE : CelesTrak demande de ne pas interroger ses
%   donnees plus de quelques fois par jour (bonne conduite, pas une
%   limite technique). Le cache local evite tout telechargement repete
%   inutile au sein d'une meme journee.

if nargin < 2
    % Racine de projet = 2 niveaux au-dessus de ce fichier (orbit/..)
    this_dir = fileparts(mfilename('fullpath'));
    cache_dir = fullfile(this_dir, '..', 'data', 'tle_cache');
end
if ~exist(cache_dir, 'dir')
    mkdir(cache_dir);
end

today_str = datestr(now, 'yyyymmdd');
cache_file = fullfile(cache_dir, sprintf('%d_%s.tle', norad_id, today_str));

if exist(cache_file, 'file')
    % --- Lecture depuis le cache (deja telecharge aujourd'hui) --------
    fid = fopen(cache_file, 'r');
    raw = fread(fid, '*char').';
    fclose(fid);
else
    % --- Telechargement depuis CelesTrak -------------------------------
    url = sprintf('https://celestrak.org/NORAD/elements/gp.php?CATNR=%d&FORMAT=tle', norad_id);
    try
        raw = webread(url);
    catch ME
        error(['Echec de la recuperation du TLE (NORAD %d). Verifie ta ' ...
               'connexion internet et que le NORAD ID existe. Erreur : %s'], ...
               norad_id, ME.message);
    end
    % Sauvegarde en cache pour le reste de la journee
    fid = fopen(cache_file, 'w');
    fwrite(fid, raw);
    fclose(fid);
end

lines = strsplit(strtrim(raw), newline);
if numel(lines) < 2
    error('fetch_tle:parse', 'Reponse TLE inattendue pour NORAD %d.', norad_id);
end

tle.name     = strtrim(lines{1});
tle.line1    = lines{end-1};
tle.line2    = lines{end};
tle.norad_id = norad_id;
tle.fetched  = today_str;

end