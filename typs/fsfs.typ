#import "../defs.typ": image-figure, mermaid-classes, mermaid-figure, table-figure

= Agent-Based Modelling for Building Social Damage Curves

In the previous chapters, there was a lack of insights on social damages: it seems that the most we could do population-wise, while focusing on the rapidity, openness and globalization of the method (see @seiche-objectives), was to count the pixels of a population density map.
It is a good first rough estimate but lacks a lot of comprehension of the mechanisms, dynamics, land-use evolution and protection measures that, in the end, protect people from dying or getting injured, or not.
One way of obtaining such insights is to conduct experiments, which is hard with real floods, or to have sufficient data on real events, which is not the case: the ground truth takes years to gather, and often remains partial in the end.

This is why, for a few years now, scientists have been developing more and more agent-based models (ABMs) to study the emergent properties of social groups in a lot of contexts, including emergency response to flooding, based on individual behaviour.
It is a synthetic way of obtaining insights on evacuation dynamics that cannot be observed in the field.
It is very parametrizable and adaptable to a specific city, event or culture, which is clearly lacking when counting the affected pixels from a population density map.
However, they are in need of local expertise to construct plausible rules that the agents -- here humans -- would follow; and they are often heavy in terms of necessary computing time.
They could be used directly to assess the social cost of a flooding event, but they would need to be run after each event, which can be slow and/or costly.


Economic damage functions on the other hand are an outstanding tool for quickly assessing direct impacts of flooding.
To make a computer science metaphor, it is a "compiled" tool that doesn't require the user to know the "source code" to use it, as long as one is following the guidelines.
It is also super fast, making it a very efficient tool for quick estimations.
They are not without downsides of course: they are built on average behaviours, are only as good as the data they were fitted on, and give no information on the processes that lead to the damage.
But given the objectives of SEICHE and the work conducted over the last three years, having a fast, open and global tool for assessing population damages is worth a loss of precision.
This chapter is born out of the wish of having similar kinds of curves for assessing the direct social impact of flooding.
For a specific setting, these curves could give the proportion that got injured, that safely found a shelter, and the proportion of unfortunates that died. The main idea is to use such ABMs to generate "social" damage curves.
They would be analogous to their economic counterpart, as empirical abacuses linking a single hydraulic variable or an ensemble of hydraulic variables to an impact metric, here, for example, the number of injured or dead people. To our knowledge, the systematic use of ABMs to generate compiled social damage curves (SDCs) is not widely documented; empirical fatality curves do exist (e.g. @jonkman2008methods, @dekay1993, @yazdani2023).
ABMs are widely used to understand the social dynamics of flooding disasters and to uncover insights from them, but, to our knowledge, not as a way to generate compiled tools equivalent to damage functions.
But they have huge potential to simulate ahead-of-time scenarios in specific settings, with different hydrological inputs, land covers, public policies and so on, even allowing one to characterize the underlying internal variability by running scenarios multiple times with a different random seed each time.
Then, by picking relevant parameters that can vary in real life situations, we can generate the SDCs associated with them. For example we can run the ABM on multiple water flow inputs, and record for each flow the number of simulated dead people, giving us a one-dimensional SDC that links water flow to the death toll.
For this purpose a proof-of-concept (POC) named _"Flooding Sims For Science"_ (FSFS) #footnote[That should probably be renamed to avoid copyright lawsuits from Electronic Arts.], was developed in Julia. The code is barely a prototype but shows the potential of this method.
However, it needs to be scientifically validated, which is always a steep step with ABMs or hydrodynamic models.
But it can hopefully sow some ideas on how to build SDCs.

== Literature review

Agent-based models of human behaviour in floods are a well-established line of work, and most share the same architecture: a hydrodynamic model produces flood fields that feed a population of agents, who perceive the flood, decide whether to evacuate, and move through the simulated city. Early flood evacuation models already simulated the acceptance of evacuation orders and the time needed to reach safety: Simonovic and Ahmad @simonovic2005 used a system dynamics approach to do so. Dawson et al. @dawson2011 coupled an ABM of human response to a flood with a hydrodynamic model, in which agents respond to warnings by evacuating to the nearest shelter or continuing their routine, and used it to evaluate flood warning and shelter siting in Towyn, North Wales. The authors describe their model as a tool for studying the aggregate response of the whole system rather than a precise predictor of individual behaviour @dawson2011. O'Shea et al. @oshea2020 built a coupled hydrodynamic agent-based model of Carlisle to test how direct and indirect (word-of-mouth) warnings change evacuation behaviour, and likewise present it as a way to visualise individual and group interactions and potential casualties over repeated simulations, not as a fully predictive tool @oshea2020.

Liu and Lim @liu2018 coupled a city-scale evacuation ABM to a validated hydrodynamic model for the 2011 Brisbane flood, and Mas et al. @mas2012 integrated a tsunami inundation model with an evacuation ABM for the 2011 Great East Japan event; 1,000 stochastic evacuation simulations gave a mean evacuation rate of 82.1% (SD 3.0%), consistent with the reported 90% evacuation and 520 sheltered evacuees @mas2012. Shirvani et al. @shirvani2021 went further and coupled the flood model with a pedestrian model in both directions, so that evacuees locally modify the flow; they found that accounting for this local effect can substantially change the flood impact on the evacuees themselves @shirvani2021. They rate the danger to people with the hazard rating $H_R = (V + 0.5) H$ (H the water depth in m, V the flow velocity in m/s), the mechanics-based criterion of the UK Environment Agency risk-to-people method @shirvani2021. Abebe et al. @abebe2019 extended the coupling to institutions with their coupled flood-agent-institution modelling (CLAIM) framework, and Zhang et al. @zhang2024evac built an ABM with three sub-modules -- early warning, social and flood -- and applied it to the 2021 Liulin flash flood. 

More recently, Silva et al. @silva2025ahr used the LifeSim ABM to reconstruct the 2021 Ahr Valley flood and compare simulated and observed losses. Not all models couple to a hydrodynamic model: Addai et al. @obeng2025 built Flood-ABM for the Inglewood community of Calgary, an ABM that represents individual and collective behaviour before, during and after the flood, and separates population groups with a socio-economic index combining age, education, gender, ethnicity and income to set each agent's vulnerability; agents follow four decision-making theories (protection motivation, planned behaviour, cultural risk and social capital), and the flood input comes from real inundation maps published by government agencies rather than a hydrodynamic model @obeng2025.

