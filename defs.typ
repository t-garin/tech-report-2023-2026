#import "@preview/merman:0.3.0": mermaid

#let hxy = $H(x, y)$
#let vxy = $V(x, y)$
#let txy = $T(x, y)$

#let diagram_legend_description = [Yellow $arrow$ inputs, Green $arrow$ transformations, Pink $arrow$ intermediary data, Cyan $arrow$ final data.]

#let mermaid-classes = "  classDef input fill:#FFFFCC,stroke:#333333,stroke-width:1px\n  classDef inter fill:#FFCCFF,stroke:#333333,stroke-width:1px\n  classDef final fill:#CCFFFF,stroke:#333333,stroke-width:1px\n  classDef funcs fill:#CCFFCC,stroke:#333333,stroke-width:1px"

#let make-label = label

#let mermaid-figure(
  source,
  caption: none,
  label: none,
  size: 14pt,
  width: 100%,
  legend: true,
) = {
  assert(caption != none)
  assert(label != none)
  align(center + horizon)[
    #figure(caption: caption)[
      #mermaid(
        source,
        width: width,
        typography: (font: "Atkinson Hyperlegible", size: size),
        theme: (edgeLabelBackground: "#ffffff"),
      )
      #if legend [
        #text(size: 9pt, fill: luma(90))[#diagram_legend_description]
      ]
    ]
    #make-label(label)
  ]
}

#let image-figure(
  caption: none,
  label: none,
  path: none,
  width: none,
) = {
  assert(caption != none)
  assert(label != none)
  assert(path != none)
  [#figure(caption: caption)[
      #image(path, ..if width != none { (width: width) })
    ] #make-label(label)]
}

#let bbox-figure(
  caption: none,
  label: none,
  width: 100%,
  ..paths,
) = {
  assert(caption != none)
  assert(label != none)
  let imgs = paths.pos()
  assert(imgs.len() > 0)
  [#figure(caption: caption)[
      #grid(
        columns: (1fr, 1fr),
        gutter: 0.5em,
        align: center,
        ..imgs
          .enumerate()
          .map(((i, path)) => if calc.odd(imgs.len()) and i + 1 == imgs.len() {
            grid.cell(colspan: 2, image(path, width: width / 2))
          } else {
            image(path, width: width)
          }),
      )
    ] #make-label(label)]
}

#let table-figure(
  caption: none,
  label: none,
  columns: none,
  align: left + horizon,
  ..args,
) = {
  assert(caption != none)
  assert(label != none)
  assert(columns != none)
  set par(justify: false)
  [#figure(caption: caption)[
      #table(columns: columns, align: align, ..args)
    ] #make-label(label)]
}
