#import "../defs.typ": image-figure, table-figure, txy
= Conflicts of interest

I declare no conflicts of interest. This work was funded 100% by the CNES, in the form of a PhD grant. As part of my PhD I got to work at the public CECI laboratory (UMR 5318 CNRS/Cerfacs/IRD). Because of this, I stayed in the buildings and used the computing infrastructures and a personal laptop from Cerfacs, whose shareholders are the following French companies and public institutions: Airbus, the CNES, EDF, Météo-France, ONERA, Safran and TotalEnergies. They had no say in anything related to this work (except maybe the CNES as my employer), and my stay at Cerfacs does not mean, *in any way*, that I share values or interests with some of the shareholders, nor that I hold myself accountable for what they do. Symmetrically, they should not be held responsible for the work that has been accomplished here, except maybe for lending some of the computing power they paid for. My supervisors guided this work and have influenced it (of course) and are listed here along with their affiliations (in hierarchical order):

- Sophie RICCI (PhD Director): CECI
- Sébastien LE CORRE (PhD Co-director): Université Toulouse - Jean Jaurès (UT2J)
- Raquel RODRIGUEZ-SUQUET (PhD Supervisor): CNES
- Ludovic CASSAN (PhD Supervisor): CECI

= Declaration of LLM use

During the preparation of this work I used LLMs, mainly DeepSeek instances local to Cerfacs, through OpenCode. It mostly happened after September 2026 -- in the last three months of the contract -- when they became available. They allowed me to document and refactor properly and efficiently the SEICHE codebase I built over more than two and a half years at this point. I used them to develop FSFS from scratch, where most of the code is machine generated. They were also used in the writing of this technical report, as per the AGENTS.md file present in the repository. I may also have used some other LLMs in the last three years, but not to the same extent as the tools mentioned in the previous paragraph. After using these tools, I reviewed and edited the content as needed and I take full responsibility for the content of the published code, data, and technical report.

= Data and models availability

All the code produced during this work is open source. The SEICHE pipeline, the main software of this report, is available on GitHub @seiche, along with its documentation and test cases. The FSFS proof-of-concept described in the agent-based modelling chapter is available on a personal repository on GitHub @fsfs.

The input data used by the test cases are mostly openly available: Copernicus data (Sentinel-1 and Sentinel-2 imagery, GLO-30 DSM) through the Copernicus Data Space Ecosystem, OSO land cover (CESBIO) through the CNES GEODES portal, French national datasets (RGE-Alti @rge-alti, BDTopo, RPG, Sirène) through the IGN and INSEE, and population data (GHSL-POP @ghslpop2023, Filosofi @filosofi) through the JRC and INSEE. The ground-truth REX database of the St-Omer test case is the exception: it was made available by the SmageAa @smageaa and cannot be redistributed here; the specific files used in this study are listed in #ref(<data-sources>, supplement: [Appendix]).

Whenever I had the freedom to do so, I put everything in the public domain under the Unlicense @unlicense. Users are encouraged to reuse and build upon this work, with or without attribution.