These models answer what-if questions for a specific city or event; they are not designed to be reused. Even in the most curve-like case, Dawson et al. note that the model can build exposure functions that quantify how many people are exposed to flooding in different events @dawson2011 -- but the exposure of the population, not the damage it suffers -- and add that some behavioural rules may be generalised while others must be re-evaluated case by case @dawson2011. Addai et al. make the same point from the other side: although their study is set in Calgary's Inglewood community, the Mesa-GIS pipeline can be re-parameterised for other places, but adapting it still means swapping in local socio-economic distributions, re-tuning the cultural and trust priors, and loading the relevant infrastructure layers @obeng2025.

Chiew et al. @chiew2022 review ABM applications to integrated flood management and find the approach well suited to simulating human decision-making and behaviour in the social context of flood systems. The systematic review of Senanayake et al. @senanayake2024, covering 134 agent-based pedestrian evacuation studies, identifies persistent problems with modeller bias, computational cost, scarce calibration and validation data, and the dominance of simple rule-based decision models; it also finds that validation relies mostly on a few real-world experiments, drills and expert judgement, with few quantitative benchmarks or standard protocols. Breen et al. @breen2025 show that coupled human-flood ABMs can reveal long-term socio-hydrological feedbacks: during the latency phase, coastal protection can encourage population growth in residual-risk areas, increasing long-term exposure, although these models are still built for specific coastal case studies.

The closest existing thing to a compiled social damage curve comes not from the ABM literature but from loss-of-life estimation. Jonkman et al. @jonkman2008methods reviewed the estimation methods and proposed a death-rate model relating mortality to flood characteristics, based on more than 165 locations drawn from 11 events. Mortality is the ratio of fatalities to the exposed population, and the number of fatalities is estimated as $N = F_D N_"EXP"$. The flooded area is split into zones: in the breach zone, mortality is taken as 1 when $H V >= 7 "m"^2"/s"$ and $V >= 2 "m/s"$; in the zone with rapidly rising water, mortality follows a lognormal function of depth, $F_D (H) = Phi [(ln(H) - mu_N) / sigma_N]$ with $mu_N = 1.46$ and $sigma_N = 0.28$, which gave a good fit (R² = 0.76); and in the remaining zone $mu_N = 7.60$ and $sigma_N = 2.75$, with a very weak fit (R² = 0.09). The authors warn that no empirical data are available to check the function at higher mortality fractions @jonkman2008methods.

Earlier, DeKay and McClelland @dekay1993 derived a logistic regression for loss of life from warning time, the population at risk and the forcefulness of the flood, using the historical record of dam failures and flash floods. Jonkman and Vrijling @jonkman2008jfrm give a broader overview, noting that mortality depends on flood severity and on the possibilities for warning and evacuation, and Jonkman et al. @jonkman2003measures place these fatality estimates within the wider family of quantitative risk measures, including individual and societal risk. Jonkman et al. @jonkman2010criteria then examine how these two metrics could enter the Dutch flood safety policy, where the statutory standards for defences rest on cost-benefit analyses and loss of life has not been weighed separately; in their most stringent option, legal limits on individual and societal risk would be translated into legal limits on flood probabilities per dike ring. Di Mauro et al. @dimauro2012 compare three quantitative methods for estimating flood fatalities, and Karbasi et al. @karbasi2018 develop a regional loss-of-life equation for flash floods using depth, velocity, rise rate and evacuation variables. Peng and Zhang @peng2012huram build a Bayesian network (HURAM) from 343 dam-failure cases, and Maranzoni et al. @maranzoni2023 make the dam-break estimate probabilistic, combining uncertainty in hazard, exposure and vulnerability; their vulnerability term is an established empirical fatality function that links the fatality rate to flood hazard, how well the flood severity is understood, and warning time.

#pagebreak()

More recent work makes the empirical curve data-driven: Yazdani et al. @yazdani2023 train a random forest on nine variables describing each fatality and use it to estimate the probability of a flood fatality, while Salvati et al. @salvati2026 fit a Zipf distribution to 667 fatal floods recorded at 652 sites in Italy to estimate the return period of societal risk. These are compiled empirical tools, but they are not generated by an ABM and they do not retain the behavioural processes behind the deaths.

Lumbroso and Di Mauro @lumbroso2008 present the other approach, the Life Safety Model (LSM), an individual-level simulator that represents individual people and cars and their dynamic interaction with floodwater; it simulates evacuation times and deaths caused by drowning, exhaustion, building collapse or vehicles being swept away. The authors claim it is the only model that dynamically couples the receptors at risk with the flood hazard, and say that other models provide only a first-order estimate of evacuation times and fatalities @lumbroso2008. The LSM is therefore an ABM applied to loss of life -- but as a site-specific simulation tool, not as a generator of reusable curves.

The empirical record on who dies is comparatively rich. From a nationwide database of US flood fatalities (1959-2005), Ashley and Ashley @ashley2008 report that 63% of fatalities with known activities or locations occurred in vehicles, and that people aged 10-29 and over 60 are more vulnerable. Terti et al. @terti2017 analysed 1,075 US flash-flood fatalities and found that 61% were vehicle-related, with 41% of those occurring at night; they argue that vulnerability must be examined situationally, not generically, to capture risky cases in short-fuse floods. Jonkman and Kelman @jonkman2005causes analysed 247 fatalities from 13 flood cases and found that about two-thirds were drownings, and that men are particularly vulnerable. At the European scale, the European Flood Fatalities (EUFF) database of Petrucci et al. @petrucci2020 gathers 2,483 deadly cases over 1980-2018 in eight countries, with driving a car or other vehicle as the most frequent circumstance of the victims in all the areas studied; the earlier Mediterranean Flood Fatalities (MEFF) database @petrucci2018 covers Mediterranean flood fatalities from 1980 to 2015.

#pagebreak()

Vulnerability is also structured socially. Cutter et al. @cutter2013 propose a way to bring the Social Vulnerability Index (SoVI) into the civil works planning of the US Army Corps of Engineers (USACE); Lindersson et al. @Lindersson2023TheWT examined flood disasters and income inequality across 67 middle- and high-income countries from 1990 to 2018, and found that more unequal countries tend to suffer more flood fatalities; and Fox et al. @fox2024 build a global vulnerability-adjusted flood risk index (VARI Flood) at 90 m resolution, arguing that current approaches do not adequately account for the spatial variation in social vulnerability, which strongly shapes outcomes for exposed populations. Fatality data is thus structured by circumstance, vehicle use, age and social vulnerability -- but it is a record of past events, not a generator of curves.

