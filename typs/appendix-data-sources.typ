#import "../defs.typ": table-figure

= Data sources <data-sources>

Paths beginning with `/archive/`, `/scratch/` or `/space/` are internal to the Cerfacs cluster and are not publicly accessible. External readers should use the public source given in the same row, or contact the data provider named there. The `.slf` simulation outputs have no public source: they are internal copies of runs made by the colleagues named in their paths.

The input files for the Marmande 2019, Marmande 2021 and St-Omer test cases are listed in @marmande-2019-inputs, @marmande-2021-inputs and @stomer-inputs respectively.

== Marmande

#table-figure(
  caption: [Marmande 2019 input files],
  label: "marmande-2019-inputs",
  columns: (35%, 1fr),
  table.header([File / directory], [Source]),
  [`lf_2019_fr1.slf`], [Local copy from `/archive/globc/thnguyen/fishstick/examples/python3/telapy_study/telemac2d/Garonne19TGRS/res_Garonne_2019_flood_FR1/Garonne_2019.slf`],
  [`hf_2019_k17.slf`], [Local copy from `/scratch/globc/cassan/HYDRO/Garonne_Downstream_2023/2D-Data/Garonne_2019_flood/res_garonne2023_flood2019`],
  [`marmande_aoi.geojson`], [Intersection of the LF and HF extents],
  [`sirene_2019-12.csv`], [Downloaded from `https://data.cquest.org/geo_sirene/v2019/2019/2019-12/StockEtablissementActif_utf8_geo.csv.gz`],
  [`rpg_2020.shp`], [Downloaded from `https://data.cquest.org/registre_parcellaire_graphique/2020/RPG_2-0__SHP_LAMB93_R75_2020-01-01.7z`],
  [`bdtopo_bati_2019-12.shp`], [Downloaded from `https://data.cquest.org/ign/bdtopo/BDTOPO_3-0_2019-12-16/BDTOPO_3-0_TOUSTHEMES_SHP_LAMB93_D047_2019-12-16.7z.001`],
  [`rge_alti.tif`], [Local copy from `/space/globc/cassan/SWIFT/GARONNE/data/merged_2023_v2_culvert_dike.tif`],
  [`/floodml/`], [Local copy from `/archive/globc/FloodDAM/FloodML/FML`],
  [`esawc_2020.tif`], [Copernicus Data Space Ecosystem via openEO (`https://openeo.dataspace.copernicus.eu/openeo/1.2`)],
  [`oso_2019.tif`], [Downloaded from `https://geodes-portal.cnes.fr/`],
  [`demglo30_2011.tif`], [Copernicus Data Space Ecosystem via openEO (`https://openeo.dataspace.copernicus.eu/openeo/1.2`)],
  [`filosofi_2019.gpkg`], [Downloaded from `https://www.insee.fr/fr/statistiques/7655475?sommaire=7655515`],
  [`ghslpop_2020.tif`], [Downloaded from `https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_POP_GLOBE_R2023A/GHS_POP_E2020_GLOBE_R2023A_54009_100/V1-0/tiles/GHS_POP_E2020_GLOBE_R2023A_54009_100_V1_0_R4_C19.zip`],
)

#table-figure(
  caption: [Marmande 2021 input files],
  label: "marmande-2021-inputs",
  columns: (35%, 1fr),
  table.header([File / directory], [Source]),
  [`lf_2021_fr1.slf`], [Local copy from `/archive/globc/thnguyen/fishstick/examples/python3/telapy_study/telemac2d/Garonne21TGRS/res_Garonne_2021_flood_FR1/Garonne_2021.slf`],
  [`lf_2021_run_true.slf`], [Local copy from `/archive/globc/thnguyen/fishstick/examples/python3/telapy_study/telemac2d/Garonne21AGU/res_Garonne_2021_truth/Garonne_2021.slf`],
  [`hf_2021_k17.slf`], [Local copy from `/scratch/globc/cassan/HYDRO/Garonne_Downstream_2023/2D-Data/Garonne_2021_flood/res_garonne2023_flood2021_HF`],
  [`marmande_aoi.geojson`], [Same as 2019],
  [`sirene_2021-02.csv`], [Downloaded from `https://data.cquest.org/geo_sirene/v2019/2021/2021-02/StockEtablissementActif_utf8_geo.csv.gz`],
  [`rpg_2022.shp`], [Downloaded from `https://data.cquest.org/ign/rpg/2022/RPG_2-0__SHP_LAMB93_R75_2022-01-01.7z`],
  [`bdtopo_2021-12.gpkg`], [Downloaded from `https://data.cquest.org/ign/bdtopo/BDTOPO_3-0_2021-12-15/BDTOPO_3-0_TOUSTHEMES_GPKG_LAMB93_D047_2021-12-15.7z`],
  [`rge_alti.tif`], [Same as 2019],
  [`/floodml/`], [Same as 2019],
  [`esawc_2021.tif`], [Copernicus Data Space Ecosystem via openEO (`https://openeo.dataspace.copernicus.eu/openeo/1.2`)],
  [`oso_2021.tif`], [Downloaded from `https://geodes-portal.cnes.fr/`],
  [`demglo30_2011.tif`], [Copernicus Data Space Ecosystem via openEO (`https://openeo.dataspace.copernicus.eu/openeo/1.2`)],
  [`filosofi_2021.gpkg`], [Downloaded from `https://www.insee.fr/fr/statistiques/8735162?sommaire=8735243`],
  [`ghslpop_2020.tif`], [Same as 2019],
)

