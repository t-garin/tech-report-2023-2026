// photo
#align(center + horizon)[
  #rect(
    image("../imgs/nils_quais_toulouse_20260217-10.05.33.jpeg", height: 85%),
  )
  Overflowing flood caused by Storms Nils and Oriana\ 43.60312, 1.43556, Toulouse, France\ 17 February 2026 10:05:33, by me (public domain)
]

// quote
#pagebreak()
#align(horizon)[
  #grid(
    columns: (1fr, 57%),
    rows: 1fr,
    align(center)[
      #image("../imgs/Emma_Goldman_seated.jpg", width: 85%)
      #v(4em)
    ],

    [_The primitive man, ignorant of natural forces, dreaded their approach, hiding from the perils they threatened. As man learned to understand Nature’s phenomena, he realized that though these may destroy life and cause great loss, they also bring relief. To the earnest student it must be apparent that the accumulated forces in our social and economic life, culminating in a political act of violence, are similar to the terrors of the atmosphere, manifested in storm and lightning._


      _The Psychology of Political Violence,_ \
      Emma Goldman, 1917],
  )
]

#heading(level: 1, outlined: false, numbering: none)[Preface]
This technical report is born out of my PhD research allowance, that spanned from December 2023 to December 2026. It is a summary of 3 years of exploratory work, where tons of directions and prototypes were examined, abandonned, refactored and often lead to very interesting discussions. Even though it did not lead to a diploma, the conducted work allows to tackle very valuable scientific questions.

The goal of this document is to make it easier for current and future students, scientists and engineers to continue exploring, contradicting, and developing the tools and test cases discussed here. It is complementary to the `seiche` python module's documentation, available in the GitHub repository: @seiche. The scope of this document is broader, more methodological, whereas the documentation is more focused on user guidlines and code implementation.

The vast majority of this work will be written solely in English, as it is the _de facto_ language of science. I will attempt to explain every concept, method, and result in plain language to make it more accessible, for everybody. However, since it is a very technical document with limited space, I cannot always guarantee it, sorry. For inclusivity purposes, this document is written using the Atkinson Hyperlegible font, designed by the Braille Institute of America as both an accessible and modern typeface. Its Mono variant is used for code snippets, and the titles are in Fraunces. I attempted to design the figures with vision impairments in mind, including colour-blindness, though I recognize there may still be accessibility issues.

#heading(level: 1, outlined: false, numbering: none)[Thanks]
This work could not have been done alone, I never was, and it is of the utmost importance to me to take the time to thank everyone involved. Moreover, these three yers were more than work for me, I met amazing people, made long-lasting friendships, built a new life in Toulouse. This will be a bit long, and obviously not at all enough, so please know how much I am thankful for everything. Since most of the people that I want to thank here speak French, this will be the main language of this section.

#line(length: 100%, stroke: 0.25pt)

Ce travail n'aurait jamais pu être accompli seul, je ne l'ai jamais été, et il est d'une importance capitale pour moi de prendre le temps de remercier tout le monde. De plus, ces trois années n'ont pas été que tu travail, j'ai rencontré des personnes formidables, construit des amitiés fortes, et bâti une nouvelle vie à Toulouse. Ce sera un peu long, et clairement pas assez, mais sachez à quel point je suis reconnaissant.

TODO

#pagebreak()

// Merci énormément à Sophie, Sébastien, Raquel, et Ludovic de m'avoir offert cette opportunité, et de m'avoir permis de développer des conaissances et un savoir-faire hyper technique pendant ces trois années. Je suis désolé pour les petits accrocs qu'on a pu avoir par moment, il y'a eu des moments difficiles, qui m'ont ménés à l'arrêt de la thèse, et parfois c'était facile de tout mettre sur le dos des autres. J'ai gagné en maturité, pris en recul, et même si aujourd'hui je pense encore que des choses auraient pu être mieux organisées, je tenais à m'excuser pour les fois où c'était pas justifié. Merci encore pour votre aide, durant ces trois années, y compris humainement, que ça soit avec Sébastien, et surtout Raquel, qui ont su être là quand ça allait pas :)

// Merci aux membres du CSI qui ont participé aux discussions techniques, mais aussi été là pour gérer le déroulé de la thèse au global : Frédéric pour ton expertise technique et ta disponibilité ; Sylvain avec qui c'était toujours un bonheur de parler quand on se croisait dans des évènements scientifiques ; et surtout Vanessya, qui m'a encadrée durant mon stage de fin d'études, avec qui j'ai adoré bosser, et grâce à qui j'ai fini à Toulouse en thèse. Bientôt le chomâge, je guette des opportunités au Cerema, j'espère rejoindre la Maison un jour !


// .. The authors are hugely grateful for the ground truth data made available by Romain QUIGNEAUX, Alexis DEBACQ and Alexia FOSTIER and their colleagues at SmageAa. .. Emma doury Margot roisin jonquière, les gens de santé publique france, les gens de la DTF au cnes, ..


// Merci aux collègues du CNES,


// Merci aux collègues du Cerfacs, CECI et adjacent..es, Andrea et Thanh-Huy pour votre aide technique en hydro ; Isa, Gérard et tous les autres de CSG pour votre aide au quotidien ; Luciano, Guillaume, Anthony, Selime, dans d'autres équipes mais toujours un plaisir à croiser.




// - alba
// - amine
// - quentin
// - camille
// - chloé
// - fousiya
// - lilian
// - olivier
// - zoé
// - eliasz
// - perrine
// - elora

// - andrea thanh-huy

// - les gens du CNES
//   -

// - les vieux
//   - laurent

// - les ancien..nes
//   - juliette, françois, eliott, malak
//   - maxime, remy, romain espoeys
//   - saloua, suzanne salles, suzanne bohr,
//   - théo defontaines, william

// - la nouvelle génération de stagiaires
//   - gabriel, elisa, loly, maxime, terentin

// - la génération d'avant
//   - raphael, françois, matteo,

// - celle d'encore avant
//   - matthias

// - les gens de globc
//   - christophe
//   - soizic
//   - louis
//   - lucav
//   - lucab
//   - romain legendre
//   - cédric
//   - kollo
//   - thomas
//   - wahiba

// Ma famille, ma copine,

// Les ami..es en dehors du travail

// Enfin, les meilleur..es pour la fin, je souhaitais remercier les ami..es que je me suis fait..es à GlobC et ailleurs. Camille me demandait souvent si on était collègues ou ami..es,


#align(right)[
  Mille mercis,

  Théo
]