Warning and evacuation behaviour are the empirical basis for the agent rules. Molinari and Handmer @molinari2011 combine social-science and engineering approaches to model warning effectiveness, starting from depth-damage curves and modelling how people respond to the warning; Kuller et al. @kuller2021 review the factors that make flood warnings effective and note that the detailed aspects of warning effectiveness are still not systematically understood; Parker and Priest @parker2012 document the deficiencies that propagate through the warning chain and limit warning impact; Dash and Gladwin @dash2007 point out that warnings alone do not trigger evacuation, because people must first perceive the risk; Perry et al. @perry1980 already noted that people do not always evacuate readily when asked; and Kolen and Helsloot @kolen2014 argue that deterministic planning is insufficient and recommend probabilistic planning that accounts for uncertainty in the decision process, forecasts, citizen responses and infrastructure capacity.

More recent evidence confirms the importance of trust and social cues. Zhang et al. @zhang2024evac find that low trust in early warning information makes residents wait for others to evacuate first, especially when no one has yet moved, and that a longer lead time does not necessarily improve evacuation performance. Zulfa et al. @zulfa2024 find that households with partial house ownership, larger households, and those unfamiliar with shelters and routes are less likely to evacuate, and that flood height and duration, and whether an unofficial warning was received, also influenced the decision. Sadiq et al. @sadiq2023 review 100 US public alert and warning studies and identify twelve main themes and eight themes of policy and practical lessons; 

#pagebreak()

Arshaghi et al. @arshaghi2026 show in virtual-reality experiments that crowd behaviour strongly shaped both route choice and evacuation delay, often more than other factors, and that participants tended to follow the crowd into the water, showing the influence of social information; and Anshuka et al. @anshuka2026 find that timely warnings and training substantially improve the response, but that belief in the warning and flood velocity can still undermine the outcome even when warnings are timely. These findings are the empirical justification for the warning, risk-perception and social-interaction sub-modules of flood ABMs.

Describing and validating ABMs is a problem the community has long recognised. The Overview, Design concepts and Details (ODD) protocol of Grimm et al. @grimm2020 exists to make model descriptions complete and reproducible, because incomplete descriptions violate the basic scientific requirement that methods be described in enough detail to allow replication @grimm2020. Müller et al. @muller2013 extend it with ODD+D to describe human decision-making, starting from the premise that representing human decisions is fundamental in ABMs. Windrum et al. @windrum2007 survey the empirical validation approaches used in agent-based economics -- indirect calibration, the Werker-Brenner approach and the history-friendly approach -- and call for a commonly accepted minimal protocol for analysing ABMs. Ormerod and Rosewell @ormerod2009 note that most ABMs have no analytical solution and are run by simulation, which blurs the line between validation and verification, and argue that models giving agents high levels of cognition need particularly strong justification to be considered valid. Belfrage et al. @belfrage2024 propose a verification, validation and accreditation (VV&A) framework for ABMs used in decision support, define model credibility as confidence in the model's inferential capability, and note that few public administrations have an established accreditation process.

Flood-ABM is a case in point: Addai et al. note that direct empirical validation remains difficult because data are limited, and their validation is informal, based on reported flood impacts, a practice that often relies on expert judgment @obeng2025. The systematic review of Senanayake et al. @senanayake2024 reaches the same conclusion for pedestrian evacuation models, and Silva et al. @silva2025ahr provide a rare empirical benchmark: their reconstructed Ahr Valley simulation overestimates the observed life loss by 28.8%, which is a useful order-of-magnitude check but not a validation of the behavioural rules. 

Brussee et al. @brussee2021 show that flood fatality risk estimates are sensitive to both hydraulic model resolution and loss-of-life model parameters, which is a further reason to treat any single curve as conditional on its modelling choices.

Two adjacent bodies of work frame the effort. The escape-panic model of Helbing et al. @helbing2000 shows the physics of crowds under stress -- clogging at bottlenecks and the faster-is-slower effect -- and, tellingly for any attempt at validating crowd behaviour, reports that the authors could not find suitable data to test their model quantitatively, a scarcity that calls for reliable models @helbing2000. In socio-hydrology, Di Baldassarre et al. @dibaldassarre2013 conceptualise floodplains as coupled human-flood systems, noting that hydrology usually treats humans as a boundary condition or external forcing, so reciprocal links are not represented @dibaldassarre2013.

On the economic side, McGrath et al. @mcgrath2019 develop probabilistic depth-damage curves (PDDCs) and stress that any assessment should communicate the uncertainty and variability of the expected losses. This is the methodological analogue for SDCs. An SDC built from an ABM is, in a sense, a small contribution to this coupling: it would let a hydraulic state be converted into a social outcome without rerunning the social simulation.

Taken together, the studies above cover the field unevenly. Zhuo and Han @zhuo2020 review 61 articles at the interface of ABM and flood risk management and distinguish three areas: real-time emergency management, long-term adaptation planning, and flood hydrological modelling. Most of the models described here belong to the first and third areas: they couple a hydrodynamic or inundation model to agents who receive a warning, evacuate, help others or die, and they are applied to a single event. The second area is much thinner. Long-term adaptation, in which households and institutions change protection measures, land use or insurance over years, appears mainly through the socio-hydrological feedbacks of Breen et al. @breen2025 and the institutional coupling of Abebe et al. @abebe2019; it is not the focus of the models reviewed here. Zhuo and Han also note that decision rules are often implemented ad hoc, without a shared theoretical basis, which matches the small number of decision theories discussed above. @abm-comparison summarizes the models on the dimensions that matter for FSFS: how the hazard is coupled, what drives the agents, how the model was validated, and what outcome it produces.

