#import "../defs.typ": (
  bbox-figure, diagram_legend_description, hxy, image-figure, make-label, mermaid-classes, mermaid-figure, table-figure,
  txy, vxy,
)
= SEICHE

_Socio Economic Impacts of Catastrophic Hydrological Events_, or SEICHE, is the main Python module that was developed over the course of this study. It is a data pipeline, whose main goal is to streamline the process of using state-of-the-art data and methods to obtain impact estimations. This chapter describes the methodological choices that led to its current shape, but more in-depth technical documentation, such as the full API reference, can be found in the documentation, and the code itself in the repository @seiche. A subset of said documentation is included in the appendix for quick reference to the implementations of the methods described in this chapter.

== Objectives <seiche-objectives>

The focus of this tool is on the _direct_ impacts of flooding, that is, as explained in the first chapter of this document, the immediate consequences of the flooding event, and not the long-lasting ones. For this purpose, it relies on damage functions, standard tools to compute the direct economic damage, and filtered population rasters based on hazard conditions to try to assess the statistical number of exposed people for a certain event. As explained in the first chapter, in the first few hours or days directly following a disaster, there are already social metrics made available by local rescue teams --- such as the deceased or missing toll --- if local governing entities have sufficient allocated budget, while precise final economic and social assessments only happen months or even years after events. However, in between, there is often a time gap that SEICHE is trying to fill. For this purpose, open, global and fast methods are necessary to be able to quickly assess, even if with non-negligible uncertainty, no matter where on Earth, an estimation of the total impact, in order to provide meaningful insights to governing entities.


== General flow

#let general-flow-source = (
  "---
config:
  layout: elk
---
flowchart TD
  style hzd fill:#FFFFFF,stroke:#000000,stroke-dasharray:5 5

  t2d{{2D Hydrodynamic simulation}}:::funcs
  sat[Satellite imagery]:::input
  dem[Digital elevation model]:::input
  subgraph hzd[]
    depth[Flood maximum depth]:::inter
    speed[Flood maximum velocity]:::inter
    duration[Flood duration]:::inter
  end
  fml{{Flood mask extraction}}:::funcs
  bfm[Binary flood mask]:::inter
  defended{{Depth estimation}}:::funcs
  dmgfunc{{Economic impact estimation}}:::funcs
  socialfunc{{Social impact estimation}}:::funcs
  lc[Land cover]:::input
  popraster[Population raster]:::input
  impacteco[Direct economic impact]:::final
  impactpop[Direct social impact]:::final

  t2d --> depth & speed & duration
  sat --> fml
  fml --> bfm
  bfm & dem --> defended
  defended --> depth
  hzd & lc --> dmgfunc
  hzd & popraster --> socialfunc
  dmgfunc --> impacteco
  socialfunc --> impactpop
"
    + mermaid-classes
)

#mermaid-figure(
  general-flow-source,
  caption: [Conceptual flow of SEICHE],
  label: "diagram-general-flow",
  size: 16pt,
)

#v(1fr)

== Water hazard <sec-water-hazard>

The hazard is the description of the flood event in space and time. Two sources of hazard feed the pipeline: a 2D hydrodynamic simulation directly provides the 2D fields for maximum depth #hxy, maximum velocity #vxy and flood duration #txy, and satellite imagery is turned into a binary flood mask (BFM) which, combined with a DEM, gives #hxy through depth estimation. The user can choose to use one, or both. The hazard feeds two impact assessments: an economic one, using land cover, and a social one, using a population raster. For the economic impact, 2 sets of damage functions are vendored in the repository, Floodam @floodam-data, and JRC @huizinga2017global. The first computes an economic damage based on #hxy, #vxy, and #txy, while the JRC dataset only require #hxy.

#v(1fr)
#pagebreak()

=== Remote sensing <sec-remote-sensing>

For this study's hydrological purposes, optical and radar imagery obtained through low-orbit satellites are of interest. The first is similar to a common camera, capturing passive light emissions in the visible, or near visible, spectrum. The second actively sends radio waves and records their reflection after hitting the ground. Radar can either be an altimeter, observing directly at nadir, or a SAR, registering a large swath at once -- and more suited for flood studies. The characteristics of the satellites considered here are compiled in @sat-table, following the review of @rahman2017state. Given the employed methods to derive water hazard data from remote sensing (RS), described in @sec-flood-extent and @sec-depth, the available satellites are Sentinel-1 (S1), Sentinel-2 (S2), Landsat-8 (L8), Landsat-9 (L9), and TerraSAR-X (TSX). S1, S2 and L8 were kept; L9 was removed for data access reasons, and TSX because images are not open-source. S1 and S2 are part of the European Copernicus program. L8 is solely American, held between the National Aeronautics and Space Administration (NASA) and USGS. The whole chain, from Level 2 images to the hazard raster, is summarized in @remote-sensing-conceptual-flow.

#block(breakable: false)[
  #figure(
    kind: table,
    caption: [Satellite characteristics],
  )[
    #set par(justify: false)
    #table(
      columns: (auto, auto, auto, auto, auto),
      align: left + horizon,
      table.header([Name], [Sensor], [Spatial resolution], [Temporal resolution], [Spectral bands]),
      [S1], [SAR], [10 m], [12 days], [C-band],
      [S2], [Optical], [10 m], [5 days], [13 bands],
      [L8], [Optical], [30 m], [16 days], [11 bands],
      [L9], [Optical], [30 m], [16 days], [11 bands],
      [TSX], [SAR], [1--16 m], [11 days], [X-band],
    )
  ] <sat-table>
]

#let remote-sensing-conceptual-flow = (
  "---
config:
  layout: elk
