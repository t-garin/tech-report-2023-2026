#align(horizon)[
  #v(1fr)

  #set text(size: 30pt, font: "Fraunces")
  *Technical Report*

  #set text(size: 19pt)
  _Exploring the quantification of floods' \
  immediate social and economic aftermaths \
  through satellites, hydrodynamics and agents_ \

  #set text(size: 12pt, font: "Atkinson Hyperlegible")
  #rect(inset: 5mm, width: 100%)[
    #heading(level: 2, outlined: false, numbering: none)[Abstract]
    Floods are among the most devastating natural disasters, and their immediate consequences must be understood to design efficient mitigation policies. This report summarizes three years of work on the quantification of the direct socio-economic impacts of flooding, from satellite imagery, hydrodynamic models and agent-based simulations. It mostly presents SEICHE, an open-source data pipeline that converts flood hazard sources -- satellite-derived flood masks or 2D hydrodynamic simulations -- into hazard rasters of water depth, velocity and duration, and then into economic damage and affected population estimates, using global or French damage functions and land cover data. In a last chapter, the report explores agent-based modelling as a way of building social damage curves, with a proof-of-concept coupling a flood solver with an evacuation model.
  ]

  Théo GARIN #footnote[Centre National d'Études Spatiales (CNES), Toulouse, France] <affectation_CNES> #footnote[CECI (UMR 5318 CNRS/CERFACS/IRD), Toulouse, France] <affectation_CECI> #footnote[Université Toulouse - Jean Jaurès, Toulouse, France] <affectation_UT2J>


  Sophie RICCI @affectation_CECI #h(0.5em) Sébastien LE CORRE @affectation_UT2J \ Raquel RODRIGUEZ-SUQUET @affectation_CNES #h(0.5em) Ludovic CASSAN @affectation_CECI

  2023 --- 2026

  #v(2fr)
]