#block(breakable: false)[
  #set text(size: 9pt)
  #table-figure(
    caption: [Comparison of the reviewed agent-based models, with two adjacent models (tsunami evacuation and post-disaster recovery) shown for comparison],
    label: "abm-comparison",
    columns: (17%, 22%, 23%, 20%, 18%),
    inset: 4pt,
    table.header([Model (case)], [Hazard coupling], [Decision logic], [Validation], [Outcome]),
    [Dawson et al. @dawson2011 (Towyn, UK)],
    [one-way hydrodynamic],
    [warning response: evacuate to the nearest shelter or continue routine],
    [qualitative; aggregate behaviour, not individual prediction],
    [evacuation, warning and shelter siting],
    [O'Shea et al. @oshea2020 (Carlisle, UK)],
    [one-way hydrodynamic],
    [direct and indirect warnings; word-of-mouth],
    [repeated simulations; not a predictive tool],
    [individual and group interactions, casualties],
    [Liu and Lim @liu2018 (Brisbane, AU)],
    [one-way validated hydrodynamic],
    [evacuation],
    [hydrodynamic model validated; ABM validation not specified],
    [city-scale evacuation],
    [Mas et al. @mas2012 (Great East Japan)],
    [one-way tsunami inundation],
    [stochastic evacuation],
    [1,000 runs compared with reported evacuation],
    [evacuation rate and sheltered evacuees],
    [Shirvani et al. @shirvani2021],
    [two-way flood-pedestrian],
    [local flow modification; mechanics-based danger criterion],
    [not specified],
    [flood impact on evacuees],
    [Abebe et al. @abebe2019 (CLAIM)],
    [coupled flood-agent-institution],
    [institutional decisions],
    [not specified],
    [urban flood risk management],
    [Zhang et al. @zhang2024evac (Liulin, CN)],
    [flood sub-module (with warning and social)],
    [warning response],
    [case study],
    [flash-flood evacuation],
    [Silva et al. @silva2025ahr (Ahr Valley, DE)],
    [observed flood reconstruction],
    [evacuation],
    [empirical benchmark; +28.8% overestimate],
    [life loss],
    [Addai et al. @obeng2025 (Calgary, CA)],
    [real inundation maps],
    [four decision theories; socio-economic index],
    [informal, expert judgement],
    [differential flood effects],
    [Wang and Jia @wang2020tsunami (Seaside, OR; tsunami)],
    [tsunami inundation + network],
    [multi-modal evacuation; pedestrian-vehicle interaction],
    [application to Seaside, OR],
    [evacuation risk],
    [Ghaffarian et al. @ghaffarian2021 (Tacloban, PH; recovery)],
    [remote sensing land use; recovery],
    [household relocation and reconstruction],
    [scenario evaluation],
    [post-disaster recovery],
  )
]

#pagebreak()

This review follows the event: warning, evacuation, exposure and loss of life. It does not cover post-disaster recovery, where agent-based models have been used to represent household relocation, reconstruction and the different recovery paths of formal and informal settlements @ghaffarian2021. It also says little about social outcomes other than death. Injuries, morbidity, mental health, displacement and subjective well-being are not reviewed, although the intangible well-being effects of a flood can be about twice the tangible direct monetary losses @hudson2017. Evacuation is treated mostly as a single-mode problem (on foot or by car); multi-modal evacuation, road-network damage and pedestrian-vehicle interaction are modelled in the tsunami literature @wang2020tsunami but rarely in flood ABMs. Finally, the empirical evidence is concentrated in the United States, Europe, Japan and Australia, while the report's global ambition would require evidence from the Global South and informal settlements, where flood mortality is highest.

Two conclusions follow from this review. First, the gap claimed in this chapter is real but nuanced: empirical social damage curves already exist in the death-rate model of @jonkman2008methods and in the later regression, Bayesian, random-forest and probabilistic models (@dekay1993, @karbasi2018, @peng2012huram, @maranzoni2023, @yazdani2023, @salvati2026). What does not exist, to our knowledge, is the process-explicit, ABM-generated, setting-specific version, which can be stratified (by warning lead time, risk perception, vulnerability) and which retains the processes behind the deaths. Second, two simplifications of the POC stand out against the literature: a static death depth of 1.65 m where both @shirvani2021 ($H_R = (V + 0.5) H$) and @jonkman2008methods ($H V >= 7 "m"^2"/s"$ and $V >= 2 "m/s"$) use depth-velocity criteria, and where @musolino2020 shows that mechanics-based criteria are preferable for escape routes, while @maranzoni2023 uses an empirical fatality function that includes warning time; and a uniform random vulnerability factor where the fatality record shows structured vulnerability (vehicles, age, night-time, social inequality; @ashley2008, @terti2017, @jonkman2005causes, @petrucci2020, @cutter2013, @Lindersson2023TheWT, @fox2024, @yazdani2023) and ABMs already differentiate population groups through socio-economic indices @obeng2025 and survey data @zhang2024evac. Both are reasonable for a proof of concept, and both are the main avenues for improvement -- along with validation, which the ABM literature consistently identifies as the hardest step (@senanayake2024, @grimm2020, @windrum2007, @ormerod2009, @belfrage2024). A first validation benchmark now exists in @silva2025ahr, who compare simulated and observed losses for a real event; the same exercise should be done for FSFS before its curves are used.

== FSFS

In its current state, FSFS is not tested, and not scientifically validated. It is a prototype built quickly in the last months of the contract, as a proof of concept of this idea. There was no time to make it more robust and versatile. The results shown in this part are not to be taken as scientific facts, but as possibilities of such a tool. There is also a very real possibility that, when tested in real conditions with more certain hypotheses and data, the final result drastically changes, possibly invalidating the method. There is enough work for one or multiple PhDs on this topic, and this work does not claim to check all the boxes in a few months, with a code base developed using a combination of AI-assisted coding and rapid prototyping in Julia. However it is interesting enough to be included in this report as a full-fledged chapter, as a possibility to explore.

=== Goals of the POC

The goal of this POC is to demonstrate that an ABM can be used to build social damage curves, while remaining generic enough to be applied anywhere on Earth. On the one hand it is global: the only required inputs are a bounding box, an ISO-3 country code and a year, because the elevation comes from the global MapZen tiles @mapzen, the land cover and Manning coefficients are rasterized from OpenStreetMap, and the population is fetched from WorldPop @worldpop. On the other hand it is fast: Torrent.jl @torrentjl needs no mesh and the pipeline is a lightweight prototype that can be launched in batches, which is what makes sweeping parameters and generating SDC data points cheap. And finally it is open: every piece of data, library or tool used here is open source and widely available.



=== Flooding

#image-figure(
  caption: [FSFS input rasters (map data © OpenStreetMap contributors)],
  label: "fsfs-inputs",
  path: "imgs/fsfs_inputs.png",
  width: 100%,
)

Torrent.jl @torrentjl is a pure Julia library that was quite recently built by the US Pacific Northwest National Laboratory, as part of a contract with the US Department of Energy. It allows one to quickly simulate flooding and hydrodynamics solely based on a DEM and some precipitation data. It was implemented in FSFS because of its simplicity and the fact that it does not need a mesh to function. Another contender was LISFLOOD-FP @lisflood_fp_developers_2024_13121102, which is more battle-tested and scientifically validated, but less easy to implement, as it is a C++ library. The goal of FSFS being simply a POC, the easiest path was chosen.

If a similar tool were built to be production ready, the choice of the flood model can change the resulting SDCs, and should be a prime reflection point before implementing anything @brussee2021. If the goal is to target slow moving overflowing floods, maybe a quick-and-dirty bathtub model could work; but for flash-floods, the dynamics and urban representation within the models are of utmost importance and more complex solvers might be needed. This POC only demonstrates that the coupling of an ABM with a flood model can produce SDCs; the choice of the flood model for a production-ready version remains an open question.