---
flowchart TD
  style seiche fill:#FFFFFF,stroke:#000000,stroke-dasharray:5 5
  style tools fill:#FFFFFF,stroke:#333333,stroke-dasharray:2 2
  style otherbfm fill:#CCFFCC,stroke:#333333,stroke-width:1px,stroke-dasharray:5 5
  style swot fill:#FFFFCC,stroke:#333333,stroke-width:1px,stroke-dasharray:5 5
  style l2 fill:#FFFFFF,stroke:#333333,stroke-dasharray:5 5

  subgraph l2[Level 2 satellite images]
    s1[Sentinel-1]:::input
    s2[Sentinel-2]:::input
    l8[Landsat-8]:::input
    l9[Landsat-9]:::input
    tsx[TerraSAR-X]:::input
  end
  dem1[Copernicus or MERIT DEM]:::input
  fml{{FloodML <br/>Random Forest Inference}}:::funcs
  otherbfm{{\"Other BFM tools<br/>(e.g. CNN-based)\"}}:::funcs
  swot[\"SWOT\"]:::input
  bfm[\"Binary Flood Masks (BFMs)\"]:::inter

  snwcld[\"SNW and CLD bands<br/>(Sentinel-2 L2A)\"]:::input
  dem2[\"DEM\"]:::input

  subgraph seiche[SEICHE]
    subgraph tools[SEICHE tools]
      snwcldfilter{{Snow and Cloud filtering}}:::funcs
      magentafilter{{'Magenta' filtering}}:::funcs
    end
    filteredbfms[Filtered BFMs]:::inter
    interp{{Time interpolation<br/>and aggregation}}:::funcs
    floodmask[Aggregated flood mask]:::inter
    defended{{\"Depths Estimation from<br/>a Flood Extent aNd<br/>Digital Elevation Data<br/>(DEFENDED)\"}}:::funcs
    txy[\"T(x, y)\"]:::inter
    thresh{{Threshold}}:::funcs
    hxy[\"H(x, y)\"]:::inter
    vxy[\"Empty<br/>V(x, y)\"]:::input
    hzd[Hazard 3-band raster]:::final
  end

  l2 --> fml
  l2 --> otherbfm
  dem1 --> fml
  swot --> otherbfm
  fml --> bfm
  otherbfm -.-> bfm
  bfm -->|Optical-based BFMs| snwcldfilter
  snwcld --> snwcldfilter
  bfm -->|Radar-based BFMs| magentafilter
  snwcldfilter --> filteredbfms
  magentafilter --> filteredbfms
  filteredbfms --> interp
  interp --> txy
  txy --> thresh --> floodmask
  floodmask --> defended
  dem2 --> defended
  defended --> hxy
  hxy & vxy & txy --> hzd
"
    + mermaid-classes
)



#mermaid-figure(
  remote-sensing-conceptual-flow,
  caption: [Hazard raster generation from remote sensing],
  label: "remote-sensing-conceptual-flow",
)

Remote sensing does not provide velocity, so the $V$ band of the hazard raster is left empty for this source. As a consequence, the agricultural Floodam functions, which require $V$, cannot be used on a hazard derived from satellite imagery, while the building functions that only need $H$ and $T$ can still be applied, and the JRC functions only need $H$. For Floodam, we simply average the damage function values on all possible $V$ values before using them on $H$ and $T$.


==== Preprocessing of satellite images <sec-preprocessing>

Snow and clouds are two natural phenomena that can have a great influence on how we can observe floodwater from space: clouds block S2 optical data retrieval, potentially leading to flooded pixels that are not observed, while snow can be mistaken for water during FloodML's inference, leading to false positives. For S2, precomputed snow (SNW) and cloud (CLD) bands are available in the Level 2A (L2A) Sen2Cor products. These represent the probability of snow or clouds on each pixel, respectively, ranging from 0 to 100%. Pixels with values above a pair of thresholds (here, 50% and 50%) were removed from BFMs inferred from S2 data, as implemented in the `filter_s2.py` tool of the SEICHE repository. For S1, snow has to be detected differently, since SAR backscatter is not affected by clouds. The approach used here is called the "Magenta" filter, developed by Fatima KARBOU @karbou, and implemented in the `filter_s1.py` tool of the SEICHE repository. In practice, a false-color composite of the reference (dry, snow-free) backscatter and the current backscatter is built; snow pixels are detected in hue-saturation-value (HSV) space as the "magenta" hue, and isolated pixels are removed with a binary opening/closing. The resulting snow mask is applied to the S1 BFMs, like the SNW/CLD thresholds are applied to the S2 ones.

==== Flood extent mapping from satellite images <sec-flood-extent>


In order to estimate the direct economic impacts, the first step is to convert the Level 2 image into a hazard, in this case into water depth and flood duration maps. The first step in this process is to convert the image into a BFM, a raster with only 2 possible values, 1 if flooded, 0 if dry. One can then access the duration using a time interpolation described in @sec-duration, and the water depth can be obtained through a suite of algorithms described in @sec-depth.

To convert images into BFMs, we use an open-source tool called FloodML developed by CNES, with the help of CLS Group and NASA's Jet Propulsion Laboratory (JPL) @floodml. The SEICHE test case documentation lists several tools able to turn satellite imagery into BFMs, and the test data themselves come from Sentinel-1 and Sentinel-2 images processed with CNES' FloodML tool. FloodML is able to take as input any radar and optical image from Sentinel-1, Sentinel-2, Landsat-8, Landsat-9 and TerraSAR-X, and convert it into a BFM using a Random Forest algorithm. Flood masks for both sensors are shown in @bfm-s1-s2-bbox. Its interest was shown during the SCO projects FloodDAM @flooddam and FloodDAM-DT @flooddam-dt.

#bbox-figure(
  caption: [Sentinel-1 and Sentinel-2 flood masks (15 December 2019)],
  label: "bfm-s1-s2-bbox",
  "imgs/bfm_s1_bbox.png",
  "imgs/bfm_s2_bbox.png",
)

It is not the only tool able to conduct such a transformation. But recent years mainly saw the growth of machine learning (ML) and deep learning (DL) methods to get the BFM @Bentivoglio2021DeepLM, in the majority of cases using CNNs (e.g. @de2025highly). FloodML was kept as it was production-ready on CNES' high-performance computing (HPC), but more studies could be done in order to see if choosing a different tool would have an impact on the final damage estimation.




==== Flood duration interpolation <sec-duration>


To compute the flood duration from the filtered BFMs, a nearest neighbour interpolation is used: if a pixel is seen wet at date A, and dry at date B, all pixels closer to A will be counted as wet, while all pixels closer to B will be counted as dry.

Once the flood duration is computed, an aggregated BFM for the whole event can be derived from it: a pixel is considered flooded if its duration is strictly above a threshold, and dry otherwise. This BFM is not an additional input; it is the single flood extent used by DEFENDED (_Depths Estimation from a Flood Extent aNd Digital Elevation Data_), since depth estimation works on one map for the whole event rather than on a time series. The threshold (`param.bfm.flooded_threshold`, in seconds) discards pixels whose total flood duration does not exceed it, and its value is left to the user because it depends on the event, the watershed and the damage functions at hand. The duration map itself is kept as the T band of the hazard.


==== Water depth estimation <sec-depth>

To transform a BFM into a water depth map, one needs the said BFM, a DEM and an algorithm. The main idea is to subtract the DEM, the altitude of the terrain, from the free surface, the altitude of the water surface, allowing us to obtain the water depth.

A plethora of algorithms are available in order to obtain this free surface from BFMs and a DEM, often made by different people at different times, making it difficult code-wise to use all of them interchangeably. In order to streamline this process, a module called DEFENDED is under development, with the aim of concatenating already existing algorithms in a single place. It is currently part of SEICHE, but is intended to become a separate project. In its current state, it implements two families of methods, described below.

Using a BFM, the free surface can only be obtained on the edges of the inundation extent, where it is equal to the DEM, since the depth is null on the border of the flood extent. Then the free surface can be obtained on every pixel of the flood extent, using 2D linear interpolation for instance. FwDET @Cohen2018EstimatingFD works in this exact fashion. Another option is to modify the DEM to "flatten" it, to correct the elevation slope that allows the water to flow from mountains to rivers. One such method is to compute a HAND @Nobre2011HeightAT map based on the DEM, and subtract a constant, flat, free surface to obtain the water depth.


The implementations in SEICHE are based on @Teng2022ACA, more specifically on the algorithms available here @csiro. This paper also implements a TVD method that is not available as of now in DEFENDED. It works in a similar fashion to the HAND method: flatten the elevation slope from the DEM before subtracting it from a flat free surface. Other honourably mentioned algorithms include Waser developed during Vita Ayoub's PhD thesis @ayoub2022assimilation, FLEXTH, developed by the JRC @Betterle2024WaterDE, and Inflos developed by the Sertit @Poterek2025INterpolatedFS. These are not yet implemented in DEFENDED, but if the project of integrating all these methods into a single Python entrypoint is conducted, they should definitely be a part of it.



#bbox-figure(
  caption: [Water depth estimated with DEFENDED (depth in m): FwDET linear interpolation on the top row and the simple method on the bottom row, RGE-Alti on the left and GLO-30 on the right],
  label: "depth-s2-bbox",
  "imgs/depth_fwdet_l_rge_alti_bbox.png",
  "imgs/depth_fwdet_l_glo30_bbox.png",
  "imgs/depth_simple_e_rge_alti_bbox.png",
  "imgs/depth_simple_e_glo30_bbox.png",
)

For this study, we chose to keep all the available methods and run them in parallel, this way, the differences between the resulting damage estimations are a direct measure of the uncertainty induced by the depth estimation step.

=== Hydrodynamic model variables <sec-hydrodynamics>

#let hydrodynamics-conceptual-flow = (
  "---
config:
  layout: elk
---
flowchart TD

  dem1[DEM]:::input
  mesh[Mesh]:::input
  flow[River Flow]:::input
  t2d{{TELEMAC-2D model}}:::funcs
  xspeed_m[\"Velocity X-axis<br/>(x, y, t, meshed)\"]:::inter
  yspeed_m[\"Velocity Y-axis<br/>(x, y, t, meshed)\"]:::inter
  quadra_sum{{Quadratic sum}}:::funcs
  speed_m[\"Velocity <br/>(x, y, t, meshed)\"]:::inter
  depth_m[\"Water Depth<br/>(x, y, t, meshed)\"]:::inter
  freesurf_m[\"Free Surface<br/>(x, y, t, meshed)\"]:::inter
  duration_m[\"Duration<br/>(x, y, t, meshed)\"]:::inter
  thresh{{Apply threshold}}:::funcs
  time_agg_max{{\"Time aggregation<br/>(keep maximum)\"}}:::funcs
  time_agg_sum{{\"Time aggregation<br/>(sum timesteps)\"}}:::funcs
  raster{{Rasterization}}:::funcs
  depth[\"H(x, y)\"]:::inter
  duration[\"T(x, y)\"]:::inter
  speed[\"V(x, y)\"]:::inter
  freesurf[\"F(x, y)\"]:::inter
  dem2[DEM]:::input
  diff{{Difference}}:::funcs
  depth2[\"H(x, y) from<br/>free surface\"]:::inter
  hzd[Hazard 3-band raster]:::final
  hzd_from_freesurf[\"Hazard 3-band raster<br/>from free surface\"]:::final
  
  dem1 & mesh & flow --> t2d
  t2d --> xspeed_m & yspeed_m
  t2d --> depth_m & freesurf_m
  xspeed_m & yspeed_m --> quadra_sum --> speed_m
  depth_m --> thresh --> duration_m
  speed_m & depth_m & freesurf_m --> time_agg_max
  duration_m --> time_agg_sum
  time_agg_sum --> raster
  time_agg_max --> raster
  raster --> speed & duration & depth & freesurf
  freesurf & dem2 --> diff --> depth2
  depth & speed & duration --> hzd
  depth2 & speed & duration --> hzd_from_freesurf

"
    + mermaid-classes
)

#mermaid-figure(
  hydrodynamics-conceptual-flow,
  caption: [Hazard raster generation from TELEMAC-2D],
  label: "hydrodynamics-conceptual-flow",
)

@hydrodynamics-conceptual-flow shows how the TELEMAC-2D outputs are turned into the hazard raster: the damage functions need the maximum depth and velocity but the total duration, so the time aggregation keeps the maxima for #hxy and #vxy and sums #txy. 

The pixel size of the target grid can be set with `param.slf.pixel_size` (in m), documented in the configuration appendix. The mesh and the resulting hazard fields are shown in @slf-mesh-bbox and @hzd-slf.

#image-figure(
  caption: [TELEMAC-2D mesh and depth (in m) snapshot],
  label: "slf-mesh-bbox",
  path: "imgs/slf_mesh_bbox.png",
  width: 50%,
)

As proposed in @garin:hal-05033043, the #hxy field can also be obtained by taking the free surface from the model, rasterizing it, and subtracting a DEM from it to obtain a slightly different depth estimation, referenced by the `from_freesurf` in SEICHE. It can show promising results when using it with a high-resolution DEM, and its behaviour was not tested with a low-resolution one. The DEM datasets available will be described more in details in the next section.

#bbox-figure(
  caption: [TELEMAC-2D hazard fields (H in m, V in m/s, T in s)],
  label: "hzd-slf",
  "imgs/hzd_h_bbox.png",
  "imgs/hzd_v_bbox.png",
  "imgs/hzd_t_bbox.png",
  "imgs/hzd_hvt_rgb_bbox.png",
)

#pagebreak()

== DEM

The reference DEM in France is RGE-Alti, obtained via airborne LiDAR, and made by the _Institut national de l'information géographique et forestière_ (IGN). Internationally, the GLO-30 DSM from Copernicus is used. However, assessing water depth from RS should be done using a DEM rather than a DSM to evaluate how deep the water is in a given building. This data source was still kept as there was as yet no global open-source DEM alternative with a similar resolution at the time of interest. Tools like Bulldozer @bulldozer2023 could transform a DSM into a DEM automatically, but since they are still in active development we chose not to implement them for this study.

#bbox-figure(
  caption: [RGE-Alti and GLO-30 elevation comparison (elevation in m)],
  label: "dem-rge-vs-glo30",
  "imgs/dem_rge_alti_bbox.png",
  "imgs/dem_copernicus30_bbox.png",
  // "imgs/dem_diff_bbox.png",
  // "imgs/dem_diff_hist.png",
)


// @dem-rge-vs-glo30 compares the two elevation products over the same bbox: the difference is centred on zero (median = −0.12 m), with positive values on structures, vegetation and the river channel, and negative values mostly on cropland.


#pagebreak()

== Economic impacts <sec-economic-impacts>

Once the water hazard is represented, it can be combined with land cover data to estimate the resulting economic impacts.

#let damage-functions-source = (
  "---
config:
  layout: elk
---
flowchart TD
  hzd[Hazard 3-band raster]:::input
  oso23[OSO]:::input
  esawc[ESAWC]:::input
  rpg[RPG]:::input
  bdtopo[BDTopo]:::input
  sirene[Sirène]:::input
  floodam_norm{{\"Normalize to<br/>Floodam classes\"}}:::funcs
  jrc_norm{{Normalize to JRC classes}}:::funcs
  fa{{\"Floodam<br/>agricultural\"}}:::funcs
  fh{{\"Floodam<br/>housing\"}}:::funcs
  fc{{\"Floodam<br/>commercial\"}}:::funcs
  jrc{{\"JRC damage function<br/>(depth-only)\"}}:::funcs
  dmgfac[\"Damage factor <br/>(0 <> 1)\"]:::inter
  maxdmg[Maximum damage]:::inter
  mult{{Multiply}}:::funcs
  dmg[Direct economic impact]:::final

  oso23 --> jrc_norm --> jrc
  esawc --> jrc_norm --> jrc
  jrc --> dmgfac & maxdmg --> mult --> dmg
  rpg --> floodam_norm --> fa
  bdtopo --> floodam_norm --> fh
  sirene --> floodam_norm --> fc
  hzd --> jrc & fa & fh & fc
  fa & fh & fc --> dmg
"
    + mermaid-classes
)

#mermaid-figure(
  damage-functions-source,
  caption: [Land cover, damage functions and hazard],
  label: "damage-functions-flow",
)

#v(1fr)

=== Land cover <sec-landcover>

Multiple types of georeferenced datasets are relevant to this study. First, a land cover describes what kind of anthropogenic infrastructures or environments are present at every point in space. Such human constructs are differentiated into 'classes', whose number varies depending on the land cover. Products specialized in a subset of the land cover often exist, being destined for specific applications. Similarly, the DSM records the absolute altitude with infrastructures, while the DEM does so without them. The last land description needed here is population maps, usually giving the number of people per pixel or polygon. 

#v(1fr)
#pagebreak()

A plethora of datasets exist; the selected ones are referenced in @tab-land-description. This choice is motivated by the will to recreate the standard conditions in which damages are assessed using French national datasets, and state-of-the-art global products.

#figure(
  kind: table,
  caption: [Land description datasets (acronyms defined below)],
)[
  #set par(justify: false)
  #table(
    columns: (auto, 20%, 20%, auto, auto, auto),
    align: left + horizon,
    table.header([Dataset], [Intent], [Resolution], [N\# classes], [Extent], [Updates]),
    [BDTopo], [Housing / Public], [Polygons], [12], [France], [periodic],
    [RPG], [Agriculture], [Polygons], [73], [France], [yearly],
    [Sirène], [Companies], [Points], [458], [France], [periodic],
    [Filosofi], [Population], [200 m], [--], [France], [2-yearly],
    [RGE-Alti], [DEM], [1 m], [--], [France], [sparse],
    [OSO], [Exhaustive], [10 m], [23], [France], [yearly],
    [ESAWC], [Exhaustive], [10 m], [11], [World], [yearly],
    [GHSL-POP], [Population], [100 m], [--], [World], [5-yearly],
    [GLO-30], [DSM], [30 m], [--], [World], [2011 (single)],
  )
] <tab-land-description>

In France, the trio _Base de Données TOPOgraphique_ (BDTopo) / _Registre Parcellaire Graphique_ (RPG) / _Système national d'Identification et du Répertoire des ENtreprises et de leurs Établissements_ (Sirène) is a common way of describing the vast majority of the assets that could be impacted by floods. BDTopo is made and distributed by the IGN and, while it contains more categories, it is used here to describe housing and public services buildings. RPG is also issued by the IGN, and is specialized in mapping all agricultural parcels. Finally, Sirène is a database produced by the _Institut national de la statistique et des études économiques_ (INSEE) and designed to register companies and industries (see @lcv-assets-bbox).

Idiosyncratic limitations of these land description datasets are to be taken into account. The BDTopo buildings do not describe basements, so housing damages are probably underestimated; For houses on a slope, the damage functions would need the depth at the lowest (semi-buried construction) or highest (stilted construction) point of the building, but since this information is not available, the mean depth is used. Information on the flood duration would also be needed, since stilted houses are less exposed; The French land registry files, which could provide basement information, were not used; the building surface comes from the geometry, and for companies from the Sirène data; The datasets have different vintages: the Sirène workforce bracket is the one of December, two years before, and the RPG of the year before the event; When a company's estimated workforce exceeds a estimated threshold of  1.5 M€, the Floodam guidelines require a more detailed analysis; in that case, either a minimal value of 1.5 M€ is used, or the company is set aside, left to the user to decide. However, despite all these limitations, they are the most precise datasets available.

For a spatially continuous population census, not tied to city or department boundaries, the Filosofi dataset, also provided by the INSEE, is used. On top of a population count, it also provides additional information on socio-demographic indicies like approximative revenue, and age. 

The European Space Agency World Cover (ESAWC) is a common product for exhaustively describing the land at a 10 m spatial resolution. However, it contains only 11 classes, 2 of which are used here for flood impact estimation: Built-up (50) and Cropland (40). Having a low number of classes means more averaging and probably leads to a lower assessment precision. A more promising product for our purpose is the Occupation du SOl (OSO) provided by the _Centre d'Études Spatiales de la BIOsphère_ (CESBIO). It contains 23 classes, describing in more detail human settlements at the same 10 m resolution (see @lcv-oso-esawc-bbox). Its methodology being based solely on remote sensing data, it could in principle be generated anywhere on Earth, but at the time of this study it was only generated in France. 

Population-wise, the Global Human Settlement Layer (GHSL) POPulation product, GHSL-POP, records and predicts up to 2030 the number of people per 100 m pixels, worldwide; it is produced by the JRC. 

#bbox-figure(
  caption: [OSO 2019 and ESAWC 2020 land cover],
  label: "lcv-oso-esawc-bbox",
  "imgs/lcv_oso_bbox.png",
  "imgs/lcv_esawc_bbox.png",
)

#bbox-figure(
  caption: [BDTopo, RPG and Sirène assets],
  label: "lcv-assets-bbox",
  "imgs/lcv_assets_bbox.png",
)

#bbox-figure(
  caption: [GHSL-POP (left) and Filosofi (right) population (population count per cell)],
  label: "pop-ghsl-filosofi-bbox",
  "imgs/pop_ghslpop_bbox.png",
  "imgs/pop_filosofi_bbox.png",
)

=== Floodam damage functions

In France, the reference damage functions are generated using an R library, Floodam, developed at the _Institut National de Recherche pour l'Agriculture, l'alimentation et l'Environnement_ (INRAE) G-EAU lab, and distributed by the French Ministry of Ecology @floodam-data. The hydraulic inputs are #hxy, the maximum water depth event-wise, #txy the flood duration, and for agricultural damages #vxy the maximum velocity. For each land cover category, or class, one function is available. They are tailored to be used with BDTopo, Sirène and RPG, hence the fact that they roughly have the same classes. The damages are given in € as of 2016, written as €2016. The raw data can be found on the website of the French Ministry of Ecology @floodam-data, while the official methodological guide (2018) for this tool can be found here @floodam-guide.

For Floodam, we use the exported functions provided by the French Ministry of Ecology (see the link below), and for the JRC functions we use the default set of parameters. This choice reflects the will to assess the impacts with the standard, reference setup: changing the parameters could lead to more precise estimates, but would require case-specific information that we do not have in the general case. There is also work to do in order to bring the costs up to date: the Floodam damages are given in €2016, and the JRC ones in €2010, and neither is updated to account for inflation. For Floodam this can be done by following the damage functions' user guidelines and using data from the INSEE. Note that for agricultural damage functions, some categories that seem qualitative point to actual fixed ranges, which are described in the previously mentioned guide. The flood duration classes are given in @tab-duration-classes, and the flow velocity classes in @tab-velocity-classes: both have fixed boundaries in days and m/s respectively (tables from @floodam-guide).

#figure(
  kind: table,
  caption: [Flood duration classes (duration in days) from @floodam-guide],
)[
  #image("../imgs/tab8.png", width: 100%)
] <tab-duration-classes>

#figure(
  kind: table,
  caption: [Flow velocity classes (velocity in m/s) from @floodam-guide],
)[
  #image("../imgs/tab9.png", width: 100%)
] <tab-velocity-classes>

=== JRC damage functions

While Floodam functions are only available for France, the JRC developed global depth-damage functions, meaning one can assess direct flood damages everywhere, only needing #hxy @huizinga2017global. It comes at the cost of precision: there are only six land cover categories -- housing, industrial, commercial, agriculture, transport, infrastructures/roads -- derived at the scale of a country. They could miss some specific or endemic impacts, but at least allow one to have a sense of magnitude. The estimated costs are given in €2010.

The same reasoning applies to the JRC functions, whose maximum damage values are country-dependent and could be updated with the evolution of the relative GDP.


The JRC functions come from the global database of Huizinga et al. @huizinga2017global. It covers countries on all six continents, for six damage classes: housing, industrial, commercial, agriculture, transport, and infrastructures/roads. The depth-damage curves are defined per continent, while the maximum damage values are set at the country scale.

In SEICHE, these functions can be applied to a land cover raster, in which case the damage is computed for each pixel. @dmg-bbox compares this setup with the Floodam one on the same 2×2 km box centred on Couthures-sur-Garonne: on the left, damages estimated with Floodam on BDTopo buildings, Sirène establishments and RPG parcels, with the colourbar in €2016 per vector; on the right, damages estimated with JRC on ESAWC pixels, with the colourbar in €2010 per pixel. Both panels share the same logarithmic colour scale.

#bbox-figure(
  caption: [Floodam (€2016) and JRC (€2010) damage estimates on the same 2×2 km box],
  label: "dmg-bbox",
  "imgs/dmg_hf_bbox.png",
  "imgs/dmg_jrc_esawc_bbox.png",
)

#pagebreak()

== Social impacts <sec-social>

Assessing direct social impacts is less straightforward. Whereas direct economic impacts are directly given by the damage functions, there is no equivalent abacus for social impacts: the only possible approach is to filter a population raster by hazard conditions, which gives a statistical estimation of the number of people exposed, not of the number of casualties or injuries.

#let population-flow-source = (
  "---
config:
  layout: elk
---
flowchart TD
  hzd[Hazard 3-band raster]:::input
  ghsl[GHSL-POP]:::input
  fil[Filosofi]:::input
  cond[Conditions on H, V, T]:::input
  social{{Affected population filtering}}:::funcs
  out[Affected population per condition]:::final

  hzd --> social
  ghsl --> social
  fil --> social
  cond --> social
  social --> out
"
    + mermaid-classes
)

#mermaid-figure(
  population-flow-source,
  caption: [Population filtering by hazard conditions],
  label: "population-flow",
)

=== GHSL-POP

GHSL-POP is the population layer of the GHSL, produced by the JRC @ghslpop2023. It gives the number of residents per cell on a global grid at 100 m resolution, for epochs every five years from 1975 to 2030; the 2025 and 2030 grids are projections, while the earlier ones are estimates for the corresponding epoch @ghsl2023report. Values are population counts, so summing the cells over an area gives the total population of that area. The left panel of @pop-ghsl-filosofi-bbox shows the 100 m grid over the Marmande test case.

The product is not a direct census. Census data harmonized by the Center for International Earth Science Information Network (CIESIN) for the Gridded Population of the World (GPW, v4.11) are disaggregated to the grid using the distribution and volume of built-up area mapped by the GHSL, so that people are placed where buildings are @ghsl2023report. The product is global, so it can be used outside France; but it is a modelled disaggregation rather than a census count, and it carries no demographic structure beyond a count per cell.

In SEICHE, GHSL-POP is the global population input, used in particular for the test cases outside France. The hazard conditions are evaluated on each 100 m cell, and the population of the cells that satisfy the condition is summed. In practice, the epoch should be chosen as close as possible to the event date; the 2025 and 2030 grids are projections and should be used with care.

=== Filosofi

Filosofi (Fichier Localisé Social et Fiscal) is the French localized income and poverty dataset produced by INSEE @filosofi. It provides indicators on household disposable income, poverty and income structure at infra-communal level. For spatial analysis, INSEE distributes a 200 m grid in which each square gives the number of individuals, households and poor households, along with age structure, housing characteristics and income variables @filosofi-carroye. The right panel of @pop-ghsl-filosofi-bbox shows this grid over the same box as the GHSL-POP panel.

The 200 m grid is the smallest scale at which INSEE diffuses these data: when a square contains fewer than 11 tax households, its values are imputed and flagged, so that the user knows which cells are not directly observed @filosofi-carroye. The grid covers metropolitan France, Martinique and La Réunion, and INSEE has published it for 2015, 2017, 2019 and 2021 @filosofi-carroye @filosofi-carroye2021. Filosofi 2 replaces the Filosofi system from the 2023 vintage @filosofi.

In SEICHE, Filosofi is the national population input used for the French test cases. It is used at the 200 m cell level: a cell is counted in full as soon as it is touched by water, which is a coarser approach than GHSL-POP and gives a generally higher affected population, as the St-Omer results show. The current conditions only use the population count; the socio-demographic variables are not used.

#pagebreak()

=== Conditions

The easiest way of assessing the direct social impacts of a flooding event, or any disaster for that matter, is to filter a population raster based on some conditions on the hazard.

For example we might want to count all people in the flooded area. In this case, given a 3-band raster containing #hxy the max water depth, #vxy the max water velocity and #txy the flood duration at every point of our area and time of interest, we can select all pixels from a population raster (such as GHSL-POP) on which $H > 0$.

But we might also want to be a bit more precise and check super hazardous areas, where $H > 1.5 "m"$ and $V > 3 "m/s"$ for example. It is up to the user to define these conditions; they are given as boolean expressions on `h`, `v` and `t` in the SEICHE configuration (see @conditions-example):

#figure(
  caption: [Example hazard conditions],
)[
  ```yaml
  param.pop.conditions:
      always_true: "True"
      is_above_30cm: "h > 0.3"
      is_touched_by_water: "h > 0"
      my_specific_condition: "(h > 0.4) | (v > 1.5 & t > 86400)"
  ```
] #make-label("conditions-example")

The expressions are evaluated safely as a subset of Python, with only `h` (depth in m), `v` (velocity in m/s) and `t` (duration in s) available, as well as `True`, `False` and the boolean operators. For each expression, a new dataset with data filtered based on this condition will be produced, allowing great freedom and the exploration of a wide range of conditions when trying to assess the social impact of a flooding event in this manner.

The affected population is then computed by masking the population dataset with this condition, and summing the population values of the cells that are kept: for a raster population (GHSL-POP), only the pixels where the condition holds are kept; for Filosofi, which is handled as a table of 200 m grid cells, only the rows where the condition holds are kept.

== Test cases

SEICHE is applied to several spatial extents and events, shown in @test-cases-map, to test its capabilities and versatility. The Marmande, St-Omer, Chinon, Ohio, Tonle Sap and Nokoué extents. This section will succinctly describe the data for the test cases, as well as some specific caveats depending on the event. The primary focus is on describing the specificity of the flooding events that we decided to test SEICHE on and the reasons that motivated these choices; a full discussion of the results, of all the uncertainties leading to the final result, and of the scientific implications of such findings is left out, as it would be enough to fill one or more academic papers. A few preliminary observations on the uncertainty of the pipeline are nevertheless included, to provide a technical baseline for the conclusion. The input files, archive paths and download URLs for all test cases are listed in #ref(<data-sources>, supplement: [Appendix]).

#image-figure(
  caption: [SEICHE test case locations],
  label: "test-cases-map",
  path: "imgs/test_cases_map.png",
  width: 100%,
)

#pagebreak()

=== Marmande

The Marmande test case is the first one that was set up for SEICHE: it is an historical extent on which a lot of TELEMAC-2D simulations were run over the last years, at Cerfacs, through the work of Sophie Ricci, and her associated PhD students and collaborators. Through recent collaboration with the CNES, satellite imagery was used to validate the 2D models, as well as being assimilated by them, making it ideal to compare 2D models to remote sensing imagery in terms of damage estimation. Moreover, since it is in France, the very high resolution French dataset from the IGN and INSEE as well as the damage functions from the INRAE are available, allowing us to compare it to global datasets such as the ESAWC, OSO, GHSL-POP, and JRC damage functions. There were major flooding events in 2019, 2021, 2022 and even 2026 allowing us to have multiple analyses to conduct. The only downside -- in terms of analysis capability, not moral -- is that the flood damages were primarily agricultural, neither urban nor industrial nor commercial, and with little ground data to compare the computation outputs to.

==== Comparative analysis of TELEMAC-2D models on agricultural flood damage estimates

The comparison summarized here comes from a conference paper by #cite(<garin:hal-05033043>, form: "prose"), presented at the XXXth Telemac User Conference (8th to 10th of October 2024, Chambéry, France). It compares damage estimates produced by two different hydrodynamic models of the Garonne River, near Marmande, and studies the influence of a topo-bathymetry projection method on these estimates.

The underlying question is how sensitive the final damage output is to the water hazard inputs, given that damage functions are themselves not very precise. The conference paper was a first attempt at answering it, and the same question arises in the paper of #cite(<Sieg2022ImprovingFI>, form: "prose"): what kind of land cover and water hazard precision do we need in order to make good enough damage estimates?

Two methodological refinements were identified after publication, and are now implemented in the pipeline. The first concerns the RPG vintage: the RPG database is offset by one year, meaning that the RPG 2020 holds data for the agricultural fields present in 2019. The conference paper assumed that the 2019 version was to be used for the 2019 event. This does not affect its findings, since this area of France, between Tonneins, Marmande and La Réole, is not prone to quick land cover changes, and both models were always evaluated on the same RPG database, differing by one year. The second, and more important, concerns the classification of the flood duration into the 'short', 'medium', 'long' and 'very long' categories required by the damage functions. The conference paper defined these categories from the event's own quantiles, whereas the damage functions expect fixed ranges, given in days in the methodological guide of the French Ministry of Ecology (respectively 0-1, 2-4, 5-10 and 11-20 days, as shown in @tab-duration-classes).

The `marmande_2019` test case holds the data needed to reproduce the study. A re-edition of the conference paper accounting for these refinements, with updated figures and tables, was planned but not pursued because of lack of time. The refinements are not expected to change the findings substantially, but this remains to be checked: the results of the SEICHE pipeline applied to the `marmande_2019` test case should be compared to those of the paper before drawing further conclusions.

#pagebreak()
=== St-Omer

To account for Marmande's lack of ground data, urban, commercial and industrial impacts, a flood near the city of St-Omer, in the North of France, was studied. Between late 2023 and early 2024, two major overflowing flood peaks were observed (one in November, one in January, see @insitu-stomer), as well as other more localized rising water table and runoff floods throughout the period.

#image-figure(
  caption: [Some relevant stations in-situ water levels in m (HydroPortail @hydroportail)],
  label: "insitu-stomer",
  path: "imgs/insitu_stomer.png",
  width: 100%,
)

One of the major limitations of damage estimations using such methods is the verification of, at least, the orders of magnitude of the estimated impacts. For this, one needs ground truth, or at least an official and verified source of comparison. The major motivation behind the choice of this test case is this availability of ground data. At a regional scale of the _Hauts-de-France_ region, an official assessment report was published @prefecture, which contains, mostly in its section 1.3, aggregated statistics to which we can compare our damage estimations.

At the local scale of their watershed (depicted in @bv_smageaa), the SmageAa (_Syndicat Mixte pour l'Aménagement et la Gestion des Eaux de l'Aa_) @smageaa contacted inhabitants, business owners and industrials to register how much was lost.

#image-figure(
  caption: [The SmageAa watershed],
  label: "bv_smageaa",
  path: "imgs/bv_smageaa.jpg",
)

They kindly made available their _Retours d'EXpérience_ (REX) GIS database, which was built based on testimonies from local mayors and municipal councillors. The latter were asked to draw on maps with the help of SmageAa technicians to identify flooded areas, roads, buildings and runoff axes, after the events. They are still in the process of gathering testimonies from industrial groups, meaning this ground data is not yet available at the time of publication. This dataset is not open as of now, since it lacks some data and needs cleaning and formatting, but can be obtained on request to the technicians of the SmageAa, since it is meant to be widely available in the end.


#image-figure(
  caption: [Flooded areas, roads and buildings by flood type],
  label: "rex_flood_types_map",
  path: "imgs/rex_flood_types_map.png",
  width: 100%,
)



The REX database is made of four layers:

/ FA: (_Flooded Areas_): time-located polygons (1 to 2 days precision) that also indicate the category of the flooding event, among overflowing, runoff, rising water table, and mixed categories.
/ FR: (_Flooded Roads_): line segments of flooded roads, with the same categories and time precision.
/ FB: (_Flooded Buildings_): points of flooded buildings, with the same categories and time precision.
/ RA: (_Runoff Axes_): lines indicating the runoff axes observed during the events.

#pagebreak()

@rex_flood_types_map shows that along the minor bed of the river, the majority of the flooded areas are of the overflowing type, while runoff is logically more concentrated along the slopes. Some other types of flood are represented, yet marginal in comparison to these two. The flooded areas drawn by the SmageAa cover about 23 km² in total, with 3,377 flooded buildings and 287 km of flooded roads.

#image-figure(
  caption: [Temporal distribution of flood types],
  label: "rex_flood_types_timeline",
  path: "imgs/rex_flood_types_timeline.png",
  width: 100%,
)

Two main flooding episodes stand out in the REX database, as shown in @rex_flood_types_timeline: the first one in early November 2023, and a second one in early January 2024, similar to what is observed in @insitu-stomer. In both episodes, the overflow of watercourses is by far the dominant mechanism, both in flooded area and in number of flooded buildings, while runoff and rising water table play a smaller role.

However, in terms of hydrodynamic modelling, only satellite-derived flood masks were available. Since the overflowing events spanned a few months, the 5-day (S2) or 12-day (S1) revisit interval of the remote sensors should be partly compensated. It is a good test of the capabilities of SEICHE to assess impacts solely based on this degraded water hazard source. Possibilities of developing a hydrodynamic TELEMAC-2D model on this extent, to further enhance the range of data available and allow us to compare SEICHE's estimations made with a hydrological model to ground truth, are in discussions. At the time of writing this report, it was not yet available for me to run SEICHE on.

Scientifically, the St-Omer test case can also allow us to test how, even when only based on a remote sensing derived flood mask, the estimations can be improved through local data. Indeed, since it is on French soil, the more precise damage functions from the INRAE and datasets from the INSEE and IGN are available, and can be compared to the global ones, directly to ground truth.

==== Preliminary observations

The first lesson of the St-Omer test case is that *this pipeline is highly uncertain*: to access #txy and #hxy using satellite-only methods, at least 4 or 5 steps are required (BFM inference, cloud/snow filtering, time interpolation, depth estimation, then damage functions and land cover), each accumulating its own uncertainties. This is the major drawback of such a method. This uncertainty cascade is already present in the Marmande test case when using hydrodynamic models, but magnified when using RS-dervied flood depths (which also cannot provide water velocity). 

On the other hand, the flood extent itself is reasonably estimated: the FwDET linear interpolation yields about 18 km² of flooded area, against 23 km² drawn by the SmageAa, and the number of flooded buildings (7,379 with a non-zero depth) is of the same order of magnitude as the 3,377 of the REX database, even if twice as much overestimated.

#pagebreak()

*If at least one of the 3 (rapidity, globalization, openness) is not needed, what are the alternatives for impact estimation?* Several paths exist, each giving up on one of the pillars:

- (_Not globalized_) Using open national data (RGE-Alti, Floodam, BDTopo/Sirène/RPG) and observations (in-situ), maybe 1D models, etc. This is the enhanced version of the pipeline described above, and is the one giving the most precise results of the two;
- (_Neither globalized nor rapid_) TELEMAC-2D to which we assimilate the satellite images gives good results but at a super high computing cost;
- (_Neither globalized nor open_) Data from insurance companies. For example with the Cat-Nat compensation scheme in France, the amounts are known merely days or weeks after an event, but behind closed doors;
- (_Neither globalized nor rapid_) Ground truth for government bodies: two years after the event, the SmageAa is still gathering data, and the REX layers are not always perfectly coherent with each other.

This last point leads to the conclusion that *satellite-based impact estimation methods are useful in niche conditions*: there is no other alternative that is open, rapid and global. The ground truth itself took two years to gather, the insurance data is private, the 2D hydrodynamic models are costly, and the national data is French-only. The satellite pipeline is therefore the only method that can give an order of magnitude of the impacts, anywhere on Earth, in a matter of days. But this comes with a big question mark on the precision, as shown above.

==== Planned comparisons

An interesting comparison is to check the pipeline against itself rather than against the ground truth: for example, plotting the proportion of flooded pixels against time can reveal a dynamic that could help identify flooded areas even without external validation. Another reference source for this event is the Copernicus Emergency Management Service rapid mapping activation EMSR706 @emsr706, which provides an independently derived flood extent. This direction is still being explored. Comparisons with a TELEMAC-2D simulation on the same extent, when available, as well as with the in-situ water levels of the watershed, are the natural next step to validate the hazard fields independently of the damage functions.

=== Chinon

The Chinon test case is a second French extent, on the Loire River, on which the hydrodynamic branch of SEICHE can be fully exercised. As part of Q. Bonassies' PhD thesis @bonas2026, TELEMAC-2D simulations were launched on this extent, with a lot of work done in terms of data assimilation, using Ensemble Kalman Filter (EnKF) methods and multiple data sources. All these simulations can be used as input for the flood damage estimation, allowing us to test their relevance in terms of flood risk assessment and to ask the question: does this extra precision acquired through data assimilation make a difference in the final impact assessment given the other uncertainties of the pipeline?

The _in-situ_ data comes from the French VigiCrue stations network, and Sentinel-1 satellite images for remote sensing, unless "SWOT" is mentioned, in which case it was the SWOT (Surface Water and Ocean Topography) satellite. SWOT provides data at given nodes of a hydrographic network, allowing it to be assimilated either as _in-situ_ or, using the derived flood extents, as remote sensing. The assimilation metrics are the Wet Surface Ratio (_WSR_) derived from satellite imagery, and the Chan-Vese segmentation method (_CV_, still under development). The _nodh_ suffix indicates that the EnKF assimilation adjusted only the friction coefficients and upstream flow, and did not manually add or remove water during assimilation, unlike standard practice. For additional technical details on the data assimilation setup, refer to Q. Bonassies' PhD thesis.

@chinon-runs summarizes the runs used in this test case, which can be used as inputs for SEICHE: each of them is fed to the pipeline as an `.slf` input, and the resulting damage estimations can be compared between assimilation modes. The run names are prefixed by the assimilation mode (IDA for in-situ data assimilation, RSDA for remote sensing data assimilation, FDA for full data assimilation) and suffixed by the assimilation metric (_WSR_ or _CV_).

#block(breakable: false)[
  #set text(size: 9pt)
  #table-figure(
    caption: [Chinon simulations used as SEICHE inputs],
    label: "chinon-runs",
    columns: (17%, 15%, 20%, 17%, 31%),
    inset: 4pt,
    [Run name],
    [Assimilation mode],
    [Data source],
    [Assimilation metric],
    [EnKF configuration],
    [Free Run],
    [No assimilation],
    [N/A],
    [N/A],
    [N/A],
    [IDA],
    [In-situ],
    [VigiCrue stations],
    [Standard],
    [Standard],
    [IDA_CV],
    [In-situ],
    [VigiCrue stations],
    [Chan-Vese],
    [Standard],
    [IDA_swot],
    [In-situ],
    [SWOT (as in-situ)],
    [Standard],
    [Standard],
    [IDA_swot_CV],
    [In-situ],
    [SWOT (as in-situ)],
    [Chan-Vese],
    [Standard],
    [RSDA_WSR],
    [Remote sensing],
    [Sentinel-1],
    [Wet Surface Ratio],
    [Standard],
    [RSDA_CV],
    [Remote sensing],
    [Sentinel-1],
    [Chan-Vese],
    [Standard],
    [RSDA_swot_WSR],
    [Remote sensing],
    [SWOT (as remote sensing)],
    [Wet Surface Ratio],
    [Standard],
    [RSDA_swot_CV],
    [Remote sensing],
    [SWOT (as remote sensing)],
    [Chan-Vese],
    [Standard],
    [FDA_WSR],
    [Full],
    [VigiCrue + Sentinel-1],
    [Wet Surface Ratio],
    [Standard],
    [FDA_CV],
    [Full],
    [VigiCrue + Sentinel-1],
    [Chan-Vese],
    [Standard],
    [FDAnodh_WSR],
    [Full],
    [VigiCrue + Sentinel-1],
    [Wet Surface Ratio],
    [No manual water adjustment],
    [FDAnodh_CV],
    [Full],
    [VigiCrue + Sentinel-1],
    [Chan-Vese],
    [No manual water adjustment],
  )
]


#pagebreak()

=== Ohio River

The Ohio test case is a non-French extent, used to test the globalizability of the pipeline: the only inputs are global datasets (GHSL-POP, GLO-30 DSM, JRC damage functions, ESAWC land cover) and a TELEMAC-2D simulation, without any French national data. As documented in the test case documentation @seiche, two events are considered. The 2018 event uses a TELEMAC-2D run with Ensemble Kalman Filter in-situ data assimilation, and the GHSL-POP 2020 population raster (see #ref(<data-sources>, supplement: [Appendix])). The 2025 event was used for testing purposes only, but they should be removed and at least not taken seriously for any scientific purpose; since, as noted in the documentation, the simulations of this event have a known issue. The Ohio 2025 runs available are the free run, the IDA and RSDA runs, with the GHSL-POP 2025 raster (see #ref(<data-sources>, supplement: [Appendix])). The results of this test case are not discussed further here: its purpose is to check that the pipeline runs end-to-end on a non-French extent with only global data.

=== Tonlé Sap

|| TODO ||

=== Nokoué

|| TODO ||