== St-Omer

#table-figure(
  caption: [St-Omer 2023--2024 input files],
  label: "stomer-inputs",
  columns: (35%, 1fr),
  table.header([File / directory], [Source]),
  [`Perimetre_SmageAa.shp`], [Local copy; the SmageAa data are not open as of now and can be obtained on request from the SmageAa],
  [`sirene_2023-10.csv`], [Downloaded from `https://data.cquest.org/geo_sirene/v2019/2023/2023-10/StockEtablissementActif_utf8_geo.csv.gz`],
  [`rpg_2024.gpkg`], [Downloaded from `https://data.cquest.org/registre_parcellaire_graphique/2024/RPG_3-0__GPKG_LAMB93_R32_2024-01-01.7z`],
  [`bdtopo_2023-09.gpkg`], [Downloaded from `https://data.cquest.org/ign/bdtopo/BDTOPO_3-3_2023-09-15/BDTOPO_3-3_TOUSTHEMES_GPKG_LAMB93_D062_2023-09-15.7z`],
  [`/rge_alti_2021/`], [Downloaded from `https://data.cquest.org/ign/rgealti/RGEALTI_2-0_1M_ASC_LAMB93-IGN69_D062_2021-09-20.7z`],
  [`/floodml/`], [Local copy from the internal Cerfacs archive (see the note above)],
  [`esawc_2021.tif`], [Copernicus Data Space Ecosystem via openEO (`https://openeo.dataspace.copernicus.eu/openeo/1.2`)],
  [`oso_2023.tif`], [Downloaded from `https://geodes-portal.cnes.fr/`],
  [`demglo30_2011.tif`], [Copernicus Data Space Ecosystem via openEO (`https://openeo.dataspace.copernicus.eu/openeo/1.2`)],
  [`filosofi_2021.gpkg`], [Downloaded from `https://www.insee.fr/fr/statistiques/fichier/8735162/Filosofi2021_carreaux_200m_gpkg.zip`],
  [`ghslpop_2025.tif`], [Downloaded from `https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_POP_GLOBE_R2023A/GHS_POP_E2025_GLOBE_R2023A_54009_100/V1-0/tiles/GHS_POP_E2025_GLOBE_R2023A_54009_100_V1_0_R4_C19.zip`],
  [`/insitu/`], [Local copy of the SmageAa ground-truth data, which are not open as of now and can be obtained on request from the SmageAa],
  [`/floodml_preprocessed/`], [S2-based inferences with SNW or CLD above 50% removed],
)

== Chinon

The simulations are stored in:

- `/archive/globc/bonassies/Chinon/2D-Data/chinon_2024`
- `/archive/globc/bonassies/Chinon/2D-Data/chinon_cv`

== Ohio

=== 2018

- TELEMAC-2D run: `/archive/globc/thnguyen/fishstick/examples/python3/telapy_study/telemac2d/Ohio/res_EnKF_IDA_Ohio_2018`
- GHSL-POP 2020: `https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_POP_GLOBE_R2023A/GHS_POP_E2020_GLOBE_R2023A_54009_100/V1-0/tiles/GHS_POP_E2020_GLOBE_R2023A_54009_100_V1_0_R5_C11.zip`

=== 2025

- GHSL-POP 2025: `https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_POP_GLOBE_R2023A/GHS_POP_E2025_GLOBE_R2023A_54009_100/V1-0/tiles/GHS_POP_E2025_GLOBE_R2023A_54009_100_V1_0_R5_C11.zip`
- `ohio_2025_fr.slf`: `/scratch/globc/ricci/HYDRO/tools4telemac/Data/Ohio/2D-Data/Ohio_04-2025_flood/res_Ohio_042025_flood_FR_insitu_S1_BCNewburghWSE_24zones_OSO`
- `ohio_2025_igda.slf`: `/scratch/globc/ricci/HYDRO/tools4telemac/Data/Ohio/2D-Data/Ohio_04-2025_flood/res_EnKF_IGDA_Ohio042025_BCNewburghWSE`
- `ohio_2025_rsda.slf`: `/scratch/globc/ricci/HYDRO/tools4telemac/Data/Ohio/2D-Data/Ohio_04-2025_flood/res_EnKF_RSDA_Ohio042025_24zones-S1OSO_sbdh_025_so_005_fltbkg_misfmean`