Torrent.jl is driven by a JSON configuration file written by `write_config` in `get_flood_from_torrent.jl`, which references the input rasters shown in @fsfs-inputs and, optionally, a precipitation map, a river source or a dam failure. The inputs are described here:

/ DEM: As with a lot of things flood-related, Torrent.jl needs a DEM. The elevation explains where the water flows, how much it can accumulate, its acceleration and so on. In this POC, we use the MapZen tiles @mapzen that are globally available on the whole planet at 1 arc-second spatial resolution (around 30 m at the equator). Since the goal of the POC is to be global, we could also have used the Copernicus 30 m GLO-30 DSM, but MapZen was kept because of its easy online query system, meaning the user does not have to manually download the data; FSFS takes care of it. The tiles are fetched at a configurable `dem_zoom_level`, mosaicked and cropped to the bounding box, resampled bilinearly to `spatial_resolution`, and the no-data holes left at tile boundaries are filled by inpainting (`fill_dem_holes`) before Torrent runs.

/ Manning friction coefficients: The friction coefficients determine how quickly water can flow over a surface, resulting in different water dynamics in different land cover classes. To obtain them we fetch OpenStreetMap (OSM) data, rasterize it, and associate to each pixel a Manning coefficient, unique for one class of land cover. If none of these classes is present, there is a default fallback coefficient of 0.018, the "open surface" value of the source, for surfaces with no specific cover. @manning-from-osm summarizes the Manning coefficient mapping that was made in FSFS' POC. The mapping follows the land use / land cover approach of Kalyanapu et al. @kalyanapu2009, who recommend assigning Manning's n values from land use / land cover classes (e.g. residential, impervious) when extracting surface roughness over large areas. Their mapping assigns each land cover class a value from a look-up table of overland-surface values, with mixed classes computed as an area-weighted average: the US National Land Cover Database (NLCD) "Developed, high intensity" class, for instance, is 80% concrete and 20% short grass, giving n = 0.0404. Their values span from 0.0113 for barren land to 0.40 for shrub/scrub and mixed forest, and cover both natural and urban classes. They are defined for the NLCD classes; FSFS maps each of its OSM classes to the closest NLCD counterpart and uses the corresponding value of Kalyanapu et al. 

Water classes are not covered by their table, as water bodies were excluded from their study area, and keep typical values. In all cases, the exact values are not meant to be a scientific contribution: the goal here is to have different roughness per land cover class, not to calibrate a model.



/ Precipitation map: The precipitation, or rain, decides how much water enters the system, and ultimately, how big the flood is going to be. Here, for simplicity, we generate synthetic rain as a 2D-Gaussian blob parametrized by a peak rain rate in mm/h and a storm radius, built directly in Julia with the standard random number generator. This "blob" then performs a random walk over the domain. This is of course very unrealistic and could be greatly improved by using various rain models or datasets that are scientifically valid, but it allows this POC to have a direct control over a fictitious precipitation peak, making it easy to launch batches of simulations and generate data points for our SDCs. The rain is written as a multiband GeoTIFF with one band per time step (`n_steps + 1` bands) and read by Torrent's `rain-multiband-geotiff` section.

/ River source: Instead of rain, a flood can be driven by an upstream river source, as a point source located in the river channel. FSFS writes an asymmetric Gaussian hydrograph on top of a constant base flow: `flux(t) = base_flux + (peak_flux - base_flux) g(t)`, with `g` a Gaussian lobe normalized to 0 at the first and last time steps and 1 at `t_peak = 0.3 n_steps`, rising with width `n_steps / 10` and receding with width `n_steps / 5` (`write_river_sources`), as a CSV read by Torrent's `rain-nwm` section. The Garonne example uses this forcing, and `peak_flux` is the parameter swept to build its SDC.

/ Dam failure: A dam breach is prescribed through Torrent's `dam-failure` section: a trapezoidal breach, with `breach_width_top` and `breach_width_bottom`, opens over `failure_period` seconds, linearly lowering the dam from `dam_height_initial` to `dam_height_final`; the reservoir is described by its initial volume and surface area, the latter used as a rectangular depth curve. The Malpasset example uses this forcing, and `dam_height_final` is the parameter swept to build its SDC.

#block(breakable: false)[
  #table-figure(
    caption: [Manning's n per OSM land cover class (dimensionless)],
    label: "manning-from-osm",
    columns: (30%, 17%, 30%, 17%),
    inset: 5pt,
    column-gutter: (auto, 6%, auto),

    [Class],
    [Manning's n],
    [Class],
    [Manning's n],

    [`natural-wood`],
    [0.36],
    [`natural-scrub`],
    [0.40],

    [`natural-grassland`],
    [0.368],
    [`natural-wetland`],
    [0.1825],

    [`natural-water`],
    [0.03],
    [`landuse-forest`],
    [0.40],

    [`landuse-meadow`],
    [0.325],
    [`landuse-grass`],
    [0.368],

    [`landuse-farmland`],
    [0.325],
    [`landuse-residential`],
    [0.0678],

    [`landuse-commercial`],
    [0.0404],
    [`landuse-industrial`],
    [0.0404],

    [`landuse-quarry`],
    [0.0113],
    [`leisure-park`],
    [0.0404],

    [`leisure-garden`],
    [0.0404],
    [`waterway-river`],
    [0.035],

    [`waterway-stream`],
    [0.04],
    [`waterway-canal`],
    [0.035],
  )
]



=== Agent-based model

The agent-based model was implemented with Agents.jl @agentsjl, a dedicated framework that was the main reason to build FSFS in Julia. ABMs have three main components: agents, a space and a model. Agents are the individuals we are simulating; here we focus on human behaviour in response to flooding, so the agents are going to be humans, but they could also be birds, bacteria, atoms, or anything that can be represented with a simple set of rules. The space is where they evolve; here it is going to be a flooded city. Finally, the model is the orchestrator, describing the interactions between the agents and their space.


==== Space

Agents.jl has an OpenStreetMapSpace, which seems ideal to have a global land cover representation. However, it was mostly tailored for road movement, with a graph representation that did not really allow one to go out of the streets. Since in catastrophic situations movement tends to become a bit more chaotic, the possibility for the human agents to cross fields, parks or rail seemed important to take into account. For this purpose, the space is described as a regular grid, a non-periodic `Agents.GridSpace`; the speed of the agent, expressed in m/s, is converted into a number of cells per time step, and its pathfinding uses an A\* algorithm with a custom cost metric. The cost of moving from one cell to the next is the distance plus a penalty per metre of water depth difference (`penalty_walk_in_water`) and a penalty per metre climbed (`penalty_per_elevation`, `SlopePenalty` in `build_model.jl`); both are path costs per metre, set to 10 in the two example cases (@fsfs-config-abm). 

To account for the buildings, a mask is generated from OSM: each pixel is either 1 if an OSM building is present in the pixel, or 0. Agents cannot cross the building mask and must find an alternative path to safety. The building footprints also define the extraction points: each connected component of buildings keeps an entrance, the first walkable cell adjacent to it, with probability `entrance_ratio` (`get_extraction_points`); agents head to these extraction points when they see one, or as a fallback when no refuge is reachable. Additionally, each cell has a maximum occupancy, `max_crowd_density` agents per square metre, and agents cannot enter an over-full cell.

==== Agents

The agents here are humans, and we derive SDCs from their behavioural response to flooding. This may be the most scientifically unstable part of the whole POC, as it is almost impossible to simulate human actions with a simple set of rules. The latter are, here in this POC, very minimal and described here:

Each agent carries a role (`:civilian` or `:rescue`), a status (`:safe`, `:danger` or `:dead`), a risk perception and a vulnerability factor, both drawn uniformly at random in [0,1]. The risk perception gates whether a warned civilian complies with the warning (`will_evacuate` is true with probability `warning_compliance` times the risk perception); the vulnerability factor slows the agent down: its effective speed is `speed * (1 - vulnerability_factor)`. Every time step it first updates its flood status from the local water depth, then goes through the perceive, decide, execute and advect stages. At spawn, every civilian also receives an evacuation plan (`warning_plan` in `add_initial_agents.jl`): when a warning is configured (`warning_lead_time > 0`) and its cell is going to flood, it starts evacuating at `max(0, first_flood_time - warning_lead_time)` plus a uniform delay of up to `warning_response_delay` seconds, provided it complies (`will_evacuate`). Without a warning, no civilian has an evacuation plan and everyone reacts only to what they see. The population is sized from the WorldPop raster restricted to the flooded area: `n_agents = population_ratio * flooded population`, and `n_rescue = rescue_ratio * n_agents` (`agent_counts` in `build_model.jl`). 

#pagebreak()


Civilians are spawned on walkable, populated cells that are going to flood, weighted by the local population; rescue agents spawn once at `rescue_spawn_time` on walkable flooded cells. An agent cannot enter a cell whose occupancy exceeds `max_crowd_density`; when the next cell of its planned route is full, it moves randomly instead. An agent moves at most `cells_per_step` cells per time step, `cells_per_step = max(1, round(speed * temporal_resolution / cell_size))`.

In the perceive stage, the agent updates what it sees: whether water or an extraction point is within its vision range, and the list of endangered neighbours. An agent is endangered when its flood status is `:danger`, that is, when the local water depth exceeds `death_depth`. In the decide stage, a civilian picks an action based on its perception. If it is safe, on dry ground, with no water in view and no evacuation pending, it waits. If its risk perception is low and it sees endangered agents, it helps them. If it has been warned and the evacuation time has come, it heads to the nearest never-flooding walkable cell, a refuge (`nearest_refuge`), or to the nearest extraction point when no refuge is reachable. If it sees an extraction point, it moves towards it. If it sees water, it flees away from the nearest wet cell when on dry ground, or heads towards the nearest dry cell when standing in water. Otherwise it moves randomly. A rescue agent instead moves towards the nearest endangered agent, or escorts it to safety once it reaches it, at the average speed of both agents.

In the execute stage, the chosen action is performed by moving the agent along its A\* route, or randomly when it has no destination. Finally, in the advect stage, an agent standing in water is pushed by the local flood velocity. The flood status, updated at the start of the step, is `:safe` below `death_depth`; above it, an agent accumulates `death_time` and dies once this threshold is reached. The decision logic is summarized in @abm-decision-graph.


#let decision-graph-source = (
  "---
config:
  layout: elk
---
flowchart TD
  depth{death_depth}
  depth -->|above| dtime{death_time}
  depth -->|below| role{Rescue agent?}
  dtime -->|above| dead[dead]
  dtime -->|below| role{Rescue agent?}
  role --> endangered{Endangered<br/>in sight?}
  role --> idle{Idle?}
  endangered --> assist[Help]
  endangered --> wander[Move randomly]
  idle --> wait[Wait]
  idle --> help{Endangered<br/>neighbors &<br/>low risk?}
  help --> assist[Help]
  help --> evac{Evacuation due?}
  evac --> refuge[Move to nearest refuge]
  evac --> ext{Sees extraction point?}
  ext --> extract[Move to extraction point]
  ext --> water{Sees water?}
  water --> flee[Flee away from water]
  water --> wander
  assist & refuge & extract & flee & wander --> inwater{In water?}
  inwater --> advect[Advected by local<br/>flood velocity]
  %% edges: 0-3 threshold branches, then yes/no pairs; 18-22 actions -> In water?, 23 -> advect
  linkStyle 4,6,8,10,12,14,16,23 stroke:#0a0,stroke-width:2px
  linkStyle 5,7,9,11,13,15,17 stroke:#a00,stroke-width:2px
"
)

#mermaid-figure(
  decision-graph-source,
  caption: [Agent decision logic],
  label: "abm-decision-graph",
  size: 16pt,
  width: 100%,
  legend: false,
)

More complex rules could be added to the agents to make the model more realistic, and the literature on flood evacuation behaviour is a good source of inspiration for this: the existing agent-based models of human responses to flood warnings often include sub-modules for early warning, social interactions and the flood itself, and highlight for instance the role of trust in the warning information and of risk communication in evacuation performance (see the literature review above). The goal of this POC is not to reach this level of detail, but to show that the coupling works.

==== Model

The rain, hydrological model and ABM all have different time resolutions. For simplicity in this POC they were all made equal to `temporal_resolution`.

The whole pipeline is orchestrated by `simulate` in `run_model.jl`: the inputs (DEM, rain, Manning, buildings and population rasters) are fetched once and cached per bounding box in a local cache directory, `fsfs_cache`; Torrent is run on the DEM; the per-step `depth`, `xspeed` and `yspeed` snapshots are loaded into a raster stack; the flooded mask is the set of cells that ever exceed `flood_threshold`; the agents are sized and spawned; and the model is stepped `n_steps` times. At every ABM step the flood fields are interpolated linearly between the two surrounding snapshots at the current time (`field_grid!` in `model_step.jl`), and the wet mask, the water-in-view mask (a dilation by the vision radius) and the pathfinding depth penalties are updated. At every step the model records the number of agents in each status (`n_safe`, `n_danger`, `n_dead`). Per simulation, three files are written in the case output directory: `agents_init.csv` (role, risk perception and vulnerability of each agent), `data.csv` (per-agent-per-step status, action and position) and `metrics.csv` (per-step counts). Runs are reproducible: a `seed` in the config seeds the random number generator, so the same configuration gives the same agents; the sweeps all use a fixed seed.

Parameter sweeps (`sweep_parameter` in `run_model.jl`) change a single config key along a dotted path over a set of values and run one full simulation per value, distributed on Julia workers (`pmap`), each case in its own output directory. The summary table holds the last-step metrics of each case, from which the SDCs are built. The flood model and ABM parameters of the two example cases are listed in @fsfs-config-flood and @fsfs-config-abm.

#block(breakable: false)[
  #set text(size: 9pt)
  #table-figure(
    caption: [FSFS flood model parameters (`malpasset_dam.jl`, `garonne_1875.jl`)],
    label: "fsfs-config-flood",
    columns: (auto, auto, auto, 1fr),
    inset: 4pt,
    table.header([Parameter], [Malpasset], [Garonne (Toulouse)], [Description]),
    [`spatial_resolution`],
    [30.0 (m)],
    [50.0 (m)],
    [Grid cell size],
    [`temporal_resolution`],
    [60.0 (s)],
    [600.0 (s)],
    [Time step, shared by Torrent and the ABM],
    [`n_steps`],
    [120],
    [576],
    [Number of simulation time steps],
    [`dem_zoom_level`],
    [12],
    [12],
    [Zoom level of the MapZen DEM tiles],
    [`flood_threshold`],
    [0.01 (m)],
    [0.01 (m)],
    [Depth above which a cell is considered wet],
    [`default_manning`],
    [0.018],
    [0.018],
    [Fallback Manning coefficient],
    [`n_sources`],
    [500],
    [500],
    [Number of precipitation sources injected into Torrent],
    [`rivulet_thickness`],
    [0.1 (m)],
    [0.1 (m)],
    [Torrent rivulet thickness],
    [`rivulet_length`],
    [10 (cells)],
    [10 (cells)],
    [Torrent rivulet length],
  )
]

#block(breakable: false)[
  #set text(size: 9pt)
  #table-figure(
    caption: [FSFS agent-based model parameters (`malpasset_dam.jl`, `garonne_1875.jl`)],
    label: "fsfs-config-abm",
    columns: (auto, auto, auto, 1fr),
    inset: 4pt,
    table.header([Parameter], [Malpasset], [Garonne (Toulouse)], [Description]),
    [`vision_range`],
    [100.0 (m)],
    [100.0 (m)],
    [Perception range of an agent],
    [`speed`],
    [1.4 (m/s)],
    [1.4 (m/s)],
    [Walking speed of a civilian],
    [`low_risk_perception`],
    [0.3],
    [0.3],
    [Risk perception below which a civilian helps others],
    [`death_depth`],
    [1.65 (m)],
    [1.65 (m)],
    [Depth above which drowning can occur],
    [`death_time`],
    [300.0 (s)],
    [300.0 (s)],
    [Time spent above `death_depth` before dying],
    [`max_crowd_density`],
    [6 (agents/m²)],
    [6 (agents/m²)],
    [Maximum number of agents per square metre in a cell],
    [`entrance_ratio`],
    [0.1],
    [0.1],
    [Probability that a building component keeps its extraction point],
    [`penalty_walk_in_water`],
    [10],
    [10],
    [Path cost per metre of water depth difference],
    [`penalty_per_elevation`],
    [10],
    [10],
    [Path cost per metre of climb],
    [`population_ratio`],
    [1],
    [1],
    [Fraction of the population used to spawn agents],
    [`rescue_ratio`],
    [0.01],
    [0.01],
    [Fraction of agents that are rescue agents],
    [`rescue_spawn_time`],
    [300.0 (s)],
    [300.0 (s)],
    [Time after which rescue agents spawn],
    [`warning_lead_time`],
    [0.0 (s)],
    [0.0 (s)],
    [Lead time of the flood warning; swept in the warning sweep],
    [`warning_compliance`],
    [0.9],
    [0.9],
    [Probability that a warned agent complies, times its risk perception],
    [`warning_response_delay`],
    [60.0 (s)],
    [60.0 (s)],
    [Uniform delay before a warned agent starts evacuating],
    [`seed`],
    [1312],
    [1312],
    [Random seed; fixed in the sweeps for reproducibility],
  )
]

== Examples

To test FSFS two historical examples were used, with a documented death toll and available hydrological values, and were run on modern data in a _"what if it happened now"_ scenario. The DEM, population raster, land cover and all other kinds of data are easily accessible now, hence their use for this POC; but the behavioural model should first be run on data from back then, compared to the recorded number of deaths, and only then run on modern data, as in @silva2025ahr and @mas2012. For simplicity for this POC, the first step was skipped.


These choices were motivated by their ability to show the different kinds of hydraulics we can use as input for Torrent.jl: a dam breach and an increased river flow, the events being tragic enough to have a recorded death toll.

The Malpasset dam breach @malpasset happened on 2 December 1959 with a reported death toll of around 423. The dam sat on the Reyran river north of Fréjus, and the wave reached Fréjus in about 20 minutes. The dam was 222 m wide and 66 m high; the reservoir stored 50 million m³; and a storm peaking at 100 mm/h triggered the failure.

The 1875 Garonne flood at Toulouse @garonne1875, on 23-24 June 1875, is the largest known flood of the river. The peak flow is estimated at 8,000 m³/s (19th-century accounts report up to 18,000 m³/s, but these are pre-rating-curve estimates and likely overestimates), while the mean flow is usually around 200 m³/s, and the stage at the Pont Neuf reached 8.32 m against a usual 0.80 m. Region-wide the flood caused 476 deaths, of which 209 were in the single city of Toulouse. The input hydrograph used for the Garonne case is shown in @fsfs-input-flow-garonne.

#image-figure(
  caption: [Garonne input hydrograph (river flow in m³/s)],
  label: "fsfs-input-flow-garonne",
  path: "imgs/fsfs_input_flow_garonne.png",
  width: 100%,
)

The goal of the simulations is to simply sweep the relevant hydraulic parameter, the final dam height (`dam_height_final`) for Malpasset, and the peak flow (`peak_flux`) in Toulouse. For each value of the parameter we run FSFS, record the death toll and generate a curve. Then, if the simulation was validated and scientifically coherent, it could serve as an empirical quick-reference to assess in real time how dangerous a current hydraulic situation is.


=== Results

As for the SEICHE test cases, this part discusses data and methods rather than scientific analyses: it is an illustration of what a tool like FSFS could offer, not a validated result.

Example snapshots of the simulation are available in @fsfs-snapshot-malpasset and @fsfs-snapshot-garonne. In blue is the simulated water by Torrent.jl, the darker, the deeper. In hillshade is the MapZen DEM. Agents are not represented individually, but rather by a gradually growing circle based on the number of agents there are in a single pixel. In green are the safe agents, in orange those in danger, and in red those who are dead. The building mask is represented in pink, while the extraction points are purple triangles. The plots are only on a small zoomed-in area for legibility purposes, whose location is displayed as a red square on the global extent on the top left.

#image-figure(
  caption: [Malpasset snapshot (t = 20 min)],
  label: "fsfs-snapshot-malpasset",
  path: "imgs/fsfs_snapshot_malpasset.png",
  width: 100%,
)


#image-figure(
  caption: [Garonne snapshot (t = 33 h)],
  label: "fsfs-snapshot-garonne",
  path: "imgs/fsfs_snapshot_garonne.png",
  width: 100%,
)


The previously shown results are a single snapshot of a single event. But the real power of these simulations is to launch a batch of them and observe statistical behaviour, and ultimately, build SDCs. @sdc shows the global "damage curve" for each of the test cases, in terms of absolute number of deaths compared to a single hydraulic variable, that is the final dam height (`dam_height_final`) for Malpasset, and the input flow upstream of Toulouse for the Garonne test case.

#image-figure(
  caption: [Social damage curves: number of deaths versus final dam height (m) for Malpasset and versus input flow (m³/s) for the Garonne (Toulouse) case],
  label: "sdc",
  path: "imgs/sdc.png",
  width: 100%,
)


#image-figure(
  caption: [Death fraction by agent attributes],
  label: "sdc-attributes",
  path: "imgs/sdc_agent_attributes.png",
  width: 100%,
)

#image-figure(
  caption: [Death toll versus warning lead time (h)],
  label: "sdc-warning",
  path: "imgs/sdc_warning_time.png",
  width: 100%,
)

@sdc-attributes shows the death fraction of civilians as a function of their vulnerability factor and risk perception, for the two reference cases with no warning lead time. Risk perception gates compliance with the warning, so the death fraction falls as it increases, while vulnerability only slows movement and has little effect. @sdc-warning shows the death toll as a function of warning lead time: any warning roughly halves the toll compared with the no-warning case, and the toll then stays nearly flat in the Malpasset case, while in the Garonne case it rises again after about five hours and then fluctuates.

Use cases: the strength of such curves is that the heavy computations -- hydrodynamics and ABMs -- are done only once, offline. The resulting SDC can then be queried instantaneously, for any event on the extent, like economic damage functions are queried today. They can be tailored for a specific city: for example, for Toulouse, such a curve could be used today to assess the death toll of a flood scenario, or to compare evacuation strategies, or to evaluate where to put the warning sirens. The same curve could even be reused for future events with a different population (demographic evolution), the ABM being rerun on the new population without touching the hydrodynamics.

#pagebreak()

=== How to use it?

The main goal of generating SDCs with this POC is to use them as social damage curves, ideally in a tool such as SEICHE.

The latter applies damage functions to land cover datasets according to classes, per-pixel or per-row. The social SDCs could fit in this architecture if they are built to work based on a population dataset. It could serve as a reference, declaring how many statistical humans are present in the considered area, and a damage function would dampen this static raster or vector with a relative damage; in the same way that to obtain the damage estimation with the JRC's damage function, one needs to multiply the maximum damage field by the damage factor.

Doing so can be very practical if the built SDCs are quite generic. For example, they could work on a whole region or country. Multiple simulations are run on a bunch of relevant test cases, allowing one to extrapolate to a defined scope, simply by applying the computed social damage factor function to the population raster of a new area.

However, given the dynamic and highly localizable nature of ABMs, what seems to be the most useful use case is for a local governing entity to generate a set of SDCs adapted to their governance area, based on key hydrological indicators. For example if a city has access to one _in-situ_ water depth station, then the SDCs can be computed by varying the flow input at this point. Then, in a real scenario, the water management corps of the governing entity only has to monitor this indicator to have a quick estimation of the number of endangered and at-risk people. They can include local and granular behaviour in the agents' decision set based on local experience that might not be reflected in global datasets like OpenStreetMap.

And of course it can also be used to plan water protection measures, in a cost-benefit analysis similar to the one Floodam was designed to do. Compute an SDC without the protection measure, assess how many people were endangered, add the protection measure, compute the SDC again, compare. However, from a strictly financial point of view, it is harder to weigh the financial cost against the human benefit, compared to damage functions that assess the economic impact. A cold "average cost-of-life" that is common within insurance frameworks can be used to tackle this issue.

== Possibilities and room for improvement

As mentioned before, the primary challenge is the scientific validation. It is the hardest step and the cornerstone of using such a method in real situations. Modelling human behaviour is not trivial in a few lines of Julia, and hydrodynamic models need expertise to calibrate. So without these steps, the presented SDCs are nothing but a promise of what could be done. As mentioned before, there is enough to occupy one or more PhDs on calibrating a model like this. If feasible and once it is done, SDCs could be generated using this technique, to give an equivalent tool to the damage functions for economic impact estimation.

The main point of this technique is the sheer granularity of insights it allows one to study. In @sdc-attributes we showed the potential of having SDCs adapted to a mock vulnerability factor, risk perception and warning lead time, but the idea could easily be extrapolated to age, disabilities, gender, education, or even ethnicity or culture if the simulation takes them into account. Like any ABM, this is difficult to encode as fixed rules. Doing so raises sociological and ethical questions about researcher and developer bias, making it hard to claim the model plausibly represents reality. You could try to develop statistical models, but where to find such data? And it is not like they do not have biases of their own. But it has been a growing field of studies, and maybe with better insights and social modelling, SDCs derived from ABMs could become useful tools.

Parallel to this, what can be done today to improve the models is to provide better data sources. To keep it global and open source a 30 m DEM or 200 m resolution population raster was used, but if ultimately the goal of such simulations is to be personalized to fit a certain city's needs for example, more precise data could greatly improve the scientific relevance of the obtained results. Torrent.jl was used for simplicity, but more full fledged models like TELEMAC-2D, or global ones like LISFLOOD-FP could be relevant, depending on the scope of the model. Coupling with the ABM could also be relevant. If agents are able to put down sand bags, dykes or any other emergency protection infrastructure, the water behaviour should be changed on-the-fly.

All in all, given sufficient work and time, this is a very promising method; but we are not there yet at all